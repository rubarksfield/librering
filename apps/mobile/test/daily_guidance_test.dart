import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/daily_guidance.dart';
import 'package:librering_mobile/src/ring_analytics.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';
import 'package:librering_mobile/src/storage/preferences_repository.dart';
import 'package:ring_core/ring_core.dart';

final _now = DateTime(2026, 9, 5, 18);

void main() {
  group('scope and manual context', () {
    test('does not suggest what to do now on a historical date', () {
      expect(_evaluate(selectedDay: DateTime(2026, 9, 4)), isNull);
    });

    test('unknown journal does not assume a healthy exercise context', () {
      expect(_evaluate(journal: null)!.kind, DailyGuidanceKind.checkIn);
    });

    test('illness takes priority over stress, sleep and activity', () {
      final guidance = _evaluate(
        sleep: [_sleep()],
        journal: [_entry('Stress · Illness')],
      )!;
      expect(guidance.kind, DailyGuidanceKind.takeItEasy);
      expect(guidance.recordedSteps, isNull);
      expect(guidance.sleepMinutes, isNull);
    });

    for (final tag in ['Stress', 'Low energy']) {
      test('$tag offers a pause before freshness checks', () {
        expect(
          _evaluate(
            syncedAt: _now.add(const Duration(hours: 1)),
            journal: [_entry(tag)],
          )!.kind,
          DailyGuidanceKind.pause,
        );
      });
    }

    test('future and previous-day check-ins are not used', () {
      expect(
        _evaluate(
          journal: [
            _entry('Illness', at: _now.add(const Duration(minutes: 1))),
            _entry('Stress', at: DateTime(2026, 9, 4, 23)),
          ],
        )!.kind,
        DailyGuidanceKind.walk,
      );
    });

    test('never reads free notes, substrings or non-check-in titles', () {
      expect(
        _evaluate(
          journal: [
            _entry('Note', details: 'Illness Stress Low energy'),
            _entry('No Illness · Stressful day · Low energy today'),
            _entry('Illness', kind: JournalEntryKind.note),
          ],
        )!.kind,
        DailyGuidanceKind.walk,
      );
    });

    test('canonical tokens within a combined title are understood', () {
      expect(
        _evaluate(journal: [_entry('Coffee · Low energy · Exercise')])!.kind,
        DailyGuidanceKind.pause,
      );
    });

    test('demo ignores the real journal and unknown journal state', () {
      final buckets = _buckets(origin: DataOrigin.demo);
      expect(
        _evaluate(
          demo: true,
          activity: buckets,
          journal: [_entry('Illness · Exercise')],
        )!.kind,
        DailyGuidanceKind.walk,
      );
      expect(
        _evaluate(demo: true, activity: buckets, journal: null)!.kind,
        DailyGuidanceKind.walk,
      );
    });

    test('a manual Exercise or swim entry suppresses a steps nudge', () {
      for (final entry in [
        _entry('Exercise · Cycling'),
        _entry('Pool swim', kind: JournalEntryKind.swim),
      ]) {
        expect(_evaluate(journal: [entry])!.kind, DailyGuidanceKind.checkIn);
      }
    });

    test('exercise does not hide an actually recorded step goal', () {
      expect(
        _evaluate(
          activity: [_bucket(17, steps: 5000)],
          journal: [_entry('Exercise')],
        )!.kind,
        DailyGuidanceKind.goalReached,
      );
    });
  });

  group('recorded activity', () {
    test(
      'three fresh distinct hours support a descriptive goal comparison',
      () {
        final guidance = _evaluate()!;
        expect(guidance.kind, DailyGuidanceKind.walk);
        expect(guidance.recordedSteps, 1500);
        expect(guidance.stepGoal, 5000);
        expect(guidance.sleepTargetMinutes, 480);
      },
    );

    test(
      'gaps between recorded hours are not filled or counted as records',
      () {
        expect(
          _evaluate(activity: [_bucket(8), _bucket(17)])!.kind,
          DailyGuidanceKind.checkIn,
        );
      },
    );

    test('a recorded goal needs no inferred missing hours', () {
      final guidance = _evaluate(activity: [_bucket(17, steps: 5000)])!;
      expect(guidance.kind, DailyGuidanceKind.goalReached);
      expect(guidance.recordedSteps, 5000);
      expect(
        _evaluate(activity: [_bucket(17, steps: 5001)])!.kind,
        DailyGuidanceKind.goalReached,
      );
    });

    test('uses the saved step target rather than a universal goal', () {
      final guidance = _evaluate(
        preferences: const AppPreferences(dailyStepGoal: 1500),
      )!;
      expect(guidance.kind, DailyGuidanceKind.goalReached);
      expect(guidance.stepGoal, 1500);
    });

    test('zero, absent and previous-day activity do not imply a deficit', () {
      for (final buckets in <List<RingActivityBucket>>[
        [],
        [_bucket(9, steps: 0), _bucket(12, steps: 0), _bucket(17, steps: 0)],
        [_bucket(17, day: 4, steps: 6000)],
      ]) {
        expect(_evaluate(activity: buckets)!.kind, DailyGuidanceKind.checkIn);
      }
    });

    test('missing and non-complete activity transfer states fail closed', () {
      for (final state in <RingDataAvailability?>[
        null,
        ...RingDataAvailability.values.where(
          (value) => value != RingDataAvailability.complete,
        ),
      ]) {
        expect(
          _evaluate(activityAvailability: state)!.kind,
          DailyGuidanceKind.checkIn,
        );
      }
    });

    test('stale and future sync times cannot support activity guidance', () {
      for (final syncedAt in [
        _now.subtract(const Duration(hours: 2, seconds: 1)),
        _now.add(const Duration(seconds: 1)),
      ]) {
        expect(_evaluate(syncedAt: syncedAt)!.kind, DailyGuidanceKind.checkIn);
      }
      expect(
        _evaluate(syncedAt: _now.subtract(const Duration(hours: 2)))!.kind,
        DailyGuidanceKind.walk,
      );
    });

    test('a fresh battery sync does not make an old activity sample fresh', () {
      expect(
        _evaluate(activity: [_bucket(8), _bucket(10), _bucket(15)])!.kind,
        DailyGuidanceKind.checkIn,
      );
      expect(
        _evaluate(activity: [_bucket(8), _bucket(10), _bucket(16)])!.kind,
        DailyGuidanceKind.walk,
      );
    });

    test('future samples cannot inflate steps or supply fresh coverage', () {
      expect(
        _evaluate(
          activity: [_bucket(8), _bucket(10), _bucket(19, steps: 9000)],
        )!.kind,
        DailyGuidanceKind.checkIn,
      );
      final guidance = _evaluate(
        activity: [..._buckets(), _bucket(19, steps: 9000)],
      )!;
      expect(guidance.kind, DailyGuidanceKind.walk);
      expect(guidance.recordedSteps, 1500);
    });

    test('negative steps and duplicate timestamps fail closed', () {
      for (final buckets in [
        [..._buckets(), _bucket(16, steps: -1)],
        [..._buckets(), _bucket(17, steps: 9000)],
      ]) {
        expect(_evaluate(activity: buckets)!.kind, DailyGuidanceKind.checkIn);
      }
    });

    test(
      'quarter-hour records are summed without inflating recorded hours',
      () {
        final quarterHours = [
          for (final minute in [0, 15, 30, 45]) _bucket(9, minute: minute),
        ];
        final guidance = _evaluate(
          activity: [...quarterHours, _bucket(12), _bucket(17)],
        )!;
        expect(guidance.kind, DailyGuidanceKind.walk);
        expect(guidance.recordedSteps, 3000);
        expect(
          _evaluate(activity: [...quarterHours, _bucket(17)])!.kind,
          DailyGuidanceKind.checkIn,
        );
      },
    );

    test('manual and demo activity do not enter live guidance', () {
      for (final origin in [DataOrigin.manual, DataOrigin.demo]) {
        expect(
          _evaluate(activity: _buckets(origin: origin))!.kind,
          DailyGuidanceKind.checkIn,
        );
      }
    });

    test('no activity suggestion before noon or from 20:00 onward', () {
      for (final hour in [0, 8, 11, 20, 23]) {
        expect(
          _evaluate(now: DateTime(2026, 9, 5, hour))!.kind,
          DailyGuidanceKind.checkIn,
        );
      }
      expect(
        _evaluate(
          now: DateTime(2026, 9, 5, 12),
          activity: [_bucket(8), _bucket(10), _bucket(11)],
        )!.kind,
        DailyGuidanceKind.walk,
      );
    });

    test('invalid saved goals cannot produce a nudge', () {
      expect(
        _evaluate(preferences: const AppPreferences(dailyStepGoal: 0))!.kind,
        DailyGuidanceKind.checkIn,
      );
    });

    test(
      'calories, distance, pulse, oxygen and firmware indexes play no role',
      () {
        final guidance = _evaluate(
          activity: [
            for (final hour in [9, 12, 17])
              _bucket(hour, calories: -999999, distance: 99999999),
          ],
          addOtherSignals: true,
        )!;
        expect(guidance.kind, DailyGuidanceKind.walk);
        expect(guidance.recordedSteps, 1500);
      },
    );
  });

  group('recorded sleep', () {
    test('fully classified short sleep is prioritised over activity', () {
      final guidance = _evaluate(sleep: [_sleep()])!;
      expect(guidance.kind, DailyGuidanceKind.windDown);
      expect(guidance.sleepMinutes, 360);
      expect(guidance.recordedSteps, isNull);
    });

    test('one-hour margin is inclusive and uses the saved target', () {
      expect(
        _evaluate(sleep: [_sleep(minutes: 420)])!.kind,
        DailyGuidanceKind.windDown,
      );
      expect(
        _evaluate(sleep: [_sleep(minutes: 421)])!.kind,
        DailyGuidanceKind.walk,
      );
      expect(
        _evaluate(
          sleep: [_sleep()],
          preferences: const AppPreferences(sleepTargetMinutes: 360),
        )!.kind,
        DailyGuidanceKind.walk,
      );
    });

    test('sleep needs a same-day sync but not a two-hour activity sync', () {
      expect(
        _evaluate(sleep: [_sleep()], syncedAt: DateTime(2026, 9, 5, 9))!.kind,
        DailyGuidanceKind.windDown,
      );
      expect(
        _evaluate(sleep: [_sleep()], syncedAt: DateTime(2026, 9, 4, 23))!.kind,
        DailyGuidanceKind.checkIn,
      );
    });

    test('sleep guidance is withheld before 08:00', () {
      expect(
        _evaluate(now: DateTime(2026, 9, 5, 7, 30), sleep: [_sleep()])!.kind,
        DailyGuidanceKind.checkIn,
      );
      expect(
        _evaluate(now: DateTime(2026, 9, 5, 8), sleep: [_sleep()])!.kind,
        DailyGuidanceKind.windDown,
      );
    });

    test('partial, missing and non-complete sleep never imply short sleep', () {
      for (final state in <RingDataAvailability?>[
        null,
        ...RingDataAvailability.values.where(
          (value) => value != RingDataAvailability.complete,
        ),
      ]) {
        expect(
          _evaluate(sleep: [_sleep()], sleepAvailability: state)!.kind,
          DailyGuidanceKind.walk,
        );
      }
    });

    test('nap-only data is not treated as daily sleep', () {
      expect(
        _evaluate(sleep: [_sleep(minutes: 179)])!.kind,
        DailyGuidanceKind.walk,
      );
      expect(
        _evaluate(sleep: [_sleep(minutes: 180)])!.kind,
        DailyGuidanceKind.windDown,
      );
    });

    test(
      'gaps, zero stages and conflicting stages suppress sleep guidance',
      () {
        final normal = _sleep();
        for (final stages in <List<RingSleepStageSpan>>[
          [],
          [_span(normal.startedAtUtc, 359)],
          [
            ...normal.stages,
            _span(normal.startedAtUtc, 5, RingSleepStage.deep),
          ],
          [...normal.stages, _span(normal.startedAtUtc, 0)],
          [_span(normal.startedAtUtc, 360, RingSleepStage.awake)],
        ]) {
          expect(
            _evaluate(sleep: [_copySleep(normal, stages: stages)])!.kind,
            DailyGuidanceKind.walk,
          );
        }
      },
    );

    test(
      'out-of-bounds spans and invalid windows do not imply short sleep',
      () {
        final normal = _sleep();
        for (final session in [
          _copySleep(normal, stages: [_span(normal.startedAtUtc, 361)]),
          _copySleep(
            normal,
            stages: [
              _span(
                normal.startedAtUtc.subtract(const Duration(minutes: 1)),
                361,
              ),
            ],
          ),
          RingSleepSession(
            startedAtUtc: normal.endedAtUtc,
            endedAtUtc: normal.startedAtUtc,
            stages: [],
          ),
        ]) {
          expect(_evaluate(sleep: [session])!.kind, DailyGuidanceKind.walk);
        }
      },
    );

    test('future and previous-day sleep cannot supply a daily sleep total', () {
      expect(
        _evaluate(
          sleep: [
            _sleep(end: DateTime(2026, 9, 5, 19)),
            _sleep(end: DateTime(2026, 9, 4, 7)),
          ],
        )!.kind,
        DailyGuidanceKind.walk,
      );
    });

    test('manual and demo sleep do not enter live suggestions', () {
      for (final origin in [DataOrigin.manual, DataOrigin.demo]) {
        expect(
          _evaluate(sleep: [_sleep(origin: origin)])!.kind,
          DailyGuidanceKind.walk,
        );
      }
      expect(
        _evaluate(sleep: [_sleep(origin: DataOrigin.demo)], demo: true)!.kind,
        DailyGuidanceKind.windDown,
      );
    });

    test(
      'separate sessions contribute to the same-day recorded sleep total',
      () {
        final guidance = _evaluate(
          sleep: [
            _sleep(),
            _sleep(end: DateTime(2026, 9, 5, 14), minutes: 45),
          ],
        )!;
        expect(guidance.kind, DailyGuidanceKind.windDown);
        expect(guidance.sleepMinutes, 405);
        expect(
          _evaluate(
            sleep: [
              _sleep(),
              _sleep(end: DateTime(2026, 9, 5, 14), minutes: 90),
            ],
          )!.kind,
          DailyGuidanceKind.walk,
        );
      },
    );

    test('overlaps and duplicate sessions cannot undercount daily sleep', () {
      final normal = _sleep();
      for (final second in [
        normal,
        _sleep(end: DateTime(2026, 9, 5, 8), minutes: 180),
        _copySleep(
          normal,
          stages: [_span(normal.startedAtUtc, 360, RingSleepStage.awake)],
        ),
      ]) {
        expect(
          _evaluate(sleep: [normal, second])!.kind,
          DailyGuidanceKind.walk,
        );
      }
    });
  });
}

