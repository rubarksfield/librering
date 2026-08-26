import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/ring_analytics.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  test(
    'builds hourly activity without turning missing hours into activity',
    () {
      final analytics = RingAnalytics.fromDataset(
        _dataset(),
        localNow: DateTime(2026, 8, 26, 23),
      );

      final activity = analytics.activityFor(DateTime(2026, 8, 26));
      expect(activity.steps, 350);
      expect(activity.distanceMeters, 260);
      expect(activity.firmwareCalories, 14);
      expect(activity.coveredHours, 2);
      expect(activity.hourly[9].steps, 200);
      expect(activity.hourly[10].steps, 150);
      expect(activity.hourly[11].hasRecord, isFalse);
    },
  );

  test('summarises measured values and keeps oxygen as ranges', () {
    final analytics = RingAnalytics.fromDataset(
      _dataset(),
      localNow: DateTime(2026, 8, 26, 23),
    );

    final pulse = analytics.pulseFor(DateTime(2026, 8, 26));
    expect(pulse.mean, 65);
    expect(pulse.median, 65);
    expect(pulse.minimum, 55);
    expect(pulse.maximum, 75);

    final oxygen = analytics.oxygenFor(DateTime(2026, 8, 26));
    expect(oxygen.minimum, 94);
    expect(oxygen.maximum, 99);
    expect(oxygen.coveredHours, 2);
  });

  test('sleep composition reports coverage and related captured signals', () {
    final sleep = RingAnalytics.fromDataset(
      _dataset(),
      localNow: DateTime(2026, 8, 26, 23),
    ).latestSleep!;

    expect(sleep.intervalMinutes, 480);
    expect(sleep.recordedStageMinutes, 420);
    expect(sleep.unclassifiedMinutes, 60);
    expect(sleep.stageMinutes[RingSleepStage.deep], 80);
    expect(sleep.percentFor(RingSleepStage.rem), 24);
    expect(sleep.awakeSpans, 1);
    expect(sleep.longestSleepRunMinutes, 260);
    expect(sleep.sleepPulseMedian, 60);
    expect(sleep.oxygenMinimum, 94);
    expect(sleep.oxygenMaximum, 99);
  });

  test('opaque vendor indexes get statistics without invented units', () {
    final series = RingAnalytics.fromDataset(
      _dataset(),
      localNow: DateTime(2026, 8, 26, 23),
    ).vendorIndexFor(DateTime(2026, 8, 26), RingVendorIndexKind.stress);

    expect(series.values, <int>[30, 40, 50]);
    expect(series.median, 40);
    expect(series.minimum, 30);
    expect(series.maximum, 50);
  });

  test('unclassified stage gaps break inferred sleep continuity', () {
    final start = DateTime(2026, 8, 25, 23).toUtc();
    final sleep = SleepAnalytics.fromSession(
      RingSleepSession(
        startedAtUtc: start,
        endedAtUtc: start.add(const Duration(hours: 4)),
        stages: <RingSleepStageSpan>[
          RingSleepStageSpan(
            stage: RingSleepStage.light,
            startedAtUtc: start,
            durationMinutes: 100,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.deep,
            startedAtUtc: start.add(const Duration(minutes: 120)),
            durationMinutes: 80,
          ),
        ],
      ),
    );

    expect(sleep.unclassifiedMinutes, 60);
    expect(sleep.longestSleepRunMinutes, 100);
  });
}

RingSyncDataset _dataset() {
  final sleepStart = DateTime(2026, 8, 25, 23).toUtc();
  final sleepEnd = DateTime(2026, 8, 26, 7).toUtc();
  return RingSyncDataset(
    lastSyncedAtUtc: DateTime(2026, 8, 26, 23).toUtc(),
    source: const RingDataSource(driverId: 'test'),
    availability: const <RingDataKind, RingDataAvailability>{},
    activity: <RingActivityBucket>[
      RingActivityBucket(
        startedAtUtc: DateTime(2026, 8, 26, 9).toUtc(),
        steps: 200,
        distanceMeters: 150,
        firmwareCalories: 8,
      ),
      RingActivityBucket(
        startedAtUtc: DateTime(2026, 8, 26, 10).toUtc(),
        steps: 150,
        distanceMeters: 110,
        firmwareCalories: 6,
      ),
    ],
    heartRate: <RingHeartRateSample>[
      RingHeartRateSample(
        measuredAtUtc: DateTime(2026, 8, 26, 1).toUtc(),
        bpm: 55,
      ),
      RingHeartRateSample(
        measuredAtUtc: DateTime(2026, 8, 26, 2).toUtc(),
        bpm: 65,
      ),
      RingHeartRateSample(
        measuredAtUtc: DateTime(2026, 8, 26, 9).toUtc(),
        bpm: 75,
      ),
    ],
    oxygen: <RingOxygenRange>[
      RingOxygenRange(
        hourStartedAtUtc: DateTime(2026, 8, 26, 1).toUtc(),
        minimumPercent: 94,
        maximumPercent: 98,
      ),
      RingOxygenRange(
        hourStartedAtUtc: DateTime(2026, 8, 26, 2).toUtc(),
        minimumPercent: 96,
        maximumPercent: 99,
      ),
    ],
    vendorIndexes: <RingVendorIndexSample>[
      for (final value in <int>[30, 40, 50])
        RingVendorIndexSample(
          measuredAtUtc: DateTime(2026, 8, 26, value ~/ 10).toUtc(),
          value: value,
          kind: RingVendorIndexKind.stress,
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
            durationMinutes: 180,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.awake,
            startedAtUtc: sleepStart.add(const Duration(minutes: 260)),
            durationMinutes: 20,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.rem,
            startedAtUtc: sleepStart.add(const Duration(minutes: 280)),
            durationMinutes: 100,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.light,
            startedAtUtc: sleepStart.add(const Duration(minutes: 380)),
            durationMinutes: 40,
          ),
        ],
      ),
    ],
  );
}
