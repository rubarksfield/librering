/// Immutable records at the boundary between acquisition, storage, scoring,
/// and presentation. This package deliberately contains no Flutter, BLE, or
/// scoring implementation.
library;

enum DataOrigin { demo, ring, manual }

enum RingDataKind {
  battery,
  activity,
  heartRate,
  sleep,
  oxygen,
  stressIndex,
  firmwareHrvIndex,
}

enum RingDataAvailability {
  complete,
  noData,
  noReading,
  unavailable,
  partial,
  error,
}

class RingDataSource {
  const RingDataSource({required this.driverId, this.firmwareVersion});

  final String driverId;
  final String? firmwareVersion;
}

class RingActivityBucket {
  const RingActivityBucket({
    required this.startedAtUtc,
    required this.steps,
    required this.distanceMeters,
    required this.firmwareCalories,
    this.origin = DataOrigin.ring,
  });

  final DateTime startedAtUtc;
  final int steps;
  final int distanceMeters;
  final int firmwareCalories;
  final DataOrigin origin;

  String get recordKey => 'activity|${startedAtUtc.toIso8601String()}';
}

class RingHeartRateSample {
  const RingHeartRateSample({
    required this.measuredAtUtc,
    required this.bpm,
    this.origin = DataOrigin.ring,
  });

  final DateTime measuredAtUtc;
  final int bpm;
  final DataOrigin origin;

  String get recordKey => 'heartRate|${measuredAtUtc.toIso8601String()}';
}

enum RingVendorIndexKind { stress, firmwareHrv }

class RingVendorIndexSample {
  const RingVendorIndexSample({
    required this.measuredAtUtc,
    required this.value,
    required this.kind,
    this.origin = DataOrigin.ring,
  });

  final DateTime measuredAtUtc;
  final int value;
  final RingVendorIndexKind kind;
  final DataOrigin origin;

  String get recordKey => '${kind.name}|${measuredAtUtc.toIso8601String()}';
}

class RingOxygenRange {
  const RingOxygenRange({
    required this.hourStartedAtUtc,
    required this.minimumPercent,
    required this.maximumPercent,
    this.origin = DataOrigin.ring,
  });

  final DateTime hourStartedAtUtc;
  final int minimumPercent;
  final int maximumPercent;
  final DataOrigin origin;

  String get recordKey => 'oxygen|${hourStartedAtUtc.toIso8601String()}';
}

enum RingSleepStage { light, deep, rem, awake }

class RingSleepStageSpan {
  const RingSleepStageSpan({
    required this.stage,
    required this.startedAtUtc,
    required this.durationMinutes,
  });

  final RingSleepStage stage;
  final DateTime startedAtUtc;
  final int durationMinutes;
}

class RingSleepSession {
  RingSleepSession({
    required this.startedAtUtc,
    required this.endedAtUtc,
    required Iterable<RingSleepStageSpan> stages,
    this.origin = DataOrigin.ring,
  }) : stages = List<RingSleepStageSpan>.unmodifiable(stages);

  final DateTime startedAtUtc;
  final DateTime endedAtUtc;
  final List<RingSleepStageSpan> stages;
  final DataOrigin origin;

  String get recordKey => 'sleep|${startedAtUtc.toIso8601String()}';
}

class RingSyncDataset {
  RingSyncDataset({
    required this.lastSyncedAtUtc,
    required this.source,
    required Map<RingDataKind, RingDataAvailability> availability,
    Iterable<RingActivityBucket> activity = const <RingActivityBucket>[],
    Iterable<RingHeartRateSample> heartRate = const <RingHeartRateSample>[],
    Iterable<RingVendorIndexSample> vendorIndexes =
        const <RingVendorIndexSample>[],
    Iterable<RingOxygenRange> oxygen = const <RingOxygenRange>[],
    Iterable<RingSleepSession> sleep = const <RingSleepSession>[],
    this.batteryLevel,
    this.charging,
  }) : availability = Map<RingDataKind, RingDataAvailability>.unmodifiable(
         availability,
       ),
       activity = List<RingActivityBucket>.unmodifiable(activity),
       heartRate = List<RingHeartRateSample>.unmodifiable(heartRate),
       vendorIndexes = List<RingVendorIndexSample>.unmodifiable(vendorIndexes),
       oxygen = List<RingOxygenRange>.unmodifiable(oxygen),
       sleep = List<RingSleepSession>.unmodifiable(sleep);

  final DateTime lastSyncedAtUtc;
  final RingDataSource source;
  final Map<RingDataKind, RingDataAvailability> availability;
  final List<RingActivityBucket> activity;
  final List<RingHeartRateSample> heartRate;
  final List<RingVendorIndexSample> vendorIndexes;
  final List<RingOxygenRange> oxygen;
  final List<RingSleepSession> sleep;
  final int? batteryLevel;
  final bool? charging;

  int get recordCount =>
      activity.length +
      heartRate.length +
      vendorIndexes.length +
      oxygen.length +
      sleep.length;
}

enum DeviceCapability {
  battery,
  charging,
  deviceClock,
  heartRateHistory,
  liveHeartRate,
  oxygenHistory,
  liveOxygen,
  firmwareHrvIndex,
  firmwareStressIndex,
  steps,
  distance,
  calories,
  sleep,
  sleepStages,
  displayControls,
  findDevice,
  measurementInterval,
  rawPacketLogging,
}

enum CapabilityConfidence {
  physicallyVerified,
  modelSpecificSource,
  familyCorroborated,
  unavailable,
}

class RingAdvertisement {
  const RingAdvertisement({
    required this.deviceId,
    required this.name,
    this.serviceUuids = const <String>{},
    this.rssi,
  });

  final String deviceId;
  final String name;
  final Set<String> serviceUuids;
  final int? rssi;
}

class RingPeripheral {
  const RingPeripheral({required this.deviceId, required this.name});

  final String deviceId;
  final String name;
}

class DeviceCapabilities {
  DeviceCapabilities(Map<DeviceCapability, CapabilityConfidence> values)
    : values = Map<DeviceCapability, CapabilityConfidence>.unmodifiable(values);

  final Map<DeviceCapability, CapabilityConfidence> values;

  bool supports(DeviceCapability capability) =>
      values[capability] != null &&
      values[capability] != CapabilityConfidence.unavailable;

  CapabilityConfidence confidenceFor(DeviceCapability capability) =>
      values[capability] ?? CapabilityConfidence.unavailable;
}

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
