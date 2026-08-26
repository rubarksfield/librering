import 'dart:convert';

import 'packet.dart';

const colmiSetTimeCommandId = 0x01;

ColmiCommandPacket createSetTimeRequest(DateTime localTime) {
  final payload = <int>[
    _toBcd(localTime.year % 100),
    _toBcd(localTime.month),
    _toBcd(localTime.day),
    _toBcd(localTime.hour),
    _toBcd(localTime.minute),
    _toBcd(localTime.second),
    0x01,
  ];
  return ColmiCommandPacket.create(colmiSetTimeCommandId, payload);
}

ColmiCommandPacket parseSetTimeResponse(List<int> bytes) {
  final packet = ColmiCommandPacket.parse(bytes);
  if (packet.commandId != colmiSetTimeCommandId) {
    throw ColmiPacketFormatException(
      'Expected set-time command 0x01, received 0x${packet.commandId.toRadixString(16).padLeft(2, '0')}.',
    );
  }
  return packet;
}

class R12TimeSyncCapture {
  R12TimeSyncCapture({
    required this.requestedLocalTime,
    required this.timeZoneOffset,
    required this.request,
    required this.response,
  });

  final DateTime requestedLocalTime;
  final Duration timeZoneOffset;
  final ColmiCommandPacket request;
  final ColmiCommandPacket response;

  String toAnonymisedJson() => jsonEncode(<String, Object?>{
    'schema': 1,
    'captureType': 'r12-time-sync',
    'deviceAlias': 'owned-r12-1',
    'requestedLocalTime': requestedLocalTime.toIso8601String(),
    'timeZoneOffsetMinutes': timeZoneOffset.inMinutes,
    'timeCommand': <String, Object>{
      'id': '0x01',
      'requestHex': _hex(request.bytes),
      'responseHex': _hex(response.bytes),
    },
  });

  static String _hex(Iterable<int> bytes) =>
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
}

int _toBcd(int value) {
  if (value < 0 || value > 99) {
    throw ArgumentError.value(value, 'value', 'BCD value must be 0–99.');
  }
  return ((value ~/ 10) << 4) | (value % 10);
}
