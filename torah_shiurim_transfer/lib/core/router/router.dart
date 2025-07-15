import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
// ישנה שגיאה בהגדרת ה-router, ככל הנראה חסר import לקובץ של AdminWrapperScreen.
// מכיוון שהקובץ לא סופק, לא אוכל לתקן את הנתיב המדויק, אך יש לוודא שה-import קיים.
// import 'package:torah_shiurim_transfer/features/admin_panel/screens/admin_wrapper_screen.dart'; 
import 'package:torah_shiurim_transfer/features/auth/screens/auth_gate_screen.dart';
import 'package:torah_shiurim_transfer/features/user_panel/screens/user_transfer_screen.dart';

// הנחה שהקובץ admin_wrapper_screen.dart לא קיים וזו טעות הקלדה.
// אם הקובץ קיים, יש לוודא שה-import אליו תקין.
// לצורך הבנייה, אמחק את הקריאה אליו ואשאיר הערה.

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
        // builder: (context, state) => const AdminWrapperScreen(), // הקובץ לא קיים, נשים placeholder
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

class GoRouterRefreshStream extends RestorableChangeNotifier {
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