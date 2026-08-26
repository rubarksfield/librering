import 'package:ring_ble/ring_ble.dart';
import 'package:ring_colmi_qring/ring_colmi_qring.dart';
import 'package:ring_core/ring_core.dart';

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

abstract interface class RingPairingClient {
  Stream<RingPairingCandidate> scan({required Duration timeout});

  Future<RingPairingEvidence> connect(RingAdvertisement advertisement);

  Future<void> disconnect();
}

class PhysicalR12PairingClient implements RingPairingClient {
  PhysicalR12PairingClient(this._transport)
    : _driver = ColmiQringDriver(_transport);

  final RingBleTransport _transport;
  final ColmiQringDriver _driver;

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
  Future<void> disconnect() => _driver.disconnect();
}
