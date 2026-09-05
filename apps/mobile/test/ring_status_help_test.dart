import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:librering_mobile/src/ui/ring_status_help.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

void main() {
  testWidgets(
    'battery is separate from sync and explains saved, not live data',
    (tester) async {
      await tester.pumpWidget(
        LibreRingApp(
          initialLocation: '/today',
          currentLocalTime: DateTime(2026, 9, 5, 12),
          ringDataRepository: _Repository(_dataset(8)),
        ),
      );
      await tester.pumpAndSettle();
      final sync = find.byKey(const Key('today-quick-sync'));
      expect(
        find.descendant(of: sync, matching: find.text('Sync')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sync, matching: find.textContaining('%')),
        findsNothing,
      );
      expect(find.text('Ring battery 8%'), findsOneWidget);
      expect(find.text('Last reported · not live'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ring-battery-help')));
      await tester.pumpAndSettle();
      expect(find.text('Your ring’s battery'), findsOneWidget);
      expect(find.textContaining('not sync progress'), findsOneWidget);
      expect(
        find.textContaining('not a separate timestamp for the battery'),
        findsOneWidget,
      );
      expect(
        find.textContaining('an older value can remain visible'),
        findsOneWidget,
      );
      await _close(tester, 'Got it');
      expect(find.byKey(const Key('screen-today')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final battery in <int?>[0, null, -1, 101]) {
    testWidgets('battery $battery preserves zero versus unavailable', (
      tester,
    ) async {
      await _open(tester, battery: battery);
      expect(
        find.text(battery == 0 ? 'Ring battery 0%' : 'Ring battery —'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('ring-battery-help')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          battery == 0
              ? 'What does 0% mean?'
              : 'This does not mean the battery is at zero.',
        ),
        findsOneWidget,
      );
      await _close(tester, 'Got it');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('no history does not fabricate a battery but keeps sync help', (
    tester,
  ) async {
    await _open(tester, noDataset: true);
    expect(find.byKey(const Key('ring-battery-help')), findsNothing);
    await tester.tap(find.byKey(const Key('ring-sync-explained')));
    await tester.pumpAndSettle();
    expect(find.text('How syncing works'), findsOneWidget);
    expect(find.textContaining('time spent, not a countdown'), findsOneWidget);
    expect(find.textContaining('A failed sync does not erase'), findsOneWidget);
    await _close(tester, 'Got it');
  });

  testWidgets('example battery is explicitly sample data', (tester) async {
    await _open(tester, demo: true);
    expect(find.text('Example battery 8%'), findsOneWidget);
    expect(find.text('Sample value'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ring-battery-help')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Example data, not your ring'), findsOneWidget);
    await _close(tester, 'Got it');
  });

  for (final locale in <Locale>[const Locale('en'), const Locale('pt', 'PT')]) {
    testWidgets('both guides reflow at 320px, 2x text in $locale', (
      tester,
    ) async {
      await _open(tester, locale: locale, largeText: true);
      expect(tester.takeException(), isNull);
      for (final key in ['ring-battery-help', 'ring-sync-explained']) {
        final entry = find.byKey(Key(key));
        await tester.ensureVisible(entry);
        await tester.tap(entry);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _close(
          tester,
          locale.languageCode == 'pt' ? 'Entendido' : 'Got it',
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('help entries expose labelled 48px accessible actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      for (final key in ['ring-battery-help', 'ring-sync-explained']) {
        final entry = find.byKey(Key(key));
        final data = tester.getSemantics(entry).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(data.label, isNotEmpty);
        expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('both guides respect reduced motion', (tester) async {
    await _open(tester, reducedMotion: true);
    for (final key in ['ring-battery-help', 'ring-sync-explained']) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
      final route = ModalRoute.of(tester.element(find.byType(BottomSheet)))!;
      expect(route.animation!.status, AnimationStatus.completed);
      await _close(tester, 'Got it');
    }
  });
}

Future<void> _open(
  WidgetTester tester, {
  int? battery = 8,
  bool noDataset = false,
  bool demo = false,
  bool largeText = false,
  bool reducedMotion = false,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = largeText
      ? const Size(320, 568)
      : const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLibreRingTheme(),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('pt', 'PT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(largeText ? 2 : 1),
          disableAnimations: reducedMotion,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: RingStatusHelp(
              dataset: noDataset ? null : _dataset(battery),
              demo: demo,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester, String label) async {
  final close = find.widgetWithText(LibreRingPrimaryButton, label);
  await tester.ensureVisible(close);
  await tester.pumpAndSettle();
  await tester.tap(close);
  await tester.pumpAndSettle();
  expect(find.byType(BottomSheet), findsNothing);
}

RingSyncDataset _dataset(int? battery) => RingSyncDataset(
  lastSyncedAtUtc: DateTime.utc(2026, 9, 5, 10),
  source: const RingDataSource(driverId: 'colmi-qring-v1'),
  availability: const {},
  batteryLevel: battery,
);

class _Repository implements RingDataRepository {
  _Repository(this.value);
  final RingSyncDataset value;
  @override
  Future<void> deleteAll() async =>
      throw StateError('Help must not delete data');
  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async =>
      throw StateError('Help must not write data');
  @override
  Future<RingSyncDataset?> read() async => value;
}
