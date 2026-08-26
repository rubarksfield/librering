import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  test('returning production users launch directly into Today', () async {
    expect(
      await resolveInitialLocation(
        demoMode: false,
        captureMode: false,
        ringDataRepository: _MemoryRepository(_dataset()),
      ),
      '/today',
    );
    expect(
      await resolveInitialLocation(
        demoMode: false,
        captureMode: false,
        ringDataRepository: _MemoryRepository(null),
      ),
      '/welcome',
    );
  });

  testWidgets('production screens render stored ring data without scores', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MemoryRepository(_dataset());

    await tester.pumpWidget(
      LibreRingApp(initialLocation: '/today', ringDataRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ring data synced.'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(
      find.textContaining('Recovery scoring is unavailable'),
      findsOneWidget,
    );
    expect(find.text('82'), findsNothing);
    expect(find.textContaining('Demo data'), findsNothing);

    await tester.tap(find.text('View metrics'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-metrics')), findsOneWidget);
    expect(find.text('500', findRichText: true), findsOneWidget);
    expect(find.textContaining('64 bpm', findRichText: true), findsOneWidget);
    expect(find.textContaining('95–98 %', findRichText: true), findsOneWidget);
  });

  testWidgets(
    'local ring deletion requires confirmation and clears the store',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _MemoryRepository(_dataset());

      await tester.pumpWidget(
        LibreRingApp(
          initialLocation: '/privacy/cycle',
          ringDataRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('delete-ring-data')));
      await tester.tap(find.byKey(const Key('delete-ring-data')));
      await tester.pumpAndSettle();
      expect(find.text('Delete local ring data?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-delete-ring-data')));
      await tester.pumpAndSettle();
      expect(repository.value, isNull);
      expect(repository.deleteCount, 1);
      expect(find.byKey(const Key('delete-ring-data')), findsNothing);
    },
  );
}

class _MemoryRepository implements RingDataRepository {
  _MemoryRepository(this.value);

  RingSyncDataset? value;
  int deleteCount = 0;

  @override
  Future<void> deleteAll() async {
    deleteCount += 1;
    value = null;
  }

  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async =>
      value = incoming;

  @override
  Future<RingSyncDataset?> read() async => value;
}

RingSyncDataset _dataset() {
  final localNow = DateTime.now();
  final now = DateTime.now().toUtc();
  final todayAtNoonUtc = DateTime(
    localNow.year,
    localNow.month,
    localNow.day,
    12,
  ).toUtc();
  return RingSyncDataset(
    lastSyncedAtUtc: now,
    source: const RingDataSource(
      driverId: 'colmi-qring-v1',
      firmwareVersion: 'RT11CR_1.00.09_260424',
    ),
    availability: const <RingDataKind, RingDataAvailability>{
      RingDataKind.activity: RingDataAvailability.complete,
      RingDataKind.heartRate: RingDataAvailability.complete,
      RingDataKind.sleep: RingDataAvailability.complete,
      RingDataKind.oxygen: RingDataAvailability.complete,
    },
    batteryLevel: 73,
    activity: <RingActivityBucket>[
      RingActivityBucket(
        startedAtUtc: todayAtNoonUtc,
        steps: 500,
        distanceMeters: 400,
        firmwareCalories: 20,
      ),
    ],
    heartRate: <RingHeartRateSample>[
      RingHeartRateSample(
        measuredAtUtc: now.subtract(const Duration(minutes: 15)),
        bpm: 60,
      ),
      RingHeartRateSample(measuredAtUtc: now, bpm: 64),
    ],
    oxygen: <RingOxygenRange>[
      RingOxygenRange(
        hourStartedAtUtc: now.subtract(const Duration(hours: 1)),
        minimumPercent: 95,
        maximumPercent: 98,
      ),
    ],
    sleep: <RingSleepSession>[
      RingSleepSession(
        startedAtUtc: now.subtract(const Duration(hours: 9)),
        endedAtUtc: now.subtract(const Duration(hours: 1)),
        stages: <RingSleepStageSpan>[
          RingSleepStageSpan(
            stage: RingSleepStage.deep,
            startedAtUtc: now.subtract(const Duration(hours: 9)),
            durationMinutes: 60,
          ),
        ],
      ),
    ],
  );
}
