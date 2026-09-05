import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';
import 'package:librering_mobile/src/storage/preferences_repository.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

final _now = DateTime(2026, 9, 5, 15, 30);
const _card = Key('daily-guidance-card');

void main() {
  testWidgets(
    'Today shows recent recorded steps and saved goal, not calories',
    (tester) async {
      await _open(tester);
      expect(find.text('A little room for a walk.'), findsOneWidget);
      expect(
        find.text(
          'Your ring has recorded 1,200 of your 6,000-step goal today.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('999999'), findsNothing);
      expect(tester.getTopLeft(find.byKey(_card)).dy, lessThan(350));
      await tester.ensureVisible(
        find.byKey(const Key('daily-guidance-action')),
      );
      await tester.tap(find.byKey(const Key('daily-guidance-action')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen-movement')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('historical dates never show today guidance or check-in advice', (
    tester,
  ) async {
    await _open(tester);
    expect(find.byKey(_card), findsOneWidget);
    await tester.tap(find.byKey(const Key('previous-day')));
    await tester.pumpAndSettle();
    expect(find.byKey(_card), findsNothing);
    await tester.tap(find.byKey(const Key('next-day')));
    await tester.pumpAndSettle();
    expect(find.text('A little room for a walk.'), findsOneWidget);
  });

  testWidgets(
    'saving and deleting explicit stress context updates Today immediately',
    (tester) async {
      final journal = _Journal();
      await _open(tester, journal: journal);
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(_card)),
      );
      final saved = await container
          .read(journalProvider.notifier)
          .saveCheckIn(
            tags: ['Stress'],
            note: '',
            occurredAtUtc: _now.subtract(const Duration(minutes: 5)).toUtc(),
          );
      await tester.pumpAndSettle();
      expect(find.text('A moment to yourself.'), findsOneWidget);
      expect(
        find.textContaining('your check-in, not the ring’s stress index'),
        findsOneWidget,
      );
      expect(journal.entries.single.title, 'Stress');
      await container.read(journalProvider.notifier).delete(saved.id);
      await tester.pumpAndSettle();
      expect(find.text('A little room for a walk.'), findsOneWidget);
      expect(journal.entries, isEmpty);
    },
  );

  testWidgets('new feeling tags save canonical values in Portuguese', (
    tester,
  ) async {
    final journal = _Journal();
    await _open(
      tester,
      journal: journal,
      locale: const Locale('pt', 'PT'),
      route: '/journal/check-in',
    );
    await tester.ensureVisible(find.byKey(const Key('check-in-stress')));
    await tester.tap(find.byKey(const Key('check-in-stress')));
    await tester.ensureVisible(find.byKey(const Key('check-in-low-energy')));
    expect(find.text('Pouca energia'), findsOneWidget);
    await tester.tap(find.byKey(const Key('check-in-low-energy')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-check-in')));
    await tester.tap(find.byKey(const Key('save-check-in')));
    await tester.pumpAndSettle();
    expect(journal.entries.single.title, 'Low energy · Stress');
    expect(journal.entries.single.kind, JournalEntryKind.checkIn);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable journal never permits a personal exercise nudge', (
    tester,
  ) async {
    await _open(tester, journal: _Journal(error: true));
    expect(find.text('Start with how you feel.'), findsOneWidget);
    expect(find.text('A little room for a walk.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading goals do not briefly use default targets for guidance', (
    tester,
  ) async {
    final pending = Completer<AppPreferences>();
    await _open(tester, preferences: _Preferences(pending.future));
    expect(find.byKey(_card), findsNothing);
    pending.complete(const AppPreferences(dailyStepGoal: 6000));
    await tester.pumpAndSettle();
    expect(find.text('A little room for a walk.'), findsOneWidget);
  });

  testWidgets(
    'failed goals suppress guidance rather than substituting defaults',
    (tester) async {
      await _open(tester, preferences: _Preferences(null));
      expect(find.byKey(_card), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'no ring history preserves the connect state without made-up advice',
    (tester) async {
      await _open(tester, noHistory: true);
      expect(find.text('Your day starts here.'), findsOneWidget);
      expect(find.byKey(_card), findsNothing);
    },
  );

  testWidgets('demo guidance is labelled and never reads the real journal', (
    tester,
  ) async {
    final journal = _Journal(error: true);
    await _open(tester, demo: true, journal: journal);
    expect(find.text('EXAMPLE GUIDANCE'), findsOneWidget);
    expect(journal.reads, 0);
    expect(find.text('Give yourself some space.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _open(
  WidgetTester tester, {
  _Journal? journal,
  _Preferences? preferences,
  Locale locale = const Locale('en'),
  String route = '/today',
  bool noHistory = false,
  bool demo = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    LibreRingApp(
      initialLocation: route,
      currentLocalTime: _now,
      locale: locale,
      demoMode: demo,
      ringDataRepository: _RingRepository(noHistory ? null : _dataset()),
      journalRepository: journal ?? _Journal(),
      preferencesRepository:
          preferences ??
          _Preferences(Future.value(const AppPreferences(dailyStepGoal: 6000))),
    ),
  );
  await tester.pumpAndSettle();
}

RingSyncDataset _dataset() => RingSyncDataset(
  lastSyncedAtUtc: _now.subtract(const Duration(minutes: 5)).toUtc(),
  source: const RingDataSource(driverId: 'colmi-qring-v1'),
  availability: const {RingDataKind.activity: RingDataAvailability.complete},
  activity: [
    RingActivityBucket(
      startedAtUtc: _now.subtract(const Duration(days: 1)).toUtc(),
      steps: 300,
      distanceMeters: 0,
      firmwareCalories: 0,
    ),
    for (final hour in [12, 13, 14, 15])
      RingActivityBucket(
        startedAtUtc: DateTime(2026, 9, 5, hour, 15).toUtc(),
        steps: 300,
        distanceMeters: 220,
        firmwareCalories: 999999,
      ),
  ],
);

class _RingRepository implements RingDataRepository {
  _RingRepository(this.value);
  RingSyncDataset? value;
  @override
  Future<RingSyncDataset?> read() async => value;
  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async =>
      value = incoming;
  @override
  Future<void> deleteAll() async => value = null;
}

class _Preferences implements PreferencesRepository {
  _Preferences(this.pending);
  final Future<AppPreferences>? pending;
  @override
  Future<AppPreferences> read() async {
    if (pending == null) throw StateError('Unavailable goals');
    return pending!;
  }

  @override
  Future<void> save(AppPreferences preferences) async {}
}

class _Journal implements JournalRepository {
  _Journal({this.error = false});
  final bool error;
  int reads = 0;
  List<JournalEntry> entries = [];
  @override
  Future<List<JournalEntry>> read() async {
    reads++;
    if (error) throw StateError('Unavailable journal');
    return entries;
  }

  @override
  Future<List<JournalEntry>> upsert(JournalEntry entry) async =>
      entries = [...entries, entry];
  @override
  Future<List<JournalEntry>> delete(String id) async =>
      entries = entries.where((entry) => entry.id != id).toList();
  @override
  Future<void> deleteAll() async => entries = [];
}
