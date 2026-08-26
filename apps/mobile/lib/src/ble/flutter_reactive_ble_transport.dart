import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ring_ble/ring_ble.dart';
import 'package:ring_core/ring_core.dart';

abstract interface class ReactiveBleClient {
  Stream<DiscoveredDevice> scanForDevices({required List<Uuid> withServices});

  Stream<ConnectionStateUpdate> connectToDevice({
    required String id,
    required Duration connectionTimeout,
  });

  Future<List<ReactiveBleDiscoveredService>> discoverServices(String deviceId);

  Stream<List<int>> subscribeToCharacteristic(
    QualifiedCharacteristic characteristic,
  );

  Future<List<int>> readCharacteristic(QualifiedCharacteristic characteristic);

  Future<void> writeCharacteristicWithResponse(
    QualifiedCharacteristic characteristic, {
    required List<int> value,
  });

  Future<void> writeCharacteristicWithoutResponse(
    QualifiedCharacteristic characteristic, {
    required List<int> value,
  });
}

class ReactiveBleDiscoveredCharacteristic {
  const ReactiveBleDiscoveredCharacteristic({
    required this.uuid,
    this.canRead = false,
    required this.canWrite,
    required this.canNotify,
  });

  final String uuid;
  final bool canRead;
  final bool canWrite;
  final bool canNotify;
}

class ReactiveBleDiscoveredService {
  const ReactiveBleDiscoveredService({
    required this.uuid,
    required this.characteristics,
  });

  final String uuid;
  final List<ReactiveBleDiscoveredCharacteristic> characteristics;
}

class FlutterReactiveBleClient implements ReactiveBleClient {
  FlutterReactiveBleClient([FlutterReactiveBle? ble])
    : _ble = ble ?? FlutterReactiveBle();

  final FlutterReactiveBle _ble;

  @override
  Stream<DiscoveredDevice> scanForDevices({required List<Uuid> withServices}) =>
      _ble.scanForDevices(withServices: withServices);

  @override
  Stream<ConnectionStateUpdate> connectToDevice({
    required String id,
    required Duration connectionTimeout,
  }) => _ble.connectToDevice(id: id, connectionTimeout: connectionTimeout);

