import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:ring_core/ring_core.dart';

import 'ble/r12_pairing_client.dart';
import 'storage/data_export_service.dart';
import 'storage/journal_repository.dart';
import 'storage/preferences_repository.dart';
import 'storage/ring_data_repository.dart';

final isDemoModeProvider = Provider<bool>((Ref ref) => false);
final isProtocolCaptureModeProvider = Provider<bool>((Ref ref) => false);
final currentLocalTimeProvider = Provider<DateTime>((Ref ref) {
  final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return DateTime.now();
});
final dailySnapshotProvider = Provider<DailySnapshot?>((Ref ref) => null);
final ringPairingClientProvider = Provider<RingPairingClient?>(
  (Ref ref) => null,
);
final ringDataRepositoryProvider = Provider<RingDataRepository?>(
  (Ref ref) => null,
);
final journalRepositoryProvider = Provider<JournalRepository?>(
  (Ref ref) => null,
);
final dataExportServiceProvider = Provider<DataExportService?>(
  (Ref ref) => null,
);
final preferencesRepositoryProvider = Provider<PreferencesRepository?>(
  (Ref ref) => null,
);

class _OperationQueue {
  Future<void> _tail = Future<void>.value();

  Future<void> get whenIdle => _tail;

  Future<T> run<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}

class AppPreferencesController extends AsyncNotifier<AppPreferences> {
  final _operations = _OperationQueue();
  late Future<AppPreferences> _initialRead;

  @override
  Future<AppPreferences> build() {
    _initialRead =
        ref.watch(preferencesRepositoryProvider)?.read() ??
        Future<AppPreferences>.value(const AppPreferences());
    return _initialRead;
  }

  Future<void> save(AppPreferences preferences) => _operations.run(() async {
    await _initialRead;
    preferences.validate();
    final previous = state;
    if (!previous.hasValue) state = const AsyncLoading<AppPreferences>();
    try {
      final clean = preferences.copyWith(
        displayName: preferences.displayName.trim(),
      );
      await ref.read(preferencesRepositoryProvider)?.save(clean);
      state = AsyncData<AppPreferences>(clean);
    } catch (error, stackTrace) {
      state = previous.hasValue
          ? previous
          : AsyncError<AppPreferences>(error, stackTrace);
      rethrow;
    }
  });
}

final appPreferencesProvider =
    AsyncNotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
      retry: (_, _) => null,
    );

class RingDataController extends AsyncNotifier<RingSyncDataset?> {
  final _operations = _OperationQueue();
  late Future<RingSyncDataset?> _initialRead;

  Future<void> get whenIdle => _operations.whenIdle;

  @override
  Future<RingSyncDataset?> build() {
    _initialRead =
        ref.watch(ringDataRepositoryProvider)?.read() ??
        Future<RingSyncDataset?>.value(null);
    return _initialRead;
  }

  Future<RingSyncDataset> merge(RingSyncDataset incoming) =>
      _operations.run(() async {
        await _initialRead;
        final repository = ref.read(ringDataRepositoryProvider);
        if (repository == null) {
          throw StateError('Local ring storage is unavailable in this build.');
        }
        final previous = state;
        if (!previous.hasValue) state = const AsyncLoading<RingSyncDataset?>();
        try {
          final merged = await repository.merge(incoming);
          state = AsyncData<RingSyncDataset?>(merged);
          return merged;
        } catch (error, stackTrace) {
          state = previous.hasValue
              ? previous
              : AsyncError<RingSyncDataset?>(error, stackTrace);
          rethrow;
        }
      });

  Future<void> deleteAll() => _operations.run(() async {
    try {
      await _initialRead;
    } catch (_) {
      // Explicit deletion is allowed even when an existing store is unreadable.
      // Wait for that read to finish so it cannot later restore stale UI state.
    }
    final repository = ref.read(ringDataRepositoryProvider);
    if (repository == null) return;
    final previous = state;
    if (!previous.hasValue) state = const AsyncLoading<RingSyncDataset?>();
    try {
      await repository.deleteAll();
      // A successfully removed corrupt store must not keep blocking new syncs.
      _initialRead = Future<RingSyncDataset?>.value(null);
      state = const AsyncData<RingSyncDataset?>(null);
    } catch (error, stackTrace) {
      state = previous.hasValue
          ? previous
          : AsyncError<RingSyncDataset?>(error, stackTrace);
      rethrow;
    }
  });
}

final ringDataProvider =
    AsyncNotifierProvider<RingDataController, RingSyncDataset?>(
      RingDataController.new,
      retry: (_, _) => null,
    );

class JournalController extends AsyncNotifier<List<JournalEntry>> {
  final _operations = _OperationQueue();
  late Future<List<JournalEntry>> _initialRead;

