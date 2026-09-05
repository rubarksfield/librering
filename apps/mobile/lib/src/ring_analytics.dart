import 'dart:math' as math;

import 'package:ring_core/ring_core.dart';

/// Calendar operations must not subtract fixed 24-hour durations across DST.
class RingCalendar {
  RingCalendar._();

  static DateTime day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime shift(DateTime value, int days) =>
      DateTime(value.year, value.month, value.day + days);

  static bool sameDay(DateTime timestamp, DateTime localDay) {
    final local = timestamp.toLocal();
    return local.year == localDay.year &&
        local.month == localDay.month &&
        local.day == localDay.day;
  }

  /// Includes the UTC offset so the repeated autumn hour is counted twice.
  static String hourKey(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.year}-${local.month}-${local.day}-${local.hour}-'
        '${local.timeZoneOffset.inMinutes}';
  }
}

/// Product-facing calculations that preserve the meaning of the decoded R12
/// records. No health score or clinical threshold is created here.
class RingAnalytics {
  RingAnalytics._({
    required this.dataset,
    required this.localNow,
    required this.selectedDay,
  });

  factory RingAnalytics.fromDataset(
    RingSyncDataset dataset, {
    DateTime? localNow,
    DateTime? selectedDay,
  }) {
    final now = (localNow ?? DateTime.now()).toLocal();
    final today = RingCalendar.day(now);
    final requested = RingCalendar.day(selectedDay ?? now);
    return RingAnalytics._(
      dataset: dataset,
      localNow: now,
      selectedDay: requested.isAfter(today) ? today : requested,
    );
  }

  final RingSyncDataset dataset;
  final DateTime localNow;
  final DateTime selectedDay;

  Iterable<DateTime> get _recordTimes => <DateTime>[
    ...dataset.activity.map((value) => value.startedAtUtc),
    ...dataset.heartRate.map((value) => value.measuredAtUtc),
    ...dataset.oxygen.map((value) => value.hourStartedAtUtc),
    ...dataset.vendorIndexes.map((value) => value.measuredAtUtc),
    ...dataset.sleep.map((value) => value.endedAtUtc),
  ].where(_isRecorded);

  DateTime get earliestDay {
    final times = _recordTimes.toList(growable: false)..sort();
    return times.isEmpty
        ? RingCalendar.day(localNow)
        : _day(times.first.toLocal());
  }

  DateTime? get latestRecordedDay {
    final times = _recordTimes.toList(growable: false)..sort();
    return times.isEmpty ? null : _day(times.last.toLocal());
  }

  DateTime periodStart({int days = 1}) {
    _checkDays(days);
    return RingCalendar.shift(selectedDay, 1 - days);
  }

  /// Exclusive calendar boundary; future measurements are filtered separately.
  DateTime get periodEnd => RingCalendar.shift(selectedDay, 1);

  bool _isRecorded(DateTime value) => !value.isAfter(localNow);

  bool _inPeriod(DateTime value, int days) =>
      _isRecorded(value) &&
      !value.isBefore(periodStart(days: days)) &&
      value.isBefore(periodEnd);

  ActivityDay activityFor(DateTime day) {
    final buckets =
        dataset.activity
            .where(
              (value) =>
                  _isRecorded(value.startedAtUtc) &&
                  _sameDay(value.startedAtUtc, day),
            )
            .toList(growable: false)
          ..sort(
            (left, right) => left.startedAtUtc.compareTo(right.startedAtUtc),
          );
    return ActivityDay(
      day: _day(day),
      buckets: buckets,
      steps: buckets.fold(0, (sum, value) => sum + value.steps),
      distanceMeters: buckets.fold(
        0,
        (sum, value) => sum + value.distanceMeters,
      ),
      firmwareCalories: buckets.fold(
        0,
        (sum, value) => sum + value.firmwareCalories,
      ),
    );
  }

  List<ActivityDay> activityHistory({int days = 30}) {
    _checkDays(days);
    return List<ActivityDay>.generate(
      days,
      (index) => activityFor(RingCalendar.shift(selectedDay, index + 1 - days)),
      growable: false,
    );
  }

