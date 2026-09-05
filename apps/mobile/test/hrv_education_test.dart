import 'dart:io';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:librering_mobile/src/ui/hrv_education.dart';
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

  for (final language in <(Locale, String, String, String)>[
    (const Locale('en'), 'What is HRV?', 'HRV, explained', 'Got it'),
    (
      const Locale('pt', 'PT'),
      'O que é a HRV?',
      'HRV, sem complicações',
      'Entendido',
    ),
  ]) {
    testWidgets('HRV education opens and dismisses in ${language.$1}', (
      tester,
    ) async {
      await _openApp(tester, locale: language.$1);
      await tester.ensureVisible(find.byKey(const Key('hrv-education-open')));
      expect(find.text(language.$2), findsOneWidget);
      await tester.tap(find.byKey(const Key('hrv-education-open')));
      await tester.pumpAndSettle();
      expect(find.text(language.$3), findsOneWidget);
      expect(
        find.textContaining(
          language.$1.languageCode == 'pt'
              ? 'A unidade e o cálculo não foram verificados.'
              : 'Its unit and calculation have not been verified.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          language.$1.languageCode == 'pt'
              ? 'não os intervalos entre batimentos'
              : 'not the beat-to-beat intervals',
        ),
        findsOneWidget,
      );
      await _closeGuide(tester, language.$4);
      expect(find.text(language.$3), findsNothing);
      expect(_primary(tester), '60');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('HRV education entry has an accessible labelled button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _openApp(tester);
      final open = find.byKey(const Key('hrv-education-open'));
      await tester.ensureVisible(open);
      final data = tester.getSemantics(open).getSemanticsData();
      expect(data.label, 'What is HRV?');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.getSize(open).height, greaterThanOrEqualTo(48));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('education does not change latest or period median indexes', (
    tester,
  ) async {
    await _openApp(tester);
    for (final period in <(String, String, String)>[
      ('Day', '60', 'Latest ring index'),
      ('Week', '40', 'Median ring index'),
      ('Month', '40', 'Median ring index'),
    ]) {
      await tester.ensureVisible(find.text(period.$1));
      await tester.tap(find.text(period.$1));
      await tester.pumpAndSettle();
      expect(_primary(tester), period.$2);
      expect(find.text(period.$3), findsOneWidget);
      expect(find.text('Ring estimate · unitless index'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('hrv-education-open')));
      await tester.tap(find.byKey(const Key('hrv-education-open')));
      await tester.pumpAndSettle();
      await _closeGuide(tester, 'Got it');
      expect(_primary(tester), period.$2);
      expect(tester.takeException(), isNull);
    }
  });

  for (final noDataset in <bool>[true, false]) {
    testWidgets(
      'HRV education remains available with ${noDataset ? 'no dataset' : 'empty HRV history'} in all periods',
      (tester) async {
        await _openApp(
          tester,
          repository: _MemoryRepository(
            noDataset ? null : _dataset(withSamples: false),
          ),
        );
        for (final period in <String>['Day', 'Week', 'Month']) {
          await tester.ensureVisible(find.text(period));
          await tester.tap(find.text(period));
          await tester.pumpAndSettle();
          expect(_primary(tester), '—');
          await tester.ensureVisible(
            find.byKey(const Key('hrv-education-open')),
          );
          await tester.tap(find.byKey(const Key('hrv-education-open')));
          await tester.pumpAndSettle();
          expect(find.text('HRV, explained'), findsOneWidget);
          await _closeGuide(tester, 'Got it');
          expect(_primary(tester), '—');
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('HRV guide reflows and closes on a small screen at 2x text', (
    tester,
  ) async {
    await _openApp(tester, size: const Size(320, 568), textScale: 2);
    await tester.ensureVisible(find.byKey(const Key('hrv-education-open')));
    await tester.tap(find.byKey(const Key('hrv-education-open')));
    await tester.pumpAndSettle();
    expect(find.text('HRV, explained'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _closeGuide(tester, 'Got it');
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HRV education respects reduced motion when opening', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLibreRingTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(body: HrvEducationPrompt()),
      ),
    );
    await tester.tap(find.byKey(const Key('hrv-education-open')));
    await tester.pump();
    final route = ModalRoute.of(tester.element(find.text('HRV, explained')))!;
    expect(route.animation!.status, AnimationStatus.completed);
    expect(tester.takeException(), isNull);
    await _closeGuide(tester, 'Got it');
  });

  testWidgets('stress detail does not gain HRV education', (tester) async {
    await _openApp(tester, route: '/signals/stress-index');
    expect(find.byKey(const Key('hrv-education-open')), findsNothing);
    expect(
      find.textContaining(
        'formula and scale have not been independently verified',
      ),
      findsOneWidget,
    );
  });

  testWidgets('HRV education open sheet matches golden', (tester) async {
    await _openApp(tester);
    await tester.tap(find.byKey(const Key('hrv-education-open')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/hrv_education.png'),
    );
  }, skip: !Platform.isMacOS);
}

Future<void> _openApp(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1,
  String route = '/signals/hrv-index',
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
      initialLocation: route,
      locale: locale,
      currentLocalTime: DateTime(2026, 8, 26, 23, 15),
      ringDataRepository: repository ?? _MemoryRepository(_dataset()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _closeGuide(WidgetTester tester, String label) async {
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
  availability: <RingDataKind, RingDataAvailability>{
    RingDataKind.firmwareHrvIndex: withSamples
        ? RingDataAvailability.complete
        : RingDataAvailability.noData,
  },
  vendorIndexes: <RingVendorIndexSample>[
    if (withSamples)
      for (final point in <(DateTime, int)>[
        (DateTime(2026, 8, 25, 12), 20),
        (DateTime(2026, 8, 26, 2), 40),
        (DateTime(2026, 8, 26, 12), 60),
      ])
        RingVendorIndexSample(
          measuredAtUtc: point.$1.toUtc(),
          value: point.$2,
          kind: RingVendorIndexKind.firmwareHrv,
        ),
  ],
);

Future<void> _loadFont(String family, File file) async {
  final bytes = await file.readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
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
