import 'package:flutter/services.dart';

/// Small tactile cues for accepted user interactions, never background work.
///
/// The operating system decides whether the device can deliver the effect and
/// applies its haptic settings. Reduce Motion concerns animation rather than
/// touch feedback, so it is not treated as a haptic preference.
abstract final class RingHaptics {
  static Future<void> selection({bool enabled = true}) =>
      _emit(HapticFeedback.selectionClick, enabled: enabled);

  static Future<void> action({bool enabled = true}) =>
      _emit(HapticFeedback.lightImpact, enabled: enabled);

  /// A single restrained acknowledgement, not a repeating notification pattern.
  static Future<void> success({bool enabled = true}) =>
      _emit(HapticFeedback.lightImpact, enabled: enabled);

  static Future<void> error({bool enabled = true}) =>
      _emit(HapticFeedback.mediumImpact, enabled: enabled);

  static Future<void> _emit(
    Future<void> Function() effect, {
    required bool enabled,
  }) async {
    if (!enabled) return;
    try {
      await effect();
    } on MissingPluginException {
      // A desktop, web, or test host may have no haptic implementation.
    } on PlatformException {
      // Optional tactile feedback must never interrupt the user's action.
    }
  }
}

/// One instance per chart interaction surface; keep it in State, not build().
///
/// Only changed selection keys can tick, at most once per [minimumInterval].
/// Suppressed ticks are discarded rather than queued for later playback.
class RingSelectionHaptics {
  RingSelectionHaptics({
    this.minimumInterval = const Duration(milliseconds: 100),
    this.elapsed,
  }) : assert(!minimumInterval.isNegative);

  final Duration minimumInterval;

  /// Optional monotonic clock for deterministic verification.
  final Duration Function()? elapsed;
  final Stopwatch _clock = Stopwatch()..start();
  Object? _lastSelection;
  bool _hasSelection = false;
  Duration? _lastEffectAt;

  Future<void> selection(Object key, {bool enabled = true}) async {
    if (!enabled || (_hasSelection && key == _lastSelection)) return;
    _hasSelection = true;
    _lastSelection = key;
    final now = elapsed?.call() ?? _clock.elapsed;
    if (_lastEffectAt != null && now - _lastEffectAt! < minimumInterval) return;
    _lastEffectAt = now;
    await RingHaptics.selection();
  }

  /// Permit the same point in a new gesture, retaining the rate limit.
  void reset() {
    _lastSelection = null;
    _hasSelection = false;
  }
}