  ActivityPeriod activityPeriod({int days = 7}) =>
      ActivityPeriod(days: activityHistory(days: days));

  ActivityPeriod previousActivityPeriod({int days = 7}) {
    _checkDays(days);
    return ActivityPeriod(
      days: List<ActivityDay>.generate(
        days,
        (index) =>
            activityFor(RingCalendar.shift(selectedDay, index + 1 - 2 * days)),
        growable: false,
      ),
    );
  }

  SampleSeries pulseFor(DateTime day) {
    final samples =
        dataset.heartRate
            .where(
              (value) =>
                  _isRecorded(value.measuredAtUtc) &&
                  _sameDay(value.measuredAtUtc, day),
            )
            .toList(growable: false)
          ..sort(
            (left, right) => left.measuredAtUtc.compareTo(right.measuredAtUtc),
          );
    return SampleSeries(
      day: _day(day),
      samples: samples
          .map((value) => TimedValue(value.measuredAtUtc, value.bpm))
          .toList(growable: false),
    );
  }

  SampleSeries pulsePeriod({int days = 1}) {
    _checkDays(days);
    final samples =
        dataset.heartRate
            .where((value) => _inPeriod(value.measuredAtUtc, days))
            .map((value) => TimedValue(value.measuredAtUtc, value.bpm))
            .toList(growable: false)
          ..sort((left, right) => left.at.compareTo(right.at));
    return SampleSeries(day: selectedDay, samples: samples);
  }

  OxygenSeries oxygenFor(DateTime day) {
    final ranges =
        dataset.oxygen
            .where(
              (value) =>
                  _isRecorded(value.hourStartedAtUtc) &&
                  _sameDay(value.hourStartedAtUtc, day),
            )
            .toList(growable: false)
          ..sort(
            (left, right) =>
                left.hourStartedAtUtc.compareTo(right.hourStartedAtUtc),
          );
    return OxygenSeries(day: _day(day), ranges: ranges);
  }

  OxygenSeries oxygenPeriod({int days = 1}) {
    _checkDays(days);
    final ranges =
        dataset.oxygen
            .where((value) => _inPeriod(value.hourStartedAtUtc, days))
            .toList(growable: false)
          ..sort(
            (left, right) =>
                left.hourStartedAtUtc.compareTo(right.hourStartedAtUtc),
          );
    return OxygenSeries(day: selectedDay, ranges: ranges);
  }

  SampleSeries vendorIndexFor(DateTime day, RingVendorIndexKind kind) {
    final values =
        dataset.vendorIndexes
            .where(
              (value) =>
                  value.kind == kind &&
                  _isRecorded(value.measuredAtUtc) &&
                  _sameDay(value.measuredAtUtc, day),
            )
            .toList(growable: false)
          ..sort(
            (left, right) => left.measuredAtUtc.compareTo(right.measuredAtUtc),
          );
    return SampleSeries(
      day: _day(day),
      samples: values
          .map((value) => TimedValue(value.measuredAtUtc, value.value))
          .toList(growable: false),
    );
  }

  SampleSeries vendorPeriod(RingVendorIndexKind kind, {int days = 1}) {
    _checkDays(days);
    final samples =
        dataset.vendorIndexes
            .where(
              (value) =>
                  value.kind == kind && _inPeriod(value.measuredAtUtc, days),
            )
            .map((value) => TimedValue(value.measuredAtUtc, value.value))
            .toList(growable: false)
          ..sort((left, right) => left.at.compareTo(right.at));
    return SampleSeries(day: selectedDay, samples: samples);
  }

  List<DailyValue> pulseHistory({int days = 30}) => _sampleHistory(
    days: days,
    values: dataset.heartRate
        .map((value) => TimedValue(value.measuredAtUtc, value.bpm))
        .toList(growable: false),
  );

  List<DailyValue> vendorHistory(RingVendorIndexKind kind, {int days = 30}) =>
      _sampleHistory(
        days: days,
        values: dataset.vendorIndexes
            .where((value) => value.kind == kind)
            .map((value) => TimedValue(value.measuredAtUtc, value.value))
            .toList(growable: false),
      );

