import 'dart:ffi' as ffi;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/core/router/router.dart';
import 'package:torah_shiurim_transfer/tray/tray_initializer.dart';
import 'package:torah_shiurim_transfer/tray/window_actions.dart';
import 'package:win32/win32.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hr = CoInitializeEx(ffi.nullptr, COINIT_MULTITHREADED);
  if (FAILED(hr)) {
    throw WindowsException(hr);
  }
  await WindowActions.init();
  final container = ProviderContainer();
  final logService = container.read(logServiceProvider);
  await logService.init();
  WindowActions.onWindowCloseCallback = () {
    logService.logUserActivity('Application window closed, logging out.');
    container.read(authStateProvider.notifier).logout();
  };
  await TrayInitializer(container).init();
  final router = container.read(routerProvider);
  WindowActions.router = router;
  await container.read(databaseProvider).getAppSettings();
  logService.logInfo('App settings loaded.');
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // --- סכמת הצבעים המעודכנת והמקצועית ---
  static const Color accentGold = Color(0xFFB89B72);
  static const Color parchmentBackground = Color(0xFFF9F6F2);
  static const Color inkBrownText = Color(0xFF3C3631);
  static const Color darkBackground = Color(0xFF2E2823); // רקע כהה עוד יותר לרצינות
  static const Color darkSurface = Color(0xFF4A433D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // --- ערכת נושא בהירה - נקייה וקריאה ---
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
        background: parchmentBackground,
        onBackground: inkBrownText,
        surface: parchmentBackground, // רקע לקלפים ודיאלוגים
        onSurface: inkBrownText, // טקסט על קלפים ודיאלוגים
      ),
      scaffoldBackgroundColor: parchmentBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: parchmentBackground,
        foregroundColor: inkBrownText, // צבע לאייקונים ולטקסט ב-AppBar
        titleTextStyle: TextStyle(
          color: inkBrownText,
          fontSize: 20,
          fontWeight: FontWeight.w600, // משקל מעט קל יותר למראה נקי
        ),
      ),
      // התאמות נוספות לקריאות ונוחות
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: inkBrownText,
        displayColor: inkBrownText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );

    // --- ערכת נושא כהה - מכובדת וברורה ---
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: accentGold,
        onPrimary: inkBrownText, // ניגודיות טובה על זהב
        secondary: accentGold,
        onSecondary: inkBrownText,
        error: Colors.redAccent,
        onError: Colors.white,
        background: darkBackground,
        onBackground: parchmentBackground,
        surface: darkSurface, // משטח מעט בהיר יותר ליצירת עומק
        onSurface: parchmentBackground, // טקסט על המשטח
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
      title: 'העברת שיעורי תורה',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system, // מומלץ להתאמה אוטומטית למערכת
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