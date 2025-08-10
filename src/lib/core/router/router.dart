// core/router/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:kol_hashiurim/features/admin_panel/screens/admin_panel_screen.dart';
import 'package:kol_hashiurim/features/licensing/screens/license_screen.dart';
import 'package:kol_hashiurim/features/user_panel/screens/user_transfer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<int>(0);
  ref.onDispose(refreshListenable.dispose);

  ref.listen(authStateProvider, (_, __) => refreshListenable.value++);
  ref.listen(licenseStatusProvider, (_, __) => refreshListenable.value++);

  return GoRouter(
    initialLocation: '/overlay',
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: '/license',
        builder: (context, state) {
          final licenseManagerAsync = ref.watch(licenseManagerProvider);
          return licenseManagerAsync.when(
            data: (manager) => LicenseScreen(licenseManager: manager),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Scaffold(
              body: Center(child: Text('Error loading license manager: $err')),
            ),
          );
        },
      ),
      GoRoute(
        path: '/user',
        builder: (context, state) => const UserTransferScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: '/overlay',
        builder: (context, state) =>
            const Scaffold(backgroundColor: Colors.transparent),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final licenseStatus = ref.read(licenseStatusProvider);

      final currentLocation = state.uri.path;
      final isOnLicenseScreen = currentLocation == '/license';

      if (licenseStatus.isLoading) {
        return null;
      }

      final isLicensed = licenseStatus.valueOrNull ?? false;

      if (!isLicensed) {
        return isOnLicenseScreen ? null : '/license';
      }

      if (isLicensed && isOnLicenseScreen) {
        return '/overlay';
      }

      if (authState.isLoggedOut && currentLocation != '/overlay') {
        return '/overlay';
      }

      if (authState.isAdmin && currentLocation != '/admin') {
        return '/admin';
      }

      if (authState.isUser && currentLocation != '/user') {
        return '/user';
      }

      return null;
    },
  );
});
