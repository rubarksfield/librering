import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/dashboard_screens.dart';
import 'package:librering_mobile/src/presentation_data.dart';
import 'package:librering_mobile/src/storage/preferences_repository.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

final now = DateTime(2026, 9, 5, 23, 30);

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('loading and failed history are distinct from an empty ring', (
    tester,
  ) async {
    phone(tester);
    final pending = Completer<RingSyncDataset?>();
    await tester.pumpWidget(
      LibreRingApp(
        initialLocation: '/today',
        currentLocalTime: now,
        ringDataRepository: _Repository(() => pending.future),
      ),
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel('Loading your saved ring data'),
      findsOneWidget,
    );
    expect(find.text('Your day starts here.'), findsNothing);
    pending.completeError(StateError('Local file unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Your history needs a moment.'), findsOneWidget);
    expect(find.text('Your day starts here.'), findsNothing);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('old readings never masquerade as today and remain explorable', (
    tester,
  ) async {
    phone(tester);
    final yesterday = DateTime(2026, 9, 4, 18);
    final dataset = RingSyncDataset(
      lastSyncedAtUtc: now.toUtc(),
      availability: const {
        RingDataKind.activity: RingDataAvailability.complete,
        RingDataKind.heartRate: RingDataAvailability.complete,
      },
      source: const RingDataSource(driverId: 'colmi-qring-v1'),
      activity: [
        RingActivityBucket(
          startedAtUtc: yesterday.toUtc(),
          steps: 1234,
          distanceMeters: 940,
          firmwareCalories: 40,
        ),
      ],
      heartRate: [
        RingHeartRateSample(measuredAtUtc: yesterday.toUtc(), bpm: 71),
      ],
    );
    await tester.pumpWidget(
      LibreRingApp(
        initialLocation: '/today',
        currentLocalTime: now,
        ringDataRepository: _Repository(() async => dataset),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1,234'), findsNothing);
    expect(find.text('71'), findsNothing);
    await tester.tap(find.byKey(const Key('previous-day')));
    await tester.pumpAndSettle();
    expect(find.text('1,234'), findsOneWidget);
    expect(find.text('71'), findsOneWidget);
    await tester.tap(find.byKey(const Key('domain-movement')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-movement')), findsOneWidget);
    expect(find.textContaining('4 Sep'), findsWidgets);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('1,234'), findsOneWidget);
  });

  testWidgets('root tabs preserve selected trend metric and period', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      LibreRingApp(
        demoMode: true,
        initialLocation: '/trends',
        currentLocalTime: now,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Steps'));
    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-you')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-trends')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trend-movement')), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<int>>(
            find.byKey(const Key('trend-range-selector')),
          )
          .selected,
      {7},
    );
  });

  testWidgets('saved units and targets are used by the daily dashboard', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      LibreRingApp(
        initialLocation: '/today',
        currentLocalTime: now,
        ringDataRepository: _Repository(() async => exampleRingHistory(now)),
        preferencesRepository: _Preferences(
          const AppPreferences(
            displayName: 'Jo',
            unitSystem: UnitSystem.imperial,
            dailyStepGoal: 8000,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Good evening, Jo'), findsOneWidget);
    expect(find.text('of 8,000 daily goal'), findsOneWidget);
    // Match the distance unit, not unrelated prose such as "a busy mind".
    expect(
      find.textContaining(RegExp(r'^\d+(?:[.,]\d+)? mi$')),
      findsOneWidget,
    );
  });

  testWidgets('All signals carries the day even after browsing Vitals', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      LibreRingApp(
        demoMode: true,
        initialLocation: '/today',
        currentLocalTime: now,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('previous-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All signals'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-metrics')), findsOneWidget);
    expect(find.textContaining('4 Sep'), findsWidgets);
    await tester.tap(find.byKey(const Key('previous-day')));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 Sep'), findsWidgets);
    await tester.tap(find.byKey(const Key('tab-today')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All signals'));
    await tester.pumpAndSettle();
    expect(find.textContaining('4 Sep'), findsWidgets);
    expect(find.textContaining('3 Sep'), findsNothing);
  });

  testWidgets('sleep trend axis uses hours and other signals use their units', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      LibreRingApp(
        demoMode: true,
        initialLocation: '/trends',
        currentLocalTime: now,
      ),
    );
    await tester.pumpAndSettle();
    var chart = tester.widget<RingHistoryChart>(find.byType(RingHistoryChart));
    expect(chart.axisFormatter!(480), '8h00');
    expect(chart.formatter(479.6), '8h 0m');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Steps'));
    await tester.pumpAndSettle();
    chart = tester.widget<RingHistoryChart>(find.byType(RingHistoryChart));
    expect(chart.axisFormatter!(480), '480');
  });

  testWidgets('history chart exposes missing days and zero to accessibility', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    int? selection = 2;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: RingHistoryChart(
              values: const [0, null, 80],
              labels: const ['Monday', 'Tuesday', 'Wednesday'],
              selected: selection,
              formatter: (v) => v?.toStringAsFixed(0) ?? 'No reading',
              onSelected: (index) => setState(() => selection = index),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    var node = tester.getSemantics(
      find.bySemanticsLabel('Daily history chart'),
    );
    expect(node.value, 'Wednesday, 80');
    node.owner!.performAction(node.id, SemanticsAction.decrease);
    await tester.pumpAndSettle();
    node = tester.getSemantics(find.bySemanticsLabel('Daily history chart'));
    expect(node.value, 'Tuesday, No reading');
    node.owner!.performAction(node.id, SemanticsAction.decrease);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Daily history chart')).value,
      'Monday, 0',
    );
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('dashboard controls meet iOS minimum target sizes', (
    tester,
  ) async {
    phone(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      LibreRingApp(
        demoMode: true,
        initialLocation: '/today',
        currentLocalTime: now,
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    final nav = tester.getSemantics(find.bySemanticsLabel('Vitals'));
    expect(nav.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    nav.owner!.performAction(nav.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-metrics')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('iOS detail pages support the native edge-swipe back gesture', (
    tester,
  ) async {
    phone(tester);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      LibreRingApp(
        demoMode: true,
        initialLocation: '/today',
        currentLocalTime: now,
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('domain-movement')));
    await tester.tap(find.byKey(const Key('domain-movement')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-movement')), findsOneWidget);
    await tester.dragFrom(const Offset(2, 300), const Offset(330, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-today')), findsOneWidget);
    expect(find.byKey(const Key('screen-movement')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}

class _Repository implements RingDataRepository {
  _Repository(this.reader);
  final Future<RingSyncDataset?> Function() reader;
  @override
  Future<RingSyncDataset?> read() => reader();
  @override
  Future<void> deleteAll() async {}
  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async => incoming;
}

class _Preferences implements PreferencesRepository {
  _Preferences(this.value);
  AppPreferences value;
  @override
  Future<AppPreferences> read() async => value;
  @override
  Future<void> save(AppPreferences next) async {
    value = next;
  }
}
