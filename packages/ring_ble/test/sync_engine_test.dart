import 'package:ring_ble/ring_ble.dart';
import 'package:test/test.dart';

void main() {
  test('sync phases advance in durable order', () {
    final machine = SyncStateMachine();
    for (final phase in SyncPhase.values.sublist(1, 16)) {
      machine.transition(phase);
    }
    expect(machine.phase, SyncPhase.completed);
    expect(machine.history.first, SyncPhase.idle);
    expect(machine.history.last, SyncPhase.completed);
  });

  test('sync can end partial but cannot leave a terminal state', () {
    final machine = SyncStateMachine()..transition(SyncPhase.scanning);
    machine.transition(SyncPhase.partiallyCompleted);
    expect(
      () => machine.transition(SyncPhase.connecting),
      throwsA(isA<SyncTransitionException>()),
    );
  });

  test('unused sync domains may be skipped but phases never run backwards', () {
    final machine = SyncStateMachine()
      ..transition(SyncPhase.connecting)
      ..transition(SyncPhase.discovering)
      ..transition(SyncPhase.normalising);
    expect(
      () => machine.transition(SyncPhase.syncingBattery),
      throwsA(isA<SyncTransitionException>()),
    );
  });

  test('completed is valid only after export', () {
    final machine = SyncStateMachine()..transition(SyncPhase.scanning);
    expect(
      () => machine.transition(SyncPhase.completed),
      throwsA(isA<SyncTransitionException>()),
    );
  });

  test('bounded retry succeeds without exceeding its cap', () async {
    var calls = 0;
    final result = await const RetryPolicy(maxAttempts: 3)
        .run<String>((attempt) async {
          calls++;
          if (attempt < 3) throw const _Retryable();
          return 'ok';
        }, isRetryable: (error) => error is _Retryable);
    expect(result, 'ok');
    expect(calls, 3);
  });

  test('packet deduplicator is bounded and idempotent', () {
    final deduplicator = PacketDeduplicator(capacity: 2);
    expect(deduplicator.add(<int>[1]), isTrue);
    expect(deduplicator.add(<int>[1]), isFalse);
    expect(deduplicator.add(<int>[2]), isTrue);
    expect(deduplicator.add(<int>[3]), isTrue);
    expect(deduplicator.add(<int>[1]), isTrue);
  });

  test('packet deduplicator rejects a non-positive bound', () {
    expect(() => PacketDeduplicator(capacity: 0), throwsArgumentError);
  });

  test('packet deduplicator rejects values outside a byte', () {
    final deduplicator = PacketDeduplicator();
    expect(() => deduplicator.add(<int>[-1]), throwsArgumentError);
    expect(() => deduplicator.add(<int>[256]), throwsArgumentError);
  });
}

class _Retryable implements Exception {
  const _Retryable();
}
