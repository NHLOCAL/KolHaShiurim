import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/screens/admin_panel_screen.dart';
import 'package:torah_shiurim_transfer/features/licensing/screens/license_screen.dart';
import 'package:torah_shiurim_transfer/features/user_panel/screens/user_transfer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch all dependencies at the top level
  final authState = ref.watch(authStateProvider);
  final licenseStatus = ref.watch(licenseStatusProvider);

  // The refresh listenable needs to react to both auth and license changes.
  // We can achieve this by creating a custom stream or simply by letting
  // the provider re-creation handle it, which it does.
  final refreshListenable =
      GoRouterRefreshStream(ref.watch(authStateProvider.notifier).stream);
  ref.onDispose(refreshListenable.dispose);

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
                body: Center(child: CircularProgressIndicator())),
            error: (err, stack) => Scaffold(
                body:
                    Center(child: Text('Error loading license manager: $err'))),
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
      // The redirect function is now synchronous and safe.
      final isOnLicenseScreen = state.uri.path == '/license';

      // While license status is being determined, don't redirect.
      // This prevents flickering between screens on startup.
      if (licenseStatus.isLoading) {
        return null;
      }

      final isLicensed = licenseStatus.valueOrNull ?? false;

      if (!isLicensed) {
        return isOnLicenseScreen ? null : '/license';
      }

      // If license is valid and we are on the license screen, redirect away.
      if (isLicensed && isOnLicenseScreen) {
        return '/admin';
      }

      // Standard authentication-based redirects
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

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
