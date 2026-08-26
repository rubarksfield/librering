import 'dart:async';

import 'package:ring_ble/ring_ble.dart';
import 'package:ring_colmi_qring/ring_colmi_qring.dart';
import 'package:ring_core/ring_core.dart';

typedef ProtocolCaptureSink = FutureOr<void> Function(String capture);

class RingPairingCandidate {
  const RingPairingCandidate({
    required this.advertisement,
    required this.exact,
  });

  final RingAdvertisement advertisement;
  final bool exact;
}

class RingPairingEvidence {
  const RingPairingEvidence({
    required this.name,
    required this.capabilities,
    required this.supportsBigData,
  });

  final String name;
  final DeviceCapabilities capabilities;
  final bool supportsBigData;
}

class RingMetadata {
  const RingMetadata({
    required this.batteryLevel,
    required this.charging,
    required this.firmwareVersion,
  });

  final int batteryLevel;
  final bool charging;
  final String? firmwareVersion;
}

class RingTimeSyncResult {
  const RingTimeSyncResult({required this.requestedLocalTime});

  final DateTime requestedLocalTime;
}

class RingApprovedSuiteResult {
  const RingApprovedSuiteResult({
    required this.statuses,
    this.batteryLevel,
    this.charging,
    this.firmwareVersion,
  });

  final Map<String, String> statuses;
  final int? batteryLevel;
  final bool? charging;
  final String? firmwareVersion;
}

abstract interface class RingPairingClient {
  Stream<RingPairingCandidate> scan({required Duration timeout});

  Future<RingPairingEvidence> connect(RingAdvertisement advertisement);

  Future<RingMetadata> captureMetadata();

  Future<RingTimeSyncResult> captureTimeSync();

  Future<RingApprovedSuiteResult> captureApprovedSuite();

  Future<void> disconnect();
}

class PhysicalR12PairingClient implements RingPairingClient {
  PhysicalR12PairingClient(this._transport, {this.captureSink})
    : _driver = ColmiQringDriver(_transport);

  final RingBleTransport _transport;
  final ColmiQringDriver _driver;
  final ProtocolCaptureSink? captureSink;

  @override
  Stream<RingPairingCandidate> scan({required Duration timeout}) => _transport
      .scan(timeout: timeout)
      .where(ColmiQringProfile.isInclusiveCandidate)
      .map(
        (advertisement) => RingPairingCandidate(
          advertisement: advertisement,
          exact: ColmiQringProfile.isR12Advertisement(advertisement),
        ),
      );

  @override
  Future<RingPairingEvidence> connect(RingAdvertisement advertisement) async {
    if (!ColmiQringProfile.isR12Advertisement(advertisement)) {
      throw const UnsupportedFirmwareException(
        'This candidate advertises a QRing-family service but not an exact COLMI R12 name.',
      );
    }
    final connection = await _driver.connect(
      RingPeripheral(
        deviceId: advertisement.deviceId,
        name: advertisement.name,
      ),
    );
    final capabilities = await _driver.discoverCapabilities(connection);
    return RingPairingEvidence(
      name: advertisement.name,
      capabilities: capabilities,
      supportsBigData: connection.services.any(
        (service) =>
            service.uuid.toLowerCase() == ColmiQringProfile.bigDataService,
      ),
    );
  }

  @override
  Future<RingMetadata> captureMetadata() async {
    final capture = await _driver.captureMetadata();
    final sink = captureSink;
    if (sink != null) await sink(capture.toAnonymisedJson());
    return RingMetadata(
      batteryLevel: capture.batteryLevel,
      charging: capture.charging,
      firmwareVersion: capture.firmwareVersion,
    );
  }

  @override
  Future<RingTimeSyncResult> captureTimeSync() async {
    final capture = await _driver.captureTimeSync();
    final sink = captureSink;
    if (sink != null) await sink(capture.toAnonymisedJson());
    return RingTimeSyncResult(requestedLocalTime: capture.requestedLocalTime);
  }

  @override
  Future<RingApprovedSuiteResult> captureApprovedSuite() async {
    final capture = await _driver.captureApprovedSuite();
    final sink = captureSink;
    if (sink != null) await sink(capture.toAnonymisedJson());
    return RingApprovedSuiteResult(
      statuses: capture.statuses,
      batteryLevel: capture.batteryLevel,
      charging: capture.charging,
      firmwareVersion: capture.firmwareVersion,
    );
  }

  @override
  Future<void> disconnect() => _driver.disconnect();
}