DailyGuidance? _evaluate({
  DateTime? now,
  DateTime? selectedDay,
  DateTime? syncedAt,
  List<RingActivityBucket>? activity,
  List<RingSleepSession> sleep = const [],
  List<JournalEntry>? journal = const [],
  RingDataAvailability? activityAvailability = RingDataAvailability.complete,
  RingDataAvailability? sleepAvailability = RingDataAvailability.complete,
  AppPreferences preferences = const AppPreferences(),
  bool demo = false,
  bool addOtherSignals = false,
}) {
  final localNow = now ?? _now;
  final dataset = RingSyncDataset(
    lastSyncedAtUtc: (syncedAt ?? localNow).toUtc(),
    source: const RingDataSource(driverId: 'test'),
    availability: {
      RingDataKind.activity: ?activityAvailability,
      RingDataKind.sleep: ?sleepAvailability,
    },
    activity: activity ?? _buckets(),
    sleep: sleep,
    heartRate: [
      if (addOtherSignals)
        RingHeartRateSample(measuredAtUtc: localNow.toUtc(), bpm: 200),
    ],
    oxygen: [
      if (addOtherSignals)
        RingOxygenRange(
          hourStartedAtUtc: localNow.toUtc(),
          minimumPercent: 50,
          maximumPercent: 50,
        ),
    ],
    vendorIndexes: [
      if (addOtherSignals)
        for (final kind in RingVendorIndexKind.values)
          RingVendorIndexSample(
            measuredAtUtc: localNow.toUtc(),
            value: 100,
            kind: kind,
          ),
    ],
  );
  return evaluateDailyGuidance(
    analytics: RingAnalytics.fromDataset(
      dataset,
      localNow: localNow,
      selectedDay: selectedDay,
    ),
    preferences: preferences,
    journal: journal,
    demo: demo,
  );
}

