import 'approved_capture.dart';

class R12BigDataFormatException implements Exception {
  const R12BigDataFormatException(this.message);

  final String message;

  @override
  String toString() => 'R12BigDataFormatException: $message';
}

class R12BigDataEnvelope {
  const R12BigDataEnvelope._({required this.dataId, required this.payload});

  final int dataId;
  final List<int> payload;

  factory R12BigDataEnvelope.parse(
    List<int> bytes, {
    required int expectedDataId,
  }) {
    _validateBytes(bytes);
    if (bytes.length < 6) {
      throw const R12BigDataFormatException(
        'Big-data response is shorter than its six-byte envelope.',
      );
    }
    if (bytes[0] != colmiBigDataCommandId) {
      throw R12BigDataFormatException(
        'Expected big-data command 0xbc, received 0x${bytes[0].toRadixString(16)}.',
      );
    }
    if (bytes[1] != expectedDataId) {
      throw R12BigDataFormatException(
        'Expected data id 0x${expectedDataId.toRadixString(16)}, '
        'received 0x${bytes[1].toRadixString(16)}.',
      );
    }
    final declaredLength = bytes[2] | (bytes[3] << 8);
    if (bytes.length != 6 + declaredLength) {
      throw R12BigDataFormatException(
        'Declared $declaredLength payload bytes, received ${bytes.length - 6}.',
      );
    }
    final payload = bytes.sublist(6);
    final expectedCrc = _crc16Modbus(payload);
    final receivedCrc = bytes[4] | (bytes[5] << 8);
    if (receivedCrc != expectedCrc) {
      throw R12BigDataFormatException(
        'CRC mismatch: expected $expectedCrc, received $receivedCrc.',
      );
    }
    return R12BigDataEnvelope._(
      dataId: bytes[1],
      payload: List<int>.unmodifiable(payload),
    );
  }
}

enum R12SleepStage { light, deep, rem, awake }

class R12SleepStageSpan {
  const R12SleepStageSpan({
    required this.stage,
    required this.startedAtLocal,
    required this.duration,
  });

  final R12SleepStage stage;
  final DateTime startedAtLocal;
  final Duration duration;
}

class R12SleepNight {
  const R12SleepNight({
    required this.recordLocalDay,
    required this.startedAtLocal,
    required this.endedAtLocal,
    required this.stages,
  });

  final DateTime recordLocalDay;
  final DateTime startedAtLocal;
  final DateTime endedAtLocal;
  final List<R12SleepStageSpan> stages;
}

class R12OxygenHour {
  const R12OxygenHour({
    required this.hourStartedAtLocal,
    required this.minimumPercent,
    required this.maximumPercent,
  });

  final DateTime hourStartedAtLocal;
  final int minimumPercent;
  final int maximumPercent;
}

