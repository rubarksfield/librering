import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/product_system_screens.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';
import 'package:librering_mobile/src/storage/preferences_repository.dart';

void main() {
  void viewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'preferences save real values and load them after a fresh launch',
    (tester) async {
      viewport(tester);
      final repository = _PreferencesRepository();
      Widget app(String key) => ProviderScope(
        key: ValueKey(key),
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProfilePreferencesScreen()),
      );
      await tester.pumpWidget(app('first'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('preferences-name')), 'Alex');
      await tester.enterText(
        find.byKey(const Key('preferences-step-goal')),
        '8000',
      );
      await tester.enterText(
        find.byKey(const Key('preferences-sleep-target')),
        '7.5',
      );
      final save = find.byKey(const Key('save-preferences'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.saved.displayName, 'Alex');
      expect(repository.saved.dailyStepGoal, 8000);
      expect(repository.saved.sleepTargetMinutes, 450);
      expect(find.text('Saved on this phone'), findsOneWidget);

      await tester.pumpWidget(app('second'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('preferences-name')))
            .controller!
            .text,
        'Alex',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('preferences-step-goal')),
            )
            .controller!
            .text,
        '8000',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('preferences-sleep-target')),
            )
            .controller!
            .text,
        '7.5',
      );
      expect(find.text('Notifications'), findsNothing);
      expect(find.text('Daily emphasis'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('editing a name preserves a minute-precise sleep target', (
    tester,
  ) async {
    viewport(tester);
    final repository = _PreferencesRepository()
      ..saved = const AppPreferences(sleepTargetMinutes: 465);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProfilePreferencesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('preferences-sleep-target')),
          )
          .controller!
          .text,
      '7.75',
    );
    await tester.enterText(find.byKey(const Key('preferences-name')), 'Alex');
    await tester.ensureVisible(find.byKey(const Key('save-preferences')));
    await tester.tap(find.byKey(const Key('save-preferences')));
    await tester.pumpAndSettle();
    expect(repository.saved.sleepTargetMinutes, 465);
  });

  testWidgets('demo preferences do not promise persistence', (tester) async {
    viewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isDemoModeProvider.overrideWithValue(true)],
        child: const MaterialApp(home: ProfilePreferencesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Preview settings reset'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('preferences-name')),
      'Preview',
    );
    await tester.ensureVisible(find.byKey(const Key('save-preferences')));
    await tester.tap(find.byKey(const Key('save-preferences')));
    await tester.pumpAndSettle();
    expect(find.text('Saved for this preview'), findsOneWidget);
    expect(find.text('Saved on this phone'), findsNothing);
  });

  testWidgets('invalid preferences show field errors without saving', (
    tester,
  ) async {
    viewport(tester);
    final repository = _PreferencesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProfilePreferencesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('preferences-step-goal')), '0');
    await tester.enterText(
      find.byKey(const Key('preferences-sleep-target')),
      'NaN',
    );
    final save = find.byKey(const Key('save-preferences'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
    expect(find.text('Choose 500–50,000 steps.'), findsOneWidget);
    expect(find.text('Choose 4–12 hours.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an activity reports a failed save and retries without losing the draft',
    (tester) async {
      viewport(tester);
      final repository = _JournalRepository()..fail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [journalRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(
            home: ActivityLogScreen(activityName: 'Walking'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('activity-note')),
        'By the sea',
      );
      final save = find.byKey(const Key('save-activity'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not save this activity'),
        findsOneWidget,
      );
      expect(repository.entries, isEmpty);
      expect(tester.takeException(), isNull);
      repository.fail = false;
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.entries, hasLength(1));
      expect(repository.entries.single.details, contains('By the sea'));
      expect(find.text('Saved locally'), findsOneWidget);
    },
  );

  testWidgets('two taps before the next frame create one activity', (
    tester,
  ) async {
    viewport(tester);
    final gate = Completer<void>();
    final repository = _JournalRepository()..gate = gate.future;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: ActivityLogScreen(activityName: 'Walking'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('save-activity'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save);
    await tester.pump();
    expect(repository.writes, 1);
    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.entries, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today timeline excludes past and future manual entries', (
    tester,
  ) async {
    viewport(tester);
    final now = DateTime(2026, 9, 5, 12);
    final repository = _JournalRepository()
      ..entries = [
        _entry('yesterday', DateTime(2026, 9, 4, 18)),
        _entry('morning', DateTime(2026, 9, 5, 8)),
        _entry('future', DateTime(2026, 9, 5, 13)),
      ];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ProductDayTimelineScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentLocalTimeProvider.overrideWithValue(now),
          journalRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('morning'), findsOneWidget);
    expect(find.text('yesterday'), findsNothing);
    expect(find.text('future'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

JournalEntry _entry(String title, DateTime at) => JournalEntry(
  id: title,
  kind: JournalEntryKind.note,
  occurredAtUtc: at.toUtc(),
  title: title,
  details: 'Fictional context',
);

class _PreferencesRepository implements PreferencesRepository {
  AppPreferences saved = const AppPreferences();
  int writes = 0;
  @override
  Future<AppPreferences> read() async => saved;
  @override
  Future<void> save(AppPreferences preferences) async {
    saved = preferences;
    writes++;
  }
}

class _JournalRepository implements JournalRepository {
  List<JournalEntry> entries = [];
  bool fail = false;
  int writes = 0;
  Future<void>? gate;
  @override
  Future<List<JournalEntry>> read() async => entries;
  @override
  Future<List<JournalEntry>> upsert(JournalEntry entry) async {
    writes++;
    if (gate != null) await gate;
    if (fail) throw StateError('Disk unavailable');
    return entries = [...entries, entry];
  }

  @override
  Future<List<JournalEntry>> delete(String id) async =>
      entries = entries.where((entry) => entry.id != id).toList();
  @override
  Future<void> deleteAll() async {
    entries = [];
  }
}
