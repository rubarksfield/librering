import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/analytics_screens.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:librering_mobile/src/storage/preferences_repository.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

void main() {
  final today = DateTime(2026, 8, 26);
  test(
    'sparse chart preserves the calendar domain and breaks missing intervals',
    () {
      final points = <RingChartPoint>[
        RingChartPoint(at: DateTime(2026, 8, 26, 8), value: 60),
        RingChartPoint(at: DateTime(2026, 8, 26, 9), value: 62),
        RingChartPoint(at: DateTime(2026, 8, 26, 18), value: 75),
      ];
      final painter = RingHistoryPainter(
        points: points,
        start: today,
        end: DateTime(2026, 8, 27),
        minimum: 50,
        maximum: 90,
        kind: RingChartKind.line,
        color: Colors.green,
      );
      const size = Size(350, 180);
      final plotWidth = size.width - RingHistoryPainter.leftInset - 6;
      expect(
        painter.xFor(points.first.at, size),
        closeTo(32 + plotWidth / 3, .001),
      );
      expect(
        painter.xFor(points.last.at, size),
        closeTo(32 + plotWidth * .75, .001),
      );
      expect(painter.connectsPrevious(0), isFalse);
      expect(painter.connectsPrevious(1), isTrue);
      expect(painter.connectsPrevious(2), isFalse);
    },
  );

  testWidgets('chart inspection is timestamp based and accessible', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLibreRingTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 350,
            child: RingHistoryChart(
              points: <RingChartPoint>[
                RingChartPoint(at: DateTime(2026, 8, 26, 8), value: 60),
                RingChartPoint(at: DateTime(2026, 8, 26, 18), value: 75),
              ],
              start: today,
              end: DateTime(2026, 8, 27),
              unit: 'bpm',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final chart = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is RingHistoryPainter,
    );
    final rect = tester.getRect(chart);
    await tester.tapAt(
      Offset(rect.left + 32 + (rect.width - 38) * .75, rect.center.dy),
    );
    await tester.pump();
    expect(find.text('26 Aug, 18:00 · 75 bpm'), findsOneWidget);
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'bpm history\. 2 recorded readings')),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.decrease), isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('heart history moves dates and week ends at the selected day', (
    tester,
  ) async {
    await _open(tester, '/heart');
    expect(_primary(tester), '81');
    await tester.tap(find.byKey(const Key('previous-day')));
    await tester.pumpAndSettle();
    expect(_primary(tester), '66');
    expect(find.text('81'), findsNothing);
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    final chart = tester.widget<RingHistoryChart>(
      find.byKey(const Key('heart-history-chart')),
    );
    expect(chart.start, DateTime(2026, 8, 19));
    expect(chart.end, DateTime(2026, 8, 26));
    expect(chart.points.map((p) => p.value), <double>[66]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sleep history changes the session and its overnight readings', (
    tester,
  ) async {
    await _open(tester, '/sleep');
    expect(_primary(tester), '7 h 30 min');
    expect(find.text('81 bpm'), findsOneWidget);
    await tester.tap(find.byKey(const Key('previous-day')));
    await tester.pumpAndSettle();
    expect(_primary(tester), '6 h 30 min');
    expect(find.text('66 bpm'), findsOneWidget);
    expect(find.text('81 bpm'), findsNothing);
    expect(find.textContaining('Sleep window 7 h 0 min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'detail links honor explicit dates and reject invalid calendar dates',
    (tester) async {
      await _open(tester, '/heart?date=2026-08-25');
      expect(_primary(tester), '66');
      await _open(tester, '/heart?date=2026-02-31');
      expect(_primary(tester), '81');
      await _open(tester, '/heart?date=2099-01-01');
      expect(_primary(tester), '81');
    },
  );

  testWidgets('activity uses the saved unit system and personal step goal', (
    tester,
  ) async {
    await _open(
      tester,
      '/movement',
      preferences: const AppPreferences(
        unitSystem: UnitSystem.imperial,
        dailyStepGoal: 7500,
      ),
    );
    expect(find.text('0.13 mi'), findsOneWidget);
    expect(find.text('7,500 steps'), findsOneWidget);
    final charts = tester.widgetList<RingHistoryChart>(
      find.byType(RingHistoryChart),
    );
    expect(charts.where((chart) => chart.unit == 'mi'), hasLength(1));
    expect(charts.where((chart) => chart.unit == 'km'), isEmpty);
  });

  testWidgets(
    'an unclassified sleep session is shown as a window, not zero sleep',
    (tester) async {
      final session = RingSleepSession(
        startedAtUtc: DateTime(2026, 8, 25, 23).toUtc(),
        endedAtUtc: DateTime(2026, 8, 26, 7).toUtc(),
        stages: const <RingSleepStageSpan>[],
      );
      await _open(
        tester,
        '/sleep',
        dataset: RingSyncDataset(
          lastSyncedAtUtc: DateTime(2026, 8, 26, 12).toUtc(),
          source: const RingDataSource(driverId: 'test'),
          availability: const <RingDataKind, RingDataAvailability>{},
          sleep: <RingSleepSession>[session],
        ),
      );
      expect(find.text('Recorded sleep window'), findsOneWidget);
      expect(_primary(tester), '8 h 0 min');
      expect(find.text('Estimated time asleep'), findsNothing);
      expect(find.text('Your sleep target'), findsNothing);
    },
  );

  testWidgets(
    'an empty current day stays empty until a recorded date is selected',
    (tester) async {
      await _open(tester, '/heart', now: DateTime(2026, 8, 28, 12));
      expect(
        find.text('No heart rate readings in this period'),
        findsOneWidget,
      );
      expect(find.text('81'), findsNothing);
      await tester.tap(find.byKey(const Key('previous-day')));
      await tester.pumpAndSettle();
      expect(
        find.text('No heart rate readings in this period'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('previous-day')));
      await tester.pumpAndSettle();
      expect(_primary(tester), '81');
    },
  );

  testWidgets(
    'timeline honors its day, filters sources and keeps the drill-down date',
    (tester) async {
      await _open(
        tester,
        '/day-timeline?date=2026-08-25',
        journal: <JournalEntry>[
          JournalEntry(
            id: 'yesterday',
            kind: JournalEntryKind.note,
            occurredAtUtc: DateTime(2026, 8, 25, 12).toUtc(),
            title: 'A long walk',
            details: 'Added yesterday',
          ),
          JournalEntry(
            id: 'today',
            kind: JournalEntryKind.note,
            occurredAtUtc: DateTime(2026, 8, 26, 12).toUtc(),
            title: 'Today only',
            details: 'Not yesterday',
          ),
        ],
      );
      expect(find.text('A long walk'), findsOneWidget);
      expect(find.text('Added by you'), findsOneWidget);
      expect(find.text('Today only'), findsNothing);
      expect(find.text('66 bpm'), findsOneWidget);
      expect(find.text('81 bpm'), findsNothing);
      expect(find.text('100 steps'), findsOneWidget);
      await tester.tap(find.byKey(const Key('timeline-filter-vitals')));
      await tester.pumpAndSettle();
      expect(find.text('A long walk'), findsNothing);
      expect(find.text('100 steps'), findsNothing);
      expect(find.text('95–97%'), findsOneWidget);
      await tester.ensureVisible(find.text('66 bpm'));
      await tester.tap(find.text('66 bpm'));
      await tester.pumpAndSettle();
      expect(_primary(tester), '66');
      expect(find.text('25 Aug'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'timeline validates dates and does not promote future journal moments',
    (tester) async {
      final journal = <JournalEntry>[
        JournalEntry(
          id: 'future',
          kind: JournalEntryKind.note,
          occurredAtUtc: DateTime(2026, 8, 26, 23, 55).toUtc(),
          title: 'Not happened yet',
          details: '',
        ),
      ];
      await _open(tester, '/day-timeline?date=2026-02-31', journal: journal);
      expect(find.text('81 bpm'), findsOneWidget);
      expect(find.text('66 bpm'), findsNothing);
      expect(find.text('Not happened yet'), findsNothing);
      await _open(tester, '/day-timeline?date=2099-01-01');
      expect(find.text('81 bpm'), findsOneWidget);
    },
  );

  testWidgets('timeline progressively exposes all records on a dense day', (
    tester,
  ) async {
    await _open(
      tester,
      '/day-timeline',
      dataset: RingSyncDataset(
        lastSyncedAtUtc: DateTime(2026, 8, 26, 12).toUtc(),
        source: const RingDataSource(driverId: 'test'),
        availability: const <RingDataKind, RingDataAvailability>{},
        heartRate: <RingHeartRateSample>[
          for (var minute = 0; minute < 80; minute++)
            RingHeartRateSample(
              measuredAtUtc: DateTime(2026, 8, 26, 9, minute).toUtc(),
              bpm: 60 + minute % 10,
            ),
        ],
      ),
    );
    expect(find.text('80 moments · latest first'), findsOneWidget);
    expect(find.text('Heart rate reading'), findsNWidgets(40));
    await tester.ensureVisible(find.byKey(const Key('timeline-show-more')));
    await tester.tap(find.byKey(const Key('timeline-show-more')));
    await tester.pumpAndSettle();
    expect(find.text('Heart rate reading'), findsNWidgets(80));
    expect(find.byKey(const Key('timeline-show-more')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline demo uses the example dataset with an explicit label', (
    tester,
  ) async {
    await _open(tester, '/day-timeline', demo: true);
    expect(
      find.text('Example ring data · Your journal stays separate'),
      findsOneWidget,
    );
    expect(find.text('Heart rate reading'), findsWidgets);
    expect(find.text('No moments here yet'), findsNothing);
  });

  testWidgets(
    'timeline preserves available journal events when ring storage fails',
    (tester) async {
      await _open(
        tester,
        '/day-timeline',
        ringReadError: true,
        journal: <JournalEntry>[
          JournalEntry(
            id: 'walk',
            kind: JournalEntryKind.note,
            occurredAtUtc: DateTime(2026, 8, 26, 12).toUtc(),
            title: 'A walk I recorded',
            details: '',
          ),
        ],
      );
      expect(find.text('Ring data could not be loaded'), findsOneWidget);
      expect(find.text('A walk I recorded'), findsOneWidget);
      expect(find.text('No moments here yet'), findsNothing);
    },
  );

  for (final route in <String>[
    '/movement',
    '/sleep',
    '/heart',
    '/oxygen',
    '/signals/hrv-index',
    '/you/ring/capabilities',
    '/day-timeline',
  ]) {
    testWidgets('$route reflows on a small screen with large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _open(tester, route, textScale: 2);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1400),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

String? _primary(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('analytics-primary-value'))).data;

Future<void> _open(
  WidgetTester tester,
  String route, {
  DateTime? now,
  double textScale = 1,
  AppPreferences preferences = const AppPreferences(),
  RingSyncDataset? dataset,
  List<JournalEntry> journal = const <JournalEntry>[],
  bool demo = false,
  bool ringReadError = false,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    LibreRingApp(
      key: ValueKey('$route-$textScale'),
      initialLocation: route,
      demoMode: demo,
      ringDataRepository: _MemoryRepository(
        dataset ?? _dataset(),
        readError: ringReadError,
      ),
      preferencesRepository: _MemoryPreferences(preferences),
      journalRepository: _MemoryJournal(journal),
      currentLocalTime: now ?? DateTime(2026, 8, 26, 23, 15),
    ),
  );
  await tester.pumpAndSettle();
}

class _MemoryJournal implements JournalRepository {
  _MemoryJournal(this.entries);
  List<JournalEntry> entries;
  @override
  Future<List<JournalEntry>> read() async => entries;
  @override
  Future<List<JournalEntry>> upsert(JournalEntry entry) async => entries =
      <JournalEntry>[...entries.where((value) => value.id != entry.id), entry];
  @override
  Future<List<JournalEntry>> delete(String id) async =>
      entries = entries.where((entry) => entry.id != id).toList();
  @override
  Future<void> deleteAll() async => entries = <JournalEntry>[];
}

class _MemoryPreferences implements PreferencesRepository {
  _MemoryPreferences(this.value);
  AppPreferences value;
  @override
  Future<AppPreferences> read() async => value;
  @override
  Future<void> save(AppPreferences preferences) async => value = preferences;
}

class _MemoryRepository implements RingDataRepository {
  _MemoryRepository(this.value, {this.readError = false});
  RingSyncDataset? value;
  final bool readError;
  @override
  Future<void> deleteAll() async => value = null;
  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async =>
      value = incoming;
  @override
  Future<RingSyncDataset?> read() async {
    if (readError) throw StateError('Unavailable test store');
    return value;
  }
}

RingSyncDataset _dataset() => RingSyncDataset(
  lastSyncedAtUtc: DateTime(2026, 8, 26, 23).toUtc(),
  source: const RingDataSource(
    driverId: 'colmi-qring-v1',
    firmwareVersion: 'test',
  ),
  availability: const <RingDataKind, RingDataAvailability>{},
  activity: <RingActivityBucket>[
    RingActivityBucket(
      startedAtUtc: DateTime(2026, 8, 25, 10).toUtc(),
      steps: 100,
      distanceMeters: 72,
      firmwareCalories: 5,
    ),
    RingActivityBucket(
      startedAtUtc: DateTime(2026, 8, 26, 10).toUtc(),
      steps: 300,
      distanceMeters: 216,
      firmwareCalories: 15,
    ),
  ],
  heartRate: <RingHeartRateSample>[
    RingHeartRateSample(
      measuredAtUtc: DateTime(2026, 8, 25, 2).toUtc(),
      bpm: 66,
    ),
    RingHeartRateSample(
      measuredAtUtc: DateTime(2026, 8, 26, 2).toUtc(),
      bpm: 81,
    ),
  ],
  oxygen: <RingOxygenRange>[
    RingOxygenRange(
      hourStartedAtUtc: DateTime(2026, 8, 25, 2).toUtc(),
      minimumPercent: 95,
      maximumPercent: 97,
    ),
    RingOxygenRange(
      hourStartedAtUtc: DateTime(2026, 8, 26, 2).toUtc(),
      minimumPercent: 97,
      maximumPercent: 99,
    ),
  ],
  vendorIndexes: <RingVendorIndexSample>[
    RingVendorIndexSample(
      measuredAtUtc: DateTime(2026, 8, 26, 2).toUtc(),
      value: 43,
      kind: RingVendorIndexKind.firmwareHrv,
    ),
  ],
  sleep: <RingSleepSession>[
    for (final day in <int>[25, 26])
      RingSleepSession(
        startedAtUtc: DateTime(2026, 8, day - 1, 23).toUtc(),
        endedAtUtc: DateTime(2026, 8, day, day == 25 ? 6 : 7).toUtc(),
        stages: <RingSleepStageSpan>[
          RingSleepStageSpan(
            stage: RingSleepStage.light,
            startedAtUtc: DateTime(2026, 8, day - 1, 23).toUtc(),
            durationMinutes: day == 25 ? 390 : 450,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.awake,
            startedAtUtc: DateTime(2026, 8, day, day == 25 ? 5 : 6, 30).toUtc(),
            durationMinutes: 30,
          ),
        ],
      ),
  ],
);
