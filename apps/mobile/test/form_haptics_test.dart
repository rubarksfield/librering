import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/screens.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final effects = <String>[];

  setUp(() {
    effects.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            effects.add(call.arguments as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

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
    expect(effects, isEmpty, reason: 'Loading a form is silent');
  }

  FilledButton saveButton(WidgetTester tester, String key) =>
      tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(FilledButton),
        ),
      );

  testWidgets('swim save acknowledges persistence once, not a pending press', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = _JournalRepository()..writeGate = gate.future;
    await show(tester, const SwimEntryScreen(), repository);
    final submit = saveButton(tester, 'save-swim').onPressed!;
    submit();
    submit();
    await tester.pump();
    expect(repository.upserts, 1);
    expect(effects, isEmpty);
    expect(saveButton(tester, 'save-swim').onPressed, isNull);
    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.entries, hasLength(1));
    expect(effects, <String>['HapticFeedbackType.lightImpact']);
    submit();
    await tester.pump(const Duration(seconds: 30));
    expect(effects, hasLength(1));
    expect(repository.upserts, 1);
  });

  testWidgets('failed swim save emits an error only and retains entered data', (
    tester,
  ) async {
    final repository = _JournalRepository()..failWrite = true;
    await show(tester, const SwimEntryScreen(), repository);
    await tester.enterText(find.byKey(const Key('swim-duration')), '38');
    expect(effects, isEmpty, reason: 'Typing is silent');
    saveButton(tester, 'save-swim').onPressed!();
    await tester.pumpAndSettle();
    expect(repository.entries, isEmpty);
    expect(effects, <String>['HapticFeedbackType.mediumImpact']);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('swim-duration')))
          .controller!
          .text,
      '38',
    );
  });

  testWidgets('invalid swim duration emits one error without writing', (
    tester,
  ) async {
    final repository = _JournalRepository();
    await show(tester, const SwimEntryScreen(), repository);
    await tester.enterText(find.byKey(const Key('swim-duration')), '0');
    saveButton(tester, 'save-swim').onPressed!();
    await tester.pumpAndSettle();
    expect(repository.upserts, 0);
    expect(effects, <String>['HapticFeedbackType.mediumImpact']);
  });

  testWidgets('swim choices tick only when their value changes', (
    tester,
  ) async {
    await show(tester, const SwimEntryScreen(), _JournalRepository());
    final pool = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('swim-pool')),
    );
    final dropdown = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byKey(const Key('swim-pool')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    expect(dropdown.enableFeedback, isFalse);
    pool.onChanged!('50 metres');
    await tester.pump();
    expect(effects, <String>['HapticFeedbackType.selectionClick']);
    tester
        .widget<DropdownButtonFormField<String>>(
          find.byKey(const Key('swim-pool')),
        )
        .onChanged!('50 metres');
    await tester.pump();
    expect(effects, hasLength(1));
    final effort = tester.widget<SegmentedButton<String>>(
      find.byKey(const Key('swim-effort')),
    );
    effort.onSelectionChanged!({'hard'});
    await tester.pump();
    expect(effects, hasLength(2));
    tester
        .widget<SegmentedButton<String>>(find.byKey(const Key('swim-effort')))
        .onSelectionChanged!({'hard'});
    await tester.pump();
    expect(effects, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('check-in tags tick, typing is quiet, and save confirms once', (
    tester,
  ) async {
    final repository = _JournalRepository();
    await show(tester, const CheckInScreen(), repository);
    final tag = find.byKey(const Key('check-in-travel'));
    await tester.tap(tag);
    await tester.pump();
    expect(effects, <String>['HapticFeedbackType.selectionClick']);
    tester.widget<FilterChip>(tag).onSelected!(true);
    await tester.pump();
    expect(effects, hasLength(1));
    await tester.enterText(find.byKey(const Key('check-in-note')), 'A note');
    expect(effects, hasLength(1));
    saveButton(tester, 'save-check-in').onPressed!();
    await tester.pumpAndSettle();
    expect(repository.entries, hasLength(1));
    expect(effects, <String>[
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
    ]);
    expect(saveButton(tester, 'save-check-in').onPressed, isNull);
  });

  testWidgets('leaving a saving form prevents a late result vibration', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = _JournalRepository()..writeGate = gate.future;
    await show(tester, const SwimEntryScreen(), repository);
    saveButton(tester, 'save-swim').onPressed!();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.pumpAndSettle();
    expect(effects, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final fail in [false, true]) {
    testWidgets(
      'journal deletion gives only its committed ${fail ? 'error' : 'success'} cue',
      (tester) async {
        final gate = Completer<void>();
        final repository = _JournalRepository()
          ..entries = [_oldSwim]
          ..deleteGate = gate.future
          ..failDelete = fail;
        await show(tester, const JournalScreen(), repository);
        final button = find.byKey(Key('delete-journal-${_oldSwim.id}'));
        final delete = tester.widget<IconButton>(button).onPressed!;
        delete();
        delete();
        await tester.pump();
        expect(repository.deletes, 1);
        expect(effects, isEmpty);
        gate.complete();
        await tester.pumpAndSettle();
        expect(repository.entries, hasLength(fail ? 1 : 0));
        expect(effects, <String>[
          fail
              ? 'HapticFeedbackType.mediumImpact'
              : 'HapticFeedbackType.lightImpact',
        ]);
        expect(tester.takeException(), isNull);
      },
    );
  }
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
