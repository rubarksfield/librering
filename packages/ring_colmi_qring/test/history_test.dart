import 'dart:convert';
import 'dart:io';

import 'package:ring_colmi_qring/ring_colmi_qring.dart';
import 'package:test/test.dart';

void main() {
  final historyFixture = _fixture('test/fixtures/r12-history-synthetic.json');
  final referenceToday = DateTime.parse(
    historyFixture['referenceLocalToday']! as String,
  );

  test('synthetic activity history preserves 15-minute buckets and units', () {
    final section = historyFixture['activity']! as Map<String, Object?>;
    final buckets = parseActivityHistory(_packets(section));

    expect(buckets, hasLength(1));
    expect(buckets.single.startedAtLocal, DateTime(2026, 8, 20, 10));
    expect(buckets.single.calories, 100);
    expect(buckets.single.steps, 500);
    expect(buckets.single.distanceMeters, 400);
  });

  test('synthetic heart-rate pages retain gaps on their sampled grid', () {
    final section = historyFixture['heartRate']! as Map<String, Object?>;
    final samples = parseHeartRateHistory(
      _packets(section),
      requestedLocalDay: DateTime.parse(
        section['requestedLocalDay']! as String,
      ),
    );

    expect(samples.map((sample) => sample.bpm), <int>[60, 61, 62, 63, 64]);
    expect(samples.map((sample) => sample.measuredAtLocal.minute), <int>[
      0,
      10,
      20,
      35,
      40,
    ]);
  });

  test('vendor index dates are anchored explicitly and deterministically', () {
    final stress = historyFixture['stressVendorIndex']! as Map<String, Object?>;
    final samples = parseVendorIndexHistory(
      _packets(stress),
      kind: R12VendorIndexKind.stress,
      requestedLocalDay: DateTime.parse(stress['requestedLocalDay']! as String),
      referenceLocalToday: referenceToday,
    );

    expect(samples, hasLength(9));
    expect(samples.first.kind, R12VendorIndexKind.stress);
    expect(samples.first.measuredAtLocal, DateTime(2026, 8, 20));
    expect(samples.last.measuredAtLocal, DateTime(2026, 8, 20, 5, 30));
  });

  test('firmware HRV values stay labelled as proprietary vendor indexes', () {
    final hrv =
        historyFixture['firmwareHrvVendorIndex']! as Map<String, Object?>;
    final samples = parseVendorIndexHistory(
      _packets(hrv),
      kind: R12VendorIndexKind.firmwareHrv,
      requestedLocalDay: DateTime.parse(hrv['requestedLocalDay']! as String),
      referenceLocalToday: referenceToday,
    );

    expect(samples, hasLength(9));
    expect(
      samples.every((sample) => sample.kind == R12VendorIndexKind.firmwareHrv),
      isTrue,
    );
  });

  test('history checksum corruption fails closed', () {
    final section = historyFixture['activity']! as Map<String, Object?>;
    final corrupt = _packets(section).last.toList()..[15] ^= 0xff;

    expect(
      () => parseActivityHistory(<List<int>>[corrupt]),
      throwsA(isA<R12HistoryFormatException>()),
    );
  });

  group('big-data history', () {
    final fixture = _fixture('test/fixtures/r12-big-data-synthetic.json');
    final today = DateTime.parse(fixture['referenceLocalToday']! as String);

    test('sleep envelope CRC and bounded stage records decode', () {
      final nights = parseSleepHistory(
        _hex(fixture['sleepResponseHex']! as String),
        referenceLocalToday: today,
      );

      expect(nights, hasLength(1));
      expect(nights.single.recordLocalDay, DateTime(2026, 8, 20));
      expect(nights.single.startedAtLocal, DateTime(2026, 8, 19, 23));
      expect(nights.single.endedAtLocal, DateTime(2026, 8, 20, 5));
      expect(nights.single.stages.map((span) => span.stage), <R12SleepStage>[
        R12SleepStage.deep,
        R12SleepStage.light,
        R12SleepStage.rem,
      ]);
    });

    test('oxygen 49-byte day records preserve hourly min and max', () {
      final hours = parseOxygenHistory(
        _hex(fixture['oxygenResponseHex']! as String),
        referenceLocalToday: today,
      );

      expect(hours, hasLength(1));
      expect(hours.single.hourStartedAtLocal, DateTime(2026, 8, 21));
      expect(hours.single.minimumPercent, 95);
      expect(hours.single.maximumPercent, 98);
    });

    test('big-data CRC corruption fails closed', () {
      final corrupt = _hex(fixture['sleepResponseHex']! as String)..[4] ^= 1;

      expect(
        () => parseSleepHistory(corrupt, referenceLocalToday: today),
        throwsA(isA<R12BigDataFormatException>()),
      );
    });
  });

  test('physical evidence fixture contains structure, not identifiers or values', () {
    final fixture = File(
      'test/fixtures/r12-approved-suite-physical-structure-rt11cr-1.00.09.json',
    ).readAsStringSync();
    final decoded = jsonDecode(fixture) as Map<String, Object?>;

    expect(decoded['deviceIdentifiers'], 'redacted');
    expect(decoded['rawPhysiologicalValues'], 'omitted');
    expect(fixture, isNot(contains('00008130')));
    expect(fixture, isNot(contains('COLMI R12_')));
  });
}

Map<String, Object?> _fixture(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

List<List<int>> _packets(Map<String, Object?> section) =>
    (section['packetsHex']! as List<Object?>)
        .cast<String>()
        .map(_hex)
        .toList(growable: false);

List<int> _hex(String value) {
  if (value.length.isOdd) throw FormatException('Odd-length hex fixture.');
  return <int>[
    for (var index = 0; index < value.length; index += 2)
      int.parse(value.substring(index, index + 2), radix: 16),
  ];
}
