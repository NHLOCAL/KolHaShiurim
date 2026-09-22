import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kol_hashiurim/core/router/router.dart';
import 'package:kol_hashiurim/main.dart';
import 'package:kol_hashiurim/sponsor_banner.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('app footer blends into $brightness on user and admin routes', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final router = GoRouter(
        initialLocation: '/user',
        routes: [
          GoRoute(
            path: '/user',
            builder: (_, _) => const Scaffold(body: Text('user')),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, _) => const Scaffold(body: Text('admin')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [routerProvider.overrideWithValue(router)],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      for (final route in ['/user', '/admin']) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(
          find.text('בחסות אלף בוט - תמלול מדויק לתוכן תורני'),
          findsOneWidget,
        );
        final banner = find.byType(SponsorBanner);
        expect(
          tester.getSize(banner).width,
          tester.view.physicalSize.width / tester.view.devicePixelRatio,
        );
        final material = tester.widget<Material>(
          find.descendant(of: banner, matching: find.byType(Material)).first,
        );
        expect(
          material.color,
          brightness == Brightness.dark
              ? MyApp.darkBackground
              : MyApp.parchmentBackground,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('sponsor remains visible on each route at a narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Column(
          children: [
            Expanded(child: child!),
            const SponsorBanner(),
          ],
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/admin'),
              child: const Text('העברה'),
            ),
          ),
        ),
        routes: {'/admin': (context) => const Scaffold(body: Text('ניהול'))},
      ),
    );

    expect(
      find.text('בחסות אלף בוט - תמלול מדויק לתוכן תורני'),
      findsOneWidget,
    );
    expect(find.text('0774632641'), findsOneWidget);
    await tester.tap(find.text('העברה'));
    await tester.pumpAndSettle();
    expect(find.text('ניהול'), findsOneWidget);
    expect(
      find.text('בחסות אלף בוט - תמלול מדויק לתוכן תורני'),
      findsOneWidget,
    );
    expect(find.text('0774632641'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('website link opens the sponsor URL and reports failure', (
    tester,
  ) async {
    Uri? requested;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SponsorBanner(
            launchWebsite: (uri) async {
              requested = uri;
              return false;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('בחסות אלף בוט - תמלול מדויק לתוכן תורני'));
    await tester.pump();
    expect(requested?.host, 'alef-bot.top');
    expect(requested?.queryParameters, {
      'utm_source': 'kol_hashiurim',
      'utm_medium': 'desktop_app',
      'utm_campaign': 'sponsorship',
      'utm_content': 'footer',
    });
    expect(find.text('לא ניתן לפתוח את אתר אלף בוט'), findsOneWidget);
  });
}
