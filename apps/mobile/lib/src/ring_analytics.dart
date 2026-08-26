import 'dart:math' as math;

import 'package:ring_core/ring_core.dart';

/// Product-facing calculations that preserve the meaning of the decoded R12
/// records. No health score or clinical threshold is created here.
class RingAnalytics {
  RingAnalytics._({required this.dataset, required this.localNow});

  factory RingAnalytics.fromDataset(
    RingSyncDataset dataset, {
    DateTime? localNow,
  }) => RingAnalytics._(dataset: dataset, localNow: localNow ?? DateTime.now());

  final RingSyncDataset dataset;
  final DateTime localNow;

  DateTime get selectedDay {
    final latest = <DateTime>[
      ...dataset.activity.map((value) => value.startedAtUtc),
      ...dataset.heartRate.map((value) => value.measuredAtUtc),
      ...dataset.oxygen.map((value) => value.hourStartedAtUtc),
      ...dataset.vendorIndexes.map((value) => value.measuredAtUtc),
    ];
    if (latest.isEmpty) return _day(localNow);
    latest.sort();
    final candidate = _day(latest.last.toLocal());
    final today = _day(localNow);
    return candidate.isAfter(today) ? today : candidate;
  }

  ActivityDay activityFor(DateTime day) {
    final buckets =
        dataset.activity
            .where((value) => _sameDay(value.startedAtUtc, day))
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

  List<ActivityDay> activityHistory({int days = 30}) =>
      List<ActivityDay>.generate(
        days,
        (index) =>
            activityFor(selectedDay.subtract(Duration(days: days - index - 1))),
        growable: false,
      );

  SampleSeries pulseFor(DateTime day) {
    final samples =
        dataset.heartRate
            .where((value) => _sameDay(value.measuredAtUtc, day))
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

  OxygenSeries oxygenFor(DateTime day) {
    final ranges =
        dataset.oxygen
            .where((value) => _sameDay(value.hourStartedAtUtc, day))
            .toList(growable: false)
          ..sort(
            (left, right) =>
                left.hourStartedAtUtc.compareTo(right.hourStartedAtUtc),
          );
    return OxygenSeries(day: _day(day), ranges: ranges);
  }

  SampleSeries vendorIndexFor(DateTime day, RingVendorIndexKind kind) {
    final values =
        dataset.vendorIndexes
            .where(
              (value) =>
                  value.kind == kind && _sameDay(value.measuredAtUtc, day),
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
    final grouped = <String, List<int>>{};
    for (final value in values) {
      grouped
          .putIfAbsent(_key(value.at.toLocal()), () => <int>[])
          .add(value.value);
    }
    return List<DailyValue>.generate(days, (index) {
      final day = selectedDay.subtract(Duration(days: days - index - 1));
      final dayValues = grouped[_key(day)] ?? const <int>[];
      return DailyValue(
        day: day,
        value: dayValues.isEmpty ? null : _median(dayValues).toDouble(),
        sampleCount: dayValues.length,
      );
    }, growable: false);
  }

  SleepAnalytics? get latestSleep {
    if (dataset.sleep.isEmpty) return null;
    final sessions = dataset.sleep.toList(growable: false)
      ..sort((left, right) => left.endedAtUtc.compareTo(right.endedAtUtc));
    final session = sessions.last;
    final pulse = dataset.heartRate
        .where(
          (value) =>
              !value.measuredAtUtc.isBefore(session.startedAtUtc) &&
              !value.measuredAtUtc.isAfter(session.endedAtUtc),
        )
        .map((value) => value.bpm)
        .toList(growable: false);
    final oxygen = dataset.oxygen
        .where(
          (value) =>
              !value.hourStartedAtUtc.isBefore(session.startedAtUtc) &&
              !value.hourStartedAtUtc.isAfter(session.endedAtUtc),
        )
        .toList(growable: false);
    return SleepAnalytics.fromSession(
      session,
      pulseValues: pulse,
      oxygenRanges: oxygen,
    );
  }

  List<SleepAnalytics> sleepHistory({int count = 7}) {
    final sessions = dataset.sleep.toList(growable: false)
      ..sort((left, right) => right.endedAtUtc.compareTo(left.endedAtUtc));
    return sessions
        .take(count)
        .map(SleepAnalytics.fromSession)
        .toList(growable: false);
  }

  static bool _sameDay(DateTime utc, DateTime day) {
    final local = utc.toLocal();
    return local.year == day.year &&
        local.month == day.month &&
        local.day == day.day;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

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

  int get coveredHours =>
      buckets.map((value) => value.startedAtUtc.toLocal().hour).toSet().length;

  List<HourlyActivityValue> get hourly {
    final grouped = <int, List<RingActivityBucket>>{};
    for (final bucket in buckets) {
      grouped
          .putIfAbsent(
            bucket.startedAtUtc.toLocal().hour,
            () => <RingActivityBucket>[],
          )
          .add(bucket);
    }
    return List<HourlyActivityValue>.generate(24, (hour) {
      final values = grouped[hour] ?? const <RingActivityBucket>[];
      return HourlyActivityValue(
        hour: hour,
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
      );
    }, growable: false);
  }
}

class HourlyActivityValue {
  const HourlyActivityValue({
    required this.hour,
    required this.steps,
    required this.distanceMeters,
    required this.firmwareCalories,
    required this.hasRecord,
  });

  final int hour;
  final int steps;
  final int distanceMeters;
  final int firmwareCalories;
  final bool hasRecord;
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
      samples.map((value) => value.at.toLocal().hour).toSet().length;
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
      .map((value) => value.hourStartedAtUtc.toLocal().hour)
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
    final ordered = session.stages.toList(growable: false)
      ..sort((left, right) => left.startedAtUtc.compareTo(right.startedAtUtc));
    for (final span in ordered) {
      if (previousEnd != null &&
          span.startedAtUtc.difference(previousEnd).inMinutes > 1) {
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
    );
  }

  final RingSleepSession session;
  final Map<RingSleepStage, int> stageMinutes;
  final int recordedStageMinutes;
  final int awakeSpans;
  final int longestSleepRunMinutes;
  final List<int> sleepPulse;
  final List<RingOxygenRange> oxygenRanges;

  int get intervalMinutes =>
      session.endedAtUtc.difference(session.startedAtUtc).inMinutes;
  int get asleepStageMinutes =>
      recordedStageMinutes - (stageMinutes[RingSleepStage.awake] ?? 0);
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
    if (recordedStageMinutes == 0) return 0;
    return (((stageMinutes[stage] ?? 0) / recordedStageMinutes) * 100).round();
  }
}

int _median(List<int> source) {
  final values = source.toList(growable: false)..sort();
  final middle = values.length ~/ 2;
  if (values.length.isOdd) return values[middle];
  return ((values[middle - 1] + values[middle]) / 2).round();
}
