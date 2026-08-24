import 'dart:async';

import 'package:ring_ble/ring_ble.dart';
import 'package:ring_colmi_qring/ring_colmi_qring.dart';
import 'package:ring_core/ring_core.dart';
import 'package:test/test.dart';

void main() {
  test('R12 matching is exact while candidate scan filtering is inclusive', () {
    const r12 = RingAdvertisement(deviceId: '1', name: 'COLMI R12_A1');
    const family = RingAdvertisement(
      deviceId: '2',
      name: 'Unknown',
      serviceUuids: <String>{ColmiQringProfile.commandService},
    );
    const wrong = RingAdvertisement(deviceId: '3', name: 'COLMI R09_A1');

    expect(ColmiQringProfile.isR12Advertisement(r12), isTrue);
    expect(ColmiQringProfile.isInclusiveCandidate(family), isTrue);
    expect(ColmiQringProfile.isR12Advertisement(family), isFalse);
    expect(ColmiQringProfile.isInclusiveCandidate(wrong), isFalse);
  });

  test(
    'missing expected characteristics disconnects and fails closed',
    () async {
      final transport = _FakeTransport(<BleService>[
        BleService(
          uuid: ColmiQringProfile.commandService,
          characteristics: const <BleCharacteristic>[],
        ),
      ]);
      final driver = ColmiQringDriver(transport);

      await expectLater(
        driver.connect(
          const RingPeripheral(deviceId: '1', name: 'COLMI R12_A1'),
        ),
        throwsA(isA<UnsupportedFirmwareException>()),
      );
      expect(transport.disconnectCalls, 1);
    },
  );

  test('service discovery failures disconnect before propagating', () async {
    final transport = _FakeTransport(
      _completeServices(),
      discoveryFailure: StateError('discovery failed'),
    );
    final driver = ColmiQringDriver(transport);

    await expectLater(
      driver.connect(const RingPeripheral(deviceId: '1', name: 'COLMI R12_A1')),
      throwsStateError,
    );
    expect(transport.disconnectCalls, 1);
  });

  test(
    'capabilities expose only present, family-corroborated channels',
    () async {
      final transport = _FakeTransport(_completeServices());
      final driver = ColmiQringDriver(transport);
      final connection = await driver.connect(
        const RingPeripheral(deviceId: '1', name: 'COLMI R12_A1'),
      );
      final capabilities = await driver.discoverCapabilities(connection);

      expect(capabilities.supports(DeviceCapability.battery), isTrue);
      expect(capabilities.supports(DeviceCapability.sleep), isTrue);
      expect(
        capabilities.confidenceFor(DeviceCapability.sleep),
        CapabilityConfidence.familyCorroborated,
      );
      expect(capabilities.supports(DeviceCapability.rawPacketLogging), isFalse);
    },
  );

  test('unverified sync and live payloads are never issued', () async {
    final transport = _FakeTransport(_completeServices());
    final driver = ColmiQringDriver(transport);

    await expectLater(
      driver.sync(SyncRequest(<SyncDomain>{SyncDomain.sleep}), null),
      throwsA(isA<ProtocolEvidenceIncompleteException>()),
    );
    await expectLater(
      driver.startLiveMeasurement(LiveMeasurementType.heartRate),
      throwsA(isA<ProtocolEvidenceIncompleteException>()),
    );
    expect(transport.writes, isEmpty);
  });
}

List<BleService> _completeServices() => <BleService>[
  BleService(
    uuid: ColmiQringProfile.commandService,
    characteristics: const <BleCharacteristic>[
      BleCharacteristic(uuid: ColmiQringProfile.commandWrite, canWrite: true),
      BleCharacteristic(uuid: ColmiQringProfile.commandNotify, canNotify: true),
    ],
  ),
  BleService(
    uuid: ColmiQringProfile.bigDataService,
    characteristics: const <BleCharacteristic>[
      BleCharacteristic(uuid: ColmiQringProfile.bigDataWrite, canWrite: true),
      BleCharacteristic(uuid: ColmiQringProfile.bigDataNotify, canNotify: true),
    ],
  ),
];

class _FakeTransport implements RingBleTransport {
  _FakeTransport(this.services, {this.discoveryFailure});

  final List<BleService> services;
  final Object? discoveryFailure;
  final List<List<int>> writes = <List<int>>[];
  final _connections = StreamController<BleConnectionState>.broadcast();
  int disconnectCalls = 0;

  @override
  Stream<BleConnectionState> get connectionStates => _connections.stream;

  @override
  Future<void> connect(String deviceId, {required Duration timeout}) async {
    _connections.add(BleConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    _connections.add(BleConnectionState.disconnected);
  }

  @override
  Future<List<BleService>> discoverServices() async {
    if (discoveryFailure case final Object error) throw error;
    return services;
  }

  @override
  Stream<RingAdvertisement> scan({required Duration timeout}) =>
      const Stream<RingAdvertisement>.empty();

  @override
  Stream<List<int>> subscribe({
    required String serviceUuid,
    required String characteristicUuid,
  }) => const Stream<List<int>>.empty();

  @override
  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
    required bool withResponse,
  }) async {
    writes.add(List<int>.from(value));
  }
}
