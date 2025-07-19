import 'package:flutter/material.dart'; // <-- ייבוא חסר שנוסף
import 'package:go_router/go_router.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class WindowActions {
  // נכסה את הנתב כאן כדי לאפשר ניווט מחוץ לווידג'טים
  static late GoRouter router;

  static Future<void> init() async {
    // אתחול מנהל החלונות
    await windowManager.ensureInitialized();

    // הגדרות ראשוניות לחלון
    const WindowOptions windowOptions = WindowOptions(
      size: Size(1280, 720), // <-- השגיאה הייתה כאן
      center: true,
      title: 'העברת שיעורי תורה',
    );

    // המתן עד שהחלון יהיה מוכן להצגה, ואז הסתר אותו
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.hide(); // התחל במצב מוסתר
    });

    // מנע סגירה של האפליקציה, במקום זאת היא תוסתר
    await windowManager.setPreventClose(true);
    // הוסף מאזין לאירועי חלון
    windowManager.addListener(_WindowListener());
  }

  /// מציג את פאנל הניהול
  static void showAdminPanel() {
    router.go('/admin');
    windowManager.show();
    windowManager.focus();
  }

  /// מציג את ממשק המשתמש להעברת קבצים
  static void showUserPanel() {
    // הניווט ל'/user' יטופל על ידי ה-redirect של GoRouter
    // ויוודא שהמשתמש אכן מחובר
    router.go('/user');
    windowManager.show();
    windowManager.focus();
  }

  /// מסתיר את החלון
  static void hide() {
    windowManager.hide();
  }

  /// סוגר את האפליקציה לחלוטין
  static Future<void> exitApp() async {
    await trayManager.destroy();
    await windowManager.destroy();
  }
}

/// מאזין פרטי לאירועי חלון
class _WindowListener extends WindowListener {
  @override
  void onWindowClose() {
    // כאשר המשתמש לוחץ על 'X', הסתר את החלון במקום לסגור
    WindowActions.hide();
  }
}