  @override
  Future<List<ReactiveBleDiscoveredService>> discoverServices(
    String deviceId,
  ) async {
    await _ble.discoverAllServices(deviceId);
    final services = await _ble.getDiscoveredServices(deviceId);
    return services
        .map(
          (service) => ReactiveBleDiscoveredService(
            uuid: service.id.toString(),
            characteristics: service.characteristics
                .map(
                  (characteristic) => ReactiveBleDiscoveredCharacteristic(
                    uuid: characteristic.id.toString(),
                    canRead: characteristic.isReadable,
                    canWrite:
                        characteristic.isWritableWithResponse ||
                        characteristic.isWritableWithoutResponse,
                    canNotify:
                        characteristic.isNotifiable ||
                        characteristic.isIndicatable,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(
    QualifiedCharacteristic characteristic,
  ) => _ble.subscribeToCharacteristic(characteristic);

  @override
  Future<List<int>> readCharacteristic(
    QualifiedCharacteristic characteristic,
  ) => _ble.readCharacteristic(characteristic);

  @override
  Future<void> writeCharacteristicWithResponse(
    QualifiedCharacteristic characteristic, {
    required List<int> value,
  }) => _ble.writeCharacteristicWithResponse(characteristic, value: value);

  @override
  Future<void> writeCharacteristicWithoutResponse(
    QualifiedCharacteristic characteristic, {
    required List<int> value,
  }) => _ble.writeCharacteristicWithoutResponse(characteristic, value: value);
}

class FlutterReactiveBleTransport implements RingBleTransport {
  FlutterReactiveBleTransport({ReactiveBleClient? client})
    : _client = client ?? FlutterReactiveBleClient();

  final ReactiveBleClient _client;
  final StreamController<BleConnectionState> _connectionStates =
      StreamController<BleConnectionState>.broadcast(sync: true);

  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  String? _deviceId;

  @override
  Stream<RingAdvertisement> scan({required Duration timeout}) {
    late final StreamController<RingAdvertisement> controller;
    StreamSubscription<DiscoveredDevice>? subscription;
    Timer? timer;

    Future<void> close() async {
      timer?.cancel();
      await subscription?.cancel();
      if (!controller.isClosed) await controller.close();
    }

    controller = StreamController<RingAdvertisement>(
      onListen: () {
        timer = Timer(timeout, close);
        subscription = _client
            .scanForDevices(withServices: const <Uuid>[])
            .listen(
              (device) => controller.add(
                RingAdvertisement(
                  deviceId: device.id,
                  name: device.name,
                  serviceUuids: device.serviceUuids
                      .map((uuid) => uuid.toString().toLowerCase())
                      .toSet(),
                  rssi: device.rssi,
                ),
              ),
              onError: controller.addError,
              onDone: close,
            );
      },
      onCancel: close,
    );
    return controller.stream;
  }

  @override
  Stream<BleConnectionState> get connectionStates => _connectionStates.stream;

  @override
  Future<void> connect(String deviceId, {required Duration timeout}) async {
    await _connectionSubscription?.cancel();
    _deviceId = deviceId;
    _connectionStates.add(BleConnectionState.connecting);

    final connected = Completer<void>();
    _connectionSubscription = _client
        .connectToDevice(id: deviceId, connectionTimeout: timeout)
        .listen(
          (update) {
            final state = switch (update.connectionState) {
              DeviceConnectionState.connecting => BleConnectionState.connecting,
              DeviceConnectionState.connected => BleConnectionState.connected,
              DeviceConnectionState.disconnecting =>
                BleConnectionState.disconnecting,
              DeviceConnectionState.disconnected =>
                BleConnectionState.disconnected,
            };
            _connectionStates.add(state);
            if (state == BleConnectionState.connected &&
                !connected.isCompleted) {
              connected.complete();
            } else if (state == BleConnectionState.disconnected &&
                !connected.isCompleted) {
              connected.completeError(
                StateError('The ring disconnected before setup completed.'),
              );
            }
          },
          onError: (Object error, StackTrace stack) {
            _connectionStates.add(BleConnectionState.disconnected);
            if (!connected.isCompleted) connected.completeError(error, stack);
          },
          onDone: () {
            if (!connected.isCompleted) {
              connected.completeError(
                StateError('The BLE connection ended before setup completed.'),
              );
            }
          },
        );
    await connected.future;
  }

  @override
  Future<List<BleService>> discoverServices() async {
    final deviceId = _deviceId;
    if (deviceId == null) {
      throw StateError('Service discovery requires a connected ring.');
    }
    final services = await _client.discoverServices(deviceId);
    return services
        .map(
          (service) => BleService(
            uuid: service.uuid,
            characteristics: service.characteristics.map(
              (characteristic) => BleCharacteristic(
                uuid: characteristic.uuid,
                canRead: characteristic.canRead,
                canWrite: characteristic.canWrite,
                canNotify: characteristic.canNotify,
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Stream<List<int>> subscribe({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return _client.subscribeToCharacteristic(
      _qualified(serviceUuid, characteristicUuid),
    );
  }

  @override
  Future<List<int>> read({
    required String serviceUuid,
    required String characteristicUuid,
  }) => _client.readCharacteristic(_qualified(serviceUuid, characteristicUuid));

  @override
  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
    required bool withResponse,
  }) {
    final characteristic = _qualified(serviceUuid, characteristicUuid);
    if (withResponse) {
      return _client.writeCharacteristicWithResponse(
        characteristic,
        value: value,
      );
    }
    return _client.writeCharacteristicWithoutResponse(
      characteristic,
      value: value,
    );
  }

  QualifiedCharacteristic _qualified(
    String serviceUuid,
    String characteristicUuid,
  ) {
    final deviceId = _deviceId;
    if (deviceId == null) {
      throw StateError('A characteristic operation requires a connected ring.');
    }
    return QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
      deviceId: deviceId,
    );
  }

  @override
  Future<void> disconnect() async {
    if (_deviceId == null) return;
    _connectionStates.add(BleConnectionState.disconnecting);
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _deviceId = null;
    _connectionStates.add(BleConnectionState.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _connectionStates.close();
  }
}
