import 'dart:math' as math;

import 'package:ring_core/ring_core.dart';

import 'ring_analytics.dart';

enum ProductConfidence { high, moderate, limited, unavailable }

enum ProductDomain { sleep, recovery, movement, heart, oxygen }

class ProductDomainSummary {
  const ProductDomainSummary({
    required this.domain,
    required this.label,
    required this.value,
    required this.status,
    required this.explanation,
    required this.source,
    required this.confidence,
    required this.route,
  });

  final ProductDomain domain;
  final String label;
  final String value;
  final String status;
  final String explanation;
  final String source;
  final ProductConfidence confidence;
  final String route;
}

class DailySignalView {
  const DailySignalView({
    required this.eyebrow,
    required this.headline,
    required this.body,
    required this.actionLabel,
    required this.actionRoute,
    required this.confidence,
  });

  final String eyebrow;
  final String headline;
  final String body;
  final String actionLabel;
  final String actionRoute;
  final ProductConfidence confidence;
}

class RingTrendDay {
  const RingTrendDay({
    required this.day,
    required this.steps,
    required this.hasActivityRecord,
    required this.pulseSamples,
    required this.sleepMinutes,
    required this.oxygenRanges,
  });

  final DateTime day;
  final int steps;
  final bool hasActivityRecord;
  final List<int> pulseSamples;
  final int? sleepMinutes;
  final List<RingOxygenRange> oxygenRanges;

  bool get hasData =>
      hasActivityRecord ||
      pulseSamples.isNotEmpty ||
      sleepMinutes != null ||
      oxygenRanges.isNotEmpty;

  int? get averagePulse => pulseSamples.isEmpty
      ? null
      : (pulseSamples.reduce((left, right) => left + right) /
                pulseSamples.length)
            .round();

  int? get minimumOxygen => oxygenRanges.isEmpty
      ? null
      : oxygenRanges.map((range) => range.minimumPercent).reduce(math.min);

  int? get maximumOxygen => oxygenRanges.isEmpty
      ? null
      : oxygenRanges.map((range) => range.maximumPercent).reduce(math.max);
}

class RingProductView {
  RingProductView._({
    required this.dataset,
    required this.localNow,
    required this.dailySignal,
    required this.domains,
    required this.trendDays,
    required this.latestSleep,
    required this.sleepStageMinutes,
  });

