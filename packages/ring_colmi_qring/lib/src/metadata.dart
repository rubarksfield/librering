import 'dart:convert';

import 'packet.dart';

class R12MetadataCapture {
  R12MetadataCapture({
    required this.batteryLevel,
    required this.charging,
    required this.firmwareVersion,
    required this.firmwareBytes,
    required this.batteryRequest,
    required this.batteryResponse,
    required this.capturedAt,
    required this.timeZoneOffset,
  });

  final int batteryLevel;
  final bool charging;
  final String? firmwareVersion;
  final List<int> firmwareBytes;
  final ColmiCommandPacket batteryRequest;
  final ColmiCommandPacket batteryResponse;
  final DateTime capturedAt;
  final Duration timeZoneOffset;

  String toAnonymisedJson() => jsonEncode(<String, Object?>{
    'schema': 1,
    'captureType': 'r12-metadata',
    'deviceAlias': 'owned-r12-1',
    'capturedAtUtc': capturedAt.toUtc().toIso8601String(),
    'timeZoneOffsetMinutes': timeZoneOffset.inMinutes,
    'firmwareVersion': firmwareVersion,
    'firmwareReadHex': _hex(firmwareBytes),
    'batteryLevel': batteryLevel,
    'charging': charging,
    'batteryCommand': <String, Object>{
      'id': '0x03',
      'requestHex': _hex(batteryRequest.bytes),
      'responseHex': _hex(batteryResponse.bytes),
    },
  });

  static String _hex(Iterable<int> bytes) =>
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
}
