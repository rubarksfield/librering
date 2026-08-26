import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/ble/flutter_reactive_ble_transport.dart';
import 'package:ring_ble/ring_ble.dart';

void main() {
  test('scan maps advertisements and stops at the requested bound', () async {
    final client = _FakeReactiveBleClient();
    final transport = FlutterReactiveBleTransport(client: client);

    final results = transport
        .scan(timeout: const Duration(milliseconds: 20))
        .toList();
    await Future<void>.delayed(Duration.zero);
    client.scanController.add(
      DiscoveredDevice(
        id: 'device-1',
        name: 'COLMI R12_TEST',
        serviceData: const <Uuid, Uint8List>{},
        manufacturerData: Uint8List(0),
        rssi: -42,
        serviceUuids: <Uuid>[
          Uuid.parse('6e40fff0-b5a3-f393-e0a9-e50e24dcca9e'),
        ],
      ),
    );

    final advertisements = await results;
    expect(advertisements, hasLength(1));
    expect(advertisements.single.name, 'COLMI R12_TEST');
    expect(advertisements.single.rssi, -42);
    expect(
      advertisements.single.serviceUuids,
      contains('6e40fff0-b5a3-f393-e0a9-e50e24dcca9e'),
    );
    await transport.dispose();
  });

  test('scan includes an already-connected iOS peripheral once', () async {
    final client = _FakeReactiveBleClient();
    client.connected = <DiscoveredDevice>[
      DiscoveredDevice(
        id: 'connected-device',
        name: 'COLMI R12_CONNECTED',
        serviceData: const <Uuid, Uint8List>{},
        manufacturerData: Uint8List(0),
        rssi: 0,
        serviceUuids: <Uuid>[
          Uuid.parse('6e40fff0-b5a3-f393-e0a9-e50e24dcca9e'),
        ],
      ),
    ];
    final transport = FlutterReactiveBleTransport(client: client);

    final results = transport
        .scan(timeout: const Duration(milliseconds: 20))
        .toList();
    await Future<void>.delayed(Duration.zero);
    client.scanController.add(client.connected.single);

    final advertisements = await results;
    expect(advertisements, hasLength(1));
    expect(advertisements.single.name, 'COLMI R12_CONNECTED');
    expect(advertisements.single.rssi, isNull);
    expect(client.connectedServiceFilter, <Uuid>[
      Uuid.parse('6e40fff0-b5a3-f393-e0a9-e50e24dcca9e'),
    ]);
    await transport.dispose();
  });

  test(
    'connect and discovery map plugin state without issuing writes',
    () async {
      final client = _FakeReactiveBleClient();
      final transport = FlutterReactiveBleTransport(client: client);
      final states = <BleConnectionState>[];
      final stateSubscription = transport.connectionStates.listen(states.add);

      final connection = transport.connect(
        'device-1',
        timeout: const Duration(seconds: 1),
      );
      await Future<void>.delayed(Duration.zero);
      client.connectionController.add(
        const ConnectionStateUpdate(
          deviceId: 'device-1',
          connectionState: DeviceConnectionState.connected,
          failure: null,
        ),
      );
      await connection;

      client.services = const <ReactiveBleDiscoveredService>[
        ReactiveBleDiscoveredService(
          uuid: '6e40fff0-b5a3-f393-e0a9-e50e24dcca9e',
          characteristics: <ReactiveBleDiscoveredCharacteristic>[
            ReactiveBleDiscoveredCharacteristic(
              uuid: '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
              canWrite: true,
              canNotify: false,
            ),
            ReactiveBleDiscoveredCharacteristic(
              uuid: '6e400003-b5a3-f393-e0a9-e50e24dcca9e',
              canWrite: false,
              canNotify: true,
            ),
          ],
        ),
      ];
      final services = await transport.discoverServices();

      expect(
        states,
        containsAllInOrder(<BleConnectionState>[
          BleConnectionState.connecting,
          BleConnectionState.connected,
        ]),
      );
      expect(services.single.characteristics.first.canWrite, isTrue);
      expect(services.single.characteristics.last.canNotify, isTrue);
      expect(client.writes, isEmpty);

      await transport.disconnect();
      expect(states.last, BleConnectionState.disconnected);
      await stateSubscription.cancel();
      await transport.dispose();
    },
  );
}

class _FakeReactiveBleClient implements ReactiveBleClient {
  final StreamController<DiscoveredDevice> scanController =
      StreamController<DiscoveredDevice>();
  final StreamController<ConnectionStateUpdate> connectionController =
      StreamController<ConnectionStateUpdate>();
  final StreamController<List<int>> notificationController =
      StreamController<List<int>>();

  List<ReactiveBleDiscoveredService> services =
      <ReactiveBleDiscoveredService>[];
  List<DiscoveredDevice> connected = <DiscoveredDevice>[];
  List<Uuid>? connectedServiceFilter;
  final List<List<int>> writes = <List<int>>[];
  List<int> readValue = const <int>[];

  @override
  Stream<DiscoveredDevice> scanForDevices({required List<Uuid> withServices}) =>
      scanController.stream;

  @override
  Future<List<DiscoveredDevice>> connectedDevices({
    required List<Uuid> withServices,
  }) async {
    connectedServiceFilter = withServices;
    return connected;
  }

  @override
  Stream<ConnectionStateUpdate> connectToDevice({
    required String id,
    required Duration connectionTimeout,
  }) => connectionController.stream;

  @override
  Future<List<ReactiveBleDiscoveredService>> discoverServices(
    String deviceId,
  ) async => services;

  @override
  Stream<List<int>> subscribeToCharacteristic(
    QualifiedCharacteristic characteristic,
  ) => notificationController.stream;

  @override
  Future<List<int>> readCharacteristic(
    QualifiedCharacteristic characteristic,
  ) async => List<int>.of(readValue);

  @override
  Future<void> writeCharacteristicWithResponse(
    QualifiedCharacteristic characteristic, {
    required List<int> value,
  }) async {
    writes.add(List<int>.of(value));
  }

  @override
  Future<void> writeCharacteristicWithoutResponse(
    QualifiedCharacteristic characteristic, {
    required List<int> value,
  }) async {
    writes.add(List<int>.of(value));
  }
}