List<R12SleepNight> parseSleepHistory(
  List<int> bytes, {
  required DateTime referenceLocalToday,
}) {
  final payload = R12BigDataEnvelope.parse(
    bytes,
    expectedDataId: colmiSleepDataId,
  ).payload;
  if (payload.isEmpty) {
    throw const R12BigDataFormatException(
      'Sleep payload is missing its day count.',
    );
  }

  final dayCount = payload[0];
  var index = 1;
  final today = _dateOnlyLike(referenceLocalToday);
  final nights = <R12SleepNight>[];
  for (var dayIndex = 0; dayIndex < dayCount; dayIndex++) {
    if (index + 2 > payload.length) {
      throw const R12BigDataFormatException(
        'Sleep record is missing its day and length fields.',
      );
    }
    final daysAgo = payload[index++];
    final recordLength = payload[index++];
    if (recordLength < 4 || recordLength.isOdd) {
      throw R12BigDataFormatException(
        'Sleep record length $recordLength is not a four-byte header plus stage pairs.',
      );
    }
    final recordEnd = index + recordLength;
    if (recordEnd > payload.length) {
      throw const R12BigDataFormatException(
        'Sleep record extends beyond the declared payload.',
      );
    }

    final startMinute = _u16le(payload, index);
    final endMinute = _u16le(payload, index + 2);
    if (startMinute > 1439 || endMinute > 1440) {
      throw const R12BigDataFormatException(
        'Sleep start or end minute is outside a local day.',
      );
    }
    index += 4;
    final recordDay = _shiftCalendarDays(today, -daysAgo);
    final startOffset = startMinute > endMinute
        ? startMinute - 1440
        : startMinute;
    final sessionStart = recordDay.add(Duration(minutes: startOffset));
    final sessionEnd = recordDay.add(Duration(minutes: endMinute));
    var stageStart = sessionStart;
    final stages = <R12SleepStageSpan>[];
    while (index < recordEnd) {
      final stage = _sleepStage(payload[index++]);
      final minutes = payload[index++];
      if (minutes == 0) continue;
      final duration = Duration(minutes: minutes);
      stages.add(
        R12SleepStageSpan(
          stage: stage,
          startedAtLocal: stageStart,
          duration: duration,
        ),
      );
      stageStart = stageStart.add(duration);
    }
    nights.add(
      R12SleepNight(
        recordLocalDay: recordDay,
        startedAtLocal: sessionStart,
        endedAtLocal: sessionEnd,
        stages: List<R12SleepStageSpan>.unmodifiable(stages),
      ),
    );
  }

  if (index != payload.length) {
    throw R12BigDataFormatException(
      'Sleep payload has ${payload.length - index} trailing bytes.',
    );
  }
  return List<R12SleepNight>.unmodifiable(nights);
}

List<R12OxygenHour> parseOxygenHistory(
  List<int> bytes, {
  required DateTime referenceLocalToday,
}) {
  final payload = R12BigDataEnvelope.parse(
    bytes,
    expectedDataId: colmiOxygenDataId,
  ).payload;
  if (payload.length % 49 != 0) {
    throw R12BigDataFormatException(
      'Oxygen payload length ${payload.length} is not a whole 49-byte day record.',
    );
  }

  final today = _dateOnlyLike(referenceLocalToday);
  final hours = <R12OxygenHour>[];
  for (var record = 0; record < payload.length ~/ 49; record++) {
    final offset = record * 49;
    final day = _shiftCalendarDays(today, -payload[offset]);
    for (var hour = 0; hour < 24; hour++) {
      final minimum = payload[offset + 1 + hour * 2];
      final maximum = payload[offset + 2 + hour * 2];
      if (minimum == 0 && maximum == 0) continue;
      if (minimum < 1 || maximum < 1 || minimum > 100 || maximum > 100) {
        throw const R12BigDataFormatException(
          'Oxygen range contains a value outside 1-100.',
        );
      }
      if (minimum > maximum) {
        throw const R12BigDataFormatException(
          'Oxygen range minimum exceeds its maximum.',
        );
      }
      hours.add(
        R12OxygenHour(
          hourStartedAtLocal: day.add(Duration(hours: hour)),
          minimumPercent: minimum,
          maximumPercent: maximum,
        ),
      );
    }
  }
  return List<R12OxygenHour>.unmodifiable(hours);
}

R12SleepStage _sleepStage(int value) => switch (value) {
  0x02 => R12SleepStage.light,
  0x03 => R12SleepStage.deep,
  0x04 => R12SleepStage.rem,
  0x05 => R12SleepStage.awake,
  _ => throw R12BigDataFormatException(
    'Unknown sleep-stage code 0x${value.toRadixString(16)}.',
  ),
};

DateTime _dateOnlyLike(DateTime source) => source.isUtc
    ? DateTime.utc(source.year, source.month, source.day)
    : DateTime(source.year, source.month, source.day);

DateTime _shiftCalendarDays(DateTime source, int days) => source.isUtc
    ? DateTime.utc(source.year, source.month, source.day + days)
    : DateTime(source.year, source.month, source.day + days);

int _u16le(List<int> bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8);

void _validateBytes(List<int> bytes) {
  for (var index = 0; index < bytes.length; index++) {
    if (bytes[index] < 0 || bytes[index] > 255) {
      throw R12BigDataFormatException('bytes[$index] is outside 0-255.');
    }
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
