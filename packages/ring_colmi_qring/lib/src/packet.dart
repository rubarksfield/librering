class ColmiPacketFormatException implements Exception {
  const ColmiPacketFormatException(this.message);

  final String message;

  @override
  String toString() => 'ColmiPacketFormatException: $message';
}

class ColmiCommandPacket {
  ColmiCommandPacket._(List<int> bytes) : bytes = List<int>.unmodifiable(bytes);

  static const length = 16;
  final List<int> bytes;

  int get commandId => bytes.first;
  int get checksum => bytes.last;

  factory ColmiCommandPacket.create(
    int commandId, [
    List<int> payload = const <int>[],
  ]) {
    _validateByte(commandId, 'commandId');
    if (payload.length > 14) {
      throw const ColmiPacketFormatException('Payload exceeds 14 bytes.');
    }
    final bytes = List<int>.filled(length, 0)..[0] = commandId;
    for (var index = 0; index < payload.length; index++) {
      _validateByte(payload[index], 'payload[$index]');
      bytes[index + 1] = payload[index];
    }
    bytes[15] = calculateChecksum(bytes);
    return ColmiCommandPacket._(bytes);
  }

  factory ColmiCommandPacket.parse(List<int> bytes) {
    if (bytes.length != length) {
      throw ColmiPacketFormatException(
        'Expected 16 bytes, received ${bytes.length}.',
      );
    }
    for (var index = 0; index < bytes.length; index++) {
      _validateByte(bytes[index], 'bytes[$index]');
    }
    final expected = calculateChecksum(bytes);
    if (bytes.last != expected) {
      throw ColmiPacketFormatException(
        'Checksum mismatch: expected $expected, received ${bytes.last}.',
      );
    }
    return ColmiCommandPacket._(bytes);
  }

  static int calculateChecksum(List<int> bytes) {
    if (bytes.length < 15) {
      throw const ColmiPacketFormatException('Checksum requires bytes 0–14.');
    }
    for (var index = 0; index < 15; index++) {
      _validateByte(bytes[index], 'bytes[$index]');
    }
    return bytes.take(15).fold<int>(0, (sum, value) => sum + value) & 0xff;
  }

  static void _validateByte(int value, String label) {
    if (value < 0 || value > 255) {
      throw ColmiPacketFormatException('$label is outside 0–255.');
    }
  }
}
