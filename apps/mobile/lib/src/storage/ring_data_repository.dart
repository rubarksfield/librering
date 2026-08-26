import 'dart:convert';
import 'dart:io';

import 'package:ring_core/ring_core.dart';

abstract interface class RingDataRepository {
  Future<RingSyncDataset?> read();

  Future<RingSyncDataset> merge(RingSyncDataset incoming);

  Future<void> deleteAll();
}

class RingDataStoreException implements Exception {
  const RingDataStoreException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'RingDataStoreException: $message';
}

class FileRingDataRepository implements RingDataRepository {
  FileRingDataRepository(
    Directory applicationSupportDirectory, {
    this.retention = const Duration(days: 400),
  }) : _file = File(
         '${applicationSupportDirectory.path}/librering/ring-data-v1.json',
       );

  static const int schemaVersion = 1;

  final File _file;
  final Duration retention;

  @override
  Future<RingSyncDataset?> read() async {
    if (!await _file.exists()) return null;
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Root must be a JSON object.');
      }
      return _decodeDataset(decoded);
    } on RingDataStoreException {
      rethrow;
    } catch (error) {
      throw RingDataStoreException(
        'Stored ring data is invalid and was not used.',
        error,
      );
    }
  }

  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async {
    final existing = await read();
    final latestSync =
        existing == null ||
            incoming.lastSyncedAtUtc.isAfter(existing.lastSyncedAtUtc)
        ? incoming.lastSyncedAtUtc.toUtc()
        : existing.lastSyncedAtUtc.toUtc();
    final cutoff = latestSync.subtract(retention);

    final merged = RingSyncDataset(
      lastSyncedAtUtc: latestSync,
      source: incoming.source,
      availability: <RingDataKind, RingDataAvailability>{
        ...?existing?.availability,
        ...incoming.availability,
      },
      activity: _mergeRecords<RingActivityBucket>(
        existing?.activity ?? const <RingActivityBucket>[],
        incoming.activity,
        keyOf: (value) => value.recordKey,
        dateOf: (value) => value.startedAtUtc,
        cutoff: cutoff,
      ),
      heartRate: _mergeRecords<RingHeartRateSample>(
        existing?.heartRate ?? const <RingHeartRateSample>[],
        incoming.heartRate,
        keyOf: (value) => value.recordKey,
        dateOf: (value) => value.measuredAtUtc,
        cutoff: cutoff,
      ),
      vendorIndexes: _mergeRecords<RingVendorIndexSample>(
        existing?.vendorIndexes ?? const <RingVendorIndexSample>[],
        incoming.vendorIndexes,
        keyOf: (value) => value.recordKey,
        dateOf: (value) => value.measuredAtUtc,
        cutoff: cutoff,
      ),
      oxygen: _mergeRecords<RingOxygenRange>(
        existing?.oxygen ?? const <RingOxygenRange>[],
        incoming.oxygen,
        keyOf: (value) => value.recordKey,
        dateOf: (value) => value.hourStartedAtUtc,
        cutoff: cutoff,
      ),
      sleep: _mergeRecords<RingSleepSession>(
        existing?.sleep ?? const <RingSleepSession>[],
        incoming.sleep,
        keyOf: (value) => value.recordKey,
        dateOf: (value) => value.startedAtUtc,
        cutoff: cutoff,
      ),
      batteryLevel: incoming.batteryLevel ?? existing?.batteryLevel,
      charging: incoming.charging ?? existing?.charging,
    );
    await _write(merged);
    return merged;
  }

  @override
  Future<void> deleteAll() async {
    final temporary = File('${_file.path}.tmp');
    if (await temporary.exists()) await temporary.delete();
    if (await _file.exists()) await _file.delete();
  }

  List<T> _mergeRecords<T>(
    Iterable<T> existing,
    Iterable<T> incoming, {
    required String Function(T value) keyOf,
    required DateTime Function(T value) dateOf,
    required DateTime cutoff,
  }) {
    final records = <String, T>{
      for (final value in existing) keyOf(value): value,
      for (final value in incoming) keyOf(value): value,
    };
    final retained = records.values
        .where((value) => !dateOf(value).toUtc().isBefore(cutoff))
        .toList();
    retained.sort((left, right) => dateOf(left).compareTo(dateOf(right)));
    return retained;
  }

  Future<void> _write(RingSyncDataset dataset) async {
    try {
      await _file.parent.create(recursive: true);
      final temporary = File('${_file.path}.tmp');
      if (await temporary.exists()) await temporary.delete();
      await temporary.writeAsString(
        jsonEncode(_encodeDataset(dataset)),
        flush: true,
      );
      await temporary.rename(_file.path);
    } catch (error) {
      throw RingDataStoreException('Ring data could not be stored.', error);
    }
  }

  Map<String, Object?> _encodeDataset(RingSyncDataset dataset) =>
      <String, Object?>{
        'schemaVersion': schemaVersion,
        'lastSyncedAtUtc': _date(dataset.lastSyncedAtUtc),
        'source': <String, Object?>{
          'driverId': dataset.source.driverId,
          'firmwareVersion': dataset.source.firmwareVersion,
        },
        'availability': <String, String>{
          for (final entry in dataset.availability.entries)
            entry.key.name: entry.value.name,
        },
        'batteryLevel': dataset.batteryLevel,
        'charging': dataset.charging,
        'activity': dataset.activity
            .map(
              (value) => <String, Object?>{
                'startedAtUtc': _date(value.startedAtUtc),
                'steps': value.steps,
                'distanceMeters': value.distanceMeters,
                'firmwareCalories': value.firmwareCalories,
              },
            )
            .toList(growable: false),
        'heartRate': dataset.heartRate
            .map(
              (value) => <String, Object?>{
                'measuredAtUtc': _date(value.measuredAtUtc),
                'bpm': value.bpm,
              },
            )
            .toList(growable: false),
        'vendorIndexes': dataset.vendorIndexes
            .map(
              (value) => <String, Object?>{
                'measuredAtUtc': _date(value.measuredAtUtc),
                'value': value.value,
                'kind': value.kind.name,
              },
            )
            .toList(growable: false),
        'oxygen': dataset.oxygen
            .map(
              (value) => <String, Object?>{
                'hourStartedAtUtc': _date(value.hourStartedAtUtc),
                'minimumPercent': value.minimumPercent,
                'maximumPercent': value.maximumPercent,
              },
            )
            .toList(growable: false),
        'sleep': dataset.sleep
            .map(
              (value) => <String, Object?>{
                'startedAtUtc': _date(value.startedAtUtc),
                'endedAtUtc': _date(value.endedAtUtc),
                'stages': value.stages
                    .map(
                      (span) => <String, Object?>{
                        'stage': span.stage.name,
                        'startedAtUtc': _date(span.startedAtUtc),
                        'durationMinutes': span.durationMinutes,
                      },
                    )
                    .toList(growable: false),
              },
            )
            .toList(growable: false),
      };

  RingSyncDataset _decodeDataset(Map<String, Object?> value) {
    if (_integer(value, 'schemaVersion') != schemaVersion) {
      throw const RingDataStoreException(
        'Stored ring data uses an unsupported schema version.',
      );
    }
    final source = _map(value, 'source');
    final availability = <RingDataKind, RingDataAvailability>{};
    for (final entry in _map(value, 'availability').entries) {
      availability[_enumValue(RingDataKind.values, entry.key)] = _enumValue(
        RingDataAvailability.values,
        entry.value,
      );
    }
    return RingSyncDataset(
      lastSyncedAtUtc: _dateTime(value, 'lastSyncedAtUtc'),
      source: RingDataSource(
        driverId: _string(source, 'driverId'),
        firmwareVersion: _nullableString(source, 'firmwareVersion'),
      ),
      availability: availability,
      batteryLevel: _nullableInteger(value, 'batteryLevel'),
      charging: _nullableBoolean(value, 'charging'),
      activity: _list(value, 'activity').map((item) {
        final record = _object(item);
        return RingActivityBucket(
          startedAtUtc: _dateTime(record, 'startedAtUtc'),
          steps: _integer(record, 'steps'),
          distanceMeters: _integer(record, 'distanceMeters'),
          firmwareCalories: _integer(record, 'firmwareCalories'),
        );
      }),
      heartRate: _list(value, 'heartRate').map((item) {
        final record = _object(item);
        return RingHeartRateSample(
          measuredAtUtc: _dateTime(record, 'measuredAtUtc'),
          bpm: _integer(record, 'bpm'),
        );
      }),
      vendorIndexes: _list(value, 'vendorIndexes').map((item) {
        final record = _object(item);
        return RingVendorIndexSample(
          measuredAtUtc: _dateTime(record, 'measuredAtUtc'),
          value: _integer(record, 'value'),
          kind: _enumValue(RingVendorIndexKind.values, record['kind']),
        );
      }),
      oxygen: _list(value, 'oxygen').map((item) {
        final record = _object(item);
        return RingOxygenRange(
          hourStartedAtUtc: _dateTime(record, 'hourStartedAtUtc'),
          minimumPercent: _integer(record, 'minimumPercent'),
          maximumPercent: _integer(record, 'maximumPercent'),
        );
      }),
      sleep: _list(value, 'sleep').map((item) {
        final record = _object(item);
        return RingSleepSession(
          startedAtUtc: _dateTime(record, 'startedAtUtc'),
          endedAtUtc: _dateTime(record, 'endedAtUtc'),
          stages: _list(record, 'stages').map((item) {
            final span = _object(item);
            return RingSleepStageSpan(
              stage: _enumValue(RingSleepStage.values, span['stage']),
              startedAtUtc: _dateTime(span, 'startedAtUtc'),
              durationMinutes: _integer(span, 'durationMinutes'),
            );
          }),
        );
      }),
    );
  }

  String _date(DateTime value) => value.toUtc().toIso8601String();

  DateTime _dateTime(Map<String, Object?> value, String key) =>
      DateTime.parse(_string(value, key)).toUtc();

  Map<String, Object?> _map(Map<String, Object?> value, String key) =>
      _object(value[key]);

  Map<String, Object?> _object(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('Expected a JSON object.');
    }
    return value;
  }

  List<Object?> _list(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result is! List<Object?>) {
      throw FormatException('Expected $key to be a JSON array.');
    }
    return result;
  }

  String _string(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result is! String || result.isEmpty) {
      throw FormatException('Expected $key to be a non-empty string.');
    }
    return result;
  }

  String? _nullableString(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result == null) return null;
    if (result is! String) {
      throw FormatException('Expected $key to be a string.');
    }
    return result;
  }

  int _integer(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result is! int) {
      throw FormatException('Expected $key to be an integer.');
    }
    return result;
  }

  int? _nullableInteger(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result == null) return null;
    if (result is! int) {
      throw FormatException('Expected $key to be an integer.');
    }
    return result;
  }

  bool? _nullableBoolean(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result == null) return null;
    if (result is! bool) {
      throw FormatException('Expected $key to be a boolean.');
    }
    return result;
  }

  T _enumValue<T extends Enum>(Iterable<T> values, Object? name) {
    if (name is! String) throw const FormatException('Invalid enum value.');
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () => throw FormatException('Unknown enum value: $name.'),
    );
  }
}
