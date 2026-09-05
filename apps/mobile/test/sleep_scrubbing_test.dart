import 'dart:io';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:librering_mobile/src/ui/sleep_palette.dart';
import 'package:ring_core/ring_core.dart';

const _targetKey = Key('sleep-timeline-touch-target');
const _selectionKey = Key('sleep-timeline-selection');
const _cursorKey = Key('sleep-timeline-cursor');
const _semanticsKey = Key('sleep-timeline-semantics');
const _hint = 'Drag across, or hold and slide up/down';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!Platform.isMacOS) return;
    await _loadFont(
      'Helvetica Neue',
      File('/System/Library/Fonts/HelveticaNeue.ttc'),
    );
    await _loadFont('MaterialIcons', _findMaterialIcons());
  });

  testWidgets('tap inspects the exact time, interval and duration', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text(_hint), findsOneWidget);
    await _tapFraction(tester, .125);
    _expectSelection(tester, <String>[
      '23:30',
      'Light',
      '23:00',
      '00:00',
      '1 h 0 min',
    ]);
    expect(find.byKey(_cursorKey), findsOneWidget);
    final retained = _selection(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(_selection(tester), retained);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sleep detail paints the same stage palette as Today', (
    tester,
  ) async {
    await _open(tester);
    final stageBoxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byKey(_targetKey),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      stageBoxes.map((box) => (box.decoration as BoxDecoration).color),
      <Color>[
        sleepStageColor(RingSleepStage.light),
        sleepStageColor(RingSleepStage.deep),
        sleepStageColor(RingSleepStage.rem),
        sleepStageColor(RingSleepStage.awake),
      ],
    );
  });

  testWidgets('gaps remain unclassified instead of snapping to a stage', (
    tester,
  ) async {
    await _open(tester);
    await _tapFraction(tester, .625);
    _expectSelection(tester, <String>[
      '01:30',
      'Unclassified',
      'No stage recorded',
    ]);
    expect(_selection(tester), isNot(contains('Deep')));
    expect(_selection(tester), isNot(contains('REM')));
    final target = tester.getRect(find.byKey(_targetKey));
    final cursor = tester.getRect(find.byKey(_cursorKey));
    expect(cursor.center.dx, closeTo(target.left + target.width * .625, 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('session and stage edges use half-open time intervals', (
    tester,
  ) async {
    await _open(tester);
    await _tapFraction(tester, 0);
    _expectSelection(tester, <String>['23:00', 'Light']);
    await _tapFraction(tester, .25);
    _expectSelection(tester, <String>['00:00', 'Deep']);
    await _tapFraction(tester, .5);
    _expectSelection(tester, <String>['01:00', 'Unclassified']);
    await _tapFraction(tester, .75);
    _expectSelection(tester, <String>['02:00', 'REM']);

    final rect = tester.getRect(find.byKey(_targetKey));
    final gesture = await tester.startGesture(rect.center);
    await gesture.moveTo(Offset(rect.right - 2, rect.center.dy));
    await tester.pump();
    await gesture.moveTo(Offset(rect.right + 40, rect.center.dy));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    _expectSelection(tester, <String>['02:59', 'Awake', '02:30', '03:00']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal drag updates continuously and retains selection', (
    tester,
  ) async {
    await _open(tester);
    final rect = tester.getRect(find.byKey(_targetKey));
    final gesture = await tester.startGesture(
      Offset(rect.left + rect.width * .125, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left + rect.width * .3, rect.center.dy));
    await tester.pump();
    await gesture.moveTo(Offset(rect.left + rect.width * .375, rect.center.dy));
    await tester.pump();
    _expectSelection(tester, <String>['00:30', 'Deep']);
    await gesture.moveTo(
      Offset(rect.left + rect.width * .8125, rect.center.dy),
    );
    await tester.pump();
    _expectSelection(tester, <String>['02:15', 'REM']);
    await gesture.up();
    await tester.pumpAndSettle();
    _expectSelection(tester, <String>['02:15', 'REM']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hold and vertical slide moves later down and earlier up', (
    tester,
  ) async {
    await _open(tester);
    final rect = tester.getRect(find.byKey(_targetKey));
    final start = Offset(rect.left + rect.width * .125, rect.center.dy);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    _expectSelection(tester, <String>['23:30', 'Light']);
    await gesture.moveTo(start + Offset(0, rect.width * .25));
    await tester.pump();
    _expectSelection(tester, <String>['00:30', 'Deep']);
    await gesture.moveTo(start);
    await tester.pump();
    _expectSelection(tester, <String>['23:30', 'Light']);
    await gesture.up();
    await tester.pumpAndSettle();
    _expectSelection(tester, <String>['23:30', 'Light']);
    expect(tester.getRect(find.byKey(_targetKey)).top, closeTo(rect.top, .1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hold and horizontal slide also explores the timeline', (
    tester,
  ) async {
    await _open(tester);
    final rect = tester.getRect(find.byKey(_targetKey));
    final start = Offset(rect.left + rect.width * .125, rect.center.dy);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(start + Offset(rect.width * .25, 0));
    await tester.pump();
    _expectSelection(tester, <String>['00:30', 'Deep']);
    await gesture.up();
    await tester.pumpAndSettle();
    _expectSelection(tester, <String>['00:30', 'Deep']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical hold locks its axis and clamps outside the chart', (
    tester,
  ) async {
    await _open(tester);
    final rect = tester.getRect(find.byKey(_targetKey));
    final start = Offset(rect.left + rect.width * .125, rect.center.dy);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(start + const Offset(1, 10));
    await tester.pump();
    await gesture.moveTo(start + Offset(rect.width * .6, rect.width * .25));
    await tester.pump();
    _expectSelection(tester, <String>['00:30', 'Deep']);
    await gesture.moveTo(start + Offset(rect.width * .6, rect.width * 2));
    await tester.pump();
    _expectSelection(tester, <String>['02:59', 'Awake']);
    await gesture.moveTo(start - Offset(0, rect.width * 2));
    await tester.pump();
    _expectSelection(tester, <String>['23:00', 'Light']);
    await gesture.up();
    await tester.pumpAndSettle();
    _expectSelection(tester, <String>['23:00', 'Light']);
    expect(tester.getRect(find.byKey(_targetKey)).top, closeTo(rect.top, .1));
    expect(tester.takeException(), isNull);
  });

  for (final withSelection in <bool>[false, true]) {
    testWidgets(
      'quick vertical swipe scrolls without ${withSelection ? 'changing' : 'creating'} selection',
      (tester) async {
        await _open(tester);
        if (withSelection) await _tapFraction(tester, .375);
        final before = _selection(tester);
        final rect = tester.getRect(find.byKey(_targetKey));
        await tester.dragFrom(rect.center, const Offset(0, -120));
        await tester.pumpAndSettle();
        expect(_selection(tester), before);
        expect(
          tester.getRect(find.byKey(_targetKey)).top,
          lessThan(rect.top - 30),
        );
        expect(
          find.byKey(_cursorKey),
          withSelection ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('accessible adjustments visit chronological stages and gaps', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await _open(tester);
      final node = tester.getSemantics(find.byKey(_semanticsKey));
      final data = node.getSemanticsData();
      expect(data.label, 'Sleep stages');
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);
      expect(
        find.descendant(
          of: find.byKey(_semanticsKey),
          matching: find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.button == true,
          ),
        ),
        findsNothing,
      );
      for (final expected in <String>[
        'Light',
        'Deep',
        'Unclassified',
        'REM',
        'Awake',
      ]) {
        node.owner!.performAction(node.id, SemanticsAction.increase);
        await tester.pump();
        expect(_selection(tester), contains(expected));
      }
      node.owner!.performAction(node.id, SemanticsAction.decrease);
      await tester.pump();
      expect(_selection(tester), contains('REM'));
      expect(tester.takeException(), isNull);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('changing the selected night clears the inspection', (
    tester,
  ) async {
    await _open(tester);
    await _tapFraction(tester, .375);
    _expectSelection(tester, <String>['00:30', 'Deep']);
    await tester.ensureVisible(find.byKey(const Key('previous-day')));
    await tester.tap(find.byKey(const Key('previous-day')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(_targetKey));
    await tester.pumpAndSettle();
    expect(find.text(_hint), findsOneWidget);
    expect(find.byKey(_cursorKey), findsNothing);
    expect(_selection(tester), isNot(contains('00:30')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-night session switching clears the inspection', (
    tester,
  ) async {
    await _open(tester, withNap: true);
    final overnight = find.widgetWithText(ChoiceChip, '23:00 – 03:00');
    await tester.ensureVisible(overnight);
    await tester.tap(overnight);
    await tester.pumpAndSettle();
    await _tapFraction(tester, .375);
    _expectSelection(tester, <String>['00:30', 'Deep']);
    final nap = find.widgetWithText(ChoiceChip, '09:00 – 10:00');
    await tester.ensureVisible(nap);
    await tester.tap(nap);
    await tester.pumpAndSettle();
    expect(find.byKey(_selectionKey), findsNothing);
    expect(find.byKey(_cursorKey), findsNothing);
    await _tapFraction(tester, .5);
    _expectSelection(tester, <String>['09:30', 'Light']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'equivalent data preserves selection but revised stages clear it',
    (tester) async {
      await _open(tester);
      await _tapFraction(tester, .375);
      final selected = _selection(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(_targetKey)),
      );
      await container.read(ringDataProvider.notifier).merge(_dataset());
      await tester.pumpAndSettle();
      expect(_selection(tester), selected);
      expect(find.byKey(_cursorKey), findsOneWidget);
      await container
          .read(ringDataProvider.notifier)
          .merge(_dataset(middleStage: RingSleepStage.rem));
      await tester.pumpAndSettle();
      expect(find.byKey(_selectionKey), findsNothing);
      expect(find.byKey(_cursorKey), findsNothing);
      await _tapFraction(tester, .375);
      _expectSelection(tester, <String>['00:30', 'REM']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a window without stages does not offer empty interaction', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await _open(tester, noStages: true);
      expect(
        find.text('No sleep stages recorded for this window'),
        findsOneWidget,
      );
      await _tapFraction(tester, .375);
      expect(find.byKey(_selectionKey), findsNothing);
      expect(find.byKey(_cursorKey), findsNothing);
      final data = tester
          .getSemantics(find.byKey(_semanticsKey))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.increase), isFalse);
      expect(data.hasAction(SemanticsAction.decrease), isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('sleep inspection reflows on a small screen at 2x text', (
    tester,
  ) async {
    await _open(tester, size: const Size(320, 568), textScale: 2);
    await _tapFraction(tester, .625);
    _expectSelection(tester, <String>[
      '01:30',
      'Unclassified',
      'No stage recorded',
    ]);
    await tester.ensureVisible(find.byKey(_selectionKey));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected sleep interval matches golden', (tester) async {
    await _open(tester);
    await _tapFraction(tester, .375);
    await Scrollable.ensureVisible(
      tester.element(find.byKey(_selectionKey)),
      alignment: .8,
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sleep_scrubbing.png'),
    );
  }, skip: !Platform.isMacOS);
}

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool noStages = false,
  bool withNap = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    LibreRingApp(
      initialLocation: '/sleep',
      currentLocalTime: DateTime(2026, 8, 26, 12),
      ringDataRepository: _MemoryRepository(
        _dataset(noStages: noStages, withNap: withNap),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(_targetKey));
  await tester.pumpAndSettle();
}

Future<void> _tapFraction(WidgetTester tester, double fraction) async {
  await tester.ensureVisible(find.byKey(_targetKey));
  await tester.pumpAndSettle();
  final rect = tester.getRect(find.byKey(_targetKey));
  await tester.tapAt(Offset(rect.left + rect.width * fraction, rect.center.dy));
  await tester.pump();
}

String _selection(WidgetTester tester) {
  final finder = find.byKey(_selectionKey);
  if (finder.evaluate().isEmpty) return '';
  final widget = tester.widget(finder);
  if (widget is Text) return widget.data ?? widget.textSpan!.toPlainText();
  return tester
      .widgetList<Text>(
        find.descendant(of: finder, matching: find.byType(Text)),
      )
      .map((text) => text.data ?? text.textSpan!.toPlainText())
      .join(' ');
}

void _expectSelection(WidgetTester tester, List<String> values) {
  final text = _selection(tester);
  for (final value in values) {
    expect(text, contains(value));
  }
}

class _MemoryRepository implements RingDataRepository {
  _MemoryRepository(this.value);
  RingSyncDataset? value;
  @override
  Future<void> deleteAll() async => value = null;
  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async =>
      value = incoming;
  @override
  Future<RingSyncDataset?> read() async => value;
}

RingSyncDataset _dataset({
  bool noStages = false,
  bool withNap = false,
  RingSleepStage middleStage = RingSleepStage.deep,
}) => RingSyncDataset(
  lastSyncedAtUtc: DateTime(2026, 8, 26, 12).toUtc(),
  source: const RingDataSource(driverId: 'sleep-scrubbing-test'),
  availability: const <RingDataKind, RingDataAvailability>{},
  sleep: <RingSleepSession>[
    for (final day in <int>[25, 26])
      RingSleepSession(
        startedAtUtc: DateTime(2026, 8, day - 1, 23).toUtc(),
        endedAtUtc: DateTime(2026, 8, day, 3).toUtc(),
        stages: noStages
            ? const <RingSleepStageSpan>[]
            : <RingSleepStageSpan>[
                RingSleepStageSpan(
                  stage: RingSleepStage.light,
                  startedAtUtc: DateTime(2026, 8, day - 1, 23).toUtc(),
                  durationMinutes: 60,
                ),
                RingSleepStageSpan(
                  stage: middleStage,
                  startedAtUtc: DateTime(2026, 8, day).toUtc(),
                  durationMinutes: 60,
                ),
                RingSleepStageSpan(
                  stage: RingSleepStage.rem,
                  startedAtUtc: DateTime(2026, 8, day, 2).toUtc(),
                  durationMinutes: 30,
                ),
                RingSleepStageSpan(
                  stage: RingSleepStage.awake,
                  startedAtUtc: DateTime(2026, 8, day, 2, 30).toUtc(),
                  durationMinutes: 30,
                ),
              ],
      ),
    if (withNap)
      RingSleepSession(
        startedAtUtc: DateTime(2026, 8, 26, 9).toUtc(),
        endedAtUtc: DateTime(2026, 8, 26, 10).toUtc(),
        stages: <RingSleepStageSpan>[
          RingSleepStageSpan(
            stage: RingSleepStage.light,
            startedAtUtc: DateTime(2026, 8, 26, 9).toUtc(),
            durationMinutes: 60,
          ),
        ],
      ),
  ],
);

Future<void> _loadFont(String family, File file) async {
  final bytes = await file.readAsBytes();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

File _findMaterialIcons() {
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.parent.path != directory.path) {
    final file = File(
      '${directory.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (file.existsSync()) return file;
    directory = directory.parent;
  }
  throw StateError('Flutter Material Icons font is unavailable for the golden');
}
