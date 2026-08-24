import 'dart:async';

import 'package:ring_ble/ring_ble.dart';
import 'package:ring_ble/ring_ble_testing.dart';
import 'package:test/test.dart';

void main() {
  test('slow connections respect the caller timeout', () async {
    final transport = ScriptedBleTransport(
      connectionDelay: const Duration(milliseconds: 20),
    );
    addTearDown(transport.dispose);
    final states = <BleConnectionState>[];
    final subscription = transport.connectionStates.listen(states.add);
    addTearDown(subscription.cancel);

    await expectLater(
      transport.connect('ring', timeout: const Duration(milliseconds: 1)),
      throwsA(isA<TimeoutException>()),
    );
    await pumpEventQueue();
    expect(states.last, BleConnectionState.disconnected);
  });

  test('failed connections are visible and never become connected', () async {
    final transport = ScriptedBleTransport(
      connectionFailure: StateError('adapter unavailable'),
    );
    addTearDown(transport.dispose);
    final states = <BleConnectionState>[];
    final subscription = transport.connectionStates.listen(states.add);
    addTearDown(subscription.cancel);

    await expectLater(
      transport.connect('ring', timeout: const Duration(seconds: 1)),
      throwsStateError,
    );
    await pumpEventQueue();

    expect(states, <BleConnectionState>[
      BleConnectionState.connecting,
      BleConnectionState.disconnected,
    ]);
  });

  test(
    'an interruption can be followed by a bounded foreground reconnect',
    () async {
      final transport = ScriptedBleTransport();
      addTearDown(transport.dispose);
      final states = <BleConnectionState>[];
      final subscription = transport.connectionStates.listen(states.add);
      addTearDown(subscription.cancel);

      await transport.connect('ring', timeout: const Duration(seconds: 1));
      transport.interrupt();
      await transport.connect('ring', timeout: const Duration(seconds: 1));
      await pumpEventQueue();

      expect(transport.connectCalls, 2);
      expect(states, <BleConnectionState>[
        BleConnectionState.connecting,
        BleConnectionState.connected,
        BleConnectionState.disconnecting,
        BleConnectionState.disconnected,
        BleConnectionState.connecting,
        BleConnectionState.connected,
      ]);
    },
  );

  test(
    'protocol notifications are fixture supplied and defensively copied',
    () async {
      final transport = ScriptedBleTransport();
      addTearDown(transport.dispose);
      final received = <List<int>>[];
      final subscription = transport
          .subscribe(serviceUuid: 'service', characteristicUuid: 'notify')
          .listen(received.add);
      addTearDown(subscription.cancel);
      final fixture = <int>[1, 2, 3];

      transport.emitNotification(
        serviceUuid: 'SERVICE',
        characteristicUuid: 'NOTIFY',
        value: fixture,
      );
      fixture[0] = 9;
      await pumpEventQueue();

      expect(received, <List<int>>[
        <int>[1, 2, 3],
      ]);
    },
  );
}