  List<DailyValue> _sampleHistory({
    required int days,
    required List<TimedValue> values,
  }) {
    _checkDays(days);
    final grouped = <String, List<int>>{};
    for (final value in values) {
      if (!_inPeriod(value.at, days)) continue;
      grouped
          .putIfAbsent(_key(value.at.toLocal()), () => <int>[])
          .add(value.value);
    }
    return List<DailyValue>.generate(days, (index) {
      final day = RingCalendar.shift(selectedDay, index + 1 - days);
      final dayValues = grouped[_key(day)] ?? const <int>[];
      return DailyValue(
        day: day,
        value: dayValues.isEmpty ? null : _median(dayValues).toDouble(),
        sampleCount: dayValues.length,
      );
    }, growable: false);
  }

  SleepAnalytics? get latestSleep {
    final sessions =
        dataset.sleep
            .where((value) => _isRecorded(value.endedAtUtc))
            .toList(growable: false)
          ..sort((left, right) => left.endedAtUtc.compareTo(right.endedAtUtc));
    return sessions.isEmpty ? null : sleepForSession(sessions.last);
  }

  List<DateTime> get availableSleepDays {
    final days =
        dataset.sleep
            .where((session) => _isRecorded(session.endedAtUtc))
            .map((session) => _day(session.endedAtUtc.toLocal()))
            .toSet()
            .toList(growable: false)
          ..sort((left, right) => right.compareTo(left));
    return days;
  }

  List<SleepAnalytics> sleepOn(DateTime day) {
    final sessions =
        dataset.sleep
            .where(
              (session) =>
                  _isRecorded(session.endedAtUtc) &&
                  _sameDay(session.endedAtUtc, day),
            )
            .toList(growable: false)
          ..sort((left, right) => right.endedAtUtc.compareTo(left.endedAtUtc));
    return sessions.map(sleepForSession).toList(growable: false);
  }

  SleepAnalytics? sleepFor(DateTime day) {
    final sessions = sleepOn(day);
    return sessions.isEmpty ? null : sessions.first;
  }

  /// Classified asleep time across sessions ending on this day. Duplicate
  /// windows are not added twice, and conflicting stages stay unclassified.
  /// A recorded window without stages is unavailable, not zero sleep.
  int? asleepMinutesFor(DateTime day) {
    final sessions = sleepOn(day);
    if (sessions.isEmpty) return null;
    // Keep original evidence until the union is classified. Normalizing each
    // session first would erase conflicts that another session could then fill.
    // Each span remains bounded to its own source window, not the wider union.
    final boundedStages = <RingSleepStageSpan>[];
    for (final value in sessions) {
      final session = value.session;
      for (final span in session.stages) {
        final start = span.startedAtUtc.isBefore(session.startedAtUtc)
            ? session.startedAtUtc
            : span.startedAtUtc;
        final rawEnd = span.startedAtUtc.add(
          Duration(minutes: span.durationMinutes),
        );
        final end = rawEnd.isAfter(session.endedAtUtc)
            ? session.endedAtUtc
            : rawEnd;
        final minutes = end.difference(start).inMinutes;
        if (minutes <= 0) continue;
        boundedStages.add(
          RingSleepStageSpan(
            stage: span.stage,
            startedAtUtc: start,
            durationMinutes: minutes,
          ),
        );
      }
    }
    final combined = SleepAnalytics.fromSession(
      RingSleepSession(
        startedAtUtc: sessions
            .map((value) => value.session.startedAtUtc)
            .reduce((a, b) => a.isBefore(b) ? a : b),
        endedAtUtc: sessions
            .map((value) => value.session.endedAtUtc)
            .reduce((a, b) => a.isAfter(b) ? a : b),
        stages: boundedStages,
        origin: sessions.first.session.origin,
      ),
    );
    return combined.recordedStageMinutes == 0 ? null : combined.asleepMinutes;
  }

