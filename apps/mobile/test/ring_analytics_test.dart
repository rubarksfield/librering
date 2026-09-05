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
    // Composition uses the full sleep window, including its unclassified gap.
    expect(sleep.percentFor(RingSleepStage.rem), 21);
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

  test('defaults to calendar today and lets historical dates be selected', () {
    final now = DateTime(2026, 8, 29, 12);
    final today = RingAnalytics.fromDataset(_dataset(), localNow: now);
    expect(today.selectedDay, DateTime(2026, 8, 29));
    expect(today.activityFor(today.selectedDay).hasRecords, isFalse);
    expect(today.latestRecordedDay, DateTime(2026, 8, 26));
    expect(today.earliestDay, DateTime(2026, 8, 26));

    final historical = RingAnalytics.fromDataset(
      _dataset(),
      localNow: now,
      selectedDay: DateTime(2026, 8, 26),
    );
    expect(historical.activityFor(historical.selectedDay).steps, 350);
    expect(historical.pulseHistory(days: 2).map((day) => day.day), <DateTime>[
      DateTime(2026, 8, 25),
      DateTime(2026, 8, 26),
    ]);
    expect(
      RingAnalytics.fromDataset(
        _dataset(),
        localNow: now,
        selectedDay: DateTime(2026, 9, 1),
      ).selectedDay,
      DateTime(2026, 8, 29),
    );
  });

  test(
    'week statistics stop at the selected day and exclude future records',
    () {
      final now = DateTime(2026, 8, 26, 12);
      final data = RingSyncDataset(
        lastSyncedAtUtc: now.toUtc(),
        source: const RingDataSource(driverId: 'test'),
        availability: const {},
        heartRate: <RingHeartRateSample>[
          for (final (date, bpm) in <(DateTime, int)>[
            (DateTime(2026, 8, 18, 23), 10),
            (DateTime(2026, 8, 19), 60),
            (DateTime(2026, 8, 25, 23), 70),
            (DateTime(2026, 8, 26), 80),
            (DateTime(2026, 8, 26, 13), 90),
          ])
            RingHeartRateSample(measuredAtUtc: date.toUtc(), bpm: bpm),
        ],
        oxygen: <RingOxygenRange>[
          for (final date in <DateTime>[
            DateTime(2026, 8, 19, 1),
            DateTime(2026, 8, 25, 1),
            DateTime(2026, 8, 26, 1),
            DateTime(2026, 8, 26, 13),
          ])
            RingOxygenRange(
              hourStartedAtUtc: date.toUtc(),
              minimumPercent: 95,
              maximumPercent: 99,
            ),
        ],
        vendorIndexes: <RingVendorIndexSample>[
          for (final date in <DateTime>[
            DateTime(2026, 8, 19, 1),
            DateTime(2026, 8, 25, 1),
            DateTime(2026, 8, 26, 1),
            DateTime(2026, 8, 26, 13),
          ])
            RingVendorIndexSample(
              measuredAtUtc: date.toUtc(),
              kind: RingVendorIndexKind.stress,
              value: 40,
            ),
        ],
      );
      final historical = RingAnalytics.fromDataset(
        data,
        localNow: now,
        selectedDay: DateTime(2026, 8, 25),
      );
      expect(historical.periodStart(days: 7), DateTime(2026, 8, 19));
      expect(historical.periodEnd, DateTime(2026, 8, 26));
      expect(historical.pulsePeriod(days: 7).values, <int>[60, 70]);
      expect(historical.oxygenPeriod(days: 7).coveredHours, 2);
      expect(
        historical
            .vendorPeriod(RingVendorIndexKind.stress, days: 7)
            .coveredHours,
        2,
      );

      final today = RingAnalytics.fromDataset(data, localNow: now);
      expect(today.pulsePeriod().values, <int>[80]);
      expect(today.oxygenPeriod().ranges.length, 1);
      expect(today.vendorPeriod(RingVendorIndexKind.stress).samples.length, 1);
    },
  );

  test('sleep-only datasets participate in available date bounds', () {
    final now = DateTime(2026, 8, 29, 12);
    final analytics = RingAnalytics.fromDataset(
      RingSyncDataset(
        lastSyncedAtUtc: now.toUtc(),
        source: const RingDataSource(driverId: 'test'),
        availability: const {},
        sleep: _dataset().sleep,
      ),
      localNow: now,
    );
    expect(analytics.earliestDay, DateTime(2026, 8, 26));
    expect(analytics.latestRecordedDay, DateTime(2026, 8, 26));
    expect(analytics.availableSleepDays, <DateTime>[DateTime(2026, 8, 26)]);
    expect(analytics.sleepFor(DateTime(2026, 8, 29)), isNull);
    expect(analytics.sleepFor(DateTime(2026, 8, 26)), isNotNull);
  });

  test('historical sleep links only pulse and full oxygen hours inside it', () {
    final start = DateTime(2026, 8, 25, 23, 30).toUtc();
    final end = DateTime(2026, 8, 26, 7, 30).toUtc();
    final session = RingSleepSession(
      startedAtUtc: start,
      endedAtUtc: end,
      stages: const [],
    );
    final analytics = RingAnalytics.fromDataset(
      RingSyncDataset(
        lastSyncedAtUtc: DateTime(2026, 8, 27).toUtc(),
        source: const RingDataSource(driverId: 'test'),
        availability: const {},
        sleep: [session],
        heartRate: [
          RingHeartRateSample(measuredAtUtc: start, bpm: 58),
          RingHeartRateSample(
            measuredAtUtc: end.subtract(const Duration(minutes: 1)),
            bpm: 62,
          ),
          RingHeartRateSample(measuredAtUtc: end, bpm: 99),
        ],
        oxygen: [
          for (final hour in <int>[23, 24, 30, 31])
            RingOxygenRange(
              hourStartedAtUtc: DateTime(2026, 8, 25, hour).toUtc(),
              minimumPercent: 95,
              maximumPercent: 98,
            ),
        ],
      ),
      localNow: DateTime(2026, 8, 27),
    );
    final sleep = analytics.sleepFor(DateTime(2026, 8, 26))!;
    expect(sleep.sleepPulse, <int>[58, 62]);
    expect(sleep.oxygenRanges.length, 2);
    expect(sleep.unclassifiedMinutes, 480);
    expect(sleep.asleepMinutes, 0);
    expect(analytics.sleepHistory().single.sleepPulseMedian, 60);
  });

  test('stage overlap and bounds cannot inflate sleep or erase gaps', () {
    final start = DateTime.utc(2026, 8, 25, 23);
    final sleep = SleepAnalytics.fromSession(
      RingSleepSession(
        startedAtUtc: start,
        endedAtUtc: start.add(const Duration(minutes: 60)),
        stages: [
          RingSleepStageSpan(
            stage: RingSleepStage.light,
            startedAtUtc: start.subtract(const Duration(minutes: 10)),
            durationMinutes: 40,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.deep,
            startedAtUtc: start.add(const Duration(minutes: 20)),
            durationMinutes: 20,
          ),
          RingSleepStageSpan(
            stage: RingSleepStage.awake,
            startedAtUtc: start.add(const Duration(minutes: 50)),
            durationMinutes: 30,
          ),
        ],
      ),
    );
    expect(sleep.stageMinutes[RingSleepStage.light], 20);
    expect(sleep.stageMinutes[RingSleepStage.deep], 10);
    expect(sleep.stageMinutes[RingSleepStage.awake], 10);
    expect(sleep.asleepMinutes, 30);
    expect(sleep.recordedStageMinutes, 40);
    expect(sleep.unclassifiedMinutes, 20);
    expect(sleep.longestSleepRunMinutes, 20);
  });

  test(
    'activity period average excludes missing days, retains measured zero',
    () {
      final now = DateTime(2026, 8, 26, 23);
      final analytics = RingAnalytics.fromDataset(
        RingSyncDataset(
          lastSyncedAtUtc: now.toUtc(),
          source: const RingDataSource(driverId: 'test'),
          availability: const {},
          activity: [
            ..._dataset().activity,
            RingActivityBucket(
              startedAtUtc: DateTime(2026, 8, 25, 9).toUtc(),
              steps: 0,
              distanceMeters: 0,
              firmwareCalories: 0,
            ),
          ],
        ),
        localNow: now,
      );
      final week = analytics.activityPeriod(days: 7);
      expect(week.steps, 350);
      expect(week.recordedDays, 2);
      expect(week.missingDays, 5);
      expect(week.averageRecordedDaySteps, 175);
      expect(week.mostStepsDay!.day, DateTime(2026, 8, 26));
      expect(analytics.previousActivityPeriod(days: 7).hasRecords, isFalse);
      expect(
        analytics.previousActivityPeriod(days: 7).averageRecordedDaySteps,
        isNull,
      );
    },
  );

  test('calendar histories keep distinct consecutive days across DST', () {
    final now = DateTime(2026, 3, 31, 12);
    final analytics = RingAnalytics.fromDataset(
      RingSyncDataset(
        lastSyncedAtUtc: now.toUtc(),
        source: const RingDataSource(driverId: 'test'),
        availability: const {},
      ),
      localNow: now,
    );
    final dates = analytics
        .activityHistory(days: 5)
        .map((value) => value.day)
        .toList();
    expect(dates, [
      for (var day = 27; day <= 31; day++) DateTime(2026, 3, day),
    ]);
    expect(analytics.pulseHistory(days: 5).map((value) => value.day), dates);

    for (final date in [DateTime(2026, 3, 29), DateTime(2026, 10, 25)]) {
      final hours = analytics.activityFor(date).hourly;
      expect(
        hours.length,
        RingCalendar.shift(date, 1).difference(date).inHours,
      );
      expect(hours.first.startedAt, date);
      expect(
        hours.last.startedAt.add(const Duration(hours: 1)),
        RingCalendar.shift(date, 1),
      );
    }
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
