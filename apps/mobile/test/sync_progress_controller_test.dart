import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/ble/r12_pairing_client.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:librering_mobile/src/sync_progress.dart';
import 'package:ring_colmi_qring/ring_colmi_qring.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  testWidgets(
    'sync reports real discovery, connection, and protocol progress',
    (tester) async {
      final harness = _Harness();
      harness.client.scanGate = Completer<void>();
      harness.client.connectGate = Completer<void>();

      final operation = harness.controller.quickSync();
      expect(harness.progress.stage, RingSyncStage.finding);
      expect(harness.state.syncInProgress, isTrue);
      await tester.pump();
      harness.client.scanGate!.complete();
      await tester.pump();
      expect(harness.progress.stage, RingSyncStage.connecting);
      harness.client.connectGate!.complete();
      await tester.pump();
      expect(harness.progress.stage, RingSyncStage.metadata);
      expect(harness.client.progressSyncs, 1);
      expect(harness.client.legacySyncs, 0);

      const expectedStages = <R12SyncPhase, RingSyncStage>{
        R12SyncPhase.metadata: RingSyncStage.metadata,
        R12SyncPhase.battery: RingSyncStage.battery,
        R12SyncPhase.activity: RingSyncStage.activity,
        R12SyncPhase.heartRate: RingSyncStage.heartRate,
        R12SyncPhase.sleep: RingSyncStage.sleep,
        R12SyncPhase.oxygen: RingSyncStage.oxygen,
        R12SyncPhase.stress: RingSyncStage.stress,
        R12SyncPhase.hrv: RingSyncStage.hrv,
        R12SyncPhase.normalising: RingSyncStage.normalising,
      };
      for (final entry in expectedStages.entries) {
        harness.client.report(R12SyncProgress(phase: entry.key));
        expect(harness.progress.stage, entry.value);
        expect(harness.progress.isTerminal, isFalse);
      }
      harness.client.report(
        const R12SyncProgress(
          phase: R12SyncPhase.activity,
          completedUnits: 3,
          totalUnits: 8,
        ),
      );
      expect(harness.progress.completedUnits, 3);
      expect(harness.progress.totalUnits, 8);
      expect(harness.repository.mergeCalls, 0);

      harness.client.complete();
      await tester.pump();
      await operation;
      expect(harness.progress.stage, RingSyncStage.completed);
      expect(harness.state.syncInProgress, isFalse);
      expect(harness.state.lastSyncRecordCount, 1);
    },
  );

  testWidgets(
    'elapsed time never invents progress and stalled feedback clears',
    (tester) async {
      final harness = _Harness();
      final operation = harness.controller.quickSync();
      await tester.pump();
      harness.client.report(
        const R12SyncProgress(
          phase: R12SyncPhase.heartRate,
          completedUnits: 2,
          totalUnits: 8,
        ),
      );
      await tester.pump(const Duration(seconds: 29));
      expect(harness.progress.elapsed, const Duration(seconds: 29));
      expect(harness.progress.isStalled, isFalse);
      expect(harness.progress.completedUnits, 2);
      await tester.pump(const Duration(seconds: 1));
      expect(harness.progress.isStalled, isTrue);
      expect(harness.progress.stage, RingSyncStage.heartRate);
      expect(harness.progress.completedUnits, 2);
      expect(harness.state.syncError, isNull);
      expect(harness.state.syncInProgress, isTrue);

      harness.client.report(
        const R12SyncProgress(
          phase: R12SyncPhase.heartRate,
          completedUnits: 3,
          totalUnits: 8,
        ),
      );
      expect(harness.progress.isStalled, isFalse);
      expect(harness.progress.sinceLastProgress, Duration.zero);
      expect(harness.progress.elapsed, const Duration(seconds: 30));
      expect(harness.progress.completedUnits, 3);
      await tester.pump(const Duration(seconds: 30));
      expect(harness.progress.isStalled, isTrue);
      harness.client.report(const R12SyncProgress(phase: R12SyncPhase.sleep));
      expect(harness.progress.isStalled, isFalse);
      expect(harness.progress.completedUnits, isNull);
      expect(harness.progress.totalUnits, isNull);

      harness.client.complete();
      await tester.pump();
      await operation;
      final finishedProgress = harness.progress;
      await tester.pump(const Duration(minutes: 2));
      expect(identical(harness.progress, finishedProgress), isTrue);
      expect(harness.progress.isStalled, isFalse);
    },
  );

  testWidgets(
    'saving and connection release stay busy and reject another sync',
    (tester) async {
      final harness = _Harness();
      harness.repository.mergeGate = Completer<void>();
      harness.client.disconnectGate = Completer<void>();
      final operation = harness.controller.quickSync();
      await tester.pump();
      harness.client.complete();
      await tester.pump();
      expect(harness.progress.stage, RingSyncStage.saving);
      expect(harness.state.syncInProgress, isTrue);
      expect(harness.state.lastSyncedAtUtc, isNull);
      expect(harness.repository.saved, isNull);
      await harness.controller.quickSync();
      await harness.controller.sync();
      await harness.controller.scan();
      expect(harness.client.scans, 1);
      expect(harness.client.progressSyncs, 1);

      harness.repository.mergeGate!.complete();
      await tester.pump();
      expect(harness.progress.stage, RingSyncStage.finishing);
      expect(harness.progress.isTerminal, isFalse);
      expect(harness.state.syncInProgress, isTrue);
      expect(harness.repository.saved, isNotNull);
      await tester.pump(const Duration(seconds: 30));
      expect(harness.progress.isStalled, isTrue);
      await harness.controller.quickSync();
      await harness.controller.sync();
      expect(harness.client.scans, 1);
      expect(harness.client.progressSyncs, 1);
      harness.client.disconnectGate!.complete();
      await tester.pump();
      await operation;
      expect(harness.progress.stage, RingSyncStage.completed);
      expect(harness.state.syncInProgress, isFalse);
      expect(harness.progress.isStalled, isFalse);
    },
  );

  for (final availability in RingDataAvailability.values) {
    testWidgets('terminal outcome preserves ${availability.name} semantics', (
      tester,
    ) async {
      final harness = _Harness();
      final operation = harness.controller.quickSync();
      await tester.pump();
      harness.client.complete(availability: availability);
      await tester.pump();
      await operation;
      final isPartial =
          availability == RingDataAvailability.partial ||
          availability == RingDataAvailability.error;
      expect(
        harness.progress.stage,
        isPartial ? RingSyncStage.partial : RingSyncStage.completed,
      );
      expect(harness.state.syncError, isPartial ? isNotNull : isNull);
      expect(harness.state.syncInProgress, isFalse);
      expect(harness.state.lastSyncedAtUtc, isNotNull);
      expect(harness.repository.mergeCalls, 1);
      if (availability == RingDataAvailability.noData ||
          availability == RingDataAvailability.noReading ||
          availability == RingDataAvailability.unavailable) {
        expect(harness.state.lastSyncRecordCount, 0);
      }
    });
  }

  testWidgets(
    'a failed read retains its failure until release and resets retry',
    (tester) async {
      final harness = _Harness();
      harness.client.disconnectGate = Completer<void>();
      final operation = harness.controller.quickSync();
      await tester.pump();
      harness.client.report(
        const R12SyncProgress(
          phase: R12SyncPhase.activity,
          completedUnits: 5,
          totalUnits: 8,
        ),
      );
      await tester.pump(const Duration(seconds: 34));
      harness.client.syncGate.completeError(
        StateError('Synthetic read failure'),
      );
      await tester.pump();
      expect(harness.progress.stage, RingSyncStage.finishing);
      expect(harness.state.syncError, isNotNull);
      expect(harness.state.syncInProgress, isTrue);
      await harness.controller.quickSync();
      expect(harness.client.progressSyncs, 1);
      harness.client.disconnectGate!.complete();
      await tester.pump();
      await operation;
      expect(harness.progress.stage, RingSyncStage.failed);
      expect(harness.repository.mergeCalls, 0);
      expect(harness.state.lastSyncedAtUtc, isNull);

      harness.client.syncGate = Completer<RingSyncDataset>();
      harness.client.disconnectGate = null;
      final retry = harness.controller.quickSync();
      expect(harness.progress.stage, RingSyncStage.finding);
      expect(harness.progress.elapsed, Duration.zero);
      expect(harness.progress.sinceLastProgress, Duration.zero);
      expect(harness.progress.completedUnits, isNull);
      expect(harness.progress.totalUnits, isNull);
      expect(harness.state.syncError, isNull);
      await tester.pump();
      harness.client.complete();
      await tester.pump();
      await retry;
      expect(harness.progress.stage, RingSyncStage.completed);
      expect(harness.client.progressSyncs, 2);
      expect(harness.repository.mergeCalls, 1);
    },
  );

  testWidgets('failed persistence cannot report completed or partial success', (
    tester,
  ) async {
    final harness = _Harness();
    harness.repository.failMerge = true;
    final original = _dataset();
    harness.repository.saved = original;
    await harness.container.read(ringDataProvider.future);
    final operation = harness.controller.quickSync();
    await tester.pump();
    harness.client.complete(availability: RingDataAvailability.partial);
    await tester.pump();
    await operation;
    expect(harness.progress.stage, RingSyncStage.failed);
    expect(harness.state.syncError, isNotNull);
    expect(harness.state.syncInProgress, isFalse);
    expect(harness.state.lastSyncedAtUtc, isNull);
    expect(harness.repository.saved, same(original));
    expect(harness.container.read(ringDataProvider).value, same(original));
  });

  testWidgets(
    'late protocol callbacks cannot replace saving, terminal, or retry state',
    (tester) async {
      final harness = _Harness();
      harness.repository.mergeGate = Completer<void>();
      harness.client.disconnectGate = Completer<void>();
      final operation = harness.controller.quickSync();
      await tester.pump();
      final oldCallback = harness.client.onProgress!;
      harness.client.complete();
      await tester.pump();
      expect(harness.progress.stage, RingSyncStage.saving);
      oldCallback(const R12SyncProgress(phase: R12SyncPhase.activity));
      expect(harness.progress.stage, RingSyncStage.saving);

      harness.repository.mergeGate!.complete();
      await tester.pump();
      expect(harness.progress.stage, RingSyncStage.finishing);
      oldCallback(const R12SyncProgress(phase: R12SyncPhase.activity));
      expect(harness.progress.stage, RingSyncStage.finishing);
      harness.client.disconnectGate!.complete();
      await tester.pump();
      await operation;
      oldCallback(const R12SyncProgress(phase: R12SyncPhase.activity));
      expect(harness.progress.stage, RingSyncStage.completed);

      harness.client.syncGate = Completer<RingSyncDataset>();
      harness.client.disconnectGate = null;
      harness.repository.mergeGate = null;
      final retry = harness.controller.quickSync();
      oldCallback(const R12SyncProgress(phase: R12SyncPhase.activity));
      expect(harness.progress.stage, RingSyncStage.finding);
      await tester.pump();
      expect(harness.progress.stage, RingSyncStage.metadata);
      oldCallback(const R12SyncProgress(phase: R12SyncPhase.activity));
      expect(harness.progress.stage, RingSyncStage.metadata);
      harness.client.report(
        const R12SyncProgress(phase: R12SyncPhase.heartRate),
      );
      expect(harness.progress.stage, RingSyncStage.heartRate);
      harness.client.complete();
      await tester.pump();
      await retry;
      expect(harness.progress.stage, RingSyncStage.completed);
      expect(harness.repository.mergeCalls, 2);
    },
  );

  testWidgets(
    'disposal cancels feedback ticker and ignores late read callbacks',
    (tester) async {
      final harness = _Harness();
      final operation = harness.controller.quickSync();
      await tester.pump();
      final callback = harness.client.onProgress!;
      harness.dispose();
      await tester.pump(const Duration(minutes: 2));
      expect(
        () => callback(const R12SyncProgress(phase: R12SyncPhase.hrv)),
        returnsNormally,
      );
      harness.client.complete();
      await tester.pump();
      await operation;
      expect(harness.repository.mergeCalls, 0);
      expect(harness.client.disconnects, greaterThanOrEqualTo(1));
      expect(tester.takeException(), isNull);
    },
  );
}

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        ringPairingClientProvider.overrideWithValue(client),
        ringDataRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(dispose);
  }

  final client = _ProgressClient();
  final repository = _Repository();
  late final ProviderContainer container;
  bool _disposed = false;

  RingPairingController get controller =>
      container.read(ringPairingProvider.notifier);
  RingPairingState get state => container.read(ringPairingProvider);
  RingSyncProgress get progress => state.syncProgress!;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    container.dispose();
  }
}

