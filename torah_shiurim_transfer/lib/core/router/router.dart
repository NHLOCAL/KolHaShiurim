import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/screens/admin_panel_screen.dart';
import 'package:torah_shiurim_transfer/features/auth/screens/auth_gate_screen.dart';
import 'package:torah_shiurim_transfer/features/user_panel/screens/user_transfer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  // Create a listenable to refresh the router when auth state changes.
  final refreshListenable = GoRouterRefreshStream(ref.read(authStateProvider.notifier).stream);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthGateScreen(),
      ),
      GoRoute(
        path: '/user',
        builder: (context, state) => const UserTransferScreen(),
      ),
      GoRoute(
        path: '/admin',
        // CHANGED: Point to the new, functional admin panel screen.
        builder: (context, state) => const AdminPanelScreen(),
      ),
    ],
    redirect: (context, state) {
      final currentLocation = state.uri.path;
      
      // If we are logged out, we must be on the auth gate screen.
      if (authState.isLoggedOut) {
        return currentLocation == '/' ? null : '/';
      }
      
      // If we are an admin, we must be on the admin screen.
      if (authState.isAdmin && currentLocation != '/admin') {
        return '/admin';
      }
      
      // If we are a user, we must be on the user screen.
      if (authState.isUser && currentLocation != '/user') {
        return '/user';
      }
      
      // No redirect needed.
      return null;
    },
  );
});

// Helper class to notify GoRouter of state changes.
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