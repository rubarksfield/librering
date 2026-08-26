import 'approved_capture.dart';
import 'packet.dart';

class R12HistoryFormatException implements Exception {
  const R12HistoryFormatException(this.message);

  final String message;

  @override
  String toString() => 'R12HistoryFormatException: $message';
}

class R12ActivityBucket {
  const R12ActivityBucket({
    required this.startedAtLocal,
    required this.calories,
    required this.steps,
    required this.distanceMeters,
  });

  final DateTime startedAtLocal;
  final int calories;
  final int steps;
  final int distanceMeters;
}

class R12HeartRateSample {
  const R12HeartRateSample({required this.measuredAtLocal, required this.bpm});

  final DateTime measuredAtLocal;
  final int bpm;
}

enum R12VendorIndexKind { stress, firmwareHrv }

class R12VendorIndexSample {
  const R12VendorIndexSample({
    required this.measuredAtLocal,
    required this.value,
    required this.kind,
  });

  final DateTime measuredAtLocal;
  final int value;
  final R12VendorIndexKind kind;
}

List<R12ActivityBucket> parseActivityHistory(Iterable<List<int>> frames) {
  var newCalorieProtocol = false;
  final buckets = <R12ActivityBucket>[];

  for (final packet in _parsePackets(frames, colmiActivityHistoryCommandId)) {
    final bytes = packet.bytes;
    final marker = bytes[1];
    if (marker == 0xff) continue;
    if (marker == 0xf0) {
      newCalorieProtocol = bytes[3] == 0x01;
      continue;
    }

    final year = 2000 + _decodeBcd(bytes[1], 'activity year');
    final month = _decodeBcd(bytes[2], 'activity month');
    final day = _decodeBcd(bytes[3], 'activity day');
    final slot = bytes[4];
    if (slot > 95) {
      throw R12HistoryFormatException(
        'Activity slot $slot is outside the 0-95 quarter-hour range.',
      );
    }
    final date = _checkedDate(year, month, day);
    final caloriesRaw = _u16le(bytes, 7);
    buckets.add(
      R12ActivityBucket(
        startedAtLocal: date.add(Duration(minutes: slot * 15)),
        calories: caloriesRaw * (newCalorieProtocol ? 10 : 1),
        steps: _u16le(bytes, 9),
        distanceMeters: _u16le(bytes, 11),
      ),
    );
  }

  buckets.sort(
    (left, right) => left.startedAtLocal.compareTo(right.startedAtLocal),
  );
  return List<R12ActivityBucket>.unmodifiable(buckets);
}

List<R12HeartRateSample> parseHeartRateHistory(
  Iterable<List<int>> frames, {
  required DateTime requestedLocalDay,
}) {
  var intervalMinutes = 5;
  var localDay = _dateOnlyLike(requestedLocalDay);
  final samples = <R12HeartRateSample>[];

  for (final packet in _parsePackets(frames, colmiHeartRateHistoryCommandId)) {
    final bytes = packet.bytes;
    final packetNumber = bytes[1];
    if (packetNumber == 0xff) continue;
    if (packetNumber == 0) {
      intervalMinutes = _validatedInterval(bytes[3], fallback: 5);
      continue;
    }

    final startIndex = packetNumber == 1 ? 6 : 2;
    if (packetNumber == 1) {
      final echoedSeconds = _u32le(bytes, 2);
      if (echoedSeconds > 0) {
        final echoedUtc = DateTime.fromMillisecondsSinceEpoch(
          echoedSeconds * Duration.millisecondsPerSecond,
          isUtc: true,
        );
        final echoedDay = _dateLike(
          requestedLocalDay,
          echoedUtc.year,
          echoedUtc.month,
          echoedUtc.day,
        );
        if (_calendarDayDistance(echoedDay, localDay).abs() <= 2) {
          localDay = echoedDay;
        }
      }
    }

    final precedingSamples = packetNumber == 1
        ? 0
        : 9 + (packetNumber - 2) * 13;
    for (var index = startIndex; index < 15; index++) {
      final bpm = bytes[index];
      if (bpm == 0 || bpm == 0xff) continue;
      final sampleIndex = precedingSamples + index - startIndex;
      samples.add(
        R12HeartRateSample(
          measuredAtLocal: localDay.add(
            Duration(minutes: sampleIndex * intervalMinutes),
          ),
          bpm: bpm,
        ),
      );
    }
  }

  samples.sort(
    (left, right) => left.measuredAtLocal.compareTo(right.measuredAtLocal),
  );
  return List<R12HeartRateSample>.unmodifiable(samples);
}