  Future<void> get whenIdle => _operations.whenIdle;

  @override
  Future<List<JournalEntry>> build() {
    _initialRead =
        ref.watch(journalRepositoryProvider)?.read() ??
        Future<List<JournalEntry>>.value(const <JournalEntry>[]);
    return _initialRead;
  }

  Future<T> _mutate<T>(Future<(T, List<JournalEntry>)> Function() operation) =>
      _operations.run(() async {
        await _initialRead;
        final previous = state;
        if (!previous.hasValue) {
          state = const AsyncLoading<List<JournalEntry>>();
        }
        try {
          final result = await operation();
          state = AsyncData<List<JournalEntry>>(result.$2);
          return result.$1;
        } catch (error, stackTrace) {
          state = previous.hasValue
              ? previous
              : AsyncError<List<JournalEntry>>(error, stackTrace);
          rethrow;
        }
      });

  Future<JournalEntry> saveSwim({
    required int durationMinutes,
    required String environment,
    required String effort,
    DateTime? occurredAtUtc,
  }) => _mutate(() async {
    if (durationMinutes < 1 || durationMinutes > 1440) {
      throw ArgumentError('A duration must be between 1 and 1,440 minutes.');
    }
    final repository = ref.read(journalRepositoryProvider);
    final occurred = (occurredAtUtc ?? DateTime.now()).toUtc();
    final entry = JournalEntry(
      id: 'swim|${occurred.toIso8601String()}',
      kind: JournalEntryKind.swim,
      occurredAtUtc: occurred,
      title: environment == 'Open water' ? 'Open-water swim' : 'Pool swim',
      details: '$durationMinutes minutes · $effort effort',
      durationMinutes: durationMinutes,
      environment: environment,
      effort: effort,
    );
    if (repository == null) {
      return (
        entry,
        <JournalEntry>[entry, ...state.value ?? const <JournalEntry>[]],
      );
    }
    return (entry, await repository.upsert(entry));
  });

  Future<JournalEntry> saveCheckIn({
    required List<String> tags,
    required String note,
    DateTime? occurredAtUtc,
  }) => _mutate(() async {
    if (tags.isEmpty && note.trim().isEmpty) {
      throw ArgumentError('A check-in needs a tag or note.');
    }
    final repository = ref.read(journalRepositoryProvider);
    final occurred = (occurredAtUtc ?? DateTime.now()).toUtc();
    final cleanTags = tags.toSet().toList(growable: false)..sort();
    final cleanNote = note.trim();
    final entry = JournalEntry(
      id: 'checkIn|${occurred.toIso8601String()}',
      kind: JournalEntryKind.checkIn,
      occurredAtUtc: occurred,
      title: cleanTags.isEmpty ? 'Note' : cleanTags.join(' · '),
      details: cleanNote.isEmpty ? 'No note' : cleanNote,
    );
    if (repository == null) {
      return (
        entry,
        <JournalEntry>[entry, ...state.value ?? const <JournalEntry>[]],
      );
    }
    return (entry, await repository.upsert(entry));
  });

  Future<void> delete(String id) async {
    await _mutate(() async {
      final repository = ref.read(journalRepositoryProvider);
      if (repository == null) {
        return (
          true,
          (state.value ?? const <JournalEntry>[])
              .where((entry) => entry.id != id)
              .toList(growable: false),
        );
      }
      return (true, await repository.delete(id));
    });
  }

  Future<void> deleteAll() => _operations.run(() async {
    try {
      await _initialRead;
    } catch (_) {
      // A user-confirmed reset may remove an unreadable journal, but must wait
      // for its initial read to settle before publishing the empty state.
    }
    final previous = state;
    try {
      await ref.read(journalRepositoryProvider)?.deleteAll();
      _initialRead = Future<List<JournalEntry>>.value(const <JournalEntry>[]);
      state = const AsyncData<List<JournalEntry>>(<JournalEntry>[]);
    } catch (_) {
      state = previous;
      rethrow;
    }
  });
}

final journalProvider =
    AsyncNotifierProvider<JournalController, List<JournalEntry>>(
      JournalController.new,
      retry: (_, _) => null,
    );

class DataExportController extends AsyncNotifier<LocalExportResult?> {
  final _operations = _OperationQueue();
  @override
  Future<LocalExportResult?> build() async => null;

