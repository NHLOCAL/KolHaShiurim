import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ייבוא זה יעבוד לאחר התיקון
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/router/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
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
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      themeMode: ThemeMode.system,
      // הגדרות תמיכה בעברית ו-RTL
      locale: const Locale('he', 'IL'),
      supportedLocales: const [
        Locale('he', 'IL'),
        Locale('en', 'US'), // Optional: for fallback
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
