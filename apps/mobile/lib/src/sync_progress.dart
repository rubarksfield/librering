/// Sync feedback describes work actually reached, never an estimated percentage.
enum RingSyncStage {
  finding,
  connecting,
  metadata,
  battery,
  activity,
  heartRate,
  sleep,
  oxygen,
  stress,
  hrv,
  normalising,
  saving,
  finishing,
  completed,
  partial,
  failed,
}

class RingSyncProgress {
  const RingSyncProgress({
    required this.stage,
    required this.startedAtUtc,
    this.elapsed = Duration.zero,
    this.sinceLastProgress = Duration.zero,
    this.completedUnits,
    this.totalUnits,
  });

  final RingSyncStage stage;
  final DateTime startedAtUtc;
  final Duration elapsed;
  final Duration sinceLastProgress;

  /// Day requests checked, including days with no reading or a read error.
  /// These are not counts of successfully imported records.
  final int? completedUnits;
  final int? totalUnits;

  bool get isTerminal => switch (stage) {
    RingSyncStage.completed ||
    RingSyncStage.partial ||
    RingSyncStage.failed => true,
    _ => false,
  };

  bool get isStalled =>
      !isTerminal && sinceLastProgress >= const Duration(seconds: 30);

  RingSyncProgress withTiming({
    required Duration elapsed,
    required Duration sinceLastProgress,
  }) => RingSyncProgress(
    stage: stage,
    startedAtUtc: startedAtUtc,
    elapsed: elapsed,
    sinceLastProgress: sinceLastProgress,
    completedUnits: completedUnits,
    totalUnits: totalUnits,
  );
}
