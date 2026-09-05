import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/storage/data_export_service.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';
import 'package:librering_mobile/src/storage/preferences_repository.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  test(
    'overlapping journal saves are serialized without losing entries',
    () async {
      final repository = _JournalRepository();
      final container = ProviderContainer(
        overrides: [journalRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(journalProvider.future);
      final controller = container.read(journalProvider.notifier);
      await Future.wait([
        controller.saveCheckIn(
          tags: ['Exercise'],
          note: 'First',
          occurredAtUtc: DateTime.utc(2026, 9, 1),
        ),
        controller.saveCheckIn(
          tags: ['Travel'],
          note: 'Second',
          occurredAtUtc: DateTime.utc(2026, 9, 2),
        ),
      ]);
      expect(repository.maximumConcurrentWrites, 1);
      expect(container.read(journalProvider).requireValue, hasLength(2));
    },
  );

  test('journal failure retains cached entries and allows retry', () async {
    final repository = _JournalRepository()..entries = [_entry];
    final container = ProviderContainer(
      overrides: [journalRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(journalProvider.future);
    repository.failNextWrite = true;
    final controller = container.read(journalProvider.notifier);
    await expectLater(
      controller.saveCheckIn(tags: ['Exercise'], note: 'Retry'),
      throwsStateError,
    );
    expect(container.read(journalProvider).value, hasLength(1));
    expect(container.read(journalProvider).hasError, isFalse);
    await controller.saveCheckIn(tags: ['Exercise'], note: 'Retry');
    expect(container.read(journalProvider).requireValue, hasLength(2));
  });

  test(
    'exports wait for journal initialization instead of omitting entries',
    () async {
      final journalRead = Completer<List<JournalEntry>>();
      final exporter = _Exporter();
      final container = ProviderContainer(
        overrides: [
          ringDataRepositoryProvider.overrideWithValue(_RingRepository()),
          journalRepositoryProvider.overrideWithValue(
            _JournalRepository(initialRead: journalRead.future),
          ),
          dataExportServiceProvider.overrideWithValue(exporter),
        ],
      );
      addTearDown(container.dispose);
      final pending = container.read(dataExportProvider.notifier).create();
      await Future<void>.delayed(Duration.zero);
      expect(exporter.calls, 0);
      journalRead.complete([_entry]);
      await pending;
      expect(exporter.exportedJournal, [_entry]);
    },
  );

  test('unreadable journal prevents an incomplete export', () async {
    final exporter = _Exporter();
    final journalRead = Completer<List<JournalEntry>>();
    final container = ProviderContainer(
      overrides: [
        ringDataRepositoryProvider.overrideWithValue(_RingRepository()),
        journalRepositoryProvider.overrideWithValue(
          _JournalRepository(initialRead: journalRead.future),
        ),
        dataExportServiceProvider.overrideWithValue(exporter),
      ],
    );
    addTearDown(container.dispose);
    final pending = container.read(dataExportProvider.notifier).create();
    final assertion = expectLater(pending, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    journalRead.completeError(StateError('Journal unreadable'));
    await assertion;
    expect(exporter.calls, 0);
    expect(container.read(dataExportProvider).hasError, isTrue);
  });

  test('failed sync storage keeps the last visible dataset', () async {
    final repository = _RingRepository();
    final container = ProviderContainer(
      overrides: [ringDataRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final original = await container.read(ringDataProvider.future);
    await expectLater(
      container.read(ringDataProvider.notifier).merge(repository.dataset),
      throwsStateError,
    );
    expect(container.read(ringDataProvider).value, same(original));
    expect(container.read(ringDataProvider).hasError, isFalse);
  });

  test(
    'ring merge waits for initial read so it cannot restore stale data',
    () async {
      final repository = _DelayedRingRepository();
      final container = ProviderContainer(
        overrides: [ringDataRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final incoming = RingSyncDataset(
        availability: const {},
        lastSyncedAtUtc: DateTime.utc(2026, 9, 2),
        source: const RingDataSource(driverId: 'synthetic-new'),
      );
      final pending = container.read(ringDataProvider.notifier).merge(incoming);
      await Future<void>.delayed(Duration.zero);
      expect(repository.writes, 0);
      repository.firstRead.complete(_RingRepository().dataset);
      await pending;
      await Future<void>.delayed(Duration.zero);
      expect(repository.writes, 1);
      expect(container.read(ringDataProvider).requireValue, same(incoming));
    },
  );

  test(
    'ring deletion waits for initial read so deleted data cannot reappear',
    () async {
      final repository = _DelayedRingRepository();
      final container = ProviderContainer(
        overrides: [ringDataRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final pending = container.read(ringDataProvider.notifier).deleteAll();
      await Future<void>.delayed(Duration.zero);
      expect(repository.deletes, 0);
      repository.firstRead.complete(_RingRepository().dataset);
      await pending;
      await Future<void>.delayed(Duration.zero);
      expect(repository.deletes, 1);
      expect(container.read(ringDataProvider).requireValue, isNull);
    },
  );

  test('explicit deletion can remove an unreadable ring store', () async {
    final repository = _DelayedRingRepository();
    final container = ProviderContainer(
      overrides: [ringDataRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final pending = container.read(ringDataProvider.notifier).deleteAll();
    await Future<void>.delayed(Duration.zero);
    repository.firstRead.completeError(StateError('Synthetic corrupt storage'));
    await pending;
    await Future<void>.delayed(Duration.zero);
    expect(repository.deletes, 1);
    expect(container.read(ringDataProvider).requireValue, isNull);
  });

  test(
    'a successful corrupt-store deletion allows the next ring sync',
    () async {
      final repository = _DelayedRingRepository()..failDelete = true;
      final container = ProviderContainer(
        overrides: [ringDataRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final initialFailure = expectLater(
        container.read(ringDataProvider.future),
        throwsStateError,
      );
      repository.firstRead.completeError(
        StateError('Synthetic corrupt storage'),
      );
      await initialFailure;
      final controller = container.read(ringDataProvider.notifier);
      final incoming = _RingRepository().dataset;
      await expectLater(controller.deleteAll(), throwsStateError);
      // A failed delete must not unlock overwriting an unreadable store.
      await expectLater(controller.merge(incoming), throwsStateError);
      expect(repository.writes, 0);
      repository.failDelete = false;
      await controller.deleteAll();
      await controller.merge(incoming);
      expect(repository.deletes, 2);
      expect(repository.writes, 1);
      expect(container.read(ringDataProvider).requireValue, same(incoming));
    },
  );

  test(
    'preferences notify consumers only after durable save succeeds',
    () async {
      final repository = _PreferencesRepository();
      final container = ProviderContainer(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appPreferencesProvider.future);
      await container
          .read(appPreferencesProvider.notifier)
          .save(const AppPreferences(displayName: 'Alex', dailyStepGoal: 8000));
      expect(
        container.read(appPreferencesProvider).requireValue.dailyStepGoal,
        8000,
      );
      repository.fail = true;
      await expectLater(
        container
            .read(appPreferencesProvider.notifier)
            .save(const AppPreferences(dailyStepGoal: 9000)),
        throwsStateError,
      );
      expect(container.read(appPreferencesProvider).value!.dailyStepGoal, 8000);
      expect(repository.saved.dailyStepGoal, 8000);
    },
  );

  test(
    'unreadable journal only resumes saves after successful explicit deletion',
    () async {
      final firstRead = Completer<List<JournalEntry>>();
      final repository = _JournalRepository(initialRead: firstRead.future)
        ..entries = [_entry]
        ..failDelete = true;
      final container = ProviderContainer(
        overrides: [journalRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final initialFailure = expectLater(
        container.read(journalProvider.future),
        throwsStateError,
      );
      firstRead.completeError(StateError('Synthetic corrupt journal'));
      await initialFailure;
      final controller = container.read(journalProvider.notifier);
      final previous = container.read(journalProvider);
      await expectLater(controller.deleteAll(), throwsStateError);
      // Riverpod may recreate the AsyncValue wrapper when notifying listeners.
      expect(container.read(journalProvider).error, same(previous.error));
      expect(
        container.read(journalProvider).stackTrace,
        same(previous.stackTrace),
      );
      expect(container.read(journalProvider).hasValue, isFalse);
      expect(repository.entries, [_entry]);
      await expectLater(
        controller.saveCheckIn(tags: ['Travel'], note: 'Blocked'),
        throwsStateError,
      );
      repository.failDelete = false;
      await controller.deleteAll();
      await controller.saveCheckIn(tags: ['Travel'], note: 'Recovered');
      expect(repository.entries.single.details, 'Recovered');
      expect(
        container.read(journalProvider).requireValue.single.details,
        'Recovered',
      );
    },
  );

  test('unimplemented cycle controls cannot grant consent', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(privacySettingsProvider.notifier);
    controller.setKeepLocal(true);
    controller.setUseAsContext(true);
    controller.setAllowExport(true);
    final settings = container.read(privacySettingsProvider);
    expect(settings.keepLocal, isFalse);
    expect(settings.useAsContext, isFalse);
    expect(settings.allowExport, isFalse);
  });

  testWidgets('the local clock refreshes rather than freezing on first read', (
    tester,
  ) async {
    final container = ProviderContainer();
    final first = container.read(currentLocalTimeProvider);
    await tester.pump(const Duration(minutes: 1));
    final second = container.read(currentLocalTimeProvider);
    expect(second.isAfter(first), isTrue);
    container.dispose();
  });
}

final _entry = JournalEntry(
  id: 'checkIn|existing',
  kind: JournalEntryKind.checkIn,
  occurredAtUtc: DateTime.utc(2026, 8, 31),
  title: 'Travel',
  details: 'A fictional note',
);

class _JournalRepository implements JournalRepository {
  _JournalRepository({this.initialRead});
  final Future<List<JournalEntry>>? initialRead;
  List<JournalEntry> entries = [];
  bool failNextWrite = false;
  bool failDelete = false;
  int activeWrites = 0;
  int maximumConcurrentWrites = 0;
  @override
  Future<List<JournalEntry>> read() async => initialRead ?? entries;
  @override
  Future<List<JournalEntry>> upsert(JournalEntry entry) async {
    activeWrites++;
    if (activeWrites > maximumConcurrentWrites) {
      maximumConcurrentWrites = activeWrites;
    }
    final snapshot = [...entries];
    await Future<void>.delayed(const Duration(milliseconds: 1));
    activeWrites--;
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Disk unavailable');
    }
    entries = [...snapshot.where((e) => e.id != entry.id), entry];
    return entries;
  }

  @override
  Future<List<JournalEntry>> delete(String id) async =>
      entries = entries.where((e) => e.id != id).toList();
  @override
  Future<void> deleteAll() async {
    if (failDelete) throw StateError('Synthetic journal delete failure');
    entries = [];
  }
}

class _RingRepository implements RingDataRepository {
  final dataset = RingSyncDataset(
    availability: const {},
    lastSyncedAtUtc: DateTime.utc(2026, 9, 1),
    source: const RingDataSource(
      driverId: 'test',
      firmwareVersion: 'fictional',
    ),
  );
  @override
  Future<RingSyncDataset?> read() async => dataset;
  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) =>
      throw StateError('Disk unavailable');
  @override
  Future<void> deleteAll() async {}
}

class _DelayedRingRepository implements RingDataRepository {
  final firstRead = Completer<RingSyncDataset?>();
  int writes = 0;
  int deletes = 0;
  bool failDelete = false;
  @override
  Future<RingSyncDataset?> read() => firstRead.future;
  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async {
    writes++;
    return incoming;
  }

  @override
  Future<void> deleteAll() async {
    deletes++;
    if (failDelete) throw StateError('Synthetic delete failure');
  }
}

class _Exporter implements DataExportService {
  int calls = 0;
  List<JournalEntry>? exportedJournal;
  @override
  Future<LocalExportResult> create({
    required RingSyncDataset dataset,
    required List<JournalEntry> journal,
  }) async {
    calls++;
    exportedJournal = journal;
    return LocalExportResult(
      jsonFile: File('/unused.json'),
      csvFile: File('/unused.csv'),
      rowCount: journal.length,
      sha256: '0' * 64,
      createdAtUtc: DateTime.utc(2026, 9, 1),
    );
  }
}

class _PreferencesRepository implements PreferencesRepository {
  AppPreferences saved = const AppPreferences();
  bool fail = false;
  @override
  Future<AppPreferences> read() async => saved;
  @override
  Future<void> save(AppPreferences preferences) async {
    if (fail) throw StateError('Disk unavailable');
    saved = preferences;
  }
}
