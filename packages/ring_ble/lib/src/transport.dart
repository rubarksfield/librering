import 'package:ring_core/ring_core.dart';

enum BleConnectionState { disconnected, connecting, connected, disconnecting }

class BleCharacteristic {
  const BleCharacteristic({
    required this.uuid,
    this.canRead = false,
    this.canWrite = false,
    this.canNotify = false,
  });

  final String uuid;
  final bool canRead;
  final bool canWrite;
  final bool canNotify;
}

class BleService {
  BleService({
    required this.uuid,
    required Iterable<BleCharacteristic> characteristics,
  }) : characteristics = List<BleCharacteristic>.unmodifiable(characteristics);

  final String uuid;
  final List<BleCharacteristic> characteristics;

  BleCharacteristic? characteristic(String characteristicUuid) {
    final normalised = characteristicUuid.toLowerCase();
    for (final value in characteristics) {
      if (value.uuid.toLowerCase() == normalised) return value;
    }
    return null;
  }
}

abstract interface class RingBleTransport {
  Stream<RingAdvertisement> scan({required Duration timeout});

  Stream<BleConnectionState> get connectionStates;

  Future<void> connect(String deviceId, {required Duration timeout});

  Future<List<BleService>> discoverServices();

  Stream<List<int>> subscribe({
    required String serviceUuid,
    required String characteristicUuid,
  });

  Future<List<int>> read({
    required String serviceUuid,
    required String characteristicUuid,
  });

  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
    required bool withResponse,
  });

  Future<void> disconnect();
}
