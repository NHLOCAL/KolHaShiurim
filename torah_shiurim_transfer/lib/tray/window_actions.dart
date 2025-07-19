import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';

class WindowActions {
  static late GoRouter router;

  static Future<void> init() async {
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

  static Future<void> _switchToAdminMode() async {
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    }
    await windowManager.setResizable(true);

    if (!Platform.isWindows) {
      try {
        await windowManager.setMovable(true);
      } on MissingPluginException {}
    }

    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setSize(const Size(1280, 720));
    await windowManager.center();
  }

  static Future<void> _switchToKioskMode() async {
    await windowManager.setFullScreen(true);
    await windowManager.setResizable(false);

    if (!Platform.isWindows) {
      try {
        await windowManager.setMovable(false);
      } on MissingPluginException {}
    }

    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  }

  static Future<void> showAdminPanel() async {
    await _switchToAdminMode();
    router.go('/admin');
    await windowManager.show();
    await windowManager.focus();
  }

  static Future<void> showUserPanel() async {
    await _switchToKioskMode();
    router.go('/user');
    await windowManager.show();
    await windowManager.focus();
  }

  static Future<void> hide({bool resizeToAdmin = true}) async {
    if (resizeToAdmin) {
      await _switchToAdminMode();
    }
    await windowManager.hide();
  }

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
  void onWindowFocus() {}
}