  factory RingProductView.fromDataset(
    RingSyncDataset dataset, {
    DateTime? localNow,
  }) {
    final now = (localNow ?? DateTime.now()).toLocal();
    final sleepAnalytics = RingAnalytics.fromDataset(
      dataset,
      localNow: now,
    ).latestSleep;
    final latestSleep = sleepAnalytics?.session;
    final hasSleepStages = sleepAnalytics?.stages.isNotEmpty ?? false;
    final todayActivity = dataset.activity
        .where(
          (bucket) =>
              !bucket.startedAtUtc.isAfter(now) &&
              _isSameLocalDay(bucket.startedAtUtc, now),
        )
        .toList(growable: false);
    final hasTodayActivity = todayActivity.isNotEmpty;
    final todaySteps = todayActivity.fold<int>(
      0,
      (total, bucket) => total + bucket.steps,
    );
    final todayDistance = todayActivity.fold<int>(
      0,
      (total, bucket) => total + bucket.distanceMeters,
    );
    final todayFirmwareCalories = todayActivity.fold<int>(
      0,
      (total, bucket) => total + bucket.firmwareCalories,
    );
    final recentPulse =
        dataset.heartRate
            .where((value) => !value.measuredAtUtc.isAfter(now))
            .toList(growable: false)
          ..sort(
            (left, right) => left.measuredAtUtc.compareTo(right.measuredAtUtc),
          );
    final latestPulse = recentPulse.isEmpty ? null : recentPulse.last;
    final oxygen =
        dataset.oxygen
            .where((value) => !value.hourStartedAtUtc.isAfter(now))
            .toList(growable: false)
          ..sort(
            (left, right) =>
                left.hourStartedAtUtc.compareTo(right.hourStartedAtUtc),
          );
    final latestOxygen = oxygen.isEmpty ? null : oxygen.last;
    final stageMinutes = <RingSleepStage, int>{
      for (final stage in RingSleepStage.values) stage: 0,
    };
    for (final span in sleepAnalytics?.stages ?? const <RingSleepStageSpan>[]) {
      stageMinutes[span.stage] =
          (stageMinutes[span.stage] ?? 0) + span.durationMinutes;
    }

    final trendDays = _trendDays(dataset, now, count: 90);
    final sleepDuration = latestSleep?.endedAtUtc.difference(
      latestSleep.startedAtUtc,
    );
    final sleepFresh =
        latestSleep != null &&
        now.difference(latestSleep.endedAtUtc.toLocal()) <=
            const Duration(hours: 30);
    final stale =
        now.difference(dataset.lastSyncedAtUtc.toLocal()) >
        const Duration(hours: 36);

    final dailySignal = stale
        ? const DailySignalView(
            eyebrow: 'Refresh recommended',
            headline: 'Your ring history is waiting for a refresh.',
            body: 'Everything already stored remains available. Refresh when the ring is nearby.',
            actionLabel: 'Refresh ring',
            actionRoute: '/today',
            confidence: ProductConfidence.high,
          )
        : sleepFresh
        ? DailySignalView(
            eyebrow: 'Latest sleep window · Firmware estimate',
            headline:
                'A ${durationWords(sleepDuration!)} sleep window was recorded.',
            body: !hasSleepStages
                ? 'The ring retained a sleep interval but no stage runs. Pulse and oxygen remain separate measurements.'
                : 'The ring retained ${sleepAnalytics!.stages.length} sleep-stage runs. They are firmware estimates, not EEG measurements.',
            actionLabel: 'Understand last night',
            actionRoute: '/sleep',
            confidence: !hasSleepStages
                ? ProductConfidence.limited
                : ProductConfidence.moderate,
          )
        : hasTodayActivity
        ? DailySignalView(
            eyebrow: 'Today · Ring estimate',
            headline: '$todaySteps steps are recorded so far.',
            body:
                '${distanceLabel(todayDistance)} and $todayFirmwareCalories firmware kcal are stored locally. Manual activity can add missing context.',
            actionLabel: 'View movement',
            actionRoute: '/movement',
            confidence: ProductConfidence.moderate,
          )
        : const DailySignalView(
            eyebrow: 'Recent history · Stored locally',
            headline: 'Your supported ring records are ready to inspect.',
            body: 'LibreRing keeps measurements available without turning missing inputs into a health score.',
            actionLabel: 'Explore trends',
            actionRoute: '/trends',
            confidence: ProductConfidence.high,
          );

    final domains = <ProductDomainSummary>[
      ProductDomainSummary(
        domain: ProductDomain.sleep,
        label: 'Sleep',
        value: sleepDuration == null ? '—' : durationLabel(sleepDuration),
        status: sleepDuration == null ? 'No retained session' : 'Sleep window',
        explanation: sleepDuration == null
            ? 'The ring has not supplied a supported sleep interval.'
            : !hasSleepStages
            ? 'Firmware interval · no retained stage runs'
            : '${durationWords(Duration(minutes: sleepAnalytics!.asleepMinutes))} classified asleep · ${sleepAnalytics.unclassifiedMinutes} min unclassified',
        source: 'Ring firmware',
        confidence: sleepDuration == null
            ? ProductConfidence.unavailable
            : !hasSleepStages
            ? ProductConfidence.limited
            : ProductConfidence.moderate,
        route: '/sleep',
      ),
      const ProductDomainSummary(
        domain: ProductDomain.recovery,
        label: 'Recovery',
        value: '—',
        status: 'Protected',
        explanation: 'Not calculated: verified R12 inputs are not sufficient for a defensible recovery result.',
        source: 'LibreRing decision',
        confidence: ProductConfidence.unavailable,
        route: '/recovery',
      ),
      ProductDomainSummary(
        domain: ProductDomain.movement,
        label: 'Movement',
        value: hasTodayActivity ? '$todaySteps' : '—',
        status: hasTodayActivity ? 'Steps today' : 'No buckets today',
        explanation: !hasTodayActivity
            ? 'No activity bucket has been retained for today.'
            : '${distanceLabel(todayDistance)} · $todayFirmwareCalories firmware kcal',
        source: 'Ring firmware',
        confidence: hasTodayActivity
            ? ProductConfidence.moderate
            : ProductConfidence.limited,
        route: '/movement',
      ),
      ProductDomainSummary(
        domain: ProductDomain.heart,
        label: 'Heart',
        value: latestPulse == null ? '—' : '${latestPulse.bpm}',
        status: latestPulse == null ? 'No measured sample' : 'bpm latest',
        explanation: latestPulse == null
            ? 'No measured pulse history is stored.'
            : '${recentPulse.length} measured samples · ${clockLabel(latestPulse.measuredAtUtc)} latest',
        source: 'Ring measurement',
        confidence: latestPulse == null
            ? ProductConfidence.unavailable
            : ProductConfidence.high,
        route: '/heart',
      ),
      ProductDomainSummary(
        domain: ProductDomain.oxygen,
        label: 'Oxygen',
        value: latestOxygen == null
            ? '—'
            : '${latestOxygen.minimumPercent}–${latestOxygen.maximumPercent}',
        status: latestOxygen == null ? 'No hourly range' : '% hourly range',
        explanation: latestOxygen == null
            ? 'No supported oxygen history is stored.'
            : '${oxygen.length} retained hourly ranges · not a live reading',
        source: 'Ring history',
        confidence: latestOxygen == null
            ? ProductConfidence.unavailable
            : ProductConfidence.moderate,
        route: '/oxygen',
      ),
    ];

    return RingProductView._(
      dataset: dataset,
      localNow: now,
      dailySignal: dailySignal,
      domains: domains,
      trendDays: trendDays,
      latestSleep: latestSleep,
      sleepStageMinutes: stageMinutes,
    );
  }

