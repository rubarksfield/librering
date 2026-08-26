import 'dart:async';
import 'dart:convert';

import 'package:ring_ble/ring_ble.dart';
import 'package:ring_core/ring_core.dart';

import 'approved_capture.dart';
import 'battery.dart';
import 'big_data_history.dart' as r12_big;
import 'history.dart' as r12_history;
import 'metadata.dart';
import 'packet.dart';
import 'profile.dart';
import 'time_sync.dart';

class UnsupportedFirmwareException implements Exception {
  const UnsupportedFirmwareException(this.message);

  final String message;

  @override
  String toString() => 'UnsupportedFirmwareException: $message';
}

class ColmiQringDriver implements RingDriver {
  ColmiQringDriver(this.transport);

  static const Set<String> physicallyVerifiedFirmwareVersions = <String>{
    'RT11CR_1.00.09_260424',
  };

  final RingBleTransport transport;
  StreamSubscription<List<int>>? _commandNotificationSubscription;
  StreamSubscription<List<int>>? _bigDataNotificationSubscription;
  final StreamController<List<int>> _commandNotifications =
      StreamController<List<int>>.broadcast(sync: true);
  final StreamController<List<int>> _bigDataNotifications =
      StreamController<List<int>>.broadcast(sync: true);
  RingConnection? _connection;

  @override
  String get driverId => 'colmi-qring-v1';

  @override
  String get displayName => 'COLMI QRing family';

  @override
  bool matchesAdvertisement(RingAdvertisement advertisement) =>
      ColmiQringProfile.isR12Advertisement(advertisement);

  @override
  Future<RingConnection> connect(RingPeripheral peripheral) async {
    await transport.connect(
      peripheral.deviceId,
      timeout: const Duration(seconds: 12),
    );
    try {
      final services = await transport.discoverServices();
      final validation = ColmiQringProfile.validateServices(services);
      if (!validation.isSupported) {
        throw UnsupportedFirmwareException(validation.reason!);
      }
      await _commandNotificationSubscription?.cancel();
      await _bigDataNotificationSubscription?.cancel();
      _commandNotificationSubscription = transport
          .subscribe(
            serviceUuid: ColmiQringProfile.commandService,
            characteristicUuid: ColmiQringProfile.commandNotify,
          )
          .listen(
            (packet) => _commandNotifications.add(List<int>.of(packet)),
            onError: (Object error) => unawaited(transport.disconnect()),
          );
      _bigDataNotificationSubscription = validation.supportsBigData
          ? transport
                .subscribe(
                  serviceUuid: ColmiQringProfile.bigDataService,
                  characteristicUuid: ColmiQringProfile.bigDataNotify,
                )
                .listen(
                  (packet) => _bigDataNotifications.add(List<int>.of(packet)),
                  onError: (Object error) => unawaited(transport.disconnect()),
                )
          : null;
      final connection = RingConnection(
        peripheral: peripheral,
        services: services,
      );
      _connection = connection;
      return connection;
    } catch (_) {
      await _commandNotificationSubscription?.cancel();
      await _bigDataNotificationSubscription?.cancel();
      _commandNotificationSubscription = null;
      _bigDataNotificationSubscription = null;
      await transport.disconnect();
      rethrow;
    }
  }

  @override
  Future<DeviceCapabilities> discoverCapabilities(
    RingConnection connection,
  ) async {
    final validation = ColmiQringProfile.validateServices(connection.services);
    if (!validation.isSupported) {
      throw UnsupportedFirmwareException(validation.reason!);
    }
    final confidence = CapabilityConfidence.familyCorroborated;
    return DeviceCapabilities(<DeviceCapability, CapabilityConfidence>{
      DeviceCapability.battery: confidence,
      DeviceCapability.charging: confidence,
      DeviceCapability.deviceClock: confidence,
      DeviceCapability.liveHeartRate: confidence,
      DeviceCapability.liveOxygen: confidence,
      DeviceCapability.steps: confidence,
      DeviceCapability.distance: confidence,
      DeviceCapability.calories: confidence,
      DeviceCapability.displayControls: confidence,
      if (validation
          .supportsBigData) ...<DeviceCapability, CapabilityConfidence>{
        DeviceCapability.heartRateHistory: confidence,
        DeviceCapability.oxygenHistory: confidence,
        DeviceCapability.firmwareHrvIndex: confidence,
        DeviceCapability.firmwareStressIndex: confidence,
        DeviceCapability.sleep: confidence,
        DeviceCapability.sleepStages: confidence,
      },
    });
  }

