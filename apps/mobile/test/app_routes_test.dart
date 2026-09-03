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
      '/onboarding': 'screen-product-onboarding',
      '/today': 'screen-today',
      '/metrics': 'screen-metrics',
      '/vitals': 'screen-metrics',
      '/sleep': 'screen-sleep',
      '/recovery': 'screen-recovery',
      '/movement': 'screen-movement',
      '/activity': 'screen-movement',
      '/day-timeline': 'screen-day-timeline',
      '/activity/detail': 'screen-activity-detail',
      '/activity/suggestion': 'screen-activity-suggestion',
      '/activity/sports': 'screen-activity-sports',
      '/activity/log?name=Walking': 'screen-activity-log',
      '/heart': 'screen-heart',
      '/vitals/heart': 'screen-heart',
      '/vitals/rhr': 'screen-resting-pulse-boundary',
      '/oxygen': 'screen-oxygen',
      '/vitals/oxygen': 'screen-oxygen',
      '/vitals/temperature': 'screen-temperature-unavailable',
      '/vitals/recovery': 'screen-recovery',
      '/signals/hrv-index': 'screen-hrv-index',
      '/vitals/hrv': 'screen-hrv-index',
      '/signals/stress-index': 'screen-stress-index',
      '/sport': 'screen-sport-record',
      '/sleep/evidence': 'screen-evidence',
      '/no-result': 'screen-no-result',
      '/trends': 'screen-trends',
      '/journal': 'screen-journal',
      '/journal/check-in': 'screen-check-in',
      '/journal/swim': 'screen-swim',
      '/you': 'screen-you',
      '/you/profile': 'screen-profile-preferences',
      '/you/ring': 'screen-ring-device',
      '/you/ring/sync-issue': 'screen-sync-issue',
      '/you/ring/capabilities': 'screen-capabilities',
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
    await tester.ensureVisible(find.byKey(const Key('you-cycle')));
    await tester.tap(find.byKey(const Key('you-cycle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-cycle-privacy')), findsOneWidget);
  });

  testWidgets('product-system navigation exposes four clear destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LibreRingApp(demoMode: true, initialLocation: '/today'),
    );
    await tester.pumpAndSettle();

    for (final label in <String>['Today', 'Vitals', 'Trends', 'You']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    await tester.tap(find.bySemanticsLabel('Vitals'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-metrics')), findsOneWidget);
    expect(find.textContaining('with their limits'), findsOneWidget);
  });

  testWidgets('new capability routes never turn unavailable into zero', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final route in <String>['/vitals/rhr', '/vitals/temperature']) {
      await tester.pumpWidget(
        LibreRingApp(
          key: ValueKey<String>('boundary-$route'),
          initialLocation: route,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('zero'), findsWidgets, reason: route);
      expect(find.text('0'), findsNothing, reason: route);
    }
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
      '/vitals',
      '/day-timeline',
      '/activity/suggestion',
      '/activity/sports',
      '/activity/log?name=Walking',
      '/sleep',
      '/movement',
      '/heart',
      '/oxygen',
      '/signals/hrv-index',
      '/signals/stress-index',
      '/sport',
      '/sleep/evidence',
      '/trends',
      '/journal',
      '/journal/check-in',
      '/you',
      '/you/profile',
      '/you/ring/sync-issue',
      '/you/ring/capabilities',
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
