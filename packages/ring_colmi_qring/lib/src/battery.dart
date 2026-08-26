import 'packet.dart';

const colmiBatteryCommandId = 0x03;

class ColmiBatteryReading {
  const ColmiBatteryReading({required this.level, required this.charging});

  final int level;
  final bool charging;
}

ColmiCommandPacket createBatteryRequest() =>
    ColmiCommandPacket.create(colmiBatteryCommandId);

ColmiBatteryReading parseBatteryResponse(List<int> bytes) {
  final packet = ColmiCommandPacket.parse(bytes);
  if (packet.commandId != colmiBatteryCommandId) {
    throw ColmiPacketFormatException(
      'Expected battery command 0x03, received 0x${packet.commandId.toRadixString(16).padLeft(2, '0')}.',
    );
  }
  final level = packet.bytes[1];
  final charging = packet.bytes[2];
  if (level > 100) {
    throw ColmiPacketFormatException('Battery level is outside 0–100: $level.');
  }
  if (charging != 0 && charging != 1) {
    throw ColmiPacketFormatException('Charging flag is not 0 or 1: $charging.');
  }
  return ColmiBatteryReading(level: level, charging: charging == 1);
}
