import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/sponsor_banner.dart';

void main() {
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

    expect(find.text('בחסות אלף בוט'), findsOneWidget);
    expect(find.text('0774632641'), findsOneWidget);
    await tester.tap(find.text('העברה'));
    await tester.pumpAndSettle();
    expect(find.text('ניהול'), findsOneWidget);
    expect(find.text('בחסות אלף בוט'), findsOneWidget);
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

    await tester.tap(find.text('בחסות אלף בוט'));
    await tester.pump();
    expect(requested, SponsorBanner.website);
    expect(find.text('לא ניתן לפתוח את אתר אלף בוט'), findsOneWidget);
  });
}
