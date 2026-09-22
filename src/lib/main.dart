import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:kol_hashiurim/core/router/router.dart';
import 'package:kol_hashiurim/sponsor_banner.dart';
import 'package:kol_hashiurim/tray/tray_initializer.dart';
import 'package:kol_hashiurim/tray/window_actions.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Removed CoInitializeEx call to prevent RPC_E_CHANGED_MODE error.
  // Flutter and window_manager already initialize COM on the main thread.

  final container = ProviderContainer();
  final logService = container.read(logServiceProvider);
  await logService.init();
  logService.logInfo('Logger initialized in main.');

  final bool startSilently = args.contains('--silent') || args.contains('-s');
  logService.logInfo('startSilently = $startSilently');
  logService.logInfo('Process args: $args');

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 720),
    center: true,
    title: 'קול השיעורים',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    try {
      if (startSilently) {
        logService.logInfo(
          'Application starting silently: keeping window hidden.',
        );
        await windowManager.hide();
      } else {
        logService.logInfo('Application starting normally: showing window.');
        await windowManager.show();
        await windowManager.focus();
        container.read(authStateProvider.notifier).loginAsAdmin();
      }
    } catch (e, st) {
      logService.logError('Error while handling readyToShow: $e\n$st');
    }
  });

  await WindowActions.init();
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
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(child: child ?? const SizedBox.shrink()),
            const SponsorBanner(),
          ],
        ),
      ),
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
