import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/storage/data_export_service.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  test('exports portable JSON and CSV without a device identifier', () async {
    final directory = await Directory.systemTemp.createTemp(
      'librering-export-test-',
    );
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final service = FileDataExportService(
      directory,
      clock: () => DateTime.utc(2026, 8, 26, 12),
    );
    final result = await service.create(
      dataset: RingSyncDataset(
        lastSyncedAtUtc: DateTime.utc(2026, 8, 26, 11),
        source: const RingDataSource(
          driverId: 'colmi-qring-v1',
          firmwareVersion: 'verified-test-firmware',
        ),
        availability: const <RingDataKind, RingDataAvailability>{
          RingDataKind.heartRate: RingDataAvailability.complete,
        },
        heartRate: <RingHeartRateSample>[
          RingHeartRateSample(
            measuredAtUtc: DateTime.utc(2026, 8, 26, 10),
            bpm: 62,
          ),
        ],
      ),
      journal: <JournalEntry>[
        JournalEntry(
          id: 'swim|one',
          kind: JournalEntryKind.swim,
          occurredAtUtc: DateTime.utc(2026, 8, 25, 8),
          title: 'Pool swim',
          details: '40 minutes · steady effort',
          durationMinutes: 40,
        ),
      ],
    );

    expect(result.rowCount, 2);
    expect(result.sha256, hasLength(64));
    final jsonText = await result.jsonFile.readAsString();
    final json = jsonDecode(jsonText) as Map<String, Object?>;
    expect(
      (json['privacy'] as Map<String, Object?>)['deviceIdentifierIncluded'],
      isFalse,
    );
    expect(json.keys, isNot(contains('deviceId')));
    expect(
      (json['source'] as Map<String, Object?>).keys,
      isNot(contains('deviceId')),
    );
    expect(jsonText, isNot(contains('advertisedName')));
    expect(await result.csvFile.readAsString(), contains('ring_measurement'));
    expect(await result.csvFile.readAsString(), contains('journal_swim'));
  });
}
