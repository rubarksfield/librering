import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/ring_analytics.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  final day = DateTime(2026, 9, 4);

  RingSleepStageSpan span(
    int startMinute,
    int duration,
    RingSleepStage stage,
  ) => RingSleepStageSpan(
    stage: stage,
    startedAtUtc: day.add(Duration(minutes: startMinute)).toUtc(),
    durationMinutes: duration,
  );

  RingSleepSession session(
    int startMinute,
    int endMinute,
    List<RingSleepStageSpan> stages,
  ) => RingSleepSession(
    startedAtUtc: day.add(Duration(minutes: startMinute)).toUtc(),
    endedAtUtc: day.add(Duration(minutes: endMinute)).toUtc(),
    stages: stages,
  );

  RingAnalytics analytics(List<RingSleepSession> sessions) =>
      RingAnalytics.fromDataset(
        RingSyncDataset(
          lastSyncedAtUtc: day.add(const Duration(hours: 23)).toUtc(),
          source: const RingDataSource(driverId: 'test'),
          availability: const <RingDataKind, RingDataAvailability>{},
          sleep: sessions,
        ),
        localNow: day.add(const Duration(hours: 23)),
      );

  test('daily sleep totals union duplicate and partly overlapping windows', () {
    final first = session(0, 60, [span(0, 60, RingSleepStage.light)]);
    final overlapping = session(30, 90, [span(30, 60, RingSleepStage.light)]);
    expect(analytics([first, first, overlapping]).asleepMinutesFor(day), 90);
  });

  test('daily sleep totals sum separated sessions without filling gaps', () {
    expect(
      analytics([
        session(0, 60, [span(0, 60, RingSleepStage.light)]),
        session(300, 330, [span(300, 30, RingSleepStage.deep)]),
      ]).asleepMinutesFor(day),
      90,
    );
  });

  test('contradictory stages across sessions stay unavailable', () {
    expect(
      analytics([
        session(0, 60, [span(0, 60, RingSleepStage.light)]),
        session(30, 90, [span(30, 60, RingSleepStage.awake)]),
      ]).asleepMinutesFor(day),
      30,
    );
  });

  test('another session cannot erase an existing stage conflict', () {
    expect(
      analytics([
        session(0, 60, [
          span(0, 60, RingSleepStage.light),
          span(30, 30, RingSleepStage.awake),
        ]),
        session(30, 60, [span(30, 30, RingSleepStage.deep)]),
      ]).asleepMinutesFor(day),
      30,
    );
  });

  test('missing and wholly conflicting stages are unavailable, not zero', () {
    expect(analytics([]).asleepMinutesFor(day), isNull);
    expect(analytics([session(0, 60, [])]).asleepMinutesFor(day), isNull);
    expect(
      analytics([
        session(0, 60, [
          span(0, 60, RingSleepStage.light),
          span(0, 60, RingSleepStage.awake),
        ]),
      ]).asleepMinutesFor(day),
      isNull,
    );
  });

  test('a fully classified awake window is a recorded zero', () {
    expect(
      analytics([
        session(0, 60, [span(0, 60, RingSleepStage.awake)]),
      ]).asleepMinutesFor(day),
      0,
    );
  });

  test('stages outside their own session cannot fill another session', () {
    expect(
      analytics([
        session(0, 30, [span(0, 60, RingSleepStage.light)]),
        session(60, 90, []),
      ]).asleepMinutesFor(day),
      30,
    );
  });

  test(
    'totals follow local wake date and exclude incomplete future sessions',
    () {
      final subject = analytics([
        session(-60, 60, [span(-60, 120, RingSleepStage.light)]),
        session(22 * 60, 24 * 60, [span(22 * 60, 120, RingSleepStage.light)]),
      ]);
      expect(subject.asleepMinutesFor(day), 120);
      expect(subject.asleepMinutesFor(RingCalendar.shift(day, -1)), isNull);
      expect(subject.asleepMinutesFor(RingCalendar.shift(day, 1)), isNull);
    },
  );
}
