import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/ring_data_view.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  test('builds honest measured metrics without a recovery score', () {
    final view = RingDashboardView.fromDataset(
      RingSyncDataset(
        lastSyncedAtUtc: DateTime.utc(2026, 8, 26, 13),
        source: const RingDataSource(driverId: 'colmi-qring-v1'),
        availability: const <RingDataKind, RingDataAvailability>{},
        activity: <RingActivityBucket>[
          RingActivityBucket(
            startedAtUtc: DateTime.utc(2026, 8, 26, 12),
            steps: 500,
            distanceMeters: 400,
            firmwareCalories: 20,
          ),
        ],
        heartRate: <RingHeartRateSample>[
          RingHeartRateSample(
            measuredAtUtc: DateTime.utc(2026, 8, 26, 12),
            bpm: 60,
          ),
          RingHeartRateSample(
            measuredAtUtc: DateTime.utc(2026, 8, 26, 12, 15),
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
      'Sleep',
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
            lastSyncedAtUtc: DateTime.utc(2026, 8, 26, 13),
            source: const RingDataSource(driverId: 'colmi-qring-v1'),
            availability: const <RingDataKind, RingDataAvailability>{},
            activity: activity,
          ),
          localNow: DateTime(2026, 8, 26, 13),
        );

    final recordedZero = viewWith(<RingActivityBucket>[
      RingActivityBucket(
        startedAtUtc: DateTime.utc(2026, 8, 26, 12),
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
}
