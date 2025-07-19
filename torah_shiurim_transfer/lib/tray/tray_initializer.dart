import 'package:tray_manager/tray_manager.dart';
import 'window_actions.dart';

class TrayInitializer with TrayListener {
  Future<void> init() async {
    trayManager.addListener(this);
    // יש לוודא שהקובץ 'assets/icons/app_icon.ico' קיים בפרויקט
    await trayManager.setIcon('assets/icons/app_icon.ico');
    await trayManager.setToolTip('העברת שיעורי תורה');

    // הגדרת התפריט שיופיע בלחיצה ימנית
    final menu = Menu(items: [
      MenuItem(
        label: 'פתח פאנל ניהול',
        onClick: (_) => WindowActions.showAdminPanel(),
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
    // לחיצה שמאלית: הצג את פאנל הניהול
    WindowActions.showAdminPanel();
  }

  @override
  void onTrayIconRightMouseDown() {
    // לחיצה ימנית: הצג את התפריט
    trayManager.popUpContextMenu();
  }
}
