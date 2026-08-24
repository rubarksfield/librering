import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The approved reference viewport is 390 × 844.
  });

  testWidgets('all twelve approved routes render in demo mode', (tester) async {
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
      '/sleep/evidence': 'screen-evidence',
      '/no-result': 'screen-no-result',
      '/trends': 'screen-trends',
      '/journal/swim': 'screen-swim',
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

    await tester.tap(find.byIcon(Icons.lock_outline).last);
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
}
