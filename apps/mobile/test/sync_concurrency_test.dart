import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/ble/r12_pairing_client.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  ProviderContainer containerFor(_Client client, _Repository repository) {
    final container = ProviderContainer(
      overrides: [
        ringPairingClientProvider.overrideWithValue(client),
        ringDataRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'quick sync acquires its lock before yielding to another request',
    () async {
      final client = _Client();
      final repository = _Repository();
      final container = containerFor(client, repository);
      final controller = container.read(ringPairingProvider.notifier);
      final first = controller.quickSync();
      expect(container.read(ringPairingProvider).syncInProgress, isTrue);
      final second = controller.quickSync();
      await Future.wait([first, second]);
      expect(client.scans, 1);
      expect(client.connects, 1);
      expect(client.syncs, 1);
      expect(repository.writes, 1);
      expect(container.read(ringPairingProvider).syncInProgress, isFalse);
    },
  );

  test('quick sync keeps its lock until disconnect has finished', () async {
    final client = _Client()..disconnectGate = Completer<void>();
    final repository = _Repository();
    final container = containerFor(client, repository);
    final controller = container.read(ringPairingProvider.notifier);
    final first = controller.quickSync();
    await client.releaseStarted.future;
    expect(repository.writes, 1);
    expect(container.read(ringPairingProvider).syncInProgress, isTrue);
    await controller.quickSync();
    await controller.sync();
    await controller.scan();
    expect(client.scans, 1);
    expect(client.syncs, 1);
    client.disconnectGate!.complete();
    await first;
    expect(container.read(ringPairingProvider).syncInProgress, isFalse);
    await controller.quickSync();
    expect(client.scans, 2);
    expect(client.syncs, 2);
  });

  test('a setup sync also stays locked through disconnect', () async {
    final client = _Client()..disconnectGate = Completer<void>();
    final container = containerFor(client, _Repository());
    final controller = container.read(ringPairingProvider.notifier);
    await controller.scan();
    await Future<void>.delayed(Duration.zero);
    await controller.connect();
    expect(
      container.read(ringPairingProvider).phase,
      RingPairingPhase.connected,
    );
    final first = controller.sync();
    await client.releaseStarted.future;
    expect(container.read(ringPairingProvider).syncInProgress, isTrue);
    await controller.sync();
    await controller.quickSync();
    expect(client.syncs, 1);
    expect(client.connects, 1);
    client.disconnectGate!.complete();
    await first;
    expect(container.read(ringPairingProvider).syncInProgress, isFalse);
  });

  test(
    'failed sync keeps the lock during release and permits a later retry',
    () async {
      final client = _Client()
        ..failSync = true
        ..disconnectGate = Completer<void>();
      final repository = _Repository();
      final container = containerFor(client, repository);
      final controller = container.read(ringPairingProvider.notifier);
      final first = controller.quickSync();
      await client.releaseStarted.future;
      expect(container.read(ringPairingProvider).syncInProgress, isTrue);
      expect(container.read(ringPairingProvider).syncError, isNotNull);
      await controller.quickSync();
      expect(client.syncs, 1);
      expect(repository.writes, 0);
      client.disconnectGate!.complete();
      await first;
      client.failSync = false;
      await controller.quickSync();
      expect(client.syncs, 2);
      expect(repository.writes, 1);
      expect(container.read(ringPairingProvider).syncError, isNull);
    },
  );

  test(
    'disconnect failures release the lock without losing saved data',
    () async {
      final client = _Client()..failDisconnect = true;
      final repository = _Repository();
      final container = containerFor(client, repository);
      final controller = container.read(ringPairingProvider.notifier);
      await controller.quickSync();
      expect(repository.writes, 1);
      expect(container.read(ringPairingProvider).syncInProgress, isFalse);
      client.failDisconnect = false;
      await controller.quickSync();
      expect(repository.writes, 2);
    },
  );

  test(
    'partial reads save available data but do not claim full sync success',
    () async {
      final client = _Client()..availability = RingDataAvailability.partial;
      final repository = _Repository();
      final container = containerFor(client, repository);
      await container.read(ringPairingProvider.notifier).quickSync();
      expect(repository.writes, 1);
      expect(container.read(ringPairingProvider).lastSyncedAtUtc, isNotNull);
      expect(
        container.read(ringPairingProvider).syncError,
        'Some ring data could not be read. Available records were saved; try syncing again.',
      );
      expect(container.read(ringPairingProvider).syncInProgress, isFalse);
    },
  );

  test(
    'no reading is a valid completed read rather than a sync failure',
    () async {
      final client = _Client()..availability = RingDataAvailability.noReading;
      final container = containerFor(client, _Repository());
      await container.read(ringPairingProvider.notifier).quickSync();
      expect(container.read(ringPairingProvider).syncError, isNull);
      expect(container.read(ringPairingProvider).syncInProgress, isFalse);
    },
  );
}

class _Repository implements RingDataRepository {
  int writes = 0;
  RingSyncDataset? value;
  @override
  Future<RingSyncDataset?> read() async => value;
  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async {
    writes++;
    return value = incoming;
  }

  @override
  Future<void> deleteAll() async => value = null;
}

class _Client implements RingPairingClient {
  int scans = 0;
  int connects = 0;
  int syncs = 0;
  bool failSync = false;
  bool failDisconnect = false;
  RingDataAvailability availability = RingDataAvailability.complete;
  Completer<void>? disconnectGate;
  final releaseStarted = Completer<void>();

  @override
  Stream<RingPairingCandidate> scan({required Duration timeout}) {
    scans++;
    return Stream.fromIterable(const [
      RingPairingCandidate(
        advertisement: RingAdvertisement(
          deviceId: 'synthetic-id',
          name: 'COLMI R12_TEST',
        ),
        exact: true,
      ),
    ]);
  }

  @override
  Future<RingPairingEvidence> connect(RingAdvertisement advertisement) async {
    connects++;
    return RingPairingEvidence(
      name: advertisement.name,
      capabilities: DeviceCapabilities(const {}),
      supportsBigData: true,
    );
  }

  @override
  Future<RingSyncDataset> sync() async {
    syncs++;
    if (failSync) throw StateError('Synthetic read failure');
    return RingSyncDataset(
      lastSyncedAtUtc: DateTime.utc(2026, 9, 1),
      source: const RingDataSource(driverId: 'synthetic'),
      availability: {RingDataKind.heartRate: availability},
    );
  }

  @override
  Future<void> disconnect() async {
    if (!releaseStarted.isCompleted) releaseStarted.complete();
    if (disconnectGate != null) await disconnectGate!.future;
    if (failDisconnect) throw StateError('Synthetic release failure');
  }

  @override
  Future<RingMetadata> captureMetadata() => throw UnimplementedError();
  @override
  Future<RingTimeSyncResult> captureTimeSync() => throw UnimplementedError();
  @override
  Future<RingApprovedSuiteResult> captureApprovedSuite() =>
      throw UnimplementedError();
}
