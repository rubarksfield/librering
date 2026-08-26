import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The approved reference viewport is 390 × 844.
  });

  testWidgets('all product routes render in demo mode', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const routes = <String, String>{
      '/welcome': 'screen-welcome',
      '/privacy': 'screen-privacy-promise',
      '/pairing/scan': 'screen-ring-scan',
      '/pairing/found': 'screen-ring-found',
      '/today': 'screen-today',
      '/metrics': 'screen-metrics',
      '/sleep': 'screen-sleep',
      '/recovery': 'screen-recovery',
      '/movement': 'screen-movement',
      '/heart': 'screen-heart',
      '/oxygen': 'screen-oxygen',
      '/sleep/evidence': 'screen-evidence',
      '/no-result': 'screen-no-result',
      '/trends': 'screen-trends',
      '/journal': 'screen-journal',
      '/journal/check-in': 'screen-check-in',
      '/journal/swim': 'screen-swim',
      '/you': 'screen-you',
      '/you/ring': 'screen-ring-device',
      '/you/data': 'screen-data-hub',
      '/you/about': 'screen-about',
      '/privacy/cycle': 'screen-cycle-privacy',
    };

    for (final entry in routes.entries) {
      await tester.pumpWidget(
        LibreRingApp(
          key: ValueKey<String>(entry.key),
          demoMode: true,
          initialLocation: entry.key,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey<String>(entry.value)), findsOneWidget);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  testWidgets('critical evidence-to-privacy journey preserves local state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LibreRingApp(demoMode: true, initialLocation: '/sleep'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('How this was calculated'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-evidence')), findsOneWidget);

    await tester.tap(find.text('Unsupported reading example'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-no-result')), findsOneWidget);

    await tester.tap(find.byKey(const Key('supported-trend-link')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-trends')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('trend-add-context')));
    await tester.tap(find.byKey(const Key('trend-add-context')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-swim')));
    await tester.tap(find.byKey(const Key('save-swim')));
    await tester.pumpAndSettle();
    expect(find.text('Saved locally · Manual source'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('You'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('you-cycle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-cycle-privacy')), findsOneWidget);
  });

  testWidgets('production mode never substitutes demo health values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LibreRingApp(initialLocation: '/today'));
    await tester.pumpAndSettle();

    expect(find.text('No production data yet'), findsOneWidget);
    expect(find.text('82'), findsNothing);
    expect(find.textContaining('Demo data'), findsNothing);
  });

  testWidgets('pt-PT locale renders translated first-run copy', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LibreRingApp(demoMode: true, locale: Locale('pt', 'PT')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saiba o que o seu anel sabe.'), findsOneWidget);
    expect(find.text('Configurar o LibreRing'), findsOneWidget);
  });

  testWidgets('priority screens remain usable at 200% text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final route in <String>[
      '/welcome',
      '/today',
      '/metrics',
      '/sleep',
      '/sleep/evidence',
      '/trends',
      '/journal',
      '/journal/check-in',
      '/you',
      '/you/data',
      '/privacy/cycle',
    ]) {
      await tester.pumpWidget(
        LibreRingApp(
          key: ValueKey<String>('large-$route'),
          demoMode: true,
          initialLocation: route,
        ),
      );
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) {
        fail('$route\n$error');
      }
    }
  });

  testWidgets('manual check-in requires context and stays clearly labelled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LibreRingApp(demoMode: true, initialLocation: '/journal/check-in'),
    );
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('save-check-in'));
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(of: save, matching: find.byType(FilledButton)),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('check-in-exercise')));
    await tester.enterText(
      find.byKey(const Key('check-in-note')),
      'Long pool session',
    );
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Saved locally · Manual source'), findsOneWidget);
    expect(find.textContaining('Ring measurement'), findsNothing);
  });

  testWidgets('standalone back buttons return to the correct parent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final route in <(String, String, String)>[
      ('/pairing/scan', 'Back to privacy', 'screen-privacy-promise'),
      ('/sleep/evidence', 'Back to sleep', 'screen-sleep'),
      ('/journal/check-in', 'Back to Journal', 'screen-journal'),
      ('/you/data', 'Back to You', 'screen-you'),
    ]) {
      await tester.pumpWidget(
        LibreRingApp(
          key: ValueKey<String>('back-${route.$1}'),
          demoMode: true,
          initialLocation: route.$1,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(route.$2));
      await tester.pumpAndSettle();
      expect(find.byKey(Key(route.$3)), findsOneWidget, reason: route.$1);
    }
  });
}
