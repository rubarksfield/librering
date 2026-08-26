import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      'Helvetica Neue',
      File('/System/Library/Fonts/HelveticaNeue.ttc'),
    );
    await _loadFont('MaterialIcons', _findMaterialIcons());
  });

  for (final route in <(String, String)>[
    ('/today', 'analytics_today'),
    ('/metrics', 'analytics_metrics'),
    ('/movement', 'analytics_activity'),
    ('/sleep', 'analytics_sleep'),
    ('/heart', 'analytics_heart'),
    ('/oxygen', 'analytics_oxygen'),
    ('/signals/hrv-index', 'analytics_hrv_index'),
    ('/signals/stress-index', 'analytics_stress_index'),
    ('/you/ring/capabilities', 'analytics_capabilities'),
  ]) {
    testWidgets('${route.$2} matches analytics golden', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        LibreRingApp(
          key: ValueKey<String>(route.$1),
          initialLocation: route.$1,
          ringDataRepository: _MemoryRepository(_dataset()),
          currentLocalTime: DateTime(2026, 8, 26, 23, 15),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${route.$2}.png'),
      );
    }, skip: !Platform.isMacOS);
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

RingSyncDataset _dataset() {
  final day = DateTime(2026, 8, 26);
  final sleepStart = DateTime(2026, 8, 25, 23, 34).toUtc();
  final sleepEnd = DateTime(2026, 8, 26, 7, 42).toUtc();
  return RingSyncDataset(
    lastSyncedAtUtc: DateTime(2026, 8, 26, 23, 10).toUtc(),
    source: const RingDataSource(
      driverId: 'colmi-qring-v1',
      firmwareVersion: 'RT11CR_1.00.09_260424',
    ),
    availability: const <RingDataKind, RingDataAvailability>{
      RingDataKind.activity: RingDataAvailability.complete,
      RingDataKind.heartRate: RingDataAvailability.complete,
      RingDataKind.sleep: RingDataAvailability.complete,
      RingDataKind.oxygen: RingDataAvailability.complete,
      RingDataKind.stressIndex: RingDataAvailability.complete,
      RingDataKind.firmwareHrvIndex: RingDataAvailability.complete,
    },
    batteryLevel: 55,
    activity: <RingActivityBucket>[
      for (final point in <(int, int, int, int)>[
        (7, 120, 86, 5),
        (8, 245, 176, 10),
        (10, 840, 602, 35),
        (11, 930, 660, 39),
        (12, 210, 151, 9),
        (14, 365, 262, 15),
        (18, 170, 122, 7),
        (19, 410, 294, 17),
        (20, 610, 438, 26),
        (21, 520, 373, 22),
        (22, 540, 388, 23),
      ])
        RingActivityBucket(
          startedAtUtc: DateTime(
            day.year,
            day.month,
            day.day,
            point.$1,
          ).toUtc(),
          steps: point.$2,
          distanceMeters: point.$3,
          firmwareCalories: point.$4,
        ),
    ],
    heartRate: <RingHeartRateSample>[
      for (final point in <(int, int)>[
        (0, 56),
        (2, 52),
        (5, 54),
        (8, 82),
        (10, 76),
        (12, 79),
        (15, 88),
        (18, 74),
        (20, 96),
        (22, 83),
        (23, 91),
      ])
        RingHeartRateSample(
          measuredAtUtc: DateTime(
            day.year,
            day.month,
            day.day,
            point.$1,
          ).toUtc(),
          bpm: point.$2,
        ),
    ],
    oxygen: <RingOxygenRange>[
      for (final point in <(int, int, int)>[
        (0, 96, 98),
        (1, 95, 98),
        (3, 97, 99),
        (5, 96, 98),
        (7, 95, 97),
        (12, 96, 98),
        (18, 94, 97),
        (19, 96, 99),
        (21, 95, 98),
        (22, 96, 99),
      ])
        RingOxygenRange(
          hourStartedAtUtc: DateTime(
            day.year,
            day.month,
            day.day,
            point.$1,
          ).toUtc(),
          minimumPercent: point.$2,
          maximumPercent: point.$3,
        ),
    ],
    vendorIndexes: <RingVendorIndexSample>[
      for (final kind in RingVendorIndexKind.values)
        for (final point in <(int, int)>[
          (0, 36),
          (2, 32),
          (4, 38),
          (7, 34),
          (9, 42),
          (12, 39),
          (18, 44),
          (21, 41),
          (23, 43),
        ])
          RingVendorIndexSample(
            measuredAtUtc: DateTime(
              day.year,
              day.month,
              day.day,
              point.$1,
            ).toUtc(),
            value: kind == RingVendorIndexKind.stress ? point.$2 : point.$2 + 4,
            kind: kind,
          ),
    ],
    sleep: <RingSleepSession>[
      RingSleepSession(
        startedAtUtc: sleepStart,
        endedAtUtc: sleepEnd,
        stages: <RingSleepStageSpan>[
          RingSleepStageSpan(
            stage: RingSleepStage.light,
            startedAtUtc: sleepStart,
            durationMinutes: 52,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.deep,
            startedAtUtc: sleepStart.add(const Duration(minutes: 52)),
            durationMinutes: 78,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.light,
            startedAtUtc: sleepStart.add(const Duration(minutes: 130)),
            durationMinutes: 95,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.rem,
            startedAtUtc: sleepStart.add(const Duration(minutes: 225)),
            durationMinutes: 62,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.awake,
            startedAtUtc: sleepStart.add(const Duration(minutes: 287)),
            durationMinutes: 12,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.light,
            startedAtUtc: sleepStart.add(const Duration(minutes: 299)),
            durationMinutes: 86,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.deep,
            startedAtUtc: sleepStart.add(const Duration(minutes: 385)),
            durationMinutes: 48,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.rem,
            startedAtUtc: sleepStart.add(const Duration(minutes: 433)),
            durationMinutes: 55,
          ),
        ],
      ),
    ],
  );
}

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
