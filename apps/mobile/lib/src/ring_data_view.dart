import 'package:ring_core/ring_core.dart';

import 'ring_analytics.dart';

class RingDashboardView {
  RingDashboardView._({
    required this.metrics,
    required this.pulseTrend,
    required this.latestSleep,
  });

  factory RingDashboardView.fromDataset(
    RingSyncDataset dataset, {
    DateTime? localNow,
  }) {
    final now = (localNow ?? DateTime.now()).toLocal();
    final activity = dataset.activity
        .where((bucket) {
          final local = bucket.startedAtUtc.toLocal();
          return !bucket.startedAtUtc.isAfter(now) &&
              local.year == now.year &&
              local.month == now.month &&
              local.day == now.day;
        })
        .toList(growable: false);
    final hasActivityRecords = activity.isNotEmpty;
    final steps = activity.fold<int>(0, (sum, bucket) => sum + bucket.steps);
    final distance = activity.fold<int>(
      0,
      (sum, bucket) => sum + bucket.distanceMeters,
    );
    final firmwareCalories = activity.fold<int>(
      0,
      (sum, bucket) => sum + bucket.firmwareCalories,
    );
    final heartRate =
        dataset.heartRate
            .where((value) => !value.measuredAtUtc.isAfter(now))
            .toList()
          ..sort(
            (left, right) => left.measuredAtUtc.compareTo(right.measuredAtUtc),
          );
    final oxygen =
        dataset.oxygen
            .where((value) => !value.hourStartedAtUtc.isAfter(now))
            .toList()
          ..sort(
            (left, right) =>
                left.hourStartedAtUtc.compareTo(right.hourStartedAtUtc),
          );
    final latestSleep = RingAnalytics.fromDataset(
      dataset,
      localNow: now,
    ).latestSleep?.session;
    final latestOxygen = oxygen.isEmpty ? null : oxygen.last;

    return RingDashboardView._(
      metrics: <MetricSummary>[
        MetricSummary(
          label: 'Steps',
          value: hasActivityRecords ? '$steps' : '—',
          unit: '',
          context: !hasActivityRecords
              ? 'No activity buckets today'
              : '${activity.length} retained activity buckets',
          origin: DataOrigin.ring,
        ),
        MetricSummary(
          label: 'Distance',
          value: hasActivityRecords ? _distance(distance) : '—',
          unit: '',
          context: !hasActivityRecords
              ? 'No firmware distance today'
              : 'Firmware estimate · Ring history',
          origin: DataOrigin.ring,
        ),
        MetricSummary(
          label: 'Firmware energy',
          value: hasActivityRecords ? '$firmwareCalories' : '—',
          unit: hasActivityRecords ? 'kcal' : '',
          context: !hasActivityRecords
              ? 'No firmware energy today'
              : 'Firmware estimate · Not calorie intake',
          origin: DataOrigin.ring,
        ),
        MetricSummary(
          label: 'Latest pulse',
          value: heartRate.isEmpty ? '—' : '${heartRate.last.bpm}',
          unit: heartRate.isEmpty ? '' : 'bpm',
          context: heartRate.isEmpty
              ? 'No measured pulse sample'
              : 'Measured by ring · ${_timestamp(heartRate.last.measuredAtUtc, now)}',
          origin: DataOrigin.ring,
        ),
        MetricSummary(
          label: 'Sleep window',
          value: latestSleep == null
              ? '—'
              : _duration(
                  latestSleep.endedAtUtc.difference(latestSleep.startedAtUtc),
                ),
          unit: '',
          context: latestSleep == null
              ? 'No firmware sleep session'
              : 'Firmware interval · ${_timestamp(latestSleep.endedAtUtc, now)}',
          origin: DataOrigin.ring,
        ),
        MetricSummary(
          label: 'Oxygen range',
          value: latestOxygen == null
              ? '—'
              : '${latestOxygen.minimumPercent}–${latestOxygen.maximumPercent}',
          unit: latestOxygen == null ? '' : '%',
          context: latestOxygen == null
              ? 'No hourly oxygen range'
              : 'Hourly range · ${_timestamp(latestOxygen.hourStartedAtUtc, now)}',
          origin: DataOrigin.ring,
        ),
      ],
      pulseTrend: heartRate
          .map((sample) => sample.bpm.toDouble())
          .toList(growable: false),
      latestSleep: latestSleep,
    );
  }

  final List<MetricSummary> metrics;
  final List<double> pulseTrend;
  final RingSleepSession? latestSleep;

  int? get averagePulse {
    if (pulseTrend.isEmpty) return null;
    return (pulseTrend.reduce((left, right) => left + right) /
            pulseTrend.length)
        .round();
  }

  static String durationLabel(Duration value) => _duration(value);

  static String clockLabel(DateTime value) => _clock(value);

  static String _distance(int meters) {
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String _duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }

  static String _clock(DateTime utc) {
    final value = utc.toLocal();
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  static String _timestamp(DateTime utc, DateTime now) {
    final local = utc.toLocal();
    return RingCalendar.sameDay(utc, now)
        ? 'Today ${_clock(utc)}'
        : '${local.day}/${local.month}/${local.year} ${_clock(utc)}';
  }
}
