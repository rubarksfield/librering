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

  test(
    'sync requires a connection while live and settings remain gated',
    () async {
      final transport = _FakeTransport(_completeServices());
      final driver = ColmiQringDriver(transport);
      final progress = <R12SyncProgress>[];

      await expectLater(
        driver.sync(
          SyncRequest(<SyncDomain>{SyncDomain.sleep}),
          null,
          onProgress: progress.add,
        ),
        throwsStateError,
      );
      expect(progress, isEmpty);
      await expectLater(
        driver.startLiveMeasurement(LiveMeasurementType.heartRate),
        throwsA(isA<ProtocolEvidenceIncompleteException>()),
      );
      expect(transport.writes, isEmpty);
    },
  );

  test(
    'verified read-only sync returns a provenance-bearing dataset',
    () async {
      final transport = _FakeTransport(
        _completeServices(),
        approvedSuiteResponses: true,
        readValues: <String, List<int>>{
          '${ColmiQringProfile.deviceInformationService}/'
                  '${ColmiQringProfile.firmwareRevision}':
              'RT11CR_1.00.09_260424'.codeUnits,
        },
      );
      final driver = ColmiQringDriver(transport);
      final progress = <R12SyncProgress>[];
      await driver.connect(
        const RingPeripheral(
          deviceId: 'ephemeral-only',
          name: 'COLMI R12_TEST',
        ),
      );

      final result = await driver.sync(
        SyncRequest(const <SyncDomain>{
          SyncDomain.battery,
          SyncDomain.activity,
          SyncDomain.heartRate,
          SyncDomain.sleep,
          SyncDomain.oxygen,
          SyncDomain.additional,
        }),
        null,
        onProgress: progress.add,
      );

      expect(result.partial, isEmpty);
      expect(result.completed, hasLength(6));
      expect(result.dataset, isNotNull);
      expect(result.dataset!.source.driverId, 'colmi-qring-v1');
      expect(result.dataset!.source.firmwareVersion, 'RT11CR_1.00.09_260424');
      expect(result.dataset!.batteryLevel, 73);
      expect(result.dataset!.recordCount, 0);
      expect(result.nextCursor, isNotNull);
      expect(
        progress.map((event) => event.phase).toSet(),
        orderedEquals(R12SyncPhase.values),
      );
      for (final phase in <R12SyncPhase>[
        R12SyncPhase.activity,
        R12SyncPhase.heartRate,
        R12SyncPhase.stress,
        R12SyncPhase.hrv,
      ]) {
        final days =
            phase == R12SyncPhase.activity || phase == R12SyncPhase.heartRate
            ? 8
            : 7;
        final phaseEvents = progress.where((event) => event.phase == phase);
        expect(
          phaseEvents.map((event) => event.completedUnits),
          orderedEquals(List<int>.generate(days + 1, (index) => index)),
        );
        expect(phaseEvents.every((event) => event.totalUnits == days), isTrue);
      }
      expect(progress.last.phase, R12SyncPhase.normalising);
      expect(progress.last.completedUnits, isNull);
      expect(progress.last.totalUnits, isNull);
      expect(
        transport.writes.where(
          (value) => const <int>{0x08, 0x0a, 0x50, 0xff}.contains(value.first),
        ),
        isEmpty,
      );
    },
  );

  test(
    'sync emits only requested phases and remains RingDriver compatible',
    () async {
      final transport = _verifiedTransport();
      final driver = ColmiQringDriver(transport);
      await driver.connect(
        const RingPeripheral(deviceId: 'test', name: 'COLMI R12_TEST'),
      );
      final progress = <R12SyncProgress>[];

      final result = await driver.sync(
        SyncRequest(<SyncDomain>{SyncDomain.battery}),
        null,
        onProgress: progress.add,
      );

      expect(result.completed, <SyncDomain>{SyncDomain.battery});
      expect(
        progress.map((event) => event.phase),
        orderedEquals(<R12SyncPhase>[
          R12SyncPhase.metadata,
          R12SyncPhase.battery,
          R12SyncPhase.normalising,
        ]),
      );
      expect(progress.every((event) => event.completedUnits == null), isTrue);
      expect(progress.every((event) => event.totalUnits == null), isTrue);
      final RingDriver interfaceDriver = driver;
      final noObserverResult = await interfaceDriver.sync(
        SyncRequest(<SyncDomain>{SyncDomain.battery}),
        null,
      );
      expect(noObserverResult.dataset!.batteryLevel, 73);
    },
  );

  test('day progress advances only after the request settles', () async {
    final firstDayStarted = Completer<void>();
    final releaseFirstDay = Completer<void>();
    final transport = _verifiedTransport(
      beforeWrite: (value) async {
        if (value.first == colmiActivityHistoryCommandId && value[1] == 0) {
          firstDayStarted.complete();
          await releaseFirstDay.future;
        }
      },
    );
    final driver = ColmiQringDriver(transport);
    await driver.connect(
      const RingPeripheral(deviceId: 'test', name: 'COLMI R12_TEST'),
    );
    final progress = <R12SyncProgress>[];
    final syncing = driver.sync(
      SyncRequest(<SyncDomain>{SyncDomain.activity}),
      null,
      onProgress: progress.add,
    );

    await firstDayStarted.future;
    expect(progress.last.phase, R12SyncPhase.activity);
    expect(progress.last.completedUnits, 0);
    expect(progress.last.totalUnits, 8);
    expect(
      progress.where((event) => event.phase == R12SyncPhase.activity),
      hasLength(1),
    );
    releaseFirstDay.complete();
    final result = await syncing;
    expect(result.completed, <SyncDomain>{SyncDomain.activity});
    expect(
      progress
          .where((event) => event.phase == R12SyncPhase.activity)
          .map((event) => event.completedUnits),
      orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6, 7, 8]),
    );
  });

  test(
    'settled failed days report progress without claiming successful data',
    () async {
      final transport = _verifiedTransport(
        beforeWrite: (value) async {
          if (value.first == colmiActivityHistoryCommandId) {
            throw StateError('Synthetic write failure');
          }
        },
      );
      final driver = ColmiQringDriver(transport);
      await driver.connect(
        const RingPeripheral(deviceId: 'test', name: 'COLMI R12_TEST'),
      );
      final progress = <R12SyncProgress>[];

      final result = await driver.sync(
        SyncRequest(<SyncDomain>{SyncDomain.activity}),
        null,
        onProgress: progress.add,
      );

      expect(result.completed, isEmpty);
      expect(result.partial, <SyncDomain>{SyncDomain.activity});
      expect(result.dataset!.recordCount, 0);
      expect(
        progress
            .where((event) => event.phase == R12SyncPhase.activity)
            .map((event) => event.completedUnits),
        orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6, 7, 8]),
      );
    },
  );

  test('unsupported channels do not emit a data-transfer phase', () async {
    final transport = _verifiedTransport(supportsBigData: false);
    final driver = ColmiQringDriver(transport);
    await driver.connect(
      const RingPeripheral(deviceId: 'test', name: 'COLMI R12_TEST'),
    );
    final progress = <R12SyncProgress>[];

    final result = await driver.sync(
      SyncRequest(<SyncDomain>{SyncDomain.sleep, SyncDomain.oxygen}),
      null,
      onProgress: progress.add,
    );

    expect(result.completed, isEmpty);
    expect(result.partial, <SyncDomain>{SyncDomain.sleep, SyncDomain.oxygen});
    expect(
      progress.map((event) => event.phase),
      orderedEquals(<R12SyncPhase>[
        R12SyncPhase.metadata,
        R12SyncPhase.normalising,
      ]),
    );
  });

  test('sync fails closed on an unverified firmware', () async {
    final transport = _FakeTransport(
      _completeServices(),
      readValues: <String, List<int>>{
        '${ColmiQringProfile.deviceInformationService}/'
                '${ColmiQringProfile.firmwareRevision}':
            'R12-UNVERIFIED'.codeUnits,
      },
    );
    final driver = ColmiQringDriver(transport);
    await driver.connect(
      const RingPeripheral(deviceId: 'ephemeral-only', name: 'COLMI R12_TEST'),
    );
    final progress = <R12SyncProgress>[];

    await expectLater(
      driver.sync(
        SyncRequest(<SyncDomain>{SyncDomain.battery}),
        null,
        onProgress: progress.add,
      ),
      throwsA(isA<UnsupportedFirmwareException>()),
    );
    expect(transport.writes, isEmpty);
    expect(progress.single.phase, R12SyncPhase.metadata);
  });

  test(
    'capture mode reads firmware and one bounded battery exchange',
    () async {
      final transport = _FakeTransport(
        _completeServices(),
        readValues: <String, List<int>>{
          '${ColmiQringProfile.deviceInformationService}/'
                  '${ColmiQringProfile.firmwareRevision}':
              'R12-1.2.3'.codeUnits,
        },
      );
      final driver = ColmiQringDriver(transport);
      await driver.connect(
        const RingPeripheral(
          deviceId: 'must-not-appear-in-capture',
          name: 'COLMI R12_SECRET_SUFFIX',
        ),
      );

      final capture = await driver.captureMetadata();

      expect(capture.batteryLevel, 73);
      expect(capture.charging, isFalse);
      expect(capture.firmwareVersion, 'R12-1.2.3');
      expect(transport.writes, hasLength(1));
      expect(transport.writes.single, ColmiCommandPacket.create(0x03).bytes);
      expect(capture.toAnonymisedJson(), contains('owned-r12-1'));
      expect(capture.toAnonymisedJson(), isNot(contains('must-not-appear')));
      expect(capture.toAnonymisedJson(), isNot(contains('SECRET_SUFFIX')));
    },
  );

  test('capture mode emits one deterministic local clock command', () async {
    final transport = _FakeTransport(_completeServices());
    final driver = ColmiQringDriver(transport);
    await driver.connect(
      const RingPeripheral(deviceId: 'redacted', name: 'COLMI R12_TEST'),
    );
    final localTime = DateTime(2026, 8, 26, 16, 15, 42);

    final capture = await driver.captureTimeSync(localTime: localTime);

    expect(transport.writes, hasLength(1));
    expect(
      transport.writes.single,
      ColmiCommandPacket.create(0x01, <int>[
        0x26,
        0x08,
        0x26,
        0x16,
        0x15,
        0x42,
        0x01,
      ]).bytes,
    );
    expect(capture.requestedLocalTime, localTime);
    expect(capture.response.commandId, 0x01);
    expect(capture.toAnonymisedJson(), isNot(contains('redacted')));
  });

  test('approved suite captures every supported read-only family without setting writes', () async {
    final transport = _FakeTransport(
      _completeServices(),
      approvedSuiteResponses: true,
      readValues: <String, List<int>>{
        '${ColmiQringProfile.deviceInformationService}/'
                '${ColmiQringProfile.firmwareRevision}':
            'R12-1.2.3'.codeUnits,
      },
    );
    final driver = ColmiQringDriver(transport);
    await driver.connect(
      const RingPeripheral(
        deviceId: 'must-not-appear',
        name: 'COLMI R12_SECRET',
      ),
    );

    final capture = await driver.captureApprovedSuite(
      localTime: DateTime(2026, 8, 26, 16, 15, 42),
    );

    expect(capture.statuses['metadata'], 'complete');
    expect(capture.statuses['activityHistory'], 'noData');
    expect(capture.statuses['heartRateHistory'], 'noData');
    expect(capture.statuses['stressHistory'], 'noData');
    expect(capture.statuses['firmwareHrvHistory'], 'noData');
    expect(capture.statuses['sleepHistory'], 'noData');
    expect(capture.statuses['oxygenHistory'], 'noData');
    expect(capture.statuses['liveHeartRate'], 'complete');
    expect(capture.statuses['liveOxygen'], 'complete');

    final commandWrites = transport.writes
        .where((value) => value.length == ColmiCommandPacket.length)
        .toList(growable: false);
    expect(
      commandWrites
          .where((value) => value.first == colmiActivityHistoryCommandId)
          .map((value) => value[1]),
      orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6, 7]),
    );
    expect(
      commandWrites
          .where((value) => value.first == colmiStressHistoryCommandId)
          .map((value) => value[1]),
      orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6]),
    );
    expect(
      commandWrites
          .where((value) => value.first == colmiHrvHistoryCommandId)
          .map((value) => value[1]),
      orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6]),
    );
    expect(
      commandWrites.where(
        (value) => const <int>{0x08, 0x0a, 0x50, 0xff}.contains(value.first),
      ),
      isEmpty,
    );
    for (final commandId in const <int>{
      colmiDisplayPreferenceCommandId,
      colmiAutoHeartRatePreferenceCommandId,
      colmiGoalsCommandId,
      colmiAutoOxygenPreferenceCommandId,
      colmiAutoStressPreferenceCommandId,
      colmiAutoHrvPreferenceCommandId,
    }) {
      expect(
        commandWrites.singleWhere((value) => value.first == commandId)[1],
        0x01,
      );
    }
    expect(capture.toAnonymisedJson(), isNot(contains('must-not-appear')));
    expect(capture.toAnonymisedJson(), isNot(contains('SECRET')));
  });
}

