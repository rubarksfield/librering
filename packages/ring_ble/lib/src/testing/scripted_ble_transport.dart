import 'dart:async';

import 'package:ring_core/ring_core.dart';

import '../transport.dart';

/// Deterministic BLE transport used by integration tests and demo harnesses.
///
/// This transport models connection timing and lifecycle only. Protocol payloads
/// must still come from explicitly supplied fixtures; it never invents command
/// or response bytes.
class ScriptedBleTransport implements RingBleTransport {
  ScriptedBleTransport({
    this.services = const <BleService>[],
    this.advertisements = const <RingAdvertisement>[],
    this.connectionDelay = Duration.zero,
    this.connectionFailure,
  });

  final List<BleService> services;
  final List<RingAdvertisement> advertisements;
  final Duration connectionDelay;
  final Object? connectionFailure;

  final List<List<int>> writes = <List<int>>[];
  final StreamController<BleConnectionState> _connections =
      StreamController<BleConnectionState>.broadcast();
  final Map<String, StreamController<List<int>>> _notifications =
      <String, StreamController<List<int>>>{};

  int connectCalls = 0;
  int disconnectCalls = 0;

  @override
  Stream<BleConnectionState> get connectionStates => _connections.stream;

  @override
  Stream<RingAdvertisement> scan({required Duration timeout}) =>
      Stream<RingAdvertisement>.fromIterable(advertisements);

  @override
  Future<void> connect(String deviceId, {required Duration timeout}) async {
    connectCalls++;
    _connections.add(BleConnectionState.connecting);

    if (connectionDelay > timeout) {
      await Future<void>.delayed(timeout);
      _connections.add(BleConnectionState.disconnected);
      throw TimeoutException('BLE connection timed out.', timeout);
    }
    if (connectionDelay > Duration.zero) {
      await Future<void>.delayed(connectionDelay);
    }
    if (connectionFailure case final Object error) {
      _connections.add(BleConnectionState.disconnected);
      throw error;
    }
    _connections.add(BleConnectionState.connected);
  }

  @override
  Future<List<BleService>> discoverServices() async =>
      List<BleService>.unmodifiable(services);

  @override
  Stream<List<int>> subscribe({
    required String serviceUuid,
    required String characteristicUuid,
  }) => _notifications
      .putIfAbsent(
        _key(serviceUuid, characteristicUuid),
        () => StreamController<List<int>>.broadcast(),
      )
      .stream;

  void emitNotification({
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
  }) {
    _notifications
        .putIfAbsent(
          _key(serviceUuid, characteristicUuid),
          () => StreamController<List<int>>.broadcast(),
        )
        .add(List<int>.unmodifiable(value));
  }

  void interrupt() {
    _connections.add(BleConnectionState.disconnecting);
    _connections.add(BleConnectionState.disconnected);
  }

  @override
  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
    required bool withResponse,
  }) async {
    writes.add(List<int>.unmodifiable(value));
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    _connections.add(BleConnectionState.disconnecting);
    _connections.add(BleConnectionState.disconnected);
  }

  Future<void> dispose() async {
    await _connections.close();
    for (final controller in _notifications.values) {
      await controller.close();
    }
  }

  static String _key(String serviceUuid, String characteristicUuid) =>
      '${serviceUuid.toLowerCase()}/${characteristicUuid.toLowerCase()}';
}
