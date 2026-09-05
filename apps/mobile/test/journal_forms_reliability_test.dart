import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/screens.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    Widget screen,
    _JournalRepository repository,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton saveButton(WidgetTester tester, String key) =>
      tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(FilledButton),
        ),
      );

  testWidgets('an older swim does not mark a new unsaved form as saved', (
    tester,
  ) async {
    final repository = _JournalRepository()..entries = [_oldSwim];
    await show(tester, const SwimEntryScreen(), repository);
    await tester.ensureVisible(find.byKey(const Key('swim-save-status')));
    expect(find.text('Not yet saved'), findsOneWidget);
    expect(find.text('Saved locally · Manual source'), findsNothing);
    expect(saveButton(tester, 'save-swim').onPressed, isNotNull);
    expect(repository.upserts, 0);
  });

  testWidgets(
    'swim saves reject rapid repeats and require a change after success',
    (tester) async {
      final gate = Completer<void>();
      final repository = _JournalRepository()..writeGate = gate.future;
      await show(tester, const SwimEntryScreen(), repository);
      final submit = saveButton(tester, 'save-swim').onPressed!;
      submit();
      submit();
      await tester.pump();
      expect(repository.upserts, 1);
      expect(saveButton(tester, 'save-swim').onPressed, isNull);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('swim-duration')))
            .enabled,
        isFalse,
      );
      gate.complete();
      await tester.pumpAndSettle();
      expect(repository.entries, hasLength(1));
      expect(find.text('Saved locally · Manual source'), findsOneWidget);
      expect(saveButton(tester, 'save-swim').onPressed, isNull);

      await tester.ensureVisible(find.byKey(const Key('swim-duration')));
      await tester.enterText(find.byKey(const Key('swim-duration')), '50');
      await tester.pump();
      expect(find.text('Saved locally · Manual source'), findsNothing);
      expect(saveButton(tester, 'save-swim').onPressed, isNotNull);
    },
  );

  testWidgets('failed swim save preserves values and allows a safe retry', (
    tester,
  ) async {
    final repository = _JournalRepository()..failWrite = true;
    await show(tester, const SwimEntryScreen(), repository);
    await tester.enterText(find.byKey(const Key('swim-duration')), '38');
    saveButton(tester, 'save-swim').onPressed!();
    await tester.pumpAndSettle();
    expect(repository.entries, isEmpty);
    expect(find.textContaining('Could not save your swim.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('swim-duration')))
          .controller!
          .text,
      '38',
    );
    expect(tester.takeException(), isNull);
    repository.failWrite = false;
    saveButton(tester, 'save-swim').onPressed!();
    await tester.pumpAndSettle();
    expect(repository.entries.single.durationMinutes, 38);
    expect(find.text('Saved locally · Manual source'), findsOneWidget);
  });

  testWidgets(
    'check-in preserves failed note, blocks duplicate saves, and resets after edits',
    (tester) async {
      final repository = _JournalRepository()..failWrite = true;
      await show(tester, const CheckInScreen(), repository);
      await tester.enterText(
        find.byKey(const Key('check-in-note')),
        'A useful note',
      );
      await tester.pump();
      final firstSubmit = saveButton(tester, 'save-check-in').onPressed!;
      firstSubmit();
      firstSubmit();
      await tester.pumpAndSettle();
      expect(repository.upserts, 1);
      expect(repository.entries, isEmpty);
      expect(
        find.textContaining('Could not save your check-in.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('check-in-note')))
            .controller!
            .text,
        'A useful note',
      );
      expect(tester.takeException(), isNull);
      repository.failWrite = false;
      saveButton(tester, 'save-check-in').onPressed!();
      await tester.pumpAndSettle();
      expect(repository.entries, hasLength(1));
      expect(saveButton(tester, 'save-check-in').onPressed, isNull);
      await tester.tap(find.byKey(const Key('check-in-travel')));
      await tester.pump();
      expect(find.text('Saved locally · Manual source'), findsNothing);
      expect(saveButton(tester, 'save-check-in').onPressed, isNotNull);
    },
  );

  testWidgets(
    'failed journal deletion retains the entry and blocks duplicate operations',
    (tester) async {
      final gate = Completer<void>();
      final repository = _JournalRepository()
        ..entries = [_oldSwim]
        ..deleteGate = gate.future
        ..failDelete = true;
      await show(tester, const JournalScreen(), repository);
      final button = find.byKey(Key('delete-journal-${_oldSwim.id}'));
      final delete = tester.widget<IconButton>(button).onPressed!;
      delete();
      delete();
      await tester.pump();
      expect(repository.deletes, 1);
      expect(tester.widget<IconButton>(button).onPressed, isNull);
      gate.complete();
      await tester.pumpAndSettle();
      expect(repository.entries, hasLength(1));
      expect(find.byKey(Key('journal-entry-${_oldSwim.id}')), findsOneWidget);
      expect(
        find.textContaining('Could not delete this entry.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      repository.failDelete = false;
      tester.widget<IconButton>(button).onPressed!();
      await tester.pumpAndSettle();
      expect(repository.entries, isEmpty);
    },
  );

  testWidgets(
    'cycle screen exposes no fake controls and prevents deletion during sync',
    (tester) async {
      final ringRepository = _RingRepository();
      final pairing = _PairingController();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ringDataRepositoryProvider.overrideWithValue(ringRepository),
            ringPairingProvider.overrideWith(() => pairing),
          ],
          child: const MaterialApp(home: CyclePrivacyScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not available yet'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(find.byKey(const Key('cycle-data-controls')), findsOneWidget);
      final button = find.byKey(const Key('delete-ring-data'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      pairing.beginSync();
      await tester.tap(find.byKey(const Key('confirm-delete-ring-data')));
      await tester.pumpAndSettle();
      expect(ringRepository.deleteCount, 0);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      expect(
        find.textContaining('Let your ring finish syncing'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

final _oldSwim = JournalEntry(
  id: 'old-swim',
  kind: JournalEntryKind.swim,
  occurredAtUtc: DateTime.utc(2026, 8, 20),
  title: 'Pool swim',
  details: '30 minutes · steady effort',
  durationMinutes: 30,
);

class _JournalRepository implements JournalRepository {
  List<JournalEntry> entries = [];
  Future<void>? writeGate;
  Future<void>? deleteGate;
  bool failWrite = false;
  bool failDelete = false;
  int upserts = 0;
  int deletes = 0;
  @override
  Future<List<JournalEntry>> read() async => entries;
  @override
  Future<List<JournalEntry>> upsert(JournalEntry entry) async {
    upserts++;
    await writeGate;
    if (failWrite) throw StateError('Disk unavailable');
    entries = [entry, ...entries.where((value) => value.id != entry.id)];
    return entries;
  }

  @override
  Future<List<JournalEntry>> delete(String id) async {
    deletes++;
    await deleteGate;
    if (failDelete) throw StateError('Disk unavailable');
    entries = entries.where((value) => value.id != id).toList();
    return entries;
  }

  @override
  Future<void> deleteAll() async => entries = [];
}

class _PairingController extends RingPairingController {
  @override
  RingPairingState build() => const RingPairingState();
  void beginSync() => state = state.copyWith(syncInProgress: true);
}

class _RingRepository implements RingDataRepository {
  int deleteCount = 0;
  final dataset = RingSyncDataset(
    lastSyncedAtUtc: DateTime.utc(2026, 9, 5),
    source: const RingDataSource(driverId: 'test'),
    availability: const {},
  );
  @override
  Future<RingSyncDataset?> read() async => dataset;
  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async => incoming;
  @override
  Future<void> deleteAll() async => deleteCount++;
}
