// lib/tray/window_actions.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart'; // לשם Catch של MissingPluginException

class WindowActions {
  static late GoRouter router;

  /// אתחול מנהל החלונות
  static Future<void> init() async {
    // אתחול הביינדינג לפני שימוש ב־window_manager
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(1280, 720),
      center: true,
      title: 'העברת שיעורי תורה',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.hide();
    });

    await windowManager.setPreventClose(true);
    windowManager.addListener(_WindowListener());
  }

  /// מעבר למצב ניהול (חלון רגיל)
  static Future<void> _switchToAdminMode() async {
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    }
    await windowManager.setResizable(true);

    // ניסיון ראשון: לפי פלטפורמה
    if (!Platform.isWindows) {
      try {
        await windowManager.setMovable(true);
      } on MissingPluginException {
        // התעלמות אם אין מימוש
      }
    }

    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setSize(const Size(1280, 720));
    await windowManager.center();
  }

  /// מעבר למצב קיוסק (מסך מלא ונעול)
  static Future<void> _switchToKioskMode() async {
    await windowManager.setFullScreen(true);
    await windowManager.setResizable(false);

    if (!Platform.isWindows) {
      try {
        await windowManager.setMovable(false);
      } on MissingPluginException {
        // התעלמות אם אין מימוש
      }
    }

    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  }

  /// הצגת פאנל מנהל
  static Future<void> showAdminPanel() async {
    await _switchToAdminMode();
    router.go('/admin');
    await windowManager.show();
    await windowManager.focus();
  }

  /// הצגת פאנל משתמש
  static Future<void> showUserPanel() async {
    await _switchToKioskMode();
    router.go('/user');
    await windowManager.show();
    await windowManager.focus();
  }

  /// הסתרת החלון וחזרה למצב ניהול
  static Future<void> hide() async {
    await _switchToAdminMode();
    await windowManager.hide();
  }

  /// סגירת האפליקציה
  static Future<void> exitApp() async {
    await trayManager.destroy();
    await windowManager.destroy();
  }
}

class _WindowListener extends WindowListener {
  @override
  void onWindowClose() {
    WindowActions.hide();
  }

  @override
  void onWindowFocus() {
    // במידת הצורך – הוספת לוגיקה למצב קיוסק
  }
}
