/// Immutable records at the boundary between acquisition, storage, scoring,
/// and presentation. This package deliberately contains no Flutter, BLE, or
/// scoring implementation.
library;

enum DataOrigin { demo, ring, manual }

class MetricSummary {
  const MetricSummary({
    required this.label,
    required this.value,
    required this.unit,
    required this.context,
    required this.origin,
  });

  final String label;
  final String value;
  final String unit;
  final String context;
  final DataOrigin origin;
}

class DailySnapshot {
  const DailySnapshot({
    required this.recoveryScore,
    required this.recoveryLabel,
    required this.recoverySummary,
    required this.metrics,
    required this.recoveryHistory,
    required this.hrvTrend,
    required this.origin,
  });

  final int recoveryScore;
  final String recoveryLabel;
  final String recoverySummary;
  final List<MetricSummary> metrics;
  final List<int> recoveryHistory;
  final List<double> hrvTrend;
  final DataOrigin origin;
}

class SwimEntry {
  const SwimEntry({
    required this.durationMinutes,
    required this.poolLength,
    required this.effort,
    required this.origin,
  });

  final int durationMinutes;
  final String poolLength;
  final String effort;
  final DataOrigin origin;
}
