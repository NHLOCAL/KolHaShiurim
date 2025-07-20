import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/core/router/router.dart';
import 'package:torah_shiurim_transfer/tray/tray_initializer.dart';
import 'package:torah_shiurim_transfer/tray/window_actions.dart';

void main() async {
  await WindowActions.init();

  final container = ProviderContainer();

  // אתחול שירות הלוג לפני כל שימוש בו
  final logService = container.read(logServiceProvider);
  await logService.init();

  WindowActions.onWindowCloseCallback = () {
    logService.logUserActivity('Application window closed, logging out.');
    container.read(authStateProvider.notifier).logout();
  };

  await TrayInitializer(container).init();

  WindowActions.router = container.read(routerProvider);

  // וודא שהגדרות האפליקציה נטענות מוקדם
  await container.read(databaseProvider).getAppSettings();
  logService.logInfo('App settings loaded.');

  await container.read(authStateProvider.notifier).loginAsAdmin();
  logService.logInfo('Initial admin login attempt completed.');

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // NEW: הסרת ההתייחסות ל-logService מתוך מתודת ה-build של MyApp
    // final logService = ref.watch(logServiceProvider);

    return MaterialApp.router(
      title: 'העברת שיעורי תורה',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 1,
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      themeMode: ThemeMode.light,
      locale: const Locale('he', 'IL'),
      supportedLocales: const [
        Locale('he', 'IL'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
