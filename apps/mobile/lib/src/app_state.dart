import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:ring_core/ring_core.dart';

import 'ble/r12_pairing_client.dart';
import 'storage/ring_data_repository.dart';

final isDemoModeProvider = Provider<bool>((Ref ref) => false);
final isProtocolCaptureModeProvider = Provider<bool>((Ref ref) => false);
final dailySnapshotProvider = Provider<DailySnapshot?>((Ref ref) => null);
final ringPairingClientProvider = Provider<RingPairingClient?>(
  (Ref ref) => null,
);
final ringDataRepositoryProvider = Provider<RingDataRepository?>(
  (Ref ref) => null,
);

class RingDataController extends AsyncNotifier<RingSyncDataset?> {
  @override
  Future<RingSyncDataset?> build() async {
    return ref.watch(ringDataRepositoryProvider)?.read();
  }

  Future<RingSyncDataset> merge(RingSyncDataset incoming) async {
    final repository = ref.read(ringDataRepositoryProvider);
    if (repository == null) {
      throw StateError('Local ring storage is unavailable in this build.');
    }
    state = const AsyncLoading<RingSyncDataset?>();
    try {
      final merged = await repository.merge(incoming);
      state = AsyncData<RingSyncDataset?>(merged);
      return merged;
    } catch (error, stackTrace) {
      state = AsyncError<RingSyncDataset?>(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    final repository = ref.read(ringDataRepositoryProvider);
    if (repository == null) return;
    state = const AsyncLoading<RingSyncDataset?>();
    try {
      await repository.deleteAll();
      state = const AsyncData<RingSyncDataset?>(null);
    } catch (error, stackTrace) {
      state = AsyncError<RingSyncDataset?>(error, stackTrace);
      rethrow;
    }
  }
}

final ringDataProvider =
    AsyncNotifierProvider<RingDataController, RingSyncDataset?>(
      RingDataController.new,
    );

enum RingPairingPhase {
  idle,
  scanning,
  found,
  connecting,
  connected,
  unavailable,
  failed,
}

class RingPairingState {
  const RingPairingState({
    this.phase = RingPairingPhase.idle,
    this.candidates = const <RingPairingCandidate>[],
    this.selected,
    this.evidence,
    this.message,
    this.metadata,
    this.metadataCaptureInProgress = false,
    this.metadataCaptureError,
    this.timeSync,
    this.timeSyncInProgress = false,
    this.timeSyncError,
    this.approvedSuite,
    this.approvedSuiteInProgress = false,
    this.approvedSuiteError,
    this.syncInProgress = false,
    this.syncError,
    this.lastSyncRecordCount,
    this.lastSyncedAtUtc,
  });

  final RingPairingPhase phase;
  final List<RingPairingCandidate> candidates;
  final RingPairingCandidate? selected;
  final RingPairingEvidence? evidence;
  final String? message;
  final RingMetadata? metadata;
  final bool metadataCaptureInProgress;
  final String? metadataCaptureError;
  final RingTimeSyncResult? timeSync;
  final bool timeSyncInProgress;
  final String? timeSyncError;
  final RingApprovedSuiteResult? approvedSuite;
  final bool approvedSuiteInProgress;
  final String? approvedSuiteError;
  final bool syncInProgress;
  final String? syncError;
  final int? lastSyncRecordCount;
  final DateTime? lastSyncedAtUtc;

  static const Object _unset = Object();

  RingPairingState copyWith({
    RingPairingPhase? phase,
    List<RingPairingCandidate>? candidates,
    Object? selected = _unset,
    Object? evidence = _unset,
    Object? message = _unset,
    Object? metadata = _unset,
    bool? metadataCaptureInProgress,
    Object? metadataCaptureError = _unset,
    Object? timeSync = _unset,
    bool? timeSyncInProgress,
    Object? timeSyncError = _unset,
    Object? approvedSuite = _unset,
    bool? approvedSuiteInProgress,
    Object? approvedSuiteError = _unset,
    bool? syncInProgress,
    Object? syncError = _unset,
    Object? lastSyncRecordCount = _unset,
    Object? lastSyncedAtUtc = _unset,
  }) => RingPairingState(
    phase: phase ?? this.phase,
    candidates: candidates ?? this.candidates,
    selected: identical(selected, _unset)
        ? this.selected
        : selected as RingPairingCandidate?,
    evidence: identical(evidence, _unset)
        ? this.evidence
        : evidence as RingPairingEvidence?,
    message: identical(message, _unset) ? this.message : message as String?,
    metadata: identical(metadata, _unset)
        ? this.metadata
        : metadata as RingMetadata?,
    metadataCaptureInProgress:
        metadataCaptureInProgress ?? this.metadataCaptureInProgress,
    metadataCaptureError: identical(metadataCaptureError, _unset)
        ? this.metadataCaptureError
        : metadataCaptureError as String?,
    timeSync: identical(timeSync, _unset)
        ? this.timeSync
        : timeSync as RingTimeSyncResult?,
    timeSyncInProgress: timeSyncInProgress ?? this.timeSyncInProgress,
    timeSyncError: identical(timeSyncError, _unset)
        ? this.timeSyncError
        : timeSyncError as String?,
    approvedSuite: identical(approvedSuite, _unset)
        ? this.approvedSuite
        : approvedSuite as RingApprovedSuiteResult?,
    approvedSuiteInProgress:
        approvedSuiteInProgress ?? this.approvedSuiteInProgress,
    approvedSuiteError: identical(approvedSuiteError, _unset)
        ? this.approvedSuiteError
        : approvedSuiteError as String?,
    syncInProgress: syncInProgress ?? this.syncInProgress,
    syncError: identical(syncError, _unset)
        ? this.syncError
        : syncError as String?,
    lastSyncRecordCount: identical(lastSyncRecordCount, _unset)
        ? this.lastSyncRecordCount
        : lastSyncRecordCount as int?,
    lastSyncedAtUtc: identical(lastSyncedAtUtc, _unset)
        ? this.lastSyncedAtUtc
        : lastSyncedAtUtc as DateTime?,
  );
}

class RingPairingController extends Notifier<RingPairingState> {
  static const _captureControl = MethodChannel('org.librering/capture-control');
  static const _discoveryTimeout = Duration(seconds: 12);
  StreamSubscription<RingPairingCandidate>? _scanSubscription;
  final Map<String, RingPairingCandidate> _candidates =
      <String, RingPairingCandidate>{};

  @override
  RingPairingState build() {
    final client = ref.watch(ringPairingClientProvider);
    ref.onDispose(() {
      unawaited(_scanSubscription?.cancel());
      if (client != null) unawaited(client.disconnect());
    });
    return const RingPairingState();
  }

  Future<void> scan() async {
    final client = ref.read(ringPairingClientProvider);
    if (client == null) {
      state = const RingPairingState(
        phase: RingPairingPhase.unavailable,
        message: 'Bluetooth is unavailable in this build.',
      );
      return;
    }

    await _scanSubscription?.cancel();
    _candidates.clear();
    state = const RingPairingState(
      phase: RingPairingPhase.scanning,
      message: 'Looking for a nearby COLMI R12…',
    );
    _scanSubscription = client
        .scan(timeout: _discoveryTimeout)
        .listen(
          _recordCandidate,
          onError: (Object _) {
            state = const RingPairingState(
              phase: RingPairingPhase.failed,
              message: 'The scan could not finish. Check Bluetooth permission and try again.',
            );
          },
          onDone: _finishScan,
        );
  }

  void _recordCandidate(RingPairingCandidate candidate) {
    _candidates[candidate.advertisement.deviceId] = candidate;
    final candidates = _sortedCandidates();
    final exactCandidates = candidates
        .where((candidate) => candidate.exact)
        .toList(growable: false);
    final selected = exactCandidates.length == 1
        ? exactCandidates.single
        : null;
    state = RingPairingState(
      phase: exactCandidates.isEmpty
          ? RingPairingPhase.scanning
          : RingPairingPhase.found,
      candidates: candidates,
      selected: selected,
      message: exactCandidates.isEmpty
          ? 'A QRing-family device is nearby, but its R12 identity is not confirmed.'
          : exactCandidates.length == 1
          ? '${selected!.advertisement.name} is ready to verify.'
          : '${exactCandidates.length} COLMI R12 rings were found. Choose one to verify.',
    );
  }

  void _finishScan() {
    if (state.phase == RingPairingPhase.failed) return;
    final candidates = _sortedCandidates();
    final exactCandidates = candidates
        .where((candidate) => candidate.exact)
        .toList(growable: false);
    if (exactCandidates.isNotEmpty) {
      final selected = exactCandidates.length == 1
          ? exactCandidates.single
          : null;
      state = RingPairingState(
        phase: RingPairingPhase.found,
        candidates: candidates,
        selected: selected,
        message: selected == null
            ? '${exactCandidates.length} COLMI R12 rings were found. Choose one to verify.'
            : '${selected.advertisement.name} is ready to verify.',
      );
      return;
    }
    state = RingPairingState(
      phase: RingPairingPhase.failed,
      candidates: candidates,
      message: candidates.isEmpty
          ? 'No COLMI R12 was found. If QRing is open, close it and try again.'
          : 'A QRing-family device was found, but it did not advertise an exact COLMI R12 identity.',
    );
  }

  List<RingPairingCandidate> _sortedCandidates() {
    final candidates = _candidates.values.toList(growable: false);
    candidates.sort((left, right) {
      if (left.exact != right.exact) return left.exact ? -1 : 1;
      return (right.advertisement.rssi ?? -999).compareTo(
        left.advertisement.rssi ?? -999,
      );
    });
    return candidates;
  }

  void selectCandidate(RingPairingCandidate candidate) {
    final current = _candidates[candidate.advertisement.deviceId];
    if (current == null || !current.exact) return;
    state = RingPairingState(
      phase: RingPairingPhase.found,
      candidates: state.candidates,
      selected: current,
      message: '${current.advertisement.name} is ready to verify.',
    );
  }

  Future<void> connect() async {
    final client = ref.read(ringPairingClientProvider);
    final candidate = state.selected;
    if (client == null || candidate == null) return;
    final scanSubscription = _scanSubscription;
    _scanSubscription = null;
    if (scanSubscription != null) unawaited(scanSubscription.cancel());
    state = RingPairingState(
      phase: RingPairingPhase.connecting,
      candidates: state.candidates,
      selected: candidate,
      message: 'Confirming the ring service profile…',
    );
    try {
      final evidence = await client.connect(candidate.advertisement);
      state = RingPairingState(
        phase: RingPairingPhase.connected,
        candidates: state.candidates,
        selected: candidate,
        evidence: evidence,
        message: 'Connected without sending health or settings commands.',
      );
    } catch (error) {
      unawaited(client.disconnect());
      state = RingPairingState(
        phase: RingPairingPhase.failed,
        candidates: state.candidates,
        selected: candidate,
        message: error is TimeoutException
            ? 'The ring did not connect in time. Close QRing and try again.'
            : 'The ring connection could not be verified. Close QRing and try again.',
      );
    }
  }

  Future<void> captureMetadata() async {
    if (!ref.read(isProtocolCaptureModeProvider)) return;
    final client = ref.read(ringPairingClientProvider);
    if (client == null || state.phase != RingPairingPhase.connected) return;
    final current = state;
    state = RingPairingState(
      phase: current.phase,
      candidates: current.candidates,
      selected: current.selected,
      evidence: current.evidence,
      message: current.message,
      metadata: current.metadata,
      metadataCaptureInProgress: true,
    );
    try {
      final metadata = await client.captureMetadata();
      state = RingPairingState(
        phase: current.phase,
        candidates: current.candidates,
        selected: current.selected,
        evidence: current.evidence,
        message: current.message,
        metadata: metadata,
      );
    } catch (_) {
      state = RingPairingState(
        phase: current.phase,
        candidates: current.candidates,
        selected: current.selected,
        evidence: current.evidence,
        message: current.message,
        metadata: current.metadata,
        metadataCaptureError:
            'Metadata capture failed safely. No further command was sent.',
      );
    }
  }

  Future<void> captureTimeSync() async {
    if (!ref.read(isProtocolCaptureModeProvider)) return;
    final client = ref.read(ringPairingClientProvider);
    if (client == null || state.phase != RingPairingPhase.connected) return;
    final current = state;
    state = RingPairingState(
      phase: current.phase,
      candidates: current.candidates,
      selected: current.selected,
      evidence: current.evidence,
      message: current.message,
      metadata: current.metadata,
      metadataCaptureError: current.metadataCaptureError,
      timeSync: current.timeSync,
      timeSyncInProgress: true,
    );
    try {
      final result = await client.captureTimeSync();
      state = RingPairingState(
        phase: current.phase,
        candidates: current.candidates,
        selected: current.selected,
        evidence: current.evidence,
        message: current.message,
        metadata: current.metadata,
        metadataCaptureError: current.metadataCaptureError,
        timeSync: result,
      );
    } catch (_) {
      state = RingPairingState(
        phase: current.phase,
        candidates: current.candidates,
        selected: current.selected,
        evidence: current.evidence,
        message: current.message,
        metadata: current.metadata,
        metadataCaptureError: current.metadataCaptureError,
        timeSync: current.timeSync,
        timeSyncError: 'Clock sync failed safely. No retry was attempted.',
      );
    }
  }

  Future<void> captureApprovedSuite() async {
    if (!ref.read(isProtocolCaptureModeProvider)) return;
    final client = ref.read(ringPairingClientProvider);
    if (client == null || state.phase != RingPairingPhase.connected) return;
    final current = state;
    state = RingPairingState(
      phase: current.phase,
      candidates: current.candidates,
      selected: current.selected,
      evidence: current.evidence,
      message: current.message,
      metadata: current.metadata,
      metadataCaptureError: current.metadataCaptureError,
      timeSync: current.timeSync,
      timeSyncError: current.timeSyncError,
      approvedSuite: current.approvedSuite,
      approvedSuiteInProgress: true,
    );
    try {
      unawaited(_setCaptureIdleTimer(disabled: true));
      final result = await client.captureApprovedSuite();
      final metadata = result.batteryLevel == null
          ? current.metadata
          : RingMetadata(
              batteryLevel: result.batteryLevel!,
              charging: result.charging ?? false,
              firmwareVersion: result.firmwareVersion,
            );
      state = RingPairingState(
        phase: current.phase,
        candidates: current.candidates,
        selected: current.selected,
        evidence: current.evidence,
        message: current.message,
        metadata: metadata,
        metadataCaptureError: current.metadataCaptureError,
        timeSync: current.timeSync,
        timeSyncError: current.timeSyncError,
        approvedSuite: result,
      );
    } catch (_) {
      state = RingPairingState(
        phase: current.phase,
        candidates: current.candidates,
        selected: current.selected,
        evidence: current.evidence,
        message: current.message,
        metadata: current.metadata,
        metadataCaptureError: current.metadataCaptureError,
        timeSync: current.timeSync,
        timeSyncError: current.timeSyncError,
        approvedSuite: current.approvedSuite,
        approvedSuiteError: 'The full capture stopped safely. No new raw capture file was written.',
      );
    } finally {
      unawaited(_setCaptureIdleTimer(disabled: false));
    }
  }

  Future<void> sync() async {
    if (ref.read(isProtocolCaptureModeProvider)) return;
    final client = ref.read(ringPairingClientProvider);
    if (client == null || state.syncInProgress) return;
    if (state.phase != RingPairingPhase.connected) {
      final candidate = state.selected;
      if (candidate == null) return;
      state = state.copyWith(
        syncInProgress: true,
        syncError: null,
        message: 'Reconnecting for a bounded read-only sync…',
      );
      try {
        final evidence = await client.connect(candidate.advertisement);
        state = state.copyWith(
          phase: RingPairingPhase.connected,
          evidence: evidence,
        );
      } catch (_) {
        state = state.copyWith(
          phase: RingPairingPhase.found,
          syncInProgress: false,
          syncError: 'The ring could not reconnect. Close QRing and try again.',
        );
        return;
      }
    }
    state = state.copyWith(syncInProgress: true, syncError: null);
    try {
      final dataset = await client.sync();
      final merged = await ref.read(ringDataProvider.notifier).merge(dataset);
      state = state.copyWith(
        syncInProgress: false,
        syncError: null,
        lastSyncRecordCount: merged.recordCount,
        lastSyncedAtUtc: merged.lastSyncedAtUtc,
        message: 'Ring history synced and stored locally.',
      );
    } catch (_) {
      state = state.copyWith(
        syncInProgress: false,
        syncError: 'Sync stopped safely. Existing local data was not replaced.',
      );
    } finally {
      try {
        await client.disconnect();
      } catch (_) {
        // A release error must not discard a completed local sync or escape
        // the button callback. The platform drops the link when the app exits.
      } finally {
        state = state.copyWith(
          phase: RingPairingPhase.found,
          syncInProgress: false,
        );
      }
    }
  }

  Future<void> quickSync() async {
    if (ref.read(isProtocolCaptureModeProvider)) return;
    final client = ref.read(ringPairingClientProvider);
    if (client == null || state.syncInProgress) return;

    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _candidates.clear();
    state = state.copyWith(
      phase: RingPairingPhase.scanning,
      candidates: const <RingPairingCandidate>[],
      selected: null,
      evidence: null,
      syncInProgress: true,
      syncError: null,
      message: 'Looking for your nearby R12…',
    );
    try {
      await _collectQuickSyncCandidates(client);
      var exact = _exactCandidates();
      if (exact.isEmpty) {
        state = state.copyWith(
          message: 'The ring is not visible yet. Trying once more…',
        );
        try {
          await client.disconnect();
        } catch (_) {
          // Releasing stale app-side state is best-effort before the retry.
        }
        _candidates.clear();
        await _collectQuickSyncCandidates(client);
        exact = _exactCandidates();
      }
      if (exact.length != 1) {
        final candidates = _sortedCandidates();
        state = state.copyWith(
          phase: RingPairingPhase.failed,
          candidates: candidates,
          syncInProgress: false,
          syncError: exact.isNotEmpty
              ? 'More than one R12 was found. Use device setup to choose one.'
              : candidates.isEmpty
              ? 'The R12 is connected elsewhere or is not advertising. Force-close QRing, wake the ring, and try again.'
              : 'A nearby QRing-family device was seen, but it did not advertise its R12 identity. Keep it close and try again.',
        );
        return;
      }

      final selected = exact.single;
      state = state.copyWith(
        phase: RingPairingPhase.connecting,
        candidates: _sortedCandidates(),
        selected: selected,
        message: 'Connecting for a private local sync…',
      );
      final evidence = await client.connect(selected.advertisement);
      state = state.copyWith(
        phase: RingPairingPhase.connected,
        evidence: evidence,
        syncInProgress: false,
      );
      await sync();
    } catch (_) {
      try {
        await client.disconnect();
      } catch (_) {
        // Connection release is best-effort after a failed quick sync.
      }
      state = state.copyWith(
        phase: RingPairingPhase.failed,
        syncInProgress: false,
        syncError:
            'The quick sync stopped safely. Existing local data was preserved.',
      );
    }
  }

  Future<void> _collectQuickSyncCandidates(RingPairingClient client) async {
    await for (final candidate in client.scan(timeout: _discoveryTimeout)) {
      _candidates[candidate.advertisement.deviceId] = candidate;
    }
  }

  List<RingPairingCandidate> _exactCandidates() => _candidates.values
      .where((candidate) => candidate.exact)
      .toList(growable: false);

  Future<void> _setCaptureIdleTimer({required bool disabled}) async {
    try {
      await _captureControl.invokeMethod<void>(
        'setIdleTimerDisabled',
        disabled,
      );
    } catch (_) {
      // Screen-awake control is best-effort and must never block BLE capture.
    }
  }
}

final ringPairingProvider =
    NotifierProvider<RingPairingController, RingPairingState>(
      RingPairingController.new,
    );

class PrivacySettings {
  const PrivacySettings({
    this.keepLocal = true,
    this.useAsContext = false,
    this.allowExport = false,
  });

  final bool keepLocal;
  final bool useAsContext;
  final bool allowExport;

  PrivacySettings copyWith({
    bool? keepLocal,
    bool? useAsContext,
    bool? allowExport,
  }) => PrivacySettings(
    keepLocal: keepLocal ?? this.keepLocal,
    useAsContext: useAsContext ?? this.useAsContext,
    allowExport: allowExport ?? this.allowExport,
  );
}

class PrivacyController extends Notifier<PrivacySettings> {
  @override
  PrivacySettings build() => const PrivacySettings();

  void setKeepLocal(bool value) => state = state.copyWith(
    keepLocal: value,
    useAsContext: value ? null : false,
    allowExport: value ? null : false,
  );

  void setUseAsContext(bool value) {
    if (state.keepLocal) state = state.copyWith(useAsContext: value);
  }

  void setAllowExport(bool value) {
    if (state.keepLocal) state = state.copyWith(allowExport: value);
  }
}

final privacySettingsProvider =
    NotifierProvider<PrivacyController, PrivacySettings>(PrivacyController.new);

class SwimEntryController extends Notifier<SwimEntry?> {
  @override
  SwimEntry? build() => null;

  void save({
    required int durationMinutes,
    required String poolLength,
    required String effort,
  }) {
    state = SwimEntry(
      durationMinutes: durationMinutes,
      poolLength: poolLength,
      effort: effort,
      origin: DataOrigin.manual,
    );
  }
}

final swimEntryProvider = NotifierProvider<SwimEntryController, SwimEntry?>(
  SwimEntryController.new,
);