class _ProgressClient implements RingPairingClient, RingSyncProgressClient {
  int scans = 0;
  int legacySyncs = 0;
  int progressSyncs = 0;
  int disconnects = 0;
  Completer<void>? scanGate;
  Completer<void>? connectGate;
  Completer<void>? disconnectGate;
  Completer<RingSyncDataset> syncGate = Completer<RingSyncDataset>();
  void Function(R12SyncProgress)? onProgress;

  void report(R12SyncProgress progress) => onProgress!(progress);

  void complete({
    RingDataAvailability availability = RingDataAvailability.complete,
  }) => syncGate.complete(_dataset(availability: availability));

  @override
  Stream<RingPairingCandidate> scan({required Duration timeout}) async* {
    scans++;
    if (scanGate != null) await scanGate!.future;
    yield const RingPairingCandidate(
      advertisement: RingAdvertisement(
        deviceId: 'synthetic-progress-ring',
        name: 'COLMI R12_TEST',
      ),
      exact: true,
    );
  }

  @override
  Future<RingPairingEvidence> connect(RingAdvertisement advertisement) async {
    if (connectGate != null) await connectGate!.future;
    return RingPairingEvidence(
      name: advertisement.name,
      capabilities: DeviceCapabilities(const {}),
      supportsBigData: true,
    );
  }

