import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/ring_product_view.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  test('builds an honest daily product view from verified R12 records', () {
    final now = DateTime(2026, 8, 26, 10);
    final sleepEnd = DateTime(2026, 8, 26, 7).toUtc();
    final sleepStart = sleepEnd.subtract(const Duration(hours: 7, minutes: 40));
    final view = RingProductView.fromDataset(
      RingSyncDataset(
        lastSyncedAtUtc: now.subtract(const Duration(minutes: 10)).toUtc(),
        source: const RingDataSource(
          driverId: 'colmi-qring-v1',
          firmwareVersion: 'verified-test-firmware',
        ),
        availability: const <RingDataKind, RingDataAvailability>{
          RingDataKind.activity: RingDataAvailability.complete,
          RingDataKind.heartRate: RingDataAvailability.complete,
          RingDataKind.sleep: RingDataAvailability.complete,
          RingDataKind.oxygen: RingDataAvailability.complete,
        },
        activity: <RingActivityBucket>[
          RingActivityBucket(
            startedAtUtc: DateTime(2026, 8, 26, 9).toUtc(),
            steps: 1250,
            distanceMeters: 840,
            firmwareCalories: 44,
          ),
        ],
        heartRate: <RingHeartRateSample>[
          RingHeartRateSample(
            measuredAtUtc: DateTime(2026, 8, 26, 8).toUtc(),
            bpm: 61,
          ),
          RingHeartRateSample(
            measuredAtUtc: DateTime(2026, 8, 26, 9).toUtc(),
            bpm: 64,
          ),
        ],
        sleep: <RingSleepSession>[
          RingSleepSession(
            startedAtUtc: sleepStart,
            endedAtUtc: sleepEnd,
            stages: <RingSleepStageSpan>[
              RingSleepStageSpan(
                stage: RingSleepStage.deep,
                startedAtUtc: sleepStart,
                durationMinutes: 80,
              ),
              RingSleepStageSpan(
                stage: RingSleepStage.light,
                startedAtUtc: sleepStart.add(const Duration(minutes: 80)),
                durationMinutes: 260,
              ),
              RingSleepStageSpan(
                stage: RingSleepStage.rem,
                startedAtUtc: sleepStart.add(const Duration(minutes: 340)),
                durationMinutes: 120,
              ),
            ],
          ),
        ],
        oxygen: <RingOxygenRange>[
          RingOxygenRange(
            hourStartedAtUtc: DateTime(2026, 8, 26, 5).toUtc(),
            minimumPercent: 95,
            maximumPercent: 98,
          ),
        ],
      ),
      localNow: now,
    );

    expect(view.dailySignal.headline, contains('7 h 40 min'));
    expect(view.domain(ProductDomain.sleep).value, '7:40');
    expect(
      view.domain(ProductDomain.sleep).confidence,
      ProductConfidence.moderate,
    );
    expect(view.domain(ProductDomain.movement).value, '1250');
    expect(
      view.domain(ProductDomain.movement).explanation,
      contains('44 firmware kcal'),
    );
    expect(view.domain(ProductDomain.heart).value, '64');
    expect(view.domain(ProductDomain.oxygen).value, '95–98');
    expect(view.domain(ProductDomain.recovery).value, '—');
    expect(view.domain(ProductDomain.recovery).status, 'Protected');
    expect(view.sleepStageMinutes[RingSleepStage.deep], 80);
    expect(view.validTrendDays, 1);
  });

  test('treats a retained zero activity bucket as an actual zero', () {
    final now = DateTime(2026, 8, 26, 10);
    final view = RingProductView.fromDataset(
      RingSyncDataset(
        lastSyncedAtUtc: now.toUtc(),
        source: const RingDataSource(driverId: 'colmi-qring-v1'),
        availability: const <RingDataKind, RingDataAvailability>{},
        activity: <RingActivityBucket>[
          RingActivityBucket(
            startedAtUtc: DateTime(2026, 8, 26, 9).toUtc(),
            steps: 0,
            distanceMeters: 0,
            firmwareCalories: 0,
          ),
        ],
      ),
      localNow: now,
    );

    expect(view.dailySignal.headline, '0 steps are recorded so far.');
    expect(view.domain(ProductDomain.movement).value, '0');
    expect(view.domain(ProductDomain.movement).status, 'Steps today');
    expect(view.validTrendDays, 1);
  });

  test('stale data asks for refresh without discarding local history', () {
    final now = DateTime(2026, 8, 26, 10);
    final view = RingProductView.fromDataset(
      RingSyncDataset(
        lastSyncedAtUtc: now.subtract(const Duration(days: 3)).toUtc(),
        source: const RingDataSource(driverId: 'colmi-qring-v1'),
        availability: const <RingDataKind, RingDataAvailability>{},
        heartRate: <RingHeartRateSample>[
          RingHeartRateSample(
            measuredAtUtc: now.subtract(const Duration(days: 3)).toUtc(),
            bpm: 62,
          ),
        ],
      ),
      localNow: now,
    );

    expect(view.dailySignal.eyebrow, 'Refresh recommended');
    expect(view.dailySignal.body, contains('already stored'));
    expect(
      view.domain(ProductDomain.recovery).confidence,
      ProductConfidence.unavailable,
    );
  });
}
