import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:tray_manager/tray_manager.dart';
import 'window_actions.dart';

class TrayInitializer with TrayListener {
  final ProviderContainer _container;
  TrayInitializer(this._container);

  Future<void> init() async {
    trayManager.addListener(this);

    await trayManager.setIcon('assets/icons/app_icon.ico');
    await trayManager.setToolTip('העברת שיעורי תורה');

    final menu = Menu(items: [
      MenuItem(
        label: 'פתח פאנל ניהול',
        onClick: (_) =>
            _container.read(authStateProvider.notifier).loginAsAdmin(),
      ),
      MenuItem.separator(),
      MenuItem(
        label: 'יציאה',
        onClick: (_) => WindowActions.exitApp(),
      ),
    ]);
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    _container.read(authStateProvider.notifier).loginAsAdmin();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }
}