  @override
  Future<RingSyncDataset> syncWithProgress({
    required void Function(R12SyncProgress) onProgress,
  }) {
    progressSyncs++;
    this.onProgress = onProgress;
    return syncGate.future;
  }

  @override
  Future<RingSyncDataset> sync() {
    legacySyncs++;
    return syncGate.future;
  }

  @override
  Future<void> disconnect() async {
    disconnects++;
    if (disconnectGate != null) await disconnectGate!.future;
  }

  @override
  Future<RingMetadata> captureMetadata() => throw UnimplementedError();
  @override
  Future<RingTimeSyncResult> captureTimeSync() => throw UnimplementedError();
  @override
  Future<RingApprovedSuiteResult> captureApprovedSuite() =>
      throw UnimplementedError();
}

class _Repository implements RingDataRepository {
  int mergeCalls = 0;
  RingSyncDataset? saved;
  Completer<void>? mergeGate;
  bool failMerge = false;

  @override
  Future<RingSyncDataset?> read() async => saved;

  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async {
    mergeCalls++;
    if (mergeGate != null) await mergeGate!.future;
    if (failMerge) throw StateError('Synthetic storage failure');
    return saved = incoming;
  }

  @override
  Future<void> deleteAll() async => saved = null;
}

RingSyncDataset _dataset({
  RingDataAvailability availability = RingDataAvailability.complete,
}) => RingSyncDataset(
  lastSyncedAtUtc: DateTime.utc(2026, 9, 5, 9),
  source: const RingDataSource(driverId: 'synthetic-progress'),
  availability: {RingDataKind.heartRate: availability},
  heartRate:
      availability == RingDataAvailability.noData ||
          availability == RingDataAvailability.noReading ||
          availability == RingDataAvailability.unavailable
      ? const []
      : [
          RingHeartRateSample(
            measuredAtUtc: DateTime.utc(2026, 9, 5, 8),
            bpm: 61,
          ),
        ],
);
