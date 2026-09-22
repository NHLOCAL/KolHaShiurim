import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:kol_hashiurim/features/admin_panel/screens/admin_panel_screen.dart';
import 'package:kol_hashiurim/features/user_panel/screens/user_transfer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<int>(0);
  ref.onDispose(refreshListenable.dispose);

  ref.listen(authStateProvider, (_, __) => refreshListenable.value++);

  return GoRouter(
    initialLocation: '/admin',
    refreshListenable: refreshListenable,
    routes: [
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
