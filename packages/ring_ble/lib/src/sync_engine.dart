enum SyncPhase {
  idle,
  scanning,
  connecting,
  discovering,
  identifying,
  readingMetadata,
  syncingBattery,
  syncingActivity,
  syncingHeartRate,
  syncingSleep,
  syncingOxygen,
  syncingAdditional,
  normalising,
  persisting,
  exporting,
  completed,
  partiallyCompleted,
  failed,
  cancelled,
}

class SyncTransitionException implements Exception {
  const SyncTransitionException(this.from, this.to);

  final SyncPhase from;
  final SyncPhase to;

  @override
  String toString() => 'Illegal sync transition: ${from.name} -> ${to.name}';
}

class SyncStateMachine {
  SyncPhase _phase = SyncPhase.idle;
  final List<SyncPhase> _history = <SyncPhase>[SyncPhase.idle];

  SyncPhase get phase => _phase;
  List<SyncPhase> get history => List<SyncPhase>.unmodifiable(_history);

  static const _terminal = <SyncPhase>{
    SyncPhase.completed,
    SyncPhase.partiallyCompleted,
    SyncPhase.failed,
    SyncPhase.cancelled,
  };

  static const _order = <SyncPhase>[
    SyncPhase.idle,
    SyncPhase.scanning,
    SyncPhase.connecting,
    SyncPhase.discovering,
    SyncPhase.identifying,
    SyncPhase.readingMetadata,
    SyncPhase.syncingBattery,
    SyncPhase.syncingActivity,
    SyncPhase.syncingHeartRate,
    SyncPhase.syncingSleep,
    SyncPhase.syncingOxygen,
    SyncPhase.syncingAdditional,
    SyncPhase.normalising,
    SyncPhase.persisting,
    SyncPhase.exporting,
    SyncPhase.completed,
  ];

  void transition(SyncPhase next) {
    if (_terminal.contains(_phase)) throw SyncTransitionException(_phase, next);
    if (next == SyncPhase.completed) {
      if (_phase != SyncPhase.exporting) {
        throw SyncTransitionException(_phase, next);
      }
      _record(next);
      return;
    }
    if (_terminal.contains(next) && _phase != SyncPhase.idle) {
      _record(next);
      return;
    }
    final currentIndex = _order.indexOf(_phase);
    final nextIndex = _order.indexOf(next);
    if (currentIndex < 0 || nextIndex <= currentIndex) {
      throw SyncTransitionException(_phase, next);
    }
    _record(next);
  }

  void _record(SyncPhase next) {
    _phase = next;
    _history.add(next);
  }
}

class RetryPolicy {
  const RetryPolicy({this.maxAttempts = 3});

  final int maxAttempts;

  Future<T> run<T>(
    Future<T> Function(int attempt) operation, {
    required bool Function(Object error) isRetryable,
    Future<void> Function(int attempt)? beforeRetry,
  }) async {
    if (maxAttempts < 1) throw ArgumentError.value(maxAttempts, 'maxAttempts');
    Object? lastError;
    StackTrace? lastStack;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation(attempt);
      } catch (error, stack) {
        lastError = error;
        lastStack = stack;
        if (attempt == maxAttempts || !isRetryable(error)) rethrow;
        await beforeRetry?.call(attempt);
      }
    }
    Error.throwWithStackTrace(lastError!, lastStack!);
  }
}

class PacketDeduplicator {
  factory PacketDeduplicator({int capacity = 256}) {
    if (capacity < 1) throw ArgumentError.value(capacity, 'capacity');
    return PacketDeduplicator._(capacity);
  }

  PacketDeduplicator._(this.capacity);

  final int capacity;
  final Set<String> _seen = <String>{};
  final List<String> _order = <String>[];

  bool add(List<int> bytes) {
    for (var index = 0; index < bytes.length; index++) {
      final value = bytes[index];
      if (value < 0 || value > 255) {
        throw ArgumentError.value(value, 'bytes[$index]', 'Not a byte');
      }
    }
    final key = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    if (!_seen.add(key)) return false;
    _order.add(key);
    if (_order.length > capacity) _seen.remove(_order.removeAt(0));
    return true;
  }
}
