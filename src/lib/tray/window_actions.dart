import 'dart:io' show Platform;
import 'dart:ffi' as dart_ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';
import 'package:win32/win32.dart' as win32;

class WindowActions {
  static late GoRouter router;
  static VoidCallback? onWindowCloseCallback;

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(1280, 720),
      center: true,
      title: 'קול השיעורים',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.hide();
    });

    await windowManager.setPreventClose(true);
    windowManager.addListener(_WindowListener());
  }

  static void _forceShowOnTop() {
    if (!Platform.isWindows) return;

    final ptrTitle = 'קול השיעורים'.toNativeUtf16();

    final hwnd = win32.FindWindow(dart_ffi.nullptr.cast<Utf16>(), ptrTitle);
    calloc.free(ptrTitle);

    if (hwnd == 0) return;

    win32.SetWindowPos(
      hwnd,
      win32.HWND_TOPMOST,
      0,
      0,
      0,
      0,
      win32.SWP_NOMOVE | win32.SWP_NOSIZE | win32.SWP_SHOWWINDOW,
    );
    win32.SetForegroundWindow(hwnd);
  }

  static Future<void> _switchToAdminMode() async {
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    }
    await windowManager.setAlwaysOnTop(false);
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
    await windowManager.setAlwaysOnTop(true);
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
    _forceShowOnTop();
  }

  static Future<void> hide({bool resizeToAdmin = true}) async {
    if (resizeToAdmin) {
      await _switchToAdminMode();
    } else {
      await windowManager.setAlwaysOnTop(false);
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
    WindowActions.onWindowCloseCallback?.call();
  }

  @override
  void onWindowFocus() {}
}
