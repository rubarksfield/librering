import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/ring_data_view.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  test('builds honest measured metrics without a recovery score', () {
    final view = RingDashboardView.fromDataset(
      RingSyncDataset(
        lastSyncedAtUtc: DateTime(2026, 8, 26, 13).toUtc(),
        source: const RingDataSource(driverId: 'colmi-qring-v1'),
        availability: const <RingDataKind, RingDataAvailability>{},
        activity: <RingActivityBucket>[
          RingActivityBucket(
            startedAtUtc: DateTime(2026, 8, 26, 12).toUtc(),
            steps: 500,
            distanceMeters: 400,
            firmwareCalories: 20,
          ),
        ],
        heartRate: <RingHeartRateSample>[
          RingHeartRateSample(
            measuredAtUtc: DateTime(2026, 8, 26, 12).toUtc(),
            bpm: 60,
          ),
          RingHeartRateSample(
            measuredAtUtc: DateTime(2026, 8, 26, 12, 15).toUtc(),
            bpm: 64,
          ),
        ],
      ),
      localNow: DateTime(2026, 8, 26, 13),
    );

    expect(view.metrics.map((metric) => metric.label), <String>[
      'Steps',
      'Distance',
      'Firmware energy',
      'Latest pulse',
      'Sleep window',
      'Oxygen range',
    ]);
    expect(view.metrics[0].value, '500');
    expect(view.metrics[1].value, '400 m');
    expect(view.metrics[2].value, '20');
    expect(view.metrics[2].unit, 'kcal');
    expect(view.metrics[3].value, '64');
    expect(view.averagePulse, 62);
    expect(view.pulseTrend, <double>[60, 64]);
  });

  test('distinguishes retained zero activity from missing activity', () {
    RingDashboardView viewWith(List<RingActivityBucket> activity) =>
        RingDashboardView.fromDataset(
          RingSyncDataset(
            lastSyncedAtUtc: DateTime(2026, 8, 26, 13).toUtc(),
            source: const RingDataSource(driverId: 'colmi-qring-v1'),
            availability: const <RingDataKind, RingDataAvailability>{},
            activity: activity,
          ),
          localNow: DateTime(2026, 8, 26, 13),
        );

    final recordedZero = viewWith(<RingActivityBucket>[
      RingActivityBucket(
        startedAtUtc: DateTime(2026, 8, 26, 12).toUtc(),
        steps: 0,
        distanceMeters: 0,
        firmwareCalories: 0,
      ),
    ]);
    final missing = viewWith(const <RingActivityBucket>[]);

    expect(recordedZero.metrics.take(3).map((metric) => metric.value), <String>[
      '0',
      '0 m',
      '0',
    ]);
    expect(missing.metrics.take(3).map((metric) => metric.value), <String>[
      '—',
      '—',
      '—',
    ]);
  });

  test('latest signals exclude future records and disclose an old date', () {
    final now = DateTime(2026, 8, 26, 13);
    final past = DateTime(2026, 8, 25, 11).toUtc();
    final future = DateTime(2026, 8, 26, 14).toUtc();
    final view = RingDashboardView.fromDataset(
      RingSyncDataset(
        lastSyncedAtUtc: now.toUtc(),
        source: const RingDataSource(driverId: 'test'),
        availability: const {},
        heartRate: [
          RingHeartRateSample(measuredAtUtc: past, bpm: 62),
          RingHeartRateSample(measuredAtUtc: future, bpm: 99),
        ],
        oxygen: [
          RingOxygenRange(
            hourStartedAtUtc: past,
            minimumPercent: 95,
            maximumPercent: 98,
          ),
          RingOxygenRange(
            hourStartedAtUtc: future,
            minimumPercent: 90,
            maximumPercent: 92,
          ),
        ],
      ),
      localNow: now,
    );
    expect(view.metrics[3].value, '62');
    expect(view.metrics[3].context, contains('25/8/2026'));
    expect(view.metrics[5].value, '95–98');
    expect(view.averagePulse, 62);
  });
}
