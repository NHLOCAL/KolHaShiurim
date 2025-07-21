import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/screens/admin_panel_screen.dart';
import 'package:torah_shiurim_transfer/features/licensing/screens/license_screen.dart'; // Import חדש
import 'package:torah_shiurim_transfer/features/user_panel/screens/user_transfer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  final refreshListenable =
      GoRouterRefreshStream(ref.read(authStateProvider.notifier).stream);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/admin',
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: '/license',
        builder: (context, state) {
          // נטען את ה-provider באופן אסינכרוני ונציג מסך טעינה
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
    redirect: (context, state) async {
      // --- License Check Block START ---
      final licenseManager = await ref.read(licenseManagerProvider.future);
      final isLicensed = await licenseManager.hasValidLicense();
      final isOnLicenseScreen = state.uri.path == '/license';

      if (!isLicensed) {
        return isOnLicenseScreen
            ? null
            : '/license'; // אם אין רישיון, כפה מעבר למסך הרישוי
      }

      if (isLicensed && isOnLicenseScreen) {
        return '/admin'; // אם יש רישיון ונמצאים במסך רישוי, עבור למסך הראשי
      }
      // --- License Check Block END ---

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
