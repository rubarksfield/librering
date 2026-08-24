/// Immutable records at the boundary between acquisition, storage, scoring,
/// and presentation. This package deliberately contains no Flutter, BLE, or
/// scoring implementation.
library;

enum DataOrigin { demo, ring, manual }

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
