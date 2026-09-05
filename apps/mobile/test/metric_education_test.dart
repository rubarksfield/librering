import 'dart:io';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/analytics_screens.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:librering_mobile/src/ui/calorie_education.dart';
import 'package:librering_mobile/src/ui/stress_education.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

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

  for (final locale in [const Locale('en'), const Locale('pt', 'PT')]) {
    final pt = locale.languageCode == 'pt';
    for (final stress in [true, false]) {
      testWidgets(
        '${stress ? 'stress' : 'energy'} guide opens and closes in $locale',
        (tester) async {
          await _openApp(tester, stress: stress, locale: locale);
          final open = find.byKey(
            Key(stress ? 'stress-education-open' : 'calorie-education-open'),
          );
          await tester.ensureVisible(open);
          expect(tester.getSize(open).height, greaterThanOrEqualTo(48));
          await tester.tap(open);
          await tester.pumpAndSettle();
          expect(
            find.text(
              stress
                  ? (pt
                        ? 'Índice de stress, explicado'
                        : 'Stress index, explained')
                  : (pt
                        ? 'Energia do anel, explicada'
                        : 'Ring energy, explained'),
            ),
            findsOneWidget,
          );
          expect(
            find.textContaining(
              stress
                  ? (pt
                        ? 'não uma fórmula documentada'
                        : 'not a documented formula')
                  : (pt
                        ? 'a escala, o cálculo e a precisão não foram verificados'
                        : 'the unit scale, calculation and accuracy have not been verified'),
            ),
            findsOneWidget,
          );
          await _closeGuide(tester, pt ? 'Entendido' : 'Got it');
          expect(find.byType(BottomSheet), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '${stress ? 'stress' : 'energy'} guide reflows at 2x on small $locale screen',
        (tester) async {
          await _openApp(
            tester,
            stress: stress,
            locale: locale,
            size: const Size(320, 568),
            textScale: 2,
          );
          final open = find.byKey(
            Key(stress ? 'stress-education-open' : 'calorie-education-open'),
          );
          await tester.ensureVisible(open);
          await tester.tap(open);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await _closeGuide(tester, pt ? 'Entendido' : 'Got it');
          expect(find.byType(BottomSheet), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'stress explanation preserves latest, period sample medians and missing chart days',
    (tester) async {
      await _openApp(tester);
      for (final period in [('Day', '49'), ('Week', '35'), ('Month', '35')]) {
        await tester.ensureVisible(find.text(period.$1));
        await tester.tap(find.text(period.$1));
        await tester.pumpAndSettle();
        expect(_primary(tester), period.$2);
        final chart = tester.widget<RingHistoryChart>(
          find.byKey(const Key('vendor-history-chart')),
        );
        expect(chart.unit, 'index');
        // Week/month median is of samples [10,30,40,49], not day medians [10,40].
        expect(
          chart.points.map((p) => p.value),
          period.$1 == 'Day' ? [30, 40, 49] : [10, 40],
        );
        expect(
          find.textContaining(
            period.$1 == 'Day'
                ? 'Day shows the latest captured value, not a live reading.'
                : 'The headline is the median of captured samples',
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const Key('stress-education-open')),
        );
        await tester.tap(find.byKey(const Key('stress-education-open')));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('It does not mean 49% stressed'),
          findsOneWidget,
        );
        expect(
          find.textContaining('rounded to a whole number'),
          findsOneWidget,
        );
        expect(
          find.textContaining('A gap means no usable reading was received'),
          findsOneWidget,
        );
        await _closeGuide(tester);
        expect(_primary(tester), period.$2);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'energy figure remains unchanged without claiming kcal or active calories',
    (tester) async {
      await _openApp(tester, stress: false);
      for (final period in [
        ('Day', 350.0),
        ('Week', 750.0),
        ('Month', 750.0),
      ]) {
        await tester.ensureVisible(find.text(period.$1));
        await tester.tap(find.text(period.$1));
        await tester.pumpAndSettle();
        final chart = tester.widget<RingHistoryChart>(
          find.byKey(const Key('activity-energy-chart')),
        );
        expect(chart.unit, 'firmware units');
        expect(chart.points.fold(0.0, (sum, p) => sum + p.value), period.$2);
        expect(chart.points.length, 2);
        expect(find.text('Unverified firmware units'), findsOneWidget);
        expect(find.text('Active energy'), findsNothing);
        expect(find.text('${period.$2.toInt()} kcal'), findsNothing);
        expect(find.text('${period.$2.toInt()}'), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const Key('calorie-education-open')),
        );
        await tester.tap(find.byKey(const Key('calorie-education-open')));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            'Active energy refers to energy used through movement above resting needs',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('not a calorie goal or a food allowance'),
          findsOneWidget,
        );
        await _closeGuide(tester);
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final stress in [true, false]) {
    for (final emptyDataset in [true, false]) {
      testWidgets(
        '${stress ? 'stress' : 'energy'} guide stays available with ${emptyDataset ? 'empty' : 'absent'} dataset',
        (tester) async {
          await _openApp(
            tester,
            stress: stress,
            repository: _MemoryRepository(
              emptyDataset ? _dataset(withSamples: false) : null,
            ),
          );
          for (final period in ['Day', 'Week', 'Month']) {
            await tester.ensureVisible(find.text(period));
            await tester.tap(find.text(period));
            await tester.pumpAndSettle();
            expect(_primary(tester), '—');
            final open = find.byKey(
              Key(stress ? 'stress-education-open' : 'calorie-education-open'),
            );
            await tester.ensureVisible(open);
            await tester.tap(open);
            await tester.pumpAndSettle();
            await _closeGuide(tester);
            expect(_primary(tester), '—');
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      '${stress ? 'stress' : 'energy'} help is accessible and honours reduced motion',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: buildLibreRingTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: Scaffold(
                body: stress
                    ? const StressEducationPrompt()
                    : const CalorieEducationPrompt(),
              ),
            ),
          );
          final open = find.byKey(
            Key(stress ? 'stress-education-open' : 'calorie-education-open'),
          );
          final info = tester.getSemantics(open).getSemanticsData();
          expect(info.flagsCollection.isButton, isTrue);
          expect(info.hasAction(SemanticsAction.tap), isTrue);
          expect(
            info.label,
            stress
                ? 'What does this number mean?'
                : 'Can I trust the calorie figure?',
          );
          await tester.tap(open);
          await tester.pump();
          final title = find.text(
            stress ? 'Stress index, explained' : 'Ring energy, explained',
          );
          expect(
            ModalRoute.of(tester.element(title))!.animation!.status,
            AnimationStatus.completed,
          );
          await _closeGuide(tester);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('${stress ? 'stress' : 'energy'} education sheet golden', (
      tester,
    ) async {
      await _openApp(tester, stress: stress);
      final open = find.byKey(
        Key(stress ? 'stress-education-open' : 'calorie-education-open'),
      );
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/${stress ? 'stress' : 'calorie'}_education.png',
        ),
      );
    }, skip: !Platform.isMacOS);
  }

  testWidgets('energy summary clarification golden', (tester) async {
    await _openApp(tester, stress: false);
    await tester.ensureVisible(find.text('Movement summary'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/energy_summary_education.png'),
    );
  }, skip: !Platform.isMacOS);
}

Future<void> _openApp(
  WidgetTester tester, {
  bool stress = true,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1,
  _MemoryRepository? repository,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    LibreRingApp(
      initialLocation: stress ? '/signals/stress-index' : '/movement',
      locale: locale,
      currentLocalTime: DateTime(2026, 8, 26, 23, 15),
      ringDataRepository: repository ?? _MemoryRepository(_dataset()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _closeGuide(WidgetTester tester, [String label = 'Got it']) async {
  final close = find.widgetWithText(LibreRingPrimaryButton, label);
  await tester.ensureVisible(close);
  await tester.pumpAndSettle();
  await tester.tap(close);
  await tester.pumpAndSettle();
}

String? _primary(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('analytics-primary-value'))).data;

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

RingSyncDataset _dataset({bool withSamples = true}) => RingSyncDataset(
  lastSyncedAtUtc: DateTime(2026, 8, 26, 23).toUtc(),
  source: const RingDataSource(driverId: 'colmi-qring-v1'),
  availability: {
    RingDataKind.stressIndex: withSamples
        ? RingDataAvailability.complete
        : RingDataAvailability.noData,
    RingDataKind.activity: withSamples
        ? RingDataAvailability.complete
        : RingDataAvailability.noData,
  },
  vendorIndexes: [
    if (withSamples)
      for (final sample in [
        (DateTime(2026, 8, 25, 12), 10),
        (DateTime(2026, 8, 26, 2), 30),
        (DateTime(2026, 8, 26, 12), 40),
        (DateTime(2026, 8, 26, 14), 49),
      ])
        RingVendorIndexSample(
          measuredAtUtc: sample.$1.toUtc(),
          value: sample.$2,
          kind: RingVendorIndexKind.stress,
        ),
  ],
  activity: [
    if (withSamples)
      for (final sample in [
        (DateTime(2026, 8, 25, 12), 400),
        (DateTime(2026, 8, 26, 2), 200),
        (DateTime(2026, 8, 26, 12), 150),
      ])
        RingActivityBucket(
          startedAtUtc: sample.$1.toUtc(),
          steps: 50,
          distanceMeters: 20,
          firmwareCalories: sample.$2,
        ),
  ],
);

Future<void> _loadFont(String family, File file) async {
  final loader = FontLoader(family)
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(await file.readAsBytes())),
    );
  await loader.load();
}

File _findMaterialIcons() {
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.parent.path != directory.path) {
    final candidate = File(
      '${directory.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Flutter MaterialIcons font was not found.');
}
