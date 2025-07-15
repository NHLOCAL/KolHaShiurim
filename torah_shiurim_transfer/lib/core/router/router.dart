import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';



import 'package:torah_shiurim_transfer/features/auth/screens/auth_gate_screen.dart';
import 'package:torah_shiurim_transfer/features/user_panel/screens/user_transfer_screen.dart';
import 'package:flutter/material.dart';





final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
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

        builder: (context, state) => const Scaffold(body: Center(child: Text("Admin Panel Placeholder"))),
      ),
    ],
    redirect: (context, state) {
      final currentLocation = state.uri.path;
      if (authState.isLoggedOut) {
        return currentLocation == '/' ? null : '/';
      }
      if (authState.isAdmin && currentLocation != '/admin') {
        return '/admin';
      }
      if (authState.isUser && currentLocation != '/user') {
        return '/user';
      }
      return null;
    },
    refreshListenable:
        GoRouterRefreshStream(ref.read(authStateProvider.notifier).stream),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription =
        stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}