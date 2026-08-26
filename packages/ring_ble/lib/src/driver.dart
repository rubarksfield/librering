import 'package:ring_core/ring_core.dart';

import 'transport.dart';

class RingConnection {
  RingConnection({
    required this.peripheral,
    required Iterable<BleService> services,
  }) : services = List<BleService>.unmodifiable(services);

  final RingPeripheral peripheral;
  final List<BleService> services;
}

enum ConnectionEventType { connecting, connected, interrupted, disconnected }

class ConnectionEvent {
  const ConnectionEvent(this.type, {this.message});

  final ConnectionEventType type;
  final String? message;
}

enum SyncDomain { battery, activity, heartRate, sleep, oxygen, additional }

class SyncRequest {
  SyncRequest(Iterable<SyncDomain> domains)
    : domains = Set<SyncDomain>.unmodifiable(domains);

  final Set<SyncDomain> domains;
}

class SyncCursor {
  const SyncCursor({required this.value});

  final String value;
}

class SyncResult {
  SyncResult({
    required Set<SyncDomain> completed,
    required Set<SyncDomain> partial,
    required this.recordCount,
    this.nextCursor,
    this.message,
    this.dataset,
  }) : completed = Set<SyncDomain>.unmodifiable(completed),
       partial = Set<SyncDomain>.unmodifiable(partial);

  final Set<SyncDomain> completed;
  final Set<SyncDomain> partial;
  final int recordCount;
  final SyncCursor? nextCursor;
  final String? message;
  final RingSyncDataset? dataset;
}

enum LiveMeasurementType { heartRate, oxygen }

abstract interface class LiveMeasurementSession {
  Stream<double> get values;

  Future<void> stop();
}

sealed class DeviceSetting {
  const DeviceSetting();
}

class ProtocolEvidenceIncompleteException implements Exception {
  const ProtocolEvidenceIncompleteException(this.message);

  final String message;

  @override
  String toString() => 'ProtocolEvidenceIncompleteException: $message';
}

abstract interface class RingDriver {
  String get driverId;

  String get displayName;

  bool matchesAdvertisement(RingAdvertisement advertisement);

  Future<RingConnection> connect(RingPeripheral peripheral);

  Future<DeviceCapabilities> discoverCapabilities(RingConnection connection);

  Stream<ConnectionEvent> observeConnection();

  Future<SyncResult> sync(SyncRequest request, SyncCursor? previousCursor);

  Future<LiveMeasurementSession> startLiveMeasurement(LiveMeasurementType type);

  Future<void> updateSetting(DeviceSetting setting);

  Future<void> disconnect();
}