  SleepAnalytics sleepForSession(RingSleepSession session) {
    final pulse = dataset.heartRate
        .where(
          (value) =>
              !value.measuredAtUtc.isBefore(session.startedAtUtc) &&
              value.measuredAtUtc.isBefore(session.endedAtUtc) &&
              _isRecorded(value.measuredAtUtc),
        )
        .map((value) => value.bpm)
        .toList(growable: false);
    final oxygen = dataset.oxygen
        .where(
          (value) =>
              !value.hourStartedAtUtc.isBefore(session.startedAtUtc) &&
              !value.hourStartedAtUtc
                  .add(const Duration(hours: 1))
                  .isAfter(session.endedAtUtc) &&
              _isRecorded(value.hourStartedAtUtc),
        )
        .toList(growable: false);
    return SleepAnalytics.fromSession(
      session,
      pulseValues: pulse,
      oxygenRanges: oxygen,
    );
  }

  List<SleepAnalytics> sleepHistory({int count = 7}) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'Must be positive');
    }
    final sessions =
        dataset.sleep
            .where(
              (session) =>
                  _isRecorded(session.endedAtUtc) &&
                  session.endedAtUtc.isBefore(periodEnd),
            )
            .toList(growable: false)
          ..sort((left, right) => right.endedAtUtc.compareTo(left.endedAtUtc));
    return sessions.take(count).map(sleepForSession).toList(growable: false);
  }

  static bool _sameDay(DateTime utc, DateTime day) {
    final local = utc.toLocal();
    return local.year == day.year &&
        local.month == day.month &&
        local.day == day.day;
  }

  static DateTime _day(DateTime value) => RingCalendar.day(value);

  static void _checkDays(int days) {
    if (days < 1) throw ArgumentError.value(days, 'days', 'Must be positive');
  }

  static String _key(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class ActivityDay {
  const ActivityDay({
    required this.day,
    required this.buckets,
    required this.steps,
    required this.distanceMeters,
    required this.firmwareCalories,
  });

  final DateTime day;
  final List<RingActivityBucket> buckets;
  final int steps;
  final int distanceMeters;
  final int firmwareCalories;

  bool get hasRecords => buckets.isNotEmpty;

  int get coveredHours => buckets
      .map((value) => RingCalendar.hourKey(value.startedAtUtc))
      .toSet()
      .length;

  List<HourlyActivityValue> get hourly {
    final grouped = <String, List<RingActivityBucket>>{};
    for (final bucket in buckets) {
      grouped
          .putIfAbsent(
            RingCalendar.hourKey(bucket.startedAtUtc),
            () => <RingActivityBucket>[],
          )
          .add(bucket);
    }
    final result = <HourlyActivityValue>[];
    final end = RingCalendar.shift(day, 1);
    for (
      var start = RingCalendar.day(day);
      start.isBefore(end);
      start = start.add(const Duration(hours: 1))
    ) {
      final values =
          grouped[RingCalendar.hourKey(start)] ?? const <RingActivityBucket>[];
      result.add(
        HourlyActivityValue(
          hour: start.hour,
          startedAt: start,
          steps: values.fold(0, (sum, value) => sum + value.steps),
          distanceMeters: values.fold(
            0,
            (sum, value) => sum + value.distanceMeters,
          ),
          firmwareCalories: values.fold(
            0,
            (sum, value) => sum + value.firmwareCalories,
          ),
          hasRecord: values.isNotEmpty,
        ),
      );
    }
    return List<HourlyActivityValue>.unmodifiable(result);
  }
}

/// Totals are retained records, not extrapolated full-day activity.
class ActivityPeriod {
  ActivityPeriod({required List<ActivityDay> days})
    : days = List<ActivityDay>.unmodifiable(days);

  final List<ActivityDay> days;
  int get recordedDays => days.where((value) => value.hasRecords).length;
  int get missingDays => days.length - recordedDays;
  bool get hasRecords => recordedDays > 0;
  int get steps => days.fold(0, (sum, value) => sum + value.steps);
  int get distanceMeters =>
      days.fold(0, (sum, value) => sum + value.distanceMeters);
  int get firmwareCalories =>
      days.fold(0, (sum, value) => sum + value.firmwareCalories);
  int? get averageRecordedDaySteps =>
      hasRecords ? (steps / recordedDays).round() : null;
  ActivityDay? get mostStepsDay {
    final recorded = days
        .where((value) => value.hasRecords)
        .toList(growable: false);
    if (recorded.isEmpty) return null;
    return recorded.reduce(
      (best, next) => next.steps > best.steps ? next : best,
    );
  }
}

class HourlyActivityValue {
  const HourlyActivityValue({
    required this.hour,
    required this.steps,
    required this.distanceMeters,
    required this.firmwareCalories,
    required this.hasRecord,
    required this.startedAt,
  });

  final int hour;
  final int steps;
  final int distanceMeters;
  final int firmwareCalories;
  final bool hasRecord;
  final DateTime startedAt;
}

class TimedValue {
  const TimedValue(this.at, this.value);

  final DateTime at;
  final int value;
}

class SampleSeries {
  const SampleSeries({required this.day, required this.samples});

  final DateTime day;
  final List<TimedValue> samples;

  List<int> get values =>
      samples.map((value) => value.value).toList(growable: false);
  int? get latest => samples.isEmpty ? null : samples.last.value;
  int? get minimum => samples.isEmpty ? null : values.reduce(math.min);
  int? get maximum => samples.isEmpty ? null : values.reduce(math.max);
  int? get median => samples.isEmpty ? null : _median(values);
  int? get mean => samples.isEmpty
      ? null
      : (values.reduce((left, right) => left + right) / samples.length).round();
  int get coveredHours =>
      samples.map((value) => RingCalendar.hourKey(value.at)).toSet().length;
}

class DailyValue {
  const DailyValue({
    required this.day,
    required this.value,
    required this.sampleCount,
  });

  final DateTime day;
  final double? value;
  final int sampleCount;
}

class OxygenSeries {
  const OxygenSeries({required this.day, required this.ranges});

  final DateTime day;
  final List<RingOxygenRange> ranges;

  int? get minimum => ranges.isEmpty
      ? null
      : ranges.map((value) => value.minimumPercent).reduce(math.min);
  int? get maximum => ranges.isEmpty
      ? null
      : ranges.map((value) => value.maximumPercent).reduce(math.max);
  int get coveredHours => ranges
      .map((value) => RingCalendar.hourKey(value.hourStartedAtUtc))
      .toSet()
      .length;
  int get narrowRangeCount => ranges
      .where((value) => value.maximumPercent - value.minimumPercent <= 2)
      .length;
}

class SleepAnalytics {
  SleepAnalytics._({
    required this.session,
    required this.stageMinutes,
    required this.recordedStageMinutes,
    required this.awakeSpans,
    required this.longestSleepRunMinutes,
    required this.sleepPulse,
    required this.oxygenRanges,
    required this.stages,
  });

  factory SleepAnalytics.fromSession(
    RingSleepSession session, {
    List<int> pulseValues = const <int>[],
    List<RingOxygenRange> oxygenRanges = const <RingOxygenRange>[],
  }) {
    final stages = <RingSleepStage, int>{
      for (final stage in RingSleepStage.values) stage: 0,
    };
    var awakeSpans = 0;
    var currentRun = 0;
    var longestRun = 0;
    DateTime? previousEnd;
    final ordered = _normalisedStages(session);
    for (final span in ordered) {
      if (previousEnd != null && span.startedAtUtc.isAfter(previousEnd)) {
        longestRun = math.max(longestRun, currentRun);
        currentRun = 0;
      }
      stages[span.stage] = (stages[span.stage] ?? 0) + span.durationMinutes;
      if (span.stage == RingSleepStage.awake) {
        awakeSpans += 1;
        longestRun = math.max(longestRun, currentRun);
        currentRun = 0;
      } else {
        currentRun += span.durationMinutes;
      }
      previousEnd = span.startedAtUtc.add(
        Duration(minutes: span.durationMinutes),
      );
    }
    longestRun = math.max(longestRun, currentRun);
    return SleepAnalytics._(
      session: session,
      stageMinutes: Map<RingSleepStage, int>.unmodifiable(stages),
      recordedStageMinutes: stages.values.fold(0, (sum, value) => sum + value),
      awakeSpans: awakeSpans,
      longestSleepRunMinutes: longestRun,
      sleepPulse: List<int>.unmodifiable(pulseValues),
      oxygenRanges: List<RingOxygenRange>.unmodifiable(oxygenRanges),
      stages: List<RingSleepStageSpan>.unmodifiable(ordered),
    );
  }

  final RingSleepSession session;
  final Map<RingSleepStage, int> stageMinutes;
  final int recordedStageMinutes;
  final int awakeSpans;
  final int longestSleepRunMinutes;
  final List<int> sleepPulse;
  final List<RingOxygenRange> oxygenRanges;

  /// Bounded, ordered stage spans; conflicting overlap remains unclassified.
  final List<RingSleepStageSpan> stages;

  int get intervalMinutes => math.max(
    0,
    session.endedAtUtc.difference(session.startedAtUtc).inMinutes,
  );
  int get asleepStageMinutes =>
      recordedStageMinutes - (stageMinutes[RingSleepStage.awake] ?? 0);
  int get asleepMinutes => asleepStageMinutes;
  int get unclassifiedMinutes =>
      math.max(0, intervalMinutes - recordedStageMinutes);
  int? get sleepPulseMedian => sleepPulse.isEmpty ? null : _median(sleepPulse);
  int? get sleepPulseMinimum =>
      sleepPulse.isEmpty ? null : sleepPulse.reduce(math.min);
  int? get oxygenMinimum => oxygenRanges.isEmpty
      ? null
      : oxygenRanges.map((value) => value.minimumPercent).reduce(math.min);
  int? get oxygenMaximum => oxygenRanges.isEmpty
      ? null
      : oxygenRanges.map((value) => value.maximumPercent).reduce(math.max);

  int percentFor(RingSleepStage stage) {
    if (intervalMinutes == 0) return 0;
    return (((stageMinutes[stage] ?? 0) / intervalMinutes) * 100).round();
  }
}

List<RingSleepStageSpan> _normalisedStages(RingSleepSession session) {
  if (!session.endedAtUtc.isAfter(session.startedAtUtc)) return const [];
  final spans = session.stages
      .where(
        (span) =>
            span.durationMinutes > 0 &&
            span.startedAtUtc.isBefore(session.endedAtUtc) &&
            span.startedAtUtc
                .add(Duration(minutes: span.durationMinutes))
                .isAfter(session.startedAtUtc),
      )
      .toList(growable: false);
  final boundaries = <DateTime>{session.startedAtUtc, session.endedAtUtc};
  for (final span in spans) {
    final end = span.startedAtUtc.add(Duration(minutes: span.durationMinutes));
    boundaries.add(
      span.startedAtUtc.isBefore(session.startedAtUtc)
          ? session.startedAtUtc
          : span.startedAtUtc,
    );
    boundaries.add(end.isAfter(session.endedAtUtc) ? session.endedAtUtc : end);
  }
  final points = boundaries.toList(growable: false)..sort();
  final result = <RingSleepStageSpan>[];
  for (var index = 0; index < points.length - 1; index++) {
    final start = points[index];
    final end = points[index + 1];
    final kinds = spans
        .where(
          (span) =>
              !span.startedAtUtc.isAfter(start) &&
              !span.startedAtUtc
                  .add(Duration(minutes: span.durationMinutes))
                  .isBefore(end),
        )
        .map((span) => span.stage)
        .toSet();
    final minutes = end.difference(start).inMinutes;
    if (kinds.length != 1 || minutes <= 0) continue;
    final kind = kinds.single;
    if (result.isNotEmpty &&
        result.last.stage == kind &&
        result.last.startedAtUtc.add(
              Duration(minutes: result.last.durationMinutes),
            ) ==
            start) {
      final previous = result.removeLast();
      result.add(
        RingSleepStageSpan(
          stage: kind,
          startedAtUtc: previous.startedAtUtc,
          durationMinutes: previous.durationMinutes + minutes,
        ),
      );
    } else {
      result.add(
        RingSleepStageSpan(
          stage: kind,
          startedAtUtc: start,
          durationMinutes: minutes,
        ),
      );
    }
  }
  return result;
}

int _median(List<int> source) {
  final values = source.toList(growable: false)..sort();
  final middle = values.length ~/ 2;
  if (values.length.isOdd) return values[middle];
  return ((values[middle - 1] + values[middle]) / 2).round();
}
