import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/router/router.dart';
import 'package:torah_shiurim_transfer/tray/tray_initializer.dart';
import 'package:torah_shiurim_transfer/tray/window_actions.dart';

// הפונקציה הראשית הופכת לאסינכרונית כדי לאפשר אתחול רכיבים
void main() async {
  // ודא שכל רכיבי Flutter מאותחלים
  WidgetsFlutterBinding.ensureInitialized();

  // אתחל את מנהל החלונות והמאזינים שלו
  await WindowActions.init();

  // צור מיכל ספקים (ProviderContainer) כדי לגשת לספקים מחוץ לעץ הווידג'טים
  final container = ProviderContainer();
  // קרא את ספק הנתב והעבר את האובייקט ל-WindowActions
  WindowActions.router = container.read(routerProvider);

  // אתחל את מגש המערכת
  await TrayInitializer().init();

  // הרץ את האפליקציה עם ספק לא מנוהל
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
    // קבל את הנתב מהספק
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
