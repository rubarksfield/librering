import 'dart:async';

import 'package:ring_ble/ring_ble.dart';
import 'package:ring_core/ring_core.dart';

import 'profile.dart';

class UnsupportedFirmwareException implements Exception {
  const UnsupportedFirmwareException(this.message);

  final String message;

  @override
  String toString() => 'UnsupportedFirmwareException: $message';
}

class ColmiQringDriver implements RingDriver {
  ColmiQringDriver(this.transport);

  final RingBleTransport transport;
  StreamSubscription<List<int>>? _notificationSubscription;

  @override
  String get driverId => 'colmi-qring-v1';

  @override
  String get displayName => 'COLMI QRing family';

  @override
  bool matchesAdvertisement(RingAdvertisement advertisement) =>
      ColmiQringProfile.isR12Advertisement(advertisement);

  @override
  Future<RingConnection> connect(RingPeripheral peripheral) async {
    await transport.connect(
      peripheral.deviceId,
      timeout: const Duration(seconds: 12),
    );
    try {
      final services = await transport.discoverServices();
      final validation = ColmiQringProfile.validateServices(services);
      if (!validation.isSupported) {
        throw UnsupportedFirmwareException(validation.reason!);
      }
      await _notificationSubscription?.cancel();
      _notificationSubscription = transport
          .subscribe(
            serviceUuid: ColmiQringProfile.commandService,
            characteristicUuid: ColmiQringProfile.commandNotify,
          )
          .listen(
            (_) {},
            onError: (Object error) => unawaited(transport.disconnect()),
          );
      return RingConnection(peripheral: peripheral, services: services);
    } catch (_) {
      await _notificationSubscription?.cancel();
      _notificationSubscription = null;
      await transport.disconnect();
      rethrow;
    }
  }

  @override
  Future<DeviceCapabilities> discoverCapabilities(
    RingConnection connection,
  ) async {
    final validation = ColmiQringProfile.validateServices(connection.services);
    if (!validation.isSupported) {
      throw UnsupportedFirmwareException(validation.reason!);
    }
    final confidence = CapabilityConfidence.familyCorroborated;
    return DeviceCapabilities(<DeviceCapability, CapabilityConfidence>{
      DeviceCapability.battery: confidence,
      DeviceCapability.charging: confidence,
      DeviceCapability.deviceClock: confidence,
      DeviceCapability.liveHeartRate: confidence,
      DeviceCapability.liveOxygen: confidence,
      DeviceCapability.steps: confidence,
      DeviceCapability.distance: confidence,
      DeviceCapability.calories: confidence,
      DeviceCapability.displayControls: confidence,
      if (validation
          .supportsBigData) ...<DeviceCapability, CapabilityConfidence>{
        DeviceCapability.heartRateHistory: confidence,
        DeviceCapability.oxygenHistory: confidence,
        DeviceCapability.firmwareHrvIndex: confidence,
        DeviceCapability.firmwareStressIndex: confidence,
        DeviceCapability.sleep: confidence,
        DeviceCapability.sleepStages: confidence,
      },
    });
  }

  @override
  Stream<ConnectionEvent> observeConnection() => transport.connectionStates.map(
    (state) => switch (state) {
      BleConnectionState.connecting => const ConnectionEvent(
        ConnectionEventType.connecting,
      ),
      BleConnectionState.connected => const ConnectionEvent(
        ConnectionEventType.connected,
      ),
      BleConnectionState.disconnecting => const ConnectionEvent(
        ConnectionEventType.interrupted,
        message: 'Connection is closing.',
      ),
      BleConnectionState.disconnected => const ConnectionEvent(
        ConnectionEventType.disconnected,
      ),
    },
  );

  @override
  Future<SyncResult> sync(SyncRequest request, SyncCursor? previousCursor) {
    return Future<SyncResult>.error(
      const ProtocolEvidenceIncompleteException(
        'Exact R12 history request payloads and end sentinels require a physical fixture.',
      ),
    );
  }

  @override
  Future<LiveMeasurementSession> startLiveMeasurement(
    LiveMeasurementType type,
  ) {
    return Future<LiveMeasurementSession>.error(
      const ProtocolEvidenceIncompleteException(
        'Live-measurement payloads are not enabled without an R12 fixture.',
      ),
    );
  }

  @override
  Future<void> updateSetting(DeviceSetting setting) {
    return Future<void>.error(
      const ProtocolEvidenceIncompleteException(
        'Device settings are not enabled without an R12 fixture.',
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    try {
      await _notificationSubscription?.cancel();
    } finally {
      _notificationSubscription = null;
      await transport.disconnect();
    }
  }
}
