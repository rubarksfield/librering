import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:ring_core/ring_core.dart';

import 'ble/r12_pairing_client.dart';

final isDemoModeProvider = Provider<bool>((Ref ref) => false);
final isProtocolCaptureModeProvider = Provider<bool>((Ref ref) => false);
final dailySnapshotProvider = Provider<DailySnapshot?>((Ref ref) => null);
final ringPairingClientProvider = Provider<RingPairingClient?>(
  (Ref ref) => null,
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
}

class RingPairingController extends Notifier<RingPairingState> {
  static const _captureControl = MethodChannel('org.librering/capture-control');
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
        .scan(timeout: const Duration(seconds: 12))
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
