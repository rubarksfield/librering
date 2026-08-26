import 'package:ring_core/ring_core.dart';

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
    final now = localNow ?? DateTime.now();
    final activity = dataset.activity.where((bucket) {
      final local = bucket.startedAtUtc.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    });
    final steps = activity.fold<int>(0, (sum, bucket) => sum + bucket.steps);
    final distance = activity.fold<int>(
      0,
      (sum, bucket) => sum + bucket.distanceMeters,
    );
    final heartRate = dataset.heartRate.toList()
      ..sort(
        (left, right) => left.measuredAtUtc.compareTo(right.measuredAtUtc),
      );
    final sleep = dataset.sleep.toList()
      ..sort((left, right) => left.startedAtUtc.compareTo(right.startedAtUtc));
    final oxygen = dataset.oxygen.toList()
      ..sort(
        (left, right) =>
            left.hourStartedAtUtc.compareTo(right.hourStartedAtUtc),
      );
    final latestSleep = sleep.isEmpty ? null : sleep.last;
    final latestOxygen = oxygen.isEmpty ? null : oxygen.last;

    return RingDashboardView._(
      metrics: <MetricSummary>[
        MetricSummary(
          label: 'Steps',
          value: steps == 0 ? '—' : '$steps',
          unit: '',
          context: steps == 0
              ? 'No activity buckets today'
              : '${_distance(distance)} · Ring history',
          origin: DataOrigin.ring,
        ),
        MetricSummary(
          label: 'Latest pulse',
          value: heartRate.isEmpty ? '—' : '${heartRate.last.bpm}',
          unit: heartRate.isEmpty ? '' : 'bpm',
          context: heartRate.isEmpty
              ? 'No measured pulse sample'
              : 'Measured by ring · ${_clock(heartRate.last.measuredAtUtc)}',
          origin: DataOrigin.ring,
        ),
        MetricSummary(
          label: 'Sleep',
          value: latestSleep == null
              ? '—'
              : _duration(
                  latestSleep.endedAtUtc.difference(latestSleep.startedAtUtc),
                ),
          unit: '',
          context: latestSleep == null
              ? 'No firmware sleep session'
              : 'Firmware-derived · Last session',
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
              : 'Ring history · Hourly range',
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
}
