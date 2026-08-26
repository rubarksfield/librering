import 'dart:convert';
import 'dart:io';

import 'package:ring_colmi_qring/ring_colmi_qring.dart';
import 'package:test/test.dart';

void main() {
  test('synthetic command framing fixture has the family checksum', () {
    final text = File('test/fixtures/checksum-command-03-synthetic.hex')
        .readAsStringSync();
    final bytes = text
        .trim()
        .split(RegExp(r'\s+'))
        .map((value) => int.parse(value, radix: 16))
        .toList();

    final packet = ColmiCommandPacket.parse(bytes);
    expect(packet.commandId, 0x03);
    expect(packet.checksum, 0x03);
  });

  test(
    'packet creation pads and checksums without inventing payload semantics',
    () {
      final packet = ColmiCommandPacket.create(0x69, <int>[1, 2]);
      expect(packet.bytes, hasLength(16));
      expect(
        packet.checksum,
        ColmiCommandPacket.calculateChecksum(packet.bytes),
      );
    },
  );

  test('owned-R12 battery fixture validates and decodes', () {
    final fixture = jsonDecode(
      File(
        'test/fixtures/battery-command-03-physical-capture-rt11cr-1.00.09.json',
      ).readAsStringSync(),
    ) as Map<String, Object?>;
    final command = fixture['command']! as Map<String, Object?>;
    List<int> decodeHex(String value) => <int>[
      for (var index = 0; index < value.length; index += 2)
        int.parse(value.substring(index, index + 2), radix: 16),
    ];

    expect(
      decodeHex(command['requestHex']! as String),
      createBatteryRequest().bytes,
    );
    final reading = parseBatteryResponse(
      decodeHex(command['responseHex']! as String),
    );
    expect(reading.level, 36);
    expect(reading.charging, isFalse);
    expect(fixture['deviceAlias'], 'owned-r12-1');
    expect(jsonEncode(fixture), isNot(contains('00008130')));
  });

  test('bad length and checksum fail closed', () {
    expect(
      () => ColmiCommandPacket.parse(<int>[1, 2]),
      throwsA(isA<ColmiPacketFormatException>()),
    );
    final corrupt = ColmiCommandPacket.create(0x03).bytes.toList()..[15] = 0;
    expect(
      () => ColmiCommandPacket.parse(corrupt),
      throwsA(isA<ColmiPacketFormatException>()),
    );
  });

  test('valid live warm-up packets are a no-reading result, not a timeout', () {
    final packets = List<ColmiCommandPacket>.generate(
      3,
      (_) => ColmiCommandPacket.create(colmiLiveStartCommandId, const <int>[
        colmiLiveHeartRateKind,
        0,
        0,
      ]),
    );

    expect(
      classifyLiveReadingPackets(packets, kind: colmiLiveHeartRateKind),
      'noReading',
    );
  });

  test('big-data assembly is ordered, bounded, and duplicate-safe', () {
    final assembler = BigDataAssembler(maximumBytes: 4)
      ..add(
        const BigDataFragment(sequence: 0, payload: <int>[1, 2], isLast: false),
      )
      ..add(
        const BigDataFragment(sequence: 0, payload: <int>[1, 2], isLast: false),
      )
      ..add(const BigDataFragment(sequence: 1, payload: <int>[3], isLast: true))
      ..add(
        const BigDataFragment(sequence: 1, payload: <int>[3], isLast: true),
      );
    expect(assembler.bytes, <int>[1, 2, 3]);
    expect(assembler.isComplete, isTrue);
  });

  test('out-of-sequence fragments fail without partial guesswork', () {
    final assembler = BigDataAssembler();
    expect(
      () => assembler.add(
        const BigDataFragment(sequence: 1, payload: <int>[1], isLast: true),
      ),
      throwsA(isA<BigDataAssemblyException>()),
    );
  });

  test('conflicting duplicates and non-byte payloads fail closed', () {
    final assembler = BigDataAssembler()
      ..add(
        const BigDataFragment(sequence: 0, payload: <int>[1], isLast: false),
      );
    expect(
      () => assembler.add(
        const BigDataFragment(sequence: 0, payload: <int>[2], isLast: false),
      ),
      throwsA(isA<BigDataAssemblyException>()),
    );
    expect(
      () => assembler.add(
        const BigDataFragment(sequence: 1, payload: <int>[256], isLast: true),
      ),
      throwsA(isA<BigDataAssemblyException>()),
    );
  });
}
