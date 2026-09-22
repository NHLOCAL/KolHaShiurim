import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:kol_hashiurim/core/router/router.dart';
import 'package:kol_hashiurim/features/admin_panel/screens/admin_panel_screen.dart';
import 'package:kol_hashiurim/services/device_service.dart';

import 'helpers/test_log_service.dart';

void main() {
  testWidgets('fresh installation opens administration without activation', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final logger = TestLogService();
    final devices = DeviceService(logger, scanDevices: () async => []);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        logServiceProvider.overrideWithValue(logger),
        deviceServiceProvider.overrideWithValue(devices),
        authStateProvider.overrideWith(
          (ref) => AuthStateNotifier(ref, enableDevicePolling: false),
        ),
      ],
    );
    final router = container.read(routerProvider);
    addTearDown(() async {
      router.dispose();
      container.dispose();
      devices.dispose();
      await database.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // Let asset and filesystem futures finish before checking the initial route.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/admin');
    expect(find.byType(AdminPanelScreen), findsOneWidget);

    // Device authorization still controls access to the transfer panel.
    router.go('/user');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/admin');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