_FakeTransport _verifiedTransport({
  Future<void> Function(List<int> value)? beforeWrite,
  bool supportsBigData = true,
}) => _FakeTransport(
  _completeServices()
      .where(
        (service) =>
            supportsBigData || service.uuid != ColmiQringProfile.bigDataService,
      )
      .toList(),
  approvedSuiteResponses: true,
  beforeWrite: beforeWrite,
  readValues: <String, List<int>>{
    '${ColmiQringProfile.deviceInformationService}/'
            '${ColmiQringProfile.firmwareRevision}':
        'RT11CR_1.00.09_260424'.codeUnits,
  },
);

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
  BleService(
    uuid: ColmiQringProfile.deviceInformationService,
    characteristics: const <BleCharacteristic>[
      BleCharacteristic(
        uuid: ColmiQringProfile.firmwareRevision,
        canRead: true,
      ),
    ],
  ),
];

class _FakeTransport implements RingBleTransport {
  _FakeTransport(
    this.services, {
    this.discoveryFailure,
    this.readValues = const <String, List<int>>{},
    this.approvedSuiteResponses = false,
    this.beforeWrite,
  });

  final List<BleService> services;
  final Object? discoveryFailure;
  final Map<String, List<int>> readValues;
  final bool approvedSuiteResponses;
  final Future<void> Function(List<int> value)? beforeWrite;
  final List<List<int>> writes = <List<int>>[];
  final _connections = StreamController<BleConnectionState>.broadcast();
  final _notifications = StreamController<List<int>>.broadcast();
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
  }) => _notifications.stream;

  @override
  Future<List<int>> read({
    required String serviceUuid,
    required String characteristicUuid,
  }) async => List<int>.of(
    readValues['$serviceUuid/$characteristicUuid'] ?? const <int>[],
  );

  @override
  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
    required bool withResponse,
  }) async {
    writes.add(List<int>.from(value));
    await beforeWrite?.call(value);
    if (value.isNotEmpty && value.first == 0x03) {
      final response = ColmiCommandPacket.create(0x03, <int>[73, 0]);
      scheduleMicrotask(() => _notifications.add(response.bytes));
    } else if (value.isNotEmpty && value.first == 0x01) {
      final response = ColmiCommandPacket.create(0x01, <int>[0, 0, 0, 0]);
      scheduleMicrotask(() => _notifications.add(response.bytes));
    } else if (approvedSuiteResponses && value.isNotEmpty) {
      if (value.first == colmiBigDataCommandId) {
        final dataId = value[1];
        final response = dataId == colmiSleepDataId
            ? <int>[colmiBigDataCommandId, dataId, 1, 0, 0xff, 0xff, 0]
            : <int>[colmiBigDataCommandId, dataId, 0, 0, 0xff, 0xff];
        scheduleMicrotask(() => _notifications.add(response));
      } else if (value.first == colmiLiveStartCommandId) {
        final kind = value[1];
        final reading = kind == colmiLiveHeartRateKind ? 72 : 98;
        final response = ColmiCommandPacket.create(
          colmiLiveStartCommandId,
          <int>[kind, 0, reading],
        );
        scheduleMicrotask(() => _notifications.add(response.bytes));
      } else if (value.first != colmiLiveStopCommandId) {
        final response = switch (value.first) {
          colmiActivityHistoryCommandId ||
          colmiHeartRateHistoryCommandId ||
          colmiStressHistoryCommandId ||
          colmiHrvHistoryCommandId => ColmiCommandPacket.create(
            value.first,
            const <int>[0xff],
          ),
          _ => ColmiCommandPacket.create(value.first, const <int>[0x01]),
        };
        scheduleMicrotask(() => _notifications.add(response.bytes));
      }
    }
  }
}