List<R12VendorIndexSample> parseVendorIndexHistory(
  Iterable<List<int>> frames, {
  required R12VendorIndexKind kind,
  required DateTime requestedLocalDay,
  required DateTime referenceLocalToday,
}) {
  final commandId = switch (kind) {
    R12VendorIndexKind.stress => colmiStressHistoryCommandId,
    R12VendorIndexKind.firmwareHrv => colmiHrvHistoryCommandId,
  };
  var intervalMinutes = 30;
  var localDay = _dateOnlyLike(requestedLocalDay);
  final today = _dateOnlyLike(referenceLocalToday);
  final samples = <R12VendorIndexSample>[];

  for (final packet in _parsePackets(frames, commandId)) {
    final bytes = packet.bytes;
    final packetNumber = bytes[1];
    if (packetNumber == 0xff) continue;
    if (packetNumber == 0) {
      intervalMinutes = _validatedInterval(bytes[3], fallback: 30);
      continue;
    }

    final startIndex = packetNumber == 1 ? 3 : 2;
    if (packetNumber == 1 && bytes[2] <= 29) {
      final echoedDay = _shiftCalendarDays(today, -bytes[2]);
      if (_calendarDayDistance(echoedDay, localDay).abs() <= 2) {
        localDay = echoedDay;
      }
    }
    final precedingSamples = packetNumber == 1
        ? 0
        : 12 + (packetNumber - 2) * 13;
    for (var index = startIndex; index < 15; index++) {
      final value = bytes[index];
      if (value == 0 || value == 0xff) continue;
      final sampleIndex = precedingSamples + index - startIndex;
      samples.add(
        R12VendorIndexSample(
          measuredAtLocal: localDay.add(
            Duration(minutes: sampleIndex * intervalMinutes),
          ),
          value: value,
          kind: kind,
        ),
      );
    }
  }

  samples.sort(
    (left, right) => left.measuredAtLocal.compareTo(right.measuredAtLocal),
  );
  return List<R12VendorIndexSample>.unmodifiable(samples);
}

Iterable<ColmiCommandPacket> _parsePackets(
  Iterable<List<int>> frames,
  int expectedCommandId,
) sync* {
  for (final frame in frames) {
    late final ColmiCommandPacket packet;
    try {
      packet = ColmiCommandPacket.parse(frame);
    } on ColmiPacketFormatException catch (error) {
      throw R12HistoryFormatException(error.message);
    }
    if (packet.commandId != expectedCommandId) {
      throw R12HistoryFormatException(
        'Expected command 0x${expectedCommandId.toRadixString(16)}, '
        'received 0x${packet.commandId.toRadixString(16)}.',
      );
    }
    yield packet;
  }
}

int _decodeBcd(int value, String field) {
  final high = value >> 4;
  final low = value & 0x0f;
  if (high > 9 || low > 9) {
    throw R12HistoryFormatException('$field is not valid BCD.');
  }
  return high * 10 + low;
}

DateTime _checkedDate(int year, int month, int day) {
  final value = DateTime(year, month, day);
  if (value.year != year || value.month != month || value.day != day) {
    throw const R12HistoryFormatException('Activity date is invalid.');
  }
  return value;
}

DateTime _dateOnlyLike(DateTime source) =>
    _dateLike(source, source.year, source.month, source.day);

DateTime _dateLike(DateTime source, int year, int month, int day) =>
    source.isUtc ? DateTime.utc(year, month, day) : DateTime(year, month, day);

DateTime _shiftCalendarDays(DateTime source, int days) => source.isUtc
    ? DateTime.utc(source.year, source.month, source.day + days)
    : DateTime(source.year, source.month, source.day + days);

int _calendarDayDistance(DateTime left, DateTime right) {
  final leftUtc = DateTime.utc(left.year, left.month, left.day);
  final rightUtc = DateTime.utc(right.year, right.month, right.day);
  return leftUtc.difference(rightUtc).inDays;
}

int _validatedInterval(int value, {required int fallback}) =>
    value >= 1 && value <= 240 ? value : fallback;

int _u16le(List<int> bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8);

int _u32le(List<int> bytes, int offset) =>
    bytes[offset] |
    (bytes[offset + 1] << 8) |
    (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24);
