// main.dart (מעודכן)
// מטרת הקובץ: לוודא שהיישום לא יופיע על המסך ב-startSilent,
// ולנהל במפורש מתי להראות את החלון.

import 'dart:ffi' as ffi;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:kol_hashiurim/core/router/router.dart';
import 'package:kol_hashiurim/tray/tray_initializer.dart';
import 'package:kol_hashiurim/tray/window_actions.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // window_manager צריך להיאתחל מוקדם ככל האפשר.
  await windowManager.ensureInitialized();

  // קו־שיח עם COM במצב multithreaded (מקורי שלך).
  final hr = CoInitializeEx(ffi.nullptr, COINIT_MULTITHREADED);
  if (FAILED(hr)) {
    // זרוק שגיאה שמזוהה ב־WindowsException (כמו במקור)
    throw WindowsException(hr);
  }

  // Provider container מוקדם — ישירות אחרי אתחול הסביבת הריצה.
  final container = ProviderContainer();
  final logService = container.read(logServiceProvider);

  // אתחול לוגר — חשוב לרשום מוקדם מה קורה.
  await logService.init();
  logService.logInfo('Logger initialized in main.');

  // בדיקת ארגומנטים מוקדמת
  final bool startSilently = args.contains('--silent') || args.contains('-s');
  logService.logInfo('startSilently = $startSilently');
  // רישום נוסף לעזור בדיבוג: כל args
  logService.logInfo('Process args: $args');

  // הגדרת אפשרויות החלון (לא כולל show:false מכיוון שלא תמיד קיים
  // הפרמטר הזה בתצורות שונות של window_manager; נסתמך על native runner
  // שלא יוצר WS_VISIBLE כפי ששינינו ברמת runner).
  final WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    title: 'קול השיעורים',
    // אפשרויות נוספות (אם תרצו): skipTaskbar, titleBarStyle, וכו'.
    // לדוגמה: skipTaskbar: true כש-startSilently==true — זה תלוי בהתנהגות שרוצים.
  );

  // מחכה עד שהחלון מוכן להראות / להסתיר.
  // חשוב: ממתינים ל־Future כדי שהקריאה תושלם לפני המשך אתחול.
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    try {
      if (startSilently) {
        logService.logInfo(
          'Application starting silently: keeping window hidden.',
        );
        // ניסיונות להסתרה — אם ה-native לא הראה חלון זה יהיה no-op.
        // חשוב: השינוי ברמת windows/runner מונע את ה־flash; כאן אנחנו
        // רק מוודאים במידה והחלון הוצג - נסתר אותו.
        await windowManager.hide();

        // אופציונלי: ניתן למנוע הופעה במשורת המשימות בעזרת skipTaskbar
        // אם רוצים גם זאת עושים כאן בהתאם ללוגיקה.
      } else {
        logService.logInfo('Application starting normally: showing window.');
        await windowManager.show();
        await windowManager.focus();
        // בצד Dart — בצע login רק אחרי שהחלון מוצג (כפי שהיה במקור).
        container.read(authStateProvider.notifier).loginAsAdmin();
      }
    } catch (e, st) {
      // אם חל שגיאה בספריית window_manager — נדאג לרשום אותה
      logService.logError('Error while handling readyToShow: $e\n$st');
    }
  });

  // אתחול פעולות החלון (לא אמורות לקרוא show() פנימית בלי בדיקה).
  await WindowActions.init();

  // קביעת callback לסגירת החלון
  WindowActions.onWindowCloseCallback = () {
    logService.logUserActivity('Application window closed, logging out.');
    container.read(authStateProvider.notifier).logout();
  };

  // אתחול הטריי (אייקון וכו') — בדרך כלל צריך את ה-container.
  await TrayInitializer(container).init();

  // Router ושאר אתחולים
  final router = container.read(routerProvider);
  WindowActions.router = router;

  // טעינת הגדרות מתוך DB לפני הרצת ה־UI
  await container.read(databaseProvider).getAppSettings();
  logService.logInfo('App settings loaded.');

  // עכשיו מריצים את ה־Flutter app
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

// שאר הקובץ MyApp כפי שהיה אצלך — השארתי ללא שינוי פונקציונלי כדי לשמור
// על עיצוב, נושאים, ו־router שנמצא בפרויקט שלך.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  static const Color accentGold = Color(0xFFB89B72);
  static const Color parchmentBackground = Color(0xFFF9F6F2);
  static const Color inkBrownText = Color(0xFF3C3631);
  static const Color darkBackground = Color(0xFF2E2823);
  static const Color darkSurface = Color(0xFF4A433D);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: accentGold,
        onPrimary: Colors.white,
        secondary: accentGold,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: parchmentBackground,
        onSurface: inkBrownText,
      ),
      scaffoldBackgroundColor: parchmentBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: parchmentBackground,
        foregroundColor: inkBrownText,
        titleTextStyle: TextStyle(
          color: inkBrownText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: Theme.of(
        context,
      ).textTheme.apply(bodyColor: inkBrownText, displayColor: inkBrownText),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: accentGold,
        onPrimary: inkBrownText,
        secondary: accentGold,
        onSecondary: inkBrownText,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: darkSurface,
        onSurface: parchmentBackground,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkBackground,
        foregroundColor: parchmentBackground,
        titleTextStyle: TextStyle(
          color: parchmentBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: inkBrownText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
    return MaterialApp.router(
      title: 'קול השיעורים',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      locale: const Locale('he', 'IL'),
      supportedLocales: const [Locale('he', 'IL'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
