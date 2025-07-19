import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/screens/admin_panel_screen.dart';
// auth_gate_screen יובא מכאן, אין בו צורך יותר
import 'package:torah_shiurim_transfer/features/user_panel/screens/user_transfer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  final refreshListenable =
      GoRouterRefreshStream(ref.read(authStateProvider.notifier).stream);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/admin', // התחל תמיד במסך הניהול
    refreshListenable: refreshListenable,
    routes: [
      // הסרנו את הנתיב '/' שהוביל למסך הכניסה
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
      final currentLocation = state.uri.path;

      // כאשר המשתמש מנותק (התקן נותק), החלון מוסתר על ידי ה-Notifier.
      // ה-redirect יוודא שהמצב הלוגי חוזר למסך הניהול.
      if (authState.isLoggedOut && currentLocation != '/admin') {
        return '/admin';
      }

      // אם המצב הוא "מנהל" והמיקום אינו פאנל הניהול, הפנה אותו לשם.
      if (authState.isAdmin && currentLocation != '/admin') {
        return '/admin';
      }

      // אם המצב הוא "משתמש" (התקן חובר) והוא לא במסך המשתמש, הפנה אותו לשם.
      if (authState.isUser && currentLocation != '/user') {
        return '/user';
      }

      // אין צורך בהפניה
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
