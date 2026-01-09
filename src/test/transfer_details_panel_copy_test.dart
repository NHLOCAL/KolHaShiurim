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
import 'package:kol_hashiurim/services/file_service.dart';
import 'package:kol_hashiurim/models/app_user.dart';

import 'helpers/test_log_service.dart';

class FakeFileService extends FileService {
  FakeFileService(super.logService);

  String? lastDestinationDirectory;
  String? lastNewFileName;
  File? lastSourceFile;
  var copyCalled = false;

  @override
  Future<void> copyFile({
    required File sourceFile,
    required String destinationDirectory,
    required String newFileName,
  }) async {
    copyCalled = true;
    lastSourceFile = sourceFile;
    lastDestinationDirectory = destinationDirectory;
    lastNewFileName = newFileName;
  }

  @override
  Future<void> convertAndCopyFile({
    required File sourceFile,
    required String destinationDirectory,
    required String newFileName,
    required int bitrate,
  }) async {
    throw UnimplementedError('convertAndCopyFile should not be called.');
  }
}

class FakeAuthStateNotifier extends StateNotifier<AppUserState> {
  FakeAuthStateNotifier() : super(const AppUserState.loggedOut());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('com.ryanheise.just_audio.methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'init') {
        return 1;
      }
      return null;
    });
  });

  tearDownAll(() {
    const channel = MethodChannel('com.ryanheise.just_audio.methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('copy uses base directory when single path is allowed', (
    tester,
  ) async {
    final tempDir = await Directory.systemTemp.createTemp('panel-copy');
    addTearDown(() => tempDir.delete(recursive: true));
    final sourceFile = File('${tempDir.path}/source.mp3');
    await sourceFile.writeAsString('audio');

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => database.close());

    final fakeFileService = FakeFileService(TestLogService());
    final permission = UserPermissionInfo(
      rabbi: Rabbi(id: 1, name: 'Rabbi A', targetPath: tempDir.path),
      specificPaths: const [null],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          logServiceProvider.overrideWithValue(TestLogService()),
          fileServiceProvider.overrideWithValue(fakeFileService),
          authStateProvider.overrideWith((ref) => FakeAuthStateNotifier()),
          allowedRabbisProvider.overrideWith(
            (ref) => Stream.value([permission]),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TransferDetailsPanel(
              selectedFile: sourceFile,
              onCopyComplete: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<UserPermissionInfo>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rabbi A').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('העתק את השיעור'));
    await tester.pumpAndSettle();

    expect(fakeFileService.copyCalled, isTrue);
    expect(fakeFileService.lastDestinationDirectory, tempDir.path);
    expect(fakeFileService.lastSourceFile?.path, sourceFile.path);
  });

  testWidgets('copy shows warning when specific path not selected', (
    tester,
  ) async {
    final tempDir = await Directory.systemTemp.createTemp('panel-copy-multi');
    addTearDown(() => tempDir.delete(recursive: true));
    final sourceFile = File('${tempDir.path}/source.mp3');
    await sourceFile.writeAsString('audio');

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => database.close());

    final fakeFileService = FakeFileService(TestLogService());
    final permission = UserPermissionInfo(
      rabbi: Rabbi(id: 1, name: 'Rabbi B', targetPath: tempDir.path),
      specificPaths: const ['sub-a', 'sub-b'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          logServiceProvider.overrideWithValue(TestLogService()),
          fileServiceProvider.overrideWithValue(fakeFileService),
          authStateProvider.overrideWith((ref) => FakeAuthStateNotifier()),
          allowedRabbisProvider.overrideWith(
            (ref) => Stream.value([permission]),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TransferDetailsPanel(
              selectedFile: sourceFile,
              onCopyComplete: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<UserPermissionInfo>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rabbi B').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('העתק את השיעור'));
    await tester.pump();

    expect(fakeFileService.copyCalled, isFalse);
    expect(find.text('יש לבחור תיקיית משנה ליעד'), findsOneWidget);
  });
}
