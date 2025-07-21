import 'dart:ffi' as ffi; // For Pointer and ffi.nullptr
// If you still need Utf8/malloc, etc.

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

  // Initialize COM for apartment threading
  final hr = CoInitializeEx(ffi.nullptr, COINIT_APARTMENTTHREADED);
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

  // Provide router to WindowActions after creation
  final router = container.read(routerProvider);
  WindowActions.router = router;

  await container.read(databaseProvider).getAppSettings();
  logService.logInfo('App settings loaded.');

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );

  // (Optional) Uninitialize COM when the app really closes
  // CoUninitialize();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

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
