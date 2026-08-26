import 'dart:convert';
import 'dart:io';

enum JournalEntryKind { swim, checkIn, note }

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.kind,
    required this.occurredAtUtc,
    required this.title,
    required this.details,
    this.durationMinutes,
    this.environment,
    this.effort,
  });

  final String id;
  final JournalEntryKind kind;
  final DateTime occurredAtUtc;
  final String title;
  final String details;
  final int? durationMinutes;
  final String? environment;
  final String? effort;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'kind': kind.name,
    'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
    'title': title,
    'details': details,
    'durationMinutes': durationMinutes,
    'environment': environment,
    'effort': effort,
    'origin': 'manual',
  };

  factory JournalEntry.fromJson(Map<String, Object?> value) {
    final id = value['id'];
    final kind = value['kind'];
    final occurredAtUtc = value['occurredAtUtc'];
    final title = value['title'];
    final details = value['details'];
    final durationMinutes = value['durationMinutes'];
    final environment = value['environment'];
    final effort = value['effort'];
    if (id is! String ||
        id.isEmpty ||
        kind is! String ||
        occurredAtUtc is! String ||
        title is! String ||
        details is! String ||
        (durationMinutes != null && durationMinutes is! int) ||
        (environment != null && environment is! String) ||
        (effort != null && effort is! String)) {
      throw const FormatException('Invalid journal entry.');
    }
    return JournalEntry(
      id: id,
      kind: JournalEntryKind.values.firstWhere(
        (value) => value.name == kind,
        orElse: () => throw FormatException('Unknown journal kind: $kind.'),
      ),
      occurredAtUtc: DateTime.parse(occurredAtUtc).toUtc(),
      title: title,
      details: details,
      durationMinutes: durationMinutes as int?,
      environment: environment as String?,
      effort: effort as String?,
    );
  }
}

abstract interface class JournalRepository {
  Future<List<JournalEntry>> read();

  Future<List<JournalEntry>> upsert(JournalEntry entry);

  Future<List<JournalEntry>> delete(String id);

  Future<void> deleteAll();
}

class JournalStoreException implements Exception {
  const JournalStoreException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'JournalStoreException: $message';
}

class FileJournalRepository implements JournalRepository {
  FileJournalRepository(Directory applicationSupportDirectory)
    : _file = File(
        '${applicationSupportDirectory.path}/librering/journal-v1.json',
      );

  static const schemaVersion = 1;
  final File _file;

  @override
  Future<List<JournalEntry>> read() async {
    if (!await _file.exists()) return const <JournalEntry>[];
    try {
      final root = jsonDecode(await _file.readAsString());
      if (root is! Map<String, Object?> ||
          root['schemaVersion'] != schemaVersion ||
          root['entries'] is! List<Object?>) {
        throw const FormatException('Invalid journal root.');
      }
      final entries = (root['entries'] as List<Object?>).map((item) {
        if (item is! Map<String, Object?>) {
          throw const FormatException('Invalid journal entry object.');
        }
        return JournalEntry.fromJson(item);
      }).toList();
      entries.sort(
        (left, right) => right.occurredAtUtc.compareTo(left.occurredAtUtc),
      );
      return List<JournalEntry>.unmodifiable(entries);
    } catch (error) {
      throw JournalStoreException(
        'Stored journal data is invalid and was not used.',
        error,
      );
    }
  }

  @override
  Future<List<JournalEntry>> upsert(JournalEntry entry) async {
    final entries = <String, JournalEntry>{
      for (final existing in await read()) existing.id: existing,
      entry.id: entry,
    }.values.toList();
    entries.sort(
      (left, right) => right.occurredAtUtc.compareTo(left.occurredAtUtc),
    );
    await _write(entries);
    return List<JournalEntry>.unmodifiable(entries);
  }

  @override
  Future<List<JournalEntry>> delete(String id) async {
    final entries = (await read())
        .where((entry) => entry.id != id)
        .toList(growable: false);
    await _write(entries);
    return entries;
  }

  @override
  Future<void> deleteAll() async {
    final temporary = File('${_file.path}.tmp');
    if (await temporary.exists()) await temporary.delete();
    if (await _file.exists()) await _file.delete();
  }

  Future<void> _write(List<JournalEntry> entries) async {
    try {
      await _file.parent.create(recursive: true);
      final temporary = File('${_file.path}.tmp');
      if (await temporary.exists()) await temporary.delete();
      await temporary.writeAsString(
        jsonEncode(<String, Object?>{
          'schemaVersion': schemaVersion,
          'entries': entries
              .map((entry) => entry.toJson())
              .toList(growable: false),
        }),
        flush: true,
      );
      await temporary.rename(_file.path);
    } catch (error) {
      throw JournalStoreException('Journal data could not be stored.', error);
    }
  }
}
