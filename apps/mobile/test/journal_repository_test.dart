import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';

void main() {
  late Directory temporary;
  late FileJournalRepository repository;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp(
      'librering-journal-test-',
    );
    repository = FileJournalRepository(temporary);
  });

  tearDown(() async {
    if (await temporary.exists()) await temporary.delete(recursive: true);
  });

  test('persists, replaces, and separately deletes manual context', () async {
    final first = JournalEntry(
      id: 'swim|one',
      kind: JournalEntryKind.swim,
      occurredAtUtc: DateTime.utc(2026, 8, 26, 8),
      title: 'Pool swim',
      details: '40 minutes · steady effort',
      durationMinutes: 40,
      environment: '25 metres',
      effort: 'steady',
    );
    await repository.upsert(first);
    await repository.upsert(
      JournalEntry(
        id: first.id,
        kind: first.kind,
        occurredAtUtc: first.occurredAtUtc,
        title: first.title,
        details: '45 minutes · steady effort',
        durationMinutes: 45,
        environment: first.environment,
        effort: first.effort,
      ),
    );

    expect(await repository.read(), hasLength(1));
    expect((await repository.read()).single.durationMinutes, 45);
    expect((await repository.read()).single.toJson()['origin'], 'manual');

    expect(await repository.delete(first.id), isEmpty);
    expect(await repository.read(), isEmpty);
  });

  test('corrupt journal fails closed without being overwritten', () async {
    final file = File('${temporary.path}/librering/journal-v1.json');
    await file.parent.create(recursive: true);
    await file.writeAsString('{not-json');

    await expectLater(repository.read(), throwsA(isA<JournalStoreException>()));
    expect(await file.readAsString(), '{not-json');
  });
}
