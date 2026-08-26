import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  late Directory directory;
  late FileRingDataRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('librering-store-test-');
    repository = FileRingDataRepository(directory);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('persists and reloads a provenance-bearing dataset', () async {
    final stored = await repository.merge(_dataset());
    final reloaded = await repository.read();

    expect(stored.recordCount, 5);
    expect(reloaded, isNotNull);
    expect(reloaded!.source.driverId, 'colmi-qring-v1');
    expect(reloaded.source.firmwareVersion, 'verified-firmware');
    expect(reloaded.batteryLevel, 73);
    expect(reloaded.activity.single.steps, 321);
    expect(reloaded.heartRate.single.bpm, 61);
    expect(reloaded.sleep.single.stages.single.stage, RingSleepStage.deep);
  });

  test(
    'repeated sync replaces deterministic records without duplicates',
    () async {
      await repository.merge(_dataset());
      final updated = await repository.merge(
        _dataset(
          activity: <RingActivityBucket>[
            RingActivityBucket(
              startedAtUtc: DateTime.utc(2026, 8, 26, 12),
              steps: 999,
              distanceMeters: 700,
              firmwareCalories: 40,
            ),
          ],
        ),
      );

      expect(updated.activity, hasLength(1));
      expect(updated.activity.single.steps, 999);
      expect(updated.sleep, hasLength(1));
    },
  );

  test('a no-data sync preserves previously stored history', () async {
    await repository.merge(_dataset());
    final merged = await repository.merge(
      RingSyncDataset(
        lastSyncedAtUtc: DateTime.utc(2026, 8, 26, 13),
        source: const RingDataSource(driverId: 'colmi-qring-v1'),
        availability: const <RingDataKind, RingDataAvailability>{
          RingDataKind.heartRate: RingDataAvailability.noData,
        },
      ),
    );

    expect(merged.heartRate, hasLength(1));
    expect(
      merged.availability[RingDataKind.heartRate],
      RingDataAvailability.noData,
    );
  });

  test('merge removes records outside the bounded retention window', () async {
    await repository.merge(
      _dataset(
        activity: <RingActivityBucket>[
          RingActivityBucket(
            startedAtUtc: DateTime.utc(2025, 1),
            steps: 100,
            distanceMeters: 80,
            firmwareCalories: 4,
          ),
          RingActivityBucket(
            startedAtUtc: DateTime.utc(2026, 8, 26, 12),
            steps: 321,
            distanceMeters: 240,
            firmwareCalories: 12,
          ),
        ],
      ),
    );

    final stored = await repository.read();
    expect(stored!.activity, hasLength(1));
    expect(stored.activity.single.steps, 321);
  });

  test('corrupt data fails closed and is not overwritten', () async {
    final file = File('${directory.path}/librering/ring-data-v1.json');
    await file.parent.create(recursive: true);
    await file.writeAsString('{not valid json');

    await expectLater(
      repository.read(),
      throwsA(isA<RingDataStoreException>()),
    );
    await expectLater(
      repository.merge(_dataset()),
      throwsA(isA<RingDataStoreException>()),
    );
    expect(await file.readAsString(), '{not valid json');
  });

  test('stored JSON cannot contain BLE identity fields', () async {
    await repository.merge(_dataset());
    final value = await File('${directory.path}/librering/ring-data-v1.json')
        .readAsString();

    expect(value, isNot(contains('deviceId')));
    expect(value, isNot(contains('advertisedName')));
    expect(value, isNot(contains('SECRET_SUFFIX')));
  });

  test('deleteAll removes the exact local store', () async {
    await repository.merge(_dataset());
    await repository.deleteAll();

    expect(await repository.read(), isNull);
  });
}

RingSyncDataset _dataset({List<RingActivityBucket>? activity}) {
  return RingSyncDataset(
    lastSyncedAtUtc: DateTime.utc(2026, 8, 26, 12, 30),
    source: const RingDataSource(
      driverId: 'colmi-qring-v1',
      firmwareVersion: 'verified-firmware',
    ),
    availability: const <RingDataKind, RingDataAvailability>{
      RingDataKind.activity: RingDataAvailability.complete,
      RingDataKind.heartRate: RingDataAvailability.complete,
      RingDataKind.sleep: RingDataAvailability.complete,
      RingDataKind.oxygen: RingDataAvailability.complete,
    },
    batteryLevel: 73,
    charging: false,
    activity:
        activity ??
        <RingActivityBucket>[
          RingActivityBucket(
            startedAtUtc: DateTime.utc(2026, 8, 26, 12),
            steps: 321,
            distanceMeters: 240,
            firmwareCalories: 12,
          ),
        ],
    heartRate: <RingHeartRateSample>[
      RingHeartRateSample(
        measuredAtUtc: DateTime.utc(2026, 8, 26, 12, 15),
        bpm: 61,
      ),
    ],
    vendorIndexes: <RingVendorIndexSample>[
      RingVendorIndexSample(
        measuredAtUtc: DateTime.utc(2026, 8, 26, 12, 20),
        value: 20,
        kind: RingVendorIndexKind.stress,
      ),
    ],
    oxygen: <RingOxygenRange>[
      RingOxygenRange(
        hourStartedAtUtc: DateTime.utc(2026, 8, 26, 11),
        minimumPercent: 95,
        maximumPercent: 98,
      ),
    ],
    sleep: <RingSleepSession>[
      RingSleepSession(
        startedAtUtc: DateTime.utc(2026, 8, 25, 22),
        endedAtUtc: DateTime.utc(2026, 8, 26, 6),
        stages: <RingSleepStageSpan>[
          RingSleepStageSpan(
            stage: RingSleepStage.deep,
            startedAtUtc: DateTime.utc(2026, 8, 25, 22),
            durationMinutes: 60,
          ),
        ],
      ),
    ],
  );
}