  final RingSyncDataset dataset;
  final DateTime localNow;
  final DailySignalView dailySignal;
  final List<ProductDomainSummary> domains;
  final List<RingTrendDay> trendDays;
  final RingSleepSession? latestSleep;
  final Map<RingSleepStage, int> sleepStageMinutes;

  int get validTrendDays => trendDays.where((day) => day.hasData).length;

  ProductDomainSummary domain(ProductDomain domain) =>
      domains.firstWhere((summary) => summary.domain == domain);

  List<RingTrendDay> range(int days) {
    if (days < 1) throw ArgumentError.value(days, 'days', 'Must be positive');
    if (days >= trendDays.length) return trendDays;
    return trendDays.sublist(trendDays.length - days);
  }

  static List<RingTrendDay> _trendDays(
    RingSyncDataset dataset,
    DateTime now, {
    required int count,
  }) {
    final activity = <String, int>{};
    final pulse = <String, List<int>>{};
    final sleep = <String, List<RingSleepSession>>{};
    final oxygen = <String, List<RingOxygenRange>>{};
    for (final bucket in dataset.activity) {
      if (bucket.startedAtUtc.isAfter(now)) continue;
      final key = _dayKey(bucket.startedAtUtc);
      activity[key] = (activity[key] ?? 0) + bucket.steps;
    }
    for (final sample in dataset.heartRate) {
      if (sample.measuredAtUtc.isAfter(now)) continue;
      pulse
          .putIfAbsent(_dayKey(sample.measuredAtUtc), () => <int>[])
          .add(sample.bpm);
    }
    for (final session in dataset.sleep) {
      if (session.endedAtUtc.isAfter(now) ||
          !session.endedAtUtc.isAfter(session.startedAtUtc)) {
        continue;
      }
      sleep
          .putIfAbsent(_dayKey(session.endedAtUtc), () => <RingSleepSession>[])
          .add(session);
    }
    for (final range in dataset.oxygen) {
      if (range.hourStartedAtUtc.isAfter(now)) continue;
      oxygen
          .putIfAbsent(
            _dayKey(range.hourStartedAtUtc),
            () => <RingOxygenRange>[],
          )
          .add(range);
    }
    final today = DateTime(now.year, now.month, now.day);
    return List<RingTrendDay>.generate(count, (index) {
      final day = RingCalendar.shift(today, index + 1 - count);
      final key = _localDayKey(day);
      return RingTrendDay(
        day: day,
        steps: activity[key] ?? 0,
        hasActivityRecord: activity.containsKey(key),
        pulseSamples: List<int>.unmodifiable(pulse[key] ?? const <int>[]),
        sleepMinutes: sleep[key] == null
            ? null
            : _sleepWindowMinutes(sleep[key]!),
        oxygenRanges: List<RingOxygenRange>.unmodifiable(
          oxygen[key] ?? const <RingOxygenRange>[],
        ),
      );
    }, growable: false);
  }

  /// Counts all retained windows ending on a day, without double-counting
  /// overlapping sessions. This is an interval total, not time asleep.
  static int _sleepWindowMinutes(List<RingSleepSession> sessions) {
    final sorted = sessions.toList(growable: false)
      ..sort((left, right) => left.startedAtUtc.compareTo(right.startedAtUtc));
    var start = sorted.first.startedAtUtc;
    var end = sorted.first.endedAtUtc;
    var minutes = 0;
    for (final session in sorted.skip(1)) {
      if (session.startedAtUtc.isAfter(end)) {
        minutes += end.difference(start).inMinutes;
        start = session.startedAtUtc;
        end = session.endedAtUtc;
      } else if (session.endedAtUtc.isAfter(end)) {
        end = session.endedAtUtc;
      }
    }
    return minutes + end.difference(start).inMinutes;
  }

  static bool _isSameLocalDay(DateTime utc, DateTime local) {
    final value = utc.toLocal();
    return value.year == local.year &&
        value.month == local.month &&
        value.day == local.day;
  }

  static String _dayKey(DateTime utc) => _localDayKey(utc.toLocal());

  static String _localDayKey(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';

  static String durationLabel(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }

  static String durationWords(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (minutes == 0) return '$hours hours';
    return '$hours h $minutes min';
  }

  static String distanceLabel(int meters) {
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String clockLabel(DateTime utc) {
    final local = utc.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