  Future<R12MetadataCapture> captureMetadata({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final connection = _connection;
    if (connection == null) {
      throw StateError('Metadata capture requires a connected ring.');
    }

    final firmware = await _readFirmware(connection);
    final request = createBatteryRequest();
    final response = await _requestCommand(request, timeout: timeout);
    final battery = parseBatteryResponse(response.bytes);
    final now = DateTime.now();
    return R12MetadataCapture(
      batteryLevel: battery.level,
      charging: battery.charging,
      firmwareVersion: firmware.$1,
      firmwareBytes: firmware.$2,
      batteryRequest: request,
      batteryResponse: response,
      capturedAt: now,
      timeZoneOffset: now.timeZoneOffset,
    );
  }

  Future<R12TimeSyncCapture> captureTimeSync({
    DateTime? localTime,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_connection == null) {
      throw StateError('Time sync requires a connected ring.');
    }
    final requested = localTime ?? DateTime.now();
    final request = createSetTimeRequest(requested);
    final response = parseSetTimeResponse(
      (await _requestCommand(request, timeout: timeout)).bytes,
    );
    return R12TimeSyncCapture(
      requestedLocalTime: requested,
      timeZoneOffset: requested.timeZoneOffset,
      request: request,
      response: response,
    );
  }

  Future<R12ApprovedSuiteCapture> captureApprovedSuite({
    DateTime? localTime,
  }) async {
    final connection = _connection;
    if (connection == null) {
      throw StateError('Approved-suite capture requires a connected ring.');
    }

    final startedAt = DateTime.now();
    final requestedLocalTime = localTime ?? startedAt;
    final sections = <String, Map<String, Object?>>{};
    int? batteryLevel;
    bool? charging;
    String? firmwareVersion;

    try {
      final deviceInfo = await _readAllowedDeviceInformation(connection);
      firmwareVersion = deviceInfo['firmware']?['value'] as String?;
      final request = createBatteryRequest();
      final response = await _requestCommand(
        request,
        timeout: const Duration(seconds: 5),
      );
      final battery = parseBatteryResponse(response.bytes);
      batteryLevel = battery.level;
      charging = battery.charging;
      sections['metadata'] = <String, Object?>{
        'status': 'complete',
        'deviceInformation': deviceInfo,
        'requestHex': captureHex(request.bytes),
        'responseHex': captureHex(response.bytes),
      };
    } catch (error) {
      sections['metadata'] = _errorSection(error);
    }

    sections['gattProfile'] = <String, Object?>{
      'status': 'complete',
      'services': connection.services
          .map(
            (service) => <String, Object?>{
              'uuid': service.uuid.toLowerCase(),
              'characteristics': service.characteristics
                  .map(
                    (characteristic) => <String, Object?>{
                      'uuid': characteristic.uuid.toLowerCase(),
                      'read': characteristic.canRead,
                      'write': characteristic.canWrite,
                      'notify': characteristic.canNotify,
                    },
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
    };

    try {
      final request = createSetTimeRequest(requestedLocalTime);
      final response = await _requestCommand(
        request,
        timeout: const Duration(seconds: 5),
      );
      parseSetTimeResponse(response.bytes);
      sections['timeSync'] = <String, Object?>{
        'status': 'complete',
        'requestedLocalTime': requestedLocalTime.toIso8601String(),
        'requestHex': captureHex(request.bytes),
        'responseHex': captureHex(response.bytes),
      };
    } catch (error) {
      sections['timeSync'] = _errorSection(error);
    }

    sections['readOnlyConfiguration'] = await _captureReadOnlyConfiguration();
    sections['activityHistory'] = await _captureActivityHistory(days: 8);
    sections['heartRateHistory'] = await _captureHeartRateHistory(
      today: requestedLocalTime,
      days: 8,
    );
    sections['stressHistory'] = await _captureIndexedHistory(
      days: 7,
      requestForDay: (day) => createStressHistoryRequest(dayOffset: day),
    );
    sections['firmwareHrvHistory'] = await _captureIndexedHistory(
      days: 7,
      requestForDay: (day) => createHrvHistoryRequest(dayOffset: day),
    );

    final supportsBigData = connection.services.any(
      (service) => ColmiQringProfile.uuidMatches(
        service.uuid,
        ColmiQringProfile.bigDataService,
      ),
    );
    if (supportsBigData) {
      sections['sleepHistory'] = await _captureSleepHistory();
      sections['oxygenHistory'] = await _captureBigData(
        dataId: colmiOxygenDataId,
        request: createBigDataRequest(colmiOxygenDataId),
        timeout: const Duration(seconds: 12),
      );
    } else {
      sections['sleepHistory'] = const <String, Object?>{
        'status': 'unsupported',
      };
      sections['oxygenHistory'] = const <String, Object?>{
        'status': 'unsupported',
      };
    }

    sections['liveHeartRate'] = await _captureLiveReading(
      kind: colmiLiveHeartRateKind,
      timeout: const Duration(seconds: 15),
    );
    sections['liveOxygen'] = await _captureLiveReading(
      kind: colmiLiveOxygenKind,
      timeout: const Duration(seconds: 20),
    );

    sections['unsupportedOrNotExposed'] = const <String, Object?>{
      'status': 'documented',
      'skinTemperature': 'unsupportedOnR12',
      'rawAccelerometer': 'notExposedByKnownR12Protocol',
      'rawPpg': 'notExposedByKnownR12Protocol',
      'respiration': 'notExposedByKnownR12Protocol',
      'ecg': 'unsupportedOnR12',
      'bloodPressure': 'unsupportedOnR12',
      'bloodGlucose': 'unsupportedOnR12',
    };

    return R12ApprovedSuiteCapture(
      capturedAt: startedAt,
      timeZoneOffset: startedAt.timeZoneOffset,
      sections: sections,
      batteryLevel: batteryLevel,
      charging: charging,
      firmwareVersion: firmwareVersion,
    );
  }

  Future<Map<String, Object?>> _captureReadOnlyConfiguration() async {
    final requests = <String, ColmiCommandPacket>{
      'deviceSupport': createDeviceSupportRequest(),
      'display': createPreferenceReadRequest(colmiDisplayPreferenceCommandId),
      'heartRateSchedule': createPreferenceReadRequest(
        colmiAutoHeartRatePreferenceCommandId,
      ),
      'goals': createPreferenceReadRequest(colmiGoalsCommandId),
      'oxygenSchedule': createPreferenceReadRequest(
        colmiAutoOxygenPreferenceCommandId,
      ),
      'stressSchedule': createPreferenceReadRequest(
        colmiAutoStressPreferenceCommandId,
      ),
      'firmwareHrvSchedule': createPreferenceReadRequest(
        colmiAutoHrvPreferenceCommandId,
      ),
    };
    final records = <String, Object?>{};
    for (final entry in requests.entries) {
      records[entry.key] = await _captureCommandSequence(
        request: entry.value,
        timeout: const Duration(seconds: 3),
        maximumPackets: 1,
        isComplete: (_, _) => true,
        statusFor: (_) => 'complete',
      );
    }
    return <String, Object?>{
      'status': _aggregateStatus(records.values.cast<Map<String, Object?>>()),
      'records': records,
    };
  }

  Future<Map<String, Object?>> _captureActivityHistory({
    required int days,
  }) async {
    final records = <Map<String, Object?>>[];
    for (var day = 0; day < days; day++) {
      final capture = await _captureCommandSequence(
        request: createActivityHistoryRequest(dayOffset: day),
        timeout: const Duration(seconds: 5),
        maximumPackets: 128,
        isComplete: (packet, _) {
          final subtype = packet.bytes[1];
          if (subtype == 0xff) return true;
          if (subtype == 0xf0) return false;
          return packet.bytes[6] > 0 && packet.bytes[5] == packet.bytes[6] - 1;
        },
        statusFor: (packets) =>
            packets.last.bytes[1] == 0xff ? 'noData' : 'complete',
      );
      records.add(<String, Object?>{'dayOffset': day, ...capture});
    }
    return <String, Object?>{
      'status': _aggregateStatus(records),
      'retentionDaysRequested': days,
      'days': records,
    };
  }

  Future<Map<String, Object?>> _captureHeartRateHistory({
    required DateTime today,
    required int days,
  }) async {
    final records = <Map<String, Object?>>[];
    for (var day = 0; day < days; day++) {
      int? expectedPackets;
      final target = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: day));
      final capture = await _captureCommandSequence(
        request: createHeartRateHistoryRequest(target),
        timeout: const Duration(seconds: 5),
        maximumPackets: 32,
        isComplete: (packet, _) {
          final subtype = packet.bytes[1];
          if (subtype == 0xff) return true;
          if (subtype == 0x00) {
            expectedPackets = packet.bytes[2];
            return expectedPackets == 0;
          }
          return subtype == 23 ||
              (expectedPackets != null && subtype == expectedPackets! - 1);
        },
        statusFor: (packets) =>
            packets.last.bytes[1] == 0xff ? 'noData' : 'complete',
      );
      records.add(<String, Object?>{
        'dayOffset': day,
        'requestedDate': _dateOnly(target),
        ...capture,
      });
    }
    return <String, Object?>{
      'status': _aggregateStatus(records),
      'retentionDaysRequested': days,
      'days': records,
    };
  }

  Future<Map<String, Object?>> _captureIndexedHistory({
    required int days,
    required ColmiCommandPacket Function(int dayOffset) requestForDay,
  }) async {
    final records = <Map<String, Object?>>[];
    for (var day = 0; day < days; day++) {
      int? expectedPackets;
      final capture = await _captureCommandSequence(
        request: requestForDay(day),
        timeout: const Duration(seconds: 5),
        maximumPackets: 32,
        isComplete: (packet, _) {
          final index = packet.bytes[1];
          if (index == 0xff) return true;
          if (index == 0x00) {
            expectedPackets = packet.bytes[2];
            return expectedPackets == 0;
          }
          return expectedPackets != null && index == expectedPackets! - 1;
        },
        statusFor: (packets) =>
            packets.last.bytes[1] == 0xff ? 'noData' : 'complete',
      );
      records.add(<String, Object?>{'dayOffset': day, ...capture});
    }
    return <String, Object?>{
      'status': _aggregateStatus(records),
      'retentionDaysRequested': days,
      'days': records,
    };
  }

  Future<Map<String, Object?>> _captureSleepHistory() async {
    final modern = await _captureBigData(
      dataId: colmiSleepDataId,
      request: createModernSleepBigDataRequest(),
      timeout: const Duration(seconds: 12),
    );
    if (modern['status'] != 'timeout') return modern;
    final legacy = await _captureBigData(
      dataId: colmiSleepDataId,
      request: createBigDataRequest(colmiSleepDataId),
      timeout: const Duration(seconds: 12),
    );
    return <String, Object?>{
      ...legacy,
      'fallbackReason': 'modernRequestTimedOut',
      'attempts': <Map<String, Object?>>[modern, legacy],
    };
  }

  Future<Map<String, Object?>> _captureCommandSequence({
    required ColmiCommandPacket request,
    required Duration timeout,
    required int maximumPackets,
    required bool Function(
      ColmiCommandPacket packet,
      List<ColmiCommandPacket> packets,
    )
    isComplete,
    required String Function(List<ColmiCommandPacket> packets) statusFor,
    String Function(List<ColmiCommandPacket> packets)? statusOnTimeout,
  }) async {
    final packets = <ColmiCommandPacket>[];
    final rawPackets = <List<int>>[];
    final completion = Completer<void>();
    var status = 'timeout';
    String? errorType;
    late final StreamSubscription<List<int>> subscription;
    late final Timer timer;

    subscription = _commandNotifications.stream.listen((raw) {
      if (raw.isEmpty || raw.first != request.commandId) return;
      rawPackets.add(List<int>.of(raw));
      try {
        final packet = ColmiCommandPacket.parse(raw);
        packets.add(packet);
        if (packets.length > maximumPackets) {
          status = 'packetLimit';
          if (!completion.isCompleted) completion.complete();
          return;
        }
        if (isComplete(packet, packets)) {
          status = statusFor(packets);
          if (!completion.isCompleted) completion.complete();
        }
      } catch (error) {
        status = 'invalidPacket';
        errorType = error.runtimeType.toString();
        if (!completion.isCompleted) completion.complete();
      }
    });
    timer = Timer(timeout, () {
      if (packets.isNotEmpty && statusOnTimeout != null) {
        status = statusOnTimeout(packets);
      }
      if (!completion.isCompleted) completion.complete();
    });
    try {
      await transport.write(
        serviceUuid: ColmiQringProfile.commandService,
        characteristicUuid: ColmiQringProfile.commandWrite,
        value: request.bytes,
        withResponse: true,
      );
      await completion.future;
    } catch (error) {
      status = 'writeError';
      errorType = error.runtimeType.toString();
    } finally {
      timer.cancel();
      await subscription.cancel();
    }
    return <String, Object?>{
      'status': status,
      'requestHex': captureHex(request.bytes),
      'responseCount': rawPackets.length,
      'responseHex': rawPackets.map(captureHex).toList(growable: false),
      'errorType': ?errorType,
    };
  }

  Future<Map<String, Object?>> _captureBigData({
    required int dataId,
    required List<int> request,
    required Duration timeout,
    int maximumBytes = 64 * 1024,
  }) async {
    final chunks = <List<int>>[];
    final message = <int>[];
    final completion = Completer<void>();
    var status = 'timeout';
    int? declaredDataLength;
    String? errorType;
    late final StreamSubscription<List<int>> subscription;
    late final Timer timer;

    subscription = _bigDataNotifications.stream.listen((chunk) {
      if (chunk.isEmpty) return;
      if (message.isEmpty &&
          (chunk.length < 2 ||
              chunk.first != colmiBigDataCommandId ||
              chunk[1] != dataId)) {
        return;
      }
      chunks.add(List<int>.of(chunk));
      message.addAll(chunk);
      if (message.length > maximumBytes) {
        status = 'sizeLimit';
        if (!completion.isCompleted) completion.complete();
        return;
      }
      if (message.length >= 6) {
        declaredDataLength ??= message[2] | (message[3] << 8);
        final totalLength = 6 + declaredDataLength!;
        if (totalLength > maximumBytes) {
          status = 'sizeLimit';
          if (!completion.isCompleted) completion.complete();
        } else if (message.length > totalLength) {
          status = 'lengthMismatch';
          if (!completion.isCompleted) completion.complete();
        } else if (message.length == totalLength) {
          status =
              declaredDataLength == 0 ||
                  (dataId == colmiSleepDataId &&
                      declaredDataLength! > 0 &&
                      message[6] == 0)
              ? 'noData'
              : 'complete';
          if (!completion.isCompleted) completion.complete();
        }
      }
    });
    timer = Timer(timeout, () {
      if (!completion.isCompleted) completion.complete();
    });
    try {
      await transport.write(
        serviceUuid: ColmiQringProfile.bigDataService,
        characteristicUuid: ColmiQringProfile.bigDataWrite,
        value: request,
        withResponse: true,
      );
      await completion.future;
    } catch (error) {
      status = 'writeError';
      errorType = error.runtimeType.toString();
    } finally {
      timer.cancel();
      await subscription.cancel();
    }
    return <String, Object?>{
      'status': status,
      'dataId': '0x${dataId.toRadixString(16).padLeft(2, '0')}',
      'requestHex': captureHex(request),
      'chunkCount': chunks.length,
      'chunkHex': chunks.map(captureHex).toList(growable: false),
      'declaredDataLength': declaredDataLength,
      'responseHex': captureHex(message),
      if (message.length >= 6) 'crcHex': captureHex(message.getRange(4, 6)),
      'errorType': ?errorType,
    };
  }

  Future<Map<String, Object?>> _captureLiveReading({
    required int kind,
    required Duration timeout,
  }) async {
    final start = createLiveStartRequest(kind);
    final stop = createLiveStopRequest(kind);
    final section = await _captureCommandSequence(
      request: start,
      timeout: timeout,
      maximumPackets: 64,
      isComplete: (packet, _) =>
          packet.bytes[1] == kind &&
          (packet.bytes[2] != 0 || packet.bytes[3] != 0),
      statusFor: (packets) =>
          packets.last.bytes[2] == 0 ? 'complete' : 'deviceError',
      statusOnTimeout: (packets) =>
          classifyLiveReadingPackets(packets, kind: kind),
    );
    try {
      await transport.write(
        serviceUuid: ColmiQringProfile.commandService,
        characteristicUuid: ColmiQringProfile.commandWrite,
        value: stop.bytes,
        withResponse: true,
      );
      section['stopWriteStatus'] = 'complete';
    } catch (error) {
      section['stopWriteStatus'] = 'writeError';
      section['stopErrorType'] = error.runtimeType.toString();
    }
    section['stopRequestHex'] = captureHex(stop.bytes);
    return section;
  }

  Map<String, Object?> _errorSection(Object error) => <String, Object?>{
    'status': error is TimeoutException ? 'timeout' : 'error',
    'errorType': error.runtimeType.toString(),
  };

  String _aggregateStatus(Iterable<Map<String, Object?>> records) {
    final statuses = records
        .map((record) => record['status'] as String? ?? 'unknown')
        .toList(growable: false);
    if (statuses.isEmpty) return 'noData';
    if (statuses.every((status) => status == 'noData')) return 'noData';
    if (statuses.every(
      (status) => status == 'complete' || status == 'noData',
    )) {
      return 'complete';
    }
    if (statuses.any((status) => status == 'complete' || status == 'noData')) {
      return 'partial';
    }
    return statuses.first;
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Future<Map<String, Map<String, Object?>>> _readAllowedDeviceInformation(
    RingConnection connection,
  ) async {
    const allowed = <String, String>{
      ColmiQringProfile.firmwareRevision: 'firmware',
      ColmiQringProfile.hardwareRevision: 'hardware',
      ColmiQringProfile.modelNumber: 'model',
      ColmiQringProfile.manufacturerName: 'manufacturer',
    };
    final result = <String, Map<String, Object?>>{};
    for (final service in connection.services) {
      if (!ColmiQringProfile.uuidMatches(
        service.uuid,
        ColmiQringProfile.deviceInformationService,
      )) {
        continue;
      }
      for (final characteristic in service.characteristics) {
        if (!characteristic.canRead) continue;
        String? label;
        for (final entry in allowed.entries) {
          if (ColmiQringProfile.uuidMatches(characteristic.uuid, entry.key)) {
            label = entry.value;
            break;
          }
        }
        if (label == null) continue;
        try {
          final bytes = await transport.read(
            serviceUuid: service.uuid,
            characteristicUuid: characteristic.uuid,
          );
          final trimmed = bytes.takeWhile((value) => value != 0).toList();
          final value = utf8.decode(trimmed, allowMalformed: true).trim();
          result[label] = <String, Object?>{
            'status': 'complete',
            'value': value.isEmpty ? null : value,
            'readHex': captureHex(bytes),
          };
        } catch (error) {
          result[label] = _errorSection(error);
        }
      }
    }
    for (final label in allowed.values) {
      result.putIfAbsent(
        label,
        () => const <String, Object?>{'status': 'notExposed'},
      );
    }
    return result;
  }

  Future<(String?, List<int>)> _readFirmware(RingConnection connection) async {
    for (final service in connection.services) {
      if (!ColmiQringProfile.uuidMatches(
        service.uuid,
        ColmiQringProfile.deviceInformationService,
      )) {
        continue;
      }
      for (final characteristic in service.characteristics) {
        if (!characteristic.canRead ||
            !ColmiQringProfile.uuidMatches(
              characteristic.uuid,
              ColmiQringProfile.firmwareRevision,
            )) {
          continue;
        }
        final bytes = await transport.read(
          serviceUuid: service.uuid,
          characteristicUuid: characteristic.uuid,
        );
        final trimmed = bytes.takeWhile((value) => value != 0).toList();
        final value = utf8.decode(trimmed, allowMalformed: true).trim();
        return (value.isEmpty ? null : value, List<int>.of(bytes));
      }
    }
    return (null, const <int>[]);
  }

  Future<ColmiCommandPacket> _requestCommand(
    ColmiCommandPacket request, {
    required Duration timeout,
  }) async {
    final response = _commandNotifications.stream
        .map(ColmiCommandPacket.parse)
        .firstWhere((packet) => packet.commandId == request.commandId)
        .timeout(timeout);
    await transport.write(
      serviceUuid: ColmiQringProfile.commandService,
      characteristicUuid: ColmiQringProfile.commandWrite,
      value: request.bytes,
      withResponse: true,
    );
    return response;
  }

  @override
  Stream<ConnectionEvent> observeConnection() => transport.connectionStates.map(
    (state) => switch (state) {
      BleConnectionState.connecting => const ConnectionEvent(
        ConnectionEventType.connecting,
      ),
      BleConnectionState.connected => const ConnectionEvent(
        ConnectionEventType.connected,
      ),
      BleConnectionState.disconnecting => const ConnectionEvent(
        ConnectionEventType.interrupted,
        message: 'Connection is closing.',
      ),
      BleConnectionState.disconnected => const ConnectionEvent(
        ConnectionEventType.disconnected,
      ),
    },
  );

  @override
  Future<SyncResult> sync(
    SyncRequest request,
    SyncCursor? previousCursor,
  ) async {
    final connection = _connection;
    if (connection == null) {
      throw StateError('R12 sync requires a connected ring.');
    }
    final validation = ColmiQringProfile.validateServices(connection.services);
    if (!validation.isSupported) {
      throw UnsupportedFirmwareException(validation.reason!);
    }

    final startedAt = DateTime.now();
    final firmware = await _readFirmware(connection);
    if (!physicallyVerifiedFirmwareVersions.contains(firmware.$1)) {
      throw UnsupportedFirmwareException(
        'Read-only sync is not enabled for firmware '
        '${firmware.$1 ?? 'unavailable'}. A model-specific capture is required.',
      );
    }
    final timeRequest = createSetTimeRequest(startedAt);
    parseSetTimeResponse(
      (await _requestCommand(
        timeRequest,
        timeout: const Duration(seconds: 5),
      )).bytes,
    );

    int? batteryLevel;
    bool? charging;
    final availability = <RingDataKind, RingDataAvailability>{};
    final activity = <RingActivityBucket>[];
    final heartRate = <RingHeartRateSample>[];
    final vendorIndexes = <RingVendorIndexSample>[];
    final oxygen = <RingOxygenRange>[];
    final sleep = <RingSleepSession>[];
    final completed = <SyncDomain>{};
    final partial = <SyncDomain>{};

    if (request.domains.contains(SyncDomain.battery)) {
      final response = await _requestCommand(
        createBatteryRequest(),
        timeout: const Duration(seconds: 5),
      );
      final reading = parseBatteryResponse(response.bytes);
      batteryLevel = reading.level;
      charging = reading.charging;
      availability[RingDataKind.battery] = RingDataAvailability.complete;
      completed.add(SyncDomain.battery);
    }

    if (request.domains.contains(SyncDomain.activity)) {
      final section = await _captureActivityHistory(days: 8);
      availability[RingDataKind.activity] = _availabilityFor(section);
      for (final day in _historyDays(section)) {
        for (final bucket in r12_history.parseActivityHistory(
          _responsePackets(day),
        )) {
          activity.add(
            RingActivityBucket(
              startedAtUtc: bucket.startedAtLocal.toUtc(),
              steps: bucket.steps,
              distanceMeters: bucket.distanceMeters,
              firmwareCalories: bucket.calories,
            ),
          );
        }
      }
      _recordDomainStatus(
        SyncDomain.activity,
        availability[RingDataKind.activity]!,
        completed: completed,
        partial: partial,
      );
    }

    if (request.domains.contains(SyncDomain.heartRate)) {
      final section = await _captureHeartRateHistory(today: startedAt, days: 8);
      availability[RingDataKind.heartRate] = _availabilityFor(section);
      for (final day in _historyDays(section)) {
        for (final sample in r12_history.parseHeartRateHistory(
          _responsePackets(day),
          requestedLocalDay: DateTime.parse(day['requestedDate']! as String),
        )) {
          heartRate.add(
            RingHeartRateSample(
              measuredAtUtc: sample.measuredAtLocal.toUtc(),
              bpm: sample.bpm,
            ),
          );
        }
      }
      _recordDomainStatus(
        SyncDomain.heartRate,
        availability[RingDataKind.heartRate]!,
        completed: completed,
        partial: partial,
      );
    }

    if (request.domains.contains(SyncDomain.sleep)) {
      if (validation.supportsBigData) {
        final section = await _captureSleepHistory();
        availability[RingDataKind.sleep] = _availabilityFor(section);
        if (section['status'] == 'complete') {
          for (final night in r12_big.parseSleepHistory(
            _decodeHex(section['responseHex']! as String),
            referenceLocalToday: startedAt,
          )) {
            sleep.add(
              RingSleepSession(
                startedAtUtc: night.startedAtLocal.toUtc(),
                endedAtUtc: night.endedAtLocal.toUtc(),
                stages: night.stages.map(
                  (span) => RingSleepStageSpan(
                    stage: _mapSleepStage(span.stage),
                    startedAtUtc: span.startedAtLocal.toUtc(),
                    durationMinutes: span.duration.inMinutes,
                  ),
                ),
              ),
            );
          }
        }
      } else {
        availability[RingDataKind.sleep] = RingDataAvailability.unavailable;
      }
      _recordDomainStatus(
        SyncDomain.sleep,
        availability[RingDataKind.sleep]!,
        completed: completed,
        partial: partial,
      );
    }

    if (request.domains.contains(SyncDomain.oxygen)) {
      if (validation.supportsBigData) {
        final section = await _captureBigData(
          dataId: colmiOxygenDataId,
          request: createBigDataRequest(colmiOxygenDataId),
          timeout: const Duration(seconds: 12),
        );
        availability[RingDataKind.oxygen] = _availabilityFor(section);
        if (section['status'] == 'complete') {
          for (final hour in r12_big.parseOxygenHistory(
            _decodeHex(section['responseHex']! as String),
            referenceLocalToday: startedAt,
          )) {
            oxygen.add(
              RingOxygenRange(
                hourStartedAtUtc: hour.hourStartedAtLocal.toUtc(),
                minimumPercent: hour.minimumPercent,
                maximumPercent: hour.maximumPercent,
              ),
            );
          }
        }
      } else {
        availability[RingDataKind.oxygen] = RingDataAvailability.unavailable;
      }
      _recordDomainStatus(
        SyncDomain.oxygen,
        availability[RingDataKind.oxygen]!,
        completed: completed,
        partial: partial,
      );
    }

    if (request.domains.contains(SyncDomain.additional)) {
      final stressSection = await _captureIndexedHistory(
        days: 7,
        requestForDay: (day) => createStressHistoryRequest(dayOffset: day),
      );
      final hrvSection = await _captureIndexedHistory(
        days: 7,
        requestForDay: (day) => createHrvHistoryRequest(dayOffset: day),
      );
      final stressAvailability = _availabilityFor(stressSection);
      final hrvAvailability = _availabilityFor(hrvSection);
      availability[RingDataKind.stressIndex] = stressAvailability;
      availability[RingDataKind.firmwareHrvIndex] = hrvAvailability;
      vendorIndexes.addAll(
        _decodeVendorHistory(
          stressSection,
          kind: r12_history.R12VendorIndexKind.stress,
          referenceLocalToday: startedAt,
        ),
      );
      vendorIndexes.addAll(
        _decodeVendorHistory(
          hrvSection,
          kind: r12_history.R12VendorIndexKind.firmwareHrv,
          referenceLocalToday: startedAt,
        ),
      );
      if (_isCompletedAvailability(stressAvailability) &&
          _isCompletedAvailability(hrvAvailability)) {
        completed.add(SyncDomain.additional);
      } else {
        partial.add(SyncDomain.additional);
      }
    }

    final dataset = RingSyncDataset(
      lastSyncedAtUtc: startedAt.toUtc(),
      source: RingDataSource(driverId: driverId, firmwareVersion: firmware.$1),
      availability: availability,
      activity: activity,
      heartRate: heartRate,
      vendorIndexes: vendorIndexes,
      oxygen: oxygen,
      sleep: sleep,
      batteryLevel: batteryLevel,
      charging: charging,
    );
    return SyncResult(
      completed: completed,
      partial: partial,
      recordCount: dataset.recordCount,
      nextCursor: SyncCursor(value: startedAt.toUtc().toIso8601String()),
      message: partial.isEmpty
          ? 'R12 read-only sync completed.'
          : 'R12 read-only sync completed with unavailable sections.',
      dataset: dataset,
    );
  }

  List<RingVendorIndexSample> _decodeVendorHistory(
    Map<String, Object?> section, {
    required r12_history.R12VendorIndexKind kind,
    required DateTime referenceLocalToday,
  }) {
    final values = <RingVendorIndexSample>[];
    for (final day in _historyDays(section)) {
      final offset = day['dayOffset']! as int;
      final requestedDay = DateTime(
        referenceLocalToday.year,
        referenceLocalToday.month,
        referenceLocalToday.day - offset,
      );
      for (final sample in r12_history.parseVendorIndexHistory(
        _responsePackets(day),
        kind: kind,
        requestedLocalDay: requestedDay,
        referenceLocalToday: referenceLocalToday,
      )) {
        values.add(
          RingVendorIndexSample(
            measuredAtUtc: sample.measuredAtLocal.toUtc(),
            value: sample.value,
            kind: kind == r12_history.R12VendorIndexKind.stress
                ? RingVendorIndexKind.stress
                : RingVendorIndexKind.firmwareHrv,
          ),
        );
      }
    }
    return values;
  }

  List<Map<String, Object?>> _historyDays(Map<String, Object?> section) =>
      (section['days']! as List<Object?>).cast<Map<String, Object?>>().toList(
        growable: false,
      );

  List<List<int>> _responsePackets(Map<String, Object?> day) =>
      (day['responseHex']! as List<Object?>)
          .cast<String>()
          .map(_decodeHex)
          .toList(growable: false);

  List<int> _decodeHex(String value) {
    if (value.length.isOdd) {
      throw const FormatException('R12 response contains odd-length hex.');
    }
    return <int>[
      for (var index = 0; index < value.length; index += 2)
        int.parse(value.substring(index, index + 2), radix: 16),
    ];
  }

  RingDataAvailability _availabilityFor(Map<String, Object?> section) =>
      switch (section['status']) {
        'complete' => RingDataAvailability.complete,
        'noData' => RingDataAvailability.noData,
        'noReading' => RingDataAvailability.noReading,
        'unsupported' => RingDataAvailability.unavailable,
        'partial' => RingDataAvailability.partial,
        _ => RingDataAvailability.error,
      };

  bool _isCompletedAvailability(RingDataAvailability availability) =>
      availability == RingDataAvailability.complete ||
      availability == RingDataAvailability.noData ||
      availability == RingDataAvailability.noReading;

  void _recordDomainStatus(
    SyncDomain domain,
    RingDataAvailability availability, {
    required Set<SyncDomain> completed,
    required Set<SyncDomain> partial,
  }) {
    if (_isCompletedAvailability(availability)) {
      completed.add(domain);
    } else {
      partial.add(domain);
    }
  }

  RingSleepStage _mapSleepStage(r12_big.R12SleepStage stage) => switch (stage) {
    r12_big.R12SleepStage.light => RingSleepStage.light,
    r12_big.R12SleepStage.deep => RingSleepStage.deep,
    r12_big.R12SleepStage.rem => RingSleepStage.rem,
    r12_big.R12SleepStage.awake => RingSleepStage.awake,
  };

  @override
  Future<LiveMeasurementSession> startLiveMeasurement(
    LiveMeasurementType type,
  ) {
    return Future<LiveMeasurementSession>.error(
      const ProtocolEvidenceIncompleteException(
        'Production live measurement remains disabled until a nonzero R12 reading and its completion lifecycle are physically accepted.',
      ),
    );
  }

  @override
  Future<void> updateSetting(DeviceSetting setting) {
    return Future<void>.error(
      const ProtocolEvidenceIncompleteException(
        'R12 device-setting writes are outside the approved read-only protocol scope.',
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    try {
      await _commandNotificationSubscription?.cancel();
      await _bigDataNotificationSubscription?.cancel();
    } finally {
      _commandNotificationSubscription = null;
      _bigDataNotificationSubscription = null;
      _connection = null;
      await transport.disconnect();
    }
  }
}