List<RingActivityBucket> _buckets({DataOrigin origin = DataOrigin.ring}) => [
  for (final hour in [9, 12, 17]) _bucket(hour, origin: origin),
];

RingActivityBucket _bucket(
  int hour, {
  int day = 5,
  int minute = 0,
  int steps = 500,
  int calories = 20,
  int distance = 300,
  DataOrigin origin = DataOrigin.ring,
}) => RingActivityBucket(
  startedAtUtc: DateTime(2026, 9, day, hour, minute).toUtc(),
  steps: steps,
  distanceMeters: distance,
  firmwareCalories: calories,
  origin: origin,
);

JournalEntry _entry(
  String title, {
  String details = 'No note',
  DateTime? at,
  JournalEntryKind kind = JournalEntryKind.checkIn,
}) => JournalEntry(
  id: title,
  kind: kind,
  occurredAtUtc: (at ?? _now.subtract(const Duration(hours: 1))).toUtc(),
  title: title,
  details: details,
);

RingSleepSession _sleep({
  DateTime? end,
  int minutes = 360,
  DataOrigin origin = DataOrigin.ring,
}) {
  final endedAt = (end ?? DateTime(2026, 9, 5, 7)).toUtc();
  final startedAt = endedAt.subtract(Duration(minutes: minutes));
  return RingSleepSession(
    startedAtUtc: startedAt,
    endedAtUtc: endedAt,
    stages: [_span(startedAt, minutes)],
    origin: origin,
  );
}

RingSleepStageSpan _span(
  DateTime start,
  int minutes, [
  RingSleepStage stage = RingSleepStage.light,
]) => RingSleepStageSpan(
  stage: stage,
  startedAtUtc: start,
  durationMinutes: minutes,
);

RingSleepSession _copySleep(
  RingSleepSession session, {
  required List<RingSleepStageSpan> stages,
}) => RingSleepSession(
  startedAtUtc: session.startedAtUtc,
  endedAtUtc: session.endedAtUtc,
  stages: stages,
  origin: session.origin,
);
