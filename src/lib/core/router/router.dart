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
    initialLocation: '/admin',
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
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final licenseStatus = ref.read(licenseStatusProvider);

      final isOnLicenseScreen = state.uri.path == '/license';

      if (licenseStatus.isLoading) {
        return null;
      }

      final isLicensed = licenseStatus.valueOrNull ?? false;

      if (!isLicensed) {
        return isOnLicenseScreen ? null : '/license';
      }

      if (isLicensed && isOnLicenseScreen) {
        return '/admin';
      }

      final currentLocation = state.uri.path;

      if (authState.isLoggedOut && currentLocation != '/admin') {
        return '/admin';
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
