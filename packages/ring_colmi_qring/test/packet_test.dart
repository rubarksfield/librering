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
