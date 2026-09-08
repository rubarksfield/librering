import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librering_mobile/src/analytics_screens.dart' as analytics;
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/dashboard_screens.dart' as dashboard;
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

final _day = DateTime(2026, 9, 7);

void main() {
  final effects = <String>[];
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    effects.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            effects.add(call.arguments as String);
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('an unchanged reload retains the inspected reading silently', (
    tester,
  ) async {
    await tester.pumpWidget(_history(_points()));
    await tester.pumpAndSettle();
    await _selectFirstReading(tester);
    final selection = _selection(tester);
    expect(selection, contains('06:00'));
    expect(selection, contains('62 bpm'));
    expect(effects, ['HapticFeedbackType.selectionClick']);
    effects.clear();

    // Decoding saved history creates new objects, even when its data is equal.
    await tester.pumpWidget(_history(_points()));
    await tester.pumpAndSettle();
    expect(_selection(tester), selection);
    expect(_painter(tester).selectedIndex, 0);
    await _selectFirstReading(tester);
    expect(effects, isEmpty, reason: 'The same inspected reading is a no-op.');
    expect(tester.takeException(), isNull);
  });

  for (final change in ['timestamp', 'value', 'upper', 'label', 'unit']) {
    testWidgets(
      'a same-count reload with changed $change resets selection without a haptic',
      (tester) async {
        await tester.pumpWidget(_history(_points()));
        await tester.pumpAndSettle();
        await _selectFirstReading(tester);
        expect(_painter(tester).selectedIndex, 0);
        effects.clear();

        final replacement = _points(
          firstAt: change == 'timestamp'
              ? _day.add(const Duration(hours: 5))
              : null,
          firstValue: change == 'value' ? 68 : 62,
          firstUpper: change == 'upper' ? 67 : null,
          firstLabel: change == 'label' ? 'Updated reading' : null,
        );
        await tester.pumpWidget(
          _history(replacement, unit: change == 'unit' ? 'index' : 'bpm'),
        );
        await tester.pumpAndSettle();

        expect(_selection(tester), 'Tap a reading to explore');
        expect(_painter(tester).selectedIndex, isNull);
        expect(effects, isEmpty, reason: 'Reloads are not user selections.');
        // The newly published point remains inspectable after the reset.
        await _selectFirstReading(tester);
        expect(_painter(tester).selectedIndex, 0);
        expect(_selection(tester), isNot('Tap a reading to explore'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final filteredOnly in [false, true]) {
    testWidgets(
      'a reload with no in-range points clears selection safely (filtered $filteredOnly)',
      (tester) async {
        await tester.pumpWidget(_history(_points()));
        await tester.pumpAndSettle();
        await _selectFirstReading(tester);
        effects.clear();

        await tester.pumpWidget(
          _history(
            filteredOnly
                ? _points()
                      .map(
                        (point) => analytics.RingChartPoint(
                          at: point.at.subtract(const Duration(days: 1)),
                          value: point.value,
                        ),
                      )
                      .toList()
                : const [],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No readings in this period'), findsOneWidget);
        expect(find.byKey(const Key('chart-selection')), findsNothing);
        expect(effects, isEmpty);

        await tester.pumpWidget(_history(_points()));
        await tester.pumpAndSettle();
        expect(_selection(tester), 'Tap a reading to explore');
        expect(_painter(tester).selectedIndex, isNull);
        expect(effects, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Trends retains the calendar day when refresh crosses midnight', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    var clock = DateTime(2026, 9, 7, 23, 59);
    final repository = _Repository(
      RingSyncDataset(
        lastSyncedAtUtc: clock.toUtc(),
        source: const RingDataSource(driverId: 'colmi-qring-v1'),
        availability: const {
          RingDataKind.activity: RingDataAvailability.complete,
        },
        activity: [
          for (final (day, steps) in [(6, 1234), (7, 5678)])
            RingActivityBucket(
              startedAtUtc: DateTime(2026, 9, day, 12).toUtc(),
              steps: steps,
              distanceMeters: 0,
              firmwareCalories: 0,
            ),
        ],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        currentLocalTimeProvider.overrideWith((ref) => clock),
        ringDataRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final router = GoRouter(
      initialLocation: '/trends',
      routes: [
        GoRoute(
          path: '/trends',
          builder: (context, state) => const dashboard.RefinedTrendsScreen(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: buildLibreRingTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Steps'));
    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    final chartFinder = find.byType(dashboard.RingHistoryChart);
    await tester.ensureVisible(chartFinder);
    final node = tester.getSemantics(
      find.bySemanticsLabel('Daily history chart'),
    );
    node.owner!.performAction(node.id, SemanticsAction.decrease);
    await tester.pumpAndSettle();
    var chart = tester.widget<dashboard.RingHistoryChart>(chartFinder);
    expect(chart.selected, 5);
    expect(chart.labels[chart.selected!], '6 Sep');
    expect(_trendValue(tester), '1,234');
    effects.clear();

    final reads = repository.reads;
    clock = DateTime(2026, 9, 8, 0, 1);
    // Exercise the controller's real refresh/clock invalidation path, without
    // the explicit pull gesture's separate success acknowledgment.
    await container.read(ringDataProvider.notifier).refresh();
    await tester.pumpAndSettle();

    expect(repository.reads, reads + 1);
    expect(container.read(currentLocalTimeProvider), clock);
    chart = tester.widget<dashboard.RingHistoryChart>(chartFinder);
    expect(chart.labels.last, '8 Sep');
    expect(chart.selected, 4);
    expect(chart.labels[chart.selected!], '6 Sep');
    expect(_trendValue(tester), '1,234');
    expect(find.text('Sunday, 6 Sep'), findsOneWidget);
    expect(effects, isEmpty);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

List<analytics.RingChartPoint> _points({
  DateTime? firstAt,
  double firstValue = 62,
  double? firstUpper,
  String? firstLabel,
}) => [
  analytics.RingChartPoint(
    at: firstAt ?? _day.add(const Duration(hours: 6)),
    value: firstValue,
    upper: firstUpper,
    label: firstLabel,
  ),
  analytics.RingChartPoint(at: _day.add(const Duration(hours: 18)), value: 74),
];

Widget _history(List<analytics.RingChartPoint> points, {String unit = 'bpm'}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 350,
            child: analytics.RingHistoryChart(
              points: points,
              start: _day,
              end: _day.add(const Duration(days: 1)),
              unit: unit,
            ),
          ),
        ),
      ),
    );

Future<void> _selectFirstReading(WidgetTester tester) async {
  final target = find
      .descendant(
        of: find.byType(analytics.RingHistoryChart),
        matching: find.byType(GestureDetector),
      )
      .first;
  final rect = tester.getRect(target);
  final plotWidth = rect.width - analytics.RingHistoryPainter.leftInset - 6;
  await tester.tapAt(
    Offset(
      rect.left + analytics.RingHistoryPainter.leftInset + plotWidth * .25,
      rect.center.dy,
    ),
  );
  await tester.pumpAndSettle();
}

String? _selection(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('chart-selection'))).data;

analytics.RingHistoryPainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(analytics.RingHistoryChart),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((paint) => paint.painter)
    .whereType<analytics.RingHistoryPainter>()
    .single;

String? _trendValue(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('trend-inspected-value'))).data;

class _Repository implements RingDataRepository {
  _Repository(this.value);
  final RingSyncDataset value;
  int reads = 0;

  @override
  Future<RingSyncDataset?> read() async {
    reads++;
    return value;
  }

  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) =>
      throw StateError('Chart refresh must not write saved history.');

  @override
  Future<void> deleteAll() =>
      throw StateError('Chart refresh must not delete saved history.');
}
