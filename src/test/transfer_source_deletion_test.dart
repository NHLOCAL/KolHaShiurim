import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:kol_hashiurim/features/user_panel/providers/user_panel_providers.dart';
import 'package:kol_hashiurim/features/user_panel/widgets/transfer_details_panel.dart';
import 'package:kol_hashiurim/services/device_service.dart';
import 'package:kol_hashiurim/services/file_service.dart';

import 'helpers/test_log_service.dart';

class _CopyService extends FileService {
  _CopyService() : super(TestLogService());

  @override
  Future<void> copyFile({
    required File sourceFile,
    required String destinationDirectory,
    required String newFileName,
  }) async {
    await sourceFile.copy('$destinationDirectory/$newFileName');
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 100 && !ready(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(ready(), isTrue);
}

void main() {
  for (final deleteSource in [true, false]) {
    testWidgets(
      deleteSource
          ? 'source deletion waits for preview release before completing transfer'
          : 'keeping the source does not tear down the preview player',
      (tester) async {
        final directory = Directory.systemTemp.createTempSync(
          'preview-delete-',
        );
        final source = File('${directory.path}/source.wav')
          ..writeAsStringSync('audio');
        final database = AppDatabase.forTesting(NativeDatabase.memory());
        final logger = TestLogService();
        final devices = DeviceService(logger, scanDevices: () async => []);
        final release = Completer<void>();
        var releaseRequested = false;
        var loaded = false;
        var completed = false;
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        final channels = <MethodChannel>[];
        void mock(String name, Future<Object?> Function(MethodCall) handler) {
          final channel = MethodChannel(name);
          channels.add(channel);
          messenger.setMockMethodCallHandler(channel, handler);
        }

        mock('com.ryanheise.audio_session', (_) async => null);
        mock('com.ryanheise.just_audio.methods', (call) async {
          final args = call.arguments as Map;
          if (call.method == 'init') {
            final id = args['id'];
            mock('com.ryanheise.just_audio.events.$id', (_) async => null);
            mock('com.ryanheise.just_audio.data.$id', (_) async => null);
            mock('com.ryanheise.just_audio.methods.$id', (playerCall) async {
              if (playerCall.method == 'load') {
                loaded = true;
                ServicesBinding.instance.channelBuffers.push(
                  'com.ryanheise.just_audio.events.$id',
                  const StandardMethodCodec().encodeSuccessEnvelope({
                    'processingState': 3,
                    'updatePosition': 0,
                    'updateTime': DateTime.now().millisecondsSinceEpoch,
                    'bufferedPosition': 1000000,
                    'duration': 1000000,
                    'currentIndex': 0,
                  }),
                  (_) {},
                );
                return {'duration': 1000000};
              }
              return <String, Object?>{};
            });
          } else if (call.method == 'disposePlayer') {
            releaseRequested = true;
            await release.future;
          }
          return <String, Object?>{};
        });

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(database),
            logServiceProvider.overrideWithValue(logger),
            deviceServiceProvider.overrideWithValue(devices),
            fileServiceProvider.overrideWithValue(_CopyService()),
            authStateProvider.overrideWith(
              (ref) => AuthStateNotifier(ref, enableDevicePolling: false),
            ),
            allowedRabbisProvider.overrideWith(
              (ref) => Stream.value([
                UserPermissionInfo(
                  rabbi: Rabbi(
                    id: 1,
                    name: 'Test rabbi',
                    targetPath: directory.path,
                  ),
                  specificPaths: [null],
                ),
              ]),
            ),
          ],
        );
        addTearDown(() async {
          if (!release.isCompleted) release.complete();
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          container.dispose();
          devices.dispose();
          await database.close();
          for (final channel in channels) {
            messenger.setMockMethodCallHandler(channel, null);
          }
          directory.deleteSync(recursive: true);
        });

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TransferDetailsPanel(
                  selectedFile: source,
                  onCopyComplete: () => completed = true,
                ),
              ),
            ),
          ),
        );
        await _pumpUntil(
          tester,
          () => loaded && find.text('בחר רב').evaluate().isNotEmpty,
        );
        await tester.tap(
          find.byType(DropdownButtonFormField<UserPermissionInfo>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Test rabbi').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('העתק את השיעור'));
        await _pumpUntil(
          tester,
          () => find.text('מחק קובץ מקור').evaluate().isNotEmpty,
        );
        await tester.tap(
          find.text(deleteSource ? 'מחק קובץ מקור' : 'השאר קובץ מקור'),
        );
        if (deleteSource) {
          await _pumpUntil(tester, () => releaseRequested || completed);
          expect(releaseRequested, isTrue);
          expect(source.existsSync(), isTrue);
          expect(completed, isFalse);
          release.complete();
          await _pumpUntil(tester, () => completed);
          expect(source.existsSync(), isFalse);
        } else {
          await _pumpUntil(tester, () => completed);
          expect(source.existsSync(), isTrue);
          expect(releaseRequested, isFalse);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
