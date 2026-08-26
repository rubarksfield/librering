import 'dart:convert';

import 'packet.dart';

const colmiActivityHistoryCommandId = 0x43;
const colmiHeartRateHistoryCommandId = 0x15;
const colmiAutoHeartRatePreferenceCommandId = 0x16;
const colmiGoalsCommandId = 0x21;
const colmiAutoOxygenPreferenceCommandId = 0x2c;
const colmiAutoStressPreferenceCommandId = 0x36;
const colmiStressHistoryCommandId = 0x37;
const colmiAutoHrvPreferenceCommandId = 0x38;
const colmiHrvHistoryCommandId = 0x39;
const colmiDeviceSupportCommandId = 0x3c;
const colmiDisplayPreferenceCommandId = 0x05;
const colmiLiveStartCommandId = 0x69;
const colmiLiveStopCommandId = 0x6a;
const colmiBigDataCommandId = 0xbc;
const colmiSleepDataId = 0x27;
const colmiOxygenDataId = 0x2a;
const colmiLiveHeartRateKind = 0x01;
const colmiLiveOxygenKind = 0x03;

ColmiCommandPacket createActivityHistoryRequest({int dayOffset = 0}) {
  if (dayOffset < 0 || dayOffset > 255) {
    throw ArgumentError.value(dayOffset, 'dayOffset');
  }
  return ColmiCommandPacket.create(colmiActivityHistoryCommandId, <int>[
    dayOffset,
    0x0f,
    0x00,
    0x5f,
    0x01,
  ]);
}

ColmiCommandPacket createHeartRateHistoryRequest(DateTime localDay) {
  final seconds =
      DateTime.utc(
        localDay.year,
        localDay.month,
        localDay.day,
      ).millisecondsSinceEpoch ~/
      Duration.millisecondsPerSecond;
  return ColmiCommandPacket.create(
    colmiHeartRateHistoryCommandId,
    _littleEndian32(seconds),
  );
}

ColmiCommandPacket createStressHistoryRequest({required int dayOffset}) {
  _validateDayOffset(dayOffset);
  return ColmiCommandPacket.create(colmiStressHistoryCommandId, <int>[
    dayOffset,
  ]);
}

ColmiCommandPacket createHrvHistoryRequest({required int dayOffset}) {
  _validateDayOffset(dayOffset);
  return ColmiCommandPacket.create(
    colmiHrvHistoryCommandId,
    _littleEndian32(dayOffset),
  );
}

ColmiCommandPacket createPreferenceReadRequest(int commandId) {
  const supported = <int>{
    colmiDisplayPreferenceCommandId,
    colmiAutoHeartRatePreferenceCommandId,
    colmiGoalsCommandId,
    colmiAutoOxygenPreferenceCommandId,
    colmiAutoStressPreferenceCommandId,
    colmiAutoHrvPreferenceCommandId,
  };
  if (!supported.contains(commandId)) {
    throw ArgumentError.value(commandId, 'commandId');
  }
  return ColmiCommandPacket.create(commandId, const <int>[0x01]);
}

ColmiCommandPacket createDeviceSupportRequest() =>
    ColmiCommandPacket.create(colmiDeviceSupportCommandId);

List<int> createBigDataRequest(int dataId) {
  _validateByte(dataId, 'dataId');
  return <int>[colmiBigDataCommandId, dataId, 0x01, 0x00, 0xff, 0x00, 0xff];
}

List<int> createModernSleepBigDataRequest() {
  const payload = <int>[0xff, 0x01];
  final crc = _crc16Modbus(payload);
  return <int>[
    colmiBigDataCommandId,
    colmiSleepDataId,
    payload.length,
    0x00,
    crc & 0xff,
    (crc >> 8) & 0xff,
    ...payload,
  ];
}

ColmiCommandPacket createLiveStartRequest(int kind) {
  _validateLiveKind(kind);
  return ColmiCommandPacket.create(colmiLiveStartCommandId, <int>[kind, 0x01]);
}

ColmiCommandPacket createLiveStopRequest(int kind) {
  _validateLiveKind(kind);
  return ColmiCommandPacket.create(colmiLiveStopCommandId, <int>[
    kind,
    0x00,
    0x00,
  ]);
}

String classifyLiveReadingPackets(
  List<ColmiCommandPacket> packets, {
  required int kind,
}) {
  _validateLiveKind(kind);
  if (packets.isEmpty) return 'timeout';
  if (packets.any((packet) => packet.bytes[1] != kind)) {
    return 'unexpectedPacket';
  }
  if (packets.any((packet) => packet.bytes[2] != 0)) return 'deviceError';
  if (packets.any((packet) => packet.bytes[3] != 0)) return 'complete';
  return 'noReading';
}

class R12ApprovedSuiteCapture {
  R12ApprovedSuiteCapture({
    required this.capturedAt,
    required this.timeZoneOffset,
    required this.sections,
    this.batteryLevel,
    this.charging,
    this.firmwareVersion,
  });

  final DateTime capturedAt;
  final Duration timeZoneOffset;
  final Map<String, Map<String, Object?>> sections;
  final int? batteryLevel;
  final bool? charging;
  final String? firmwareVersion;

  Map<String, String> get statuses => <String, String>{
    for (final entry in sections.entries)
      entry.key: entry.value['status'] as String? ?? 'unknown',
  };

  String toAnonymisedJson() => jsonEncode(<String, Object?>{
    'schema': 1,
    'captureType': 'r12-approved-suite',
    'deviceAlias': 'owned-r12-1',
    'capturedAtUtc': capturedAt.toUtc().toIso8601String(),
    'timeZoneOffsetMinutes': timeZoneOffset.inMinutes,
    'firmwareVersion': firmwareVersion,
    'batteryLevel': batteryLevel,
    'charging': charging,
    'sections': sections,
  });
}

String captureHex(Iterable<int> bytes) =>
    bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();

List<int> _littleEndian32(int value) => <int>[
  value & 0xff,
  (value >> 8) & 0xff,
  (value >> 16) & 0xff,
  (value >> 24) & 0xff,
];

void _validateLiveKind(int kind) {
  if (kind != colmiLiveHeartRateKind && kind != colmiLiveOxygenKind) {
    throw ArgumentError.value(kind, 'kind', 'Unsupported live-reading kind.');
  }
}

void _validateDayOffset(int dayOffset) {
  if (dayOffset < 0 || dayOffset > 255) {
    throw ArgumentError.value(dayOffset, 'dayOffset');
  }
}

int _crc16Modbus(Iterable<int> bytes) {
  var crc = 0xffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xa001 : crc >> 1;
    }
  }
  return crc;
}

void _validateByte(int value, String label) {
  if (value < 0 || value > 255) {
    throw ArgumentError.value(value, label, 'Expected a byte value.');
  }
}
