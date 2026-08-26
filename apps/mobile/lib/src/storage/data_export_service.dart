import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ring_core/ring_core.dart';

import 'journal_repository.dart';

class LocalExportResult {
  const LocalExportResult({
    required this.jsonFile,
    required this.csvFile,
    required this.rowCount,
    required this.sha256,
    required this.createdAtUtc,
  });

  final File jsonFile;
  final File csvFile;
  final int rowCount;
  final String sha256;
  final DateTime createdAtUtc;
}

abstract interface class DataExportService {
  Future<LocalExportResult> create({
    required RingSyncDataset dataset,
    required List<JournalEntry> journal,
  });
}

class FileDataExportService implements DataExportService {
  FileDataExportService(this.directory, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Directory directory;
  final DateTime Function() _clock;

  @override
  Future<LocalExportResult> create({
    required RingSyncDataset dataset,
    required List<JournalEntry> journal,
  }) async {
    final createdAtUtc = _clock().toUtc();
    final stamp = createdAtUtc
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '-');
    await directory.create(recursive: true);
    final jsonFile = File('${directory.path}/librering-export-$stamp.json');
    final csvFile = File('${directory.path}/librering-export-$stamp.csv');
    final jsonText = const JsonEncoder.withIndent('  ')
        .convert(_json(dataset, journal, createdAtUtc));
    final checksum = sha256.convert(utf8.encode(jsonText)).toString();
    await jsonFile.writeAsString(jsonText, flush: true);
    await csvFile.writeAsString(_csv(dataset, journal), flush: true);
    return LocalExportResult(
      jsonFile: jsonFile,
      csvFile: csvFile,
      rowCount: dataset.recordCount + journal.length,
      sha256: checksum,
      createdAtUtc: createdAtUtc,
    );
  }

  Map<String, Object?> _json(
    RingSyncDataset dataset,
    List<JournalEntry> journal,
    DateTime createdAtUtc,
  ) => <String, Object?>{
    'schemaVersion': 1,
    'createdAtUtc': createdAtUtc.toIso8601String(),
    'privacy': <String, Object?>{
      'account': false,
      'deviceIdentifierIncluded': false,
      'rawPacketsIncluded': false,
    },
    'source': <String, Object?>{
      'driverId': dataset.source.driverId,
      'firmwareVersion': dataset.source.firmwareVersion,
      'lastSyncedAtUtc': dataset.lastSyncedAtUtc.toUtc().toIso8601String(),
    },
    'availability': <String, String>{
      for (final item in dataset.availability.entries)
        item.key.name: item.value.name,
    },
    'battery': <String, Object?>{
      'level': dataset.batteryLevel,
      'charging': dataset.charging,
    },
    'activity': dataset.activity
        .map(
          (value) => <String, Object?>{
            'startedAtUtc': value.startedAtUtc.toUtc().toIso8601String(),
            'steps': value.steps,
            'distanceMeters': value.distanceMeters,
            'firmwareCalories': value.firmwareCalories,
            'origin': 'ringFirmwareEstimate',
          },
        )
        .toList(growable: false),
    'heartRate': dataset.heartRate
        .map(
          (value) => <String, Object?>{
            'measuredAtUtc': value.measuredAtUtc.toUtc().toIso8601String(),
            'bpm': value.bpm,
            'origin': 'ringMeasurement',
          },
        )
        .toList(growable: false),
    'oxygen': dataset.oxygen
        .map(
          (value) => <String, Object?>{
            'hourStartedAtUtc': value.hourStartedAtUtc
                .toUtc()
                .toIso8601String(),
            'minimumPercent': value.minimumPercent,
            'maximumPercent': value.maximumPercent,
            'origin': 'ringHistoryRange',
          },
        )
        .toList(growable: false),
    'sleep': dataset.sleep
        .map(
          (value) => <String, Object?>{
            'startedAtUtc': value.startedAtUtc.toUtc().toIso8601String(),
            'endedAtUtc': value.endedAtUtc.toUtc().toIso8601String(),
            'origin': 'ringFirmwareEstimate',
            'stages': value.stages
                .map(
                  (span) => <String, Object?>{
                    'stage': span.stage.name,
                    'startedAtUtc': span.startedAtUtc.toUtc().toIso8601String(),
                    'durationMinutes': span.durationMinutes,
                    'origin': 'ringFirmwareEstimate',
                  },
                )
                .toList(growable: false),
          },
        )
        .toList(growable: false),
    'opaqueVendorIndexes': dataset.vendorIndexes
        .map(
          (value) => <String, Object?>{
            'measuredAtUtc': value.measuredAtUtc.toUtc().toIso8601String(),
            'kind': value.kind.name,
            'value': value.value,
            'semanticStatus': 'unknown',
            'usedInScores': false,
          },
        )
        .toList(growable: false),
    'journal': journal.map((entry) => entry.toJson()).toList(growable: false),
  };

  String _csv(RingSyncDataset dataset, List<JournalEntry> journal) {
    final rows = <List<Object?>>[
      <Object?>[
        'record_type',
        'timestamp_utc',
        'value',
        'unit',
        'source',
        'confidence',
        'details',
      ],
      for (final value in dataset.activity)
        <Object?>[
          'activity',
          value.startedAtUtc.toUtc().toIso8601String(),
          value.steps,
          'steps',
          'ring_firmware_estimate',
          'moderate',
          '${value.distanceMeters} m; ${value.firmwareCalories} firmware calories',
        ],
      for (final value in dataset.heartRate)
        <Object?>[
          'heart_rate',
          value.measuredAtUtc.toUtc().toIso8601String(),
          value.bpm,
          'bpm',
          'ring_measurement',
          'high',
          '',
        ],
      for (final value in dataset.oxygen)
        <Object?>[
          'oxygen_range',
          value.hourStartedAtUtc.toUtc().toIso8601String(),
          '${value.minimumPercent}-${value.maximumPercent}',
          'percent',
          'ring_history_range',
          'moderate',
          'hourly range; not a live reading',
        ],
      for (final value in dataset.sleep)
        <Object?>[
          'sleep_session',
          value.startedAtUtc.toUtc().toIso8601String(),
          value.endedAtUtc.difference(value.startedAtUtc).inMinutes,
          'minutes',
          'ring_firmware_estimate',
          value.stages.isEmpty ? 'limited' : 'moderate',
          '${value.stages.length} firmware stage runs',
        ],
      for (final value in dataset.vendorIndexes)
        <Object?>[
          'opaque_${value.kind.name}',
          value.measuredAtUtc.toUtc().toIso8601String(),
          value.value,
          'unknown',
          'ring_firmware_index',
          'unavailable',
          'unknown semantics; excluded from scores',
        ],
      for (final entry in journal)
        <Object?>[
          'journal_${entry.kind.name}',
          entry.occurredAtUtc.toUtc().toIso8601String(),
          entry.durationMinutes ?? '',
          entry.durationMinutes == null ? '' : 'minutes',
          'manual',
          'high',
          '${entry.title}; ${entry.details}',
        ],
    ];
    return rows.map((row) => row.map(_cell).join(',')).join('\n');
  }

  String _cell(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }
}