  Future<LocalExportResult> create() => _operations.run(() async {
    final service = ref.read(dataExportServiceProvider);
    state = const AsyncLoading<LocalExportResult?>();
    try {
      await ref.read(ringDataProvider.notifier).whenIdle;
      await ref.read(journalProvider.notifier).whenIdle;
      final dataset = await ref.read(ringDataProvider.future);
      final journal = await ref.read(journalProvider.future);
      if (service == null || dataset == null) {
        throw StateError('Local export requires stored ring data.');
      }
      final result = await service.create(dataset: dataset, journal: journal);
      state = AsyncData<LocalExportResult?>(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError<LocalExportResult?>(error, stackTrace);
      rethrow;
    }
  });
}

final dataExportProvider =
    AsyncNotifierProvider<DataExportController, LocalExportResult?>(
      DataExportController.new,
      retry: (_, _) => null,
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
  bool _syncInFlight = false;
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
    if (_syncInFlight) return;
    final client = ref.read(ringPairingClientProvider);
    if (client == null) {
      state = const RingPairingState(
        phase: RingPairingPhase.unavailable,
        message: 'Bluetooth is unavailable in this build.',
      );
      return;
    }

    await _scanSubscription?.cancel();
    if (!ref.mounted || _syncInFlight) return;
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
            if (!ref.mounted || _syncInFlight) return;
            state = const RingPairingState(
              phase: RingPairingPhase.failed,
              message: 'The scan could not finish. Check Bluetooth permission and try again.',
            );
          },
          onDone: _finishScan,
        );
  }

  void _recordCandidate(RingPairingCandidate candidate) {
    if (!ref.mounted || _syncInFlight) return;
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
    if (!ref.mounted || _syncInFlight) return;
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
    if (_syncInFlight) return;
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
    if (_syncInFlight) return;
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
    if (client == null || _syncInFlight || state.syncInProgress) return;
    final candidate = state.selected;
    if (state.phase != RingPairingPhase.connected && candidate == null) return;
    // Acquire synchronously and hold through disconnect, including failures.
    _syncInFlight = true;
    state = state.copyWith(syncInProgress: true, syncError: null);
    try {
      if (state.phase != RingPairingPhase.connected) {
        state = state.copyWith(
          message: 'Reconnecting for a bounded read-only sync…',
        );
        final evidence = await client.connect(candidate!.advertisement);
        if (!ref.mounted) return;
        state = state.copyWith(
          phase: RingPairingPhase.connected,
          evidence: evidence,
        );
      }
      await _syncAndStore(client);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        syncError: 'Sync stopped safely. Existing local data was not replaced.',
      );
    } finally {
      await _releaseSync(client);
    }
  }

  Future<void> quickSync() async {
    if (ref.read(isProtocolCaptureModeProvider)) return;
    final client = ref.read(ringPairingClientProvider);
    if (client == null || _syncInFlight || state.syncInProgress) return;

    _syncInFlight = true;
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
      await _scanSubscription?.cancel();
      if (!ref.mounted) return;
      _scanSubscription = null;
      _candidates.clear();
      await _collectQuickSyncCandidates(client);
      if (!ref.mounted) return;
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
        if (!ref.mounted) return;
        exact = _exactCandidates();
      }
      if (exact.length != 1) {
        final candidates = _sortedCandidates();
        state = state.copyWith(
          phase: RingPairingPhase.failed,
          candidates: candidates,
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
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: RingPairingPhase.connected,
        evidence: evidence,
      );
      await _syncAndStore(client);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: RingPairingPhase.failed,
        syncError:
            'The quick sync stopped safely. Existing local data was preserved.',
      );
    } finally {
      await _releaseSync(client);
    }
  }

  Future<void> _syncAndStore(RingPairingClient client) async {
    final dataset = await client.sync();
    if (!ref.mounted) return;
    final merged = await ref.read(ringDataProvider.notifier).merge(dataset);
    if (!ref.mounted) return;
    final incomplete = dataset.availability.values.any(
      (status) =>
          status == RingDataAvailability.partial ||
          status == RingDataAvailability.error,
    );
    state = state.copyWith(
      syncError: incomplete
          ? 'Some ring data could not be read. Available records were saved; try syncing again.'
          : null,
      lastSyncRecordCount: merged.recordCount,
      lastSyncedAtUtc: merged.lastSyncedAtUtc,
      message: incomplete
          ? 'Available ring history saved locally. Some sections need another sync.'
          : 'Ring history synced and stored locally.',
    );
  }

  Future<void> _releaseSync(RingPairingClient client) async {
    try {
      await client.disconnect();
    } catch (_) {
      // Release is best-effort, but it must finish before another sync starts.
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          phase: state.phase == RingPairingPhase.failed
              ? RingPairingPhase.failed
              : RingPairingPhase.found,
          syncInProgress: false,
        );
      }
      _syncInFlight = false;
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
    this.keepLocal = false,
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

  // Cycle capture, consent, and export are not implemented. Do not grant a
  // transient consent state that has no persistent enforcement behind it.
  void setKeepLocal(bool value) => state = const PrivacySettings();

  void setUseAsContext(bool value) => state = const PrivacySettings();

  void setAllowExport(bool value) => state = const PrivacySettings();
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
