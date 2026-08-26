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
      'Latest pulse',
      'Sleep',
      'Oxygen range',
    ]);
    expect(view.metrics[0].value, '500');
    expect(view.metrics[1].value, '64');
    expect(view.averagePulse, 62);
    expect(view.pulseTrend, <double>[60, 64]);
  });
}
