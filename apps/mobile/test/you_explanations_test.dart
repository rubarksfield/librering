import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';
import 'package:librering_mobile/src/storage/preferences_repository.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  for (final locale in <Locale>[const Locale('en'), const Locale('pt', 'PT')]) {
    final portuguese = locale.languageCode == 'pt';
    testWidgets('You explains account and subscription status in $locale', (
      tester,
    ) async {
      await _open(tester, locale: locale);
      expect(
        find.text(
          portuguese ? 'O seu anel. Os seus dados.' : 'Your ring. Your data.',
        ),
        findsOneWidget,
      );
      expect(find.text('No account. No subscription.'), findsNothing);
      final button = find.byKey(const Key('you-account-explainer'));
      await tester.ensureVisible(button);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.text(
          portuguese ? 'Simples, local e seu' : 'Simple, local and yours',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          portuguese
              ? 'não tem plano pago, faturação nem funcionalidades exclusivas de subscrição'
              : 'has no paid tier, billing or subscription-only features',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          portuguese
              ? 'liga-se diretamente por Bluetooth'
              : 'connects directly over Bluetooth',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          portuguese
              ? 'Exportar e partilhar é uma escolha sua'
              : 'Exporting and sharing are your choice',
        ),
        findsOneWidget,
      );
      final close = find.text(portuguese ? 'Entendido' : 'Got it');
      await tester.ensureVisible(close);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('explanation and intro reflow at 2x text in $locale', (
      tester,
    ) async {
      await _open(tester, locale: locale, largeText: true);
      final open = find.byKey(const Key('you-account-explainer'));
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final close = find.text(portuguese ? 'Entendido' : 'Got it');
      await tester.ensureVisible(close);
      await tester.tap(close);
      await tester.pumpAndSettle();
      final intro = find.byKey(const Key('you-introduction'));
      await tester.ensureVisible(intro);
      await tester.tap(intro);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('intro-replay-explanation')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('welcome-start')));
      await tester.tap(find.byKey(const Key('welcome-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen-privacy-promise')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('privacy-continue')));
      await tester.tap(find.byKey(const Key('privacy-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen-today')), findsOneWidget);
      expect(find.byKey(const Key('screen-ring-scan')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('account explanation is an accessible labelled action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await _open(tester);
      final open = find.byKey(const Key('you-account-explainer'));
      await tester.ensureVisible(open);
      final semantics = tester.getSemantics(open).getSemanticsData();
      expect(semantics.label, 'Accounts, costs and your data');
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.hasAction(SemanticsAction.tap), isTrue);
      final introduction = find.byKey(const Key('you-introduction'));
      await tester.ensureVisible(introduction);
      final introSemantics = tester
          .getSemantics(introduction)
          .getSemanticsData();
      expect(introSemantics.label, contains('Revisit the introduction'));
      expect(introSemantics.flagsCollection.isButton, isTrue);
      expect(introSemantics.hasAction(SemanticsAction.tap), isTrue);
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
    'replaying introduction preserves history, journal and preferences',
    (tester) async {
      final ring = _RingRepository();
      final journal = _JournalRepository();
      final preferences = _PreferencesRepository();
      final datasetBefore = ring.value;
      final journalBefore = journal.value;
      final preferencesBefore = preferences.value;
      await _open(
        tester,
        ring: ring,
        journal: journal,
        preferences: preferences,
      );
      expect(find.text('Zoe'), findsOneWidget);
      final intro = find.byKey(const Key('you-introduction'));
      await tester.ensureVisible(intro);
      await tester.tap(intro);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen-welcome')), findsOneWidget);
      expect(find.text('Set up LibreRing'), findsNothing);
      expect(
        find.textContaining('your records and settings stay as they are'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const Key('welcome-start')));
      await tester.tap(find.byKey(const Key('welcome-start')));
      await tester.pumpAndSettle();
      expect(find.text('Back to Today'), findsOneWidget);
      expect(find.text('Continue privately'), findsNothing);
      await tester.ensureVisible(find.byTooltip('Back to welcome'));
      await tester.tap(find.byTooltip('Back to welcome'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('intro-replay-explanation')), findsOneWidget);
      expect(find.text('Set up LibreRing'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('welcome-start')));
      await tester.tap(find.byKey(const Key('welcome-start')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('privacy-continue')));
      await tester.tap(find.byKey(const Key('privacy-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen-today')), findsOneWidget);
      expect(identical(ring.value, datasetBefore), isTrue);
      expect(identical(journal.value, journalBefore), isTrue);
      expect(identical(preferences.value, preferencesBefore), isTrue);
      expect(ring.writes + journal.writes + preferences.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('intro replay can return directly to You', (tester) async {
    await _open(tester, location: '/welcome?replay=true');
    await tester.tap(find.text('Back to You'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-you')), findsOneWidget);
  });

  testWidgets('first-time welcome retains the actual setup route', (
    tester,
  ) async {
    await _open(tester, location: '/welcome');
    expect(find.byKey(const Key('intro-replay-explanation')), findsNothing);
    expect(find.text('Set up LibreRing'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('welcome-start')));
    await tester.tap(find.byKey(const Key('welcome-start')));
    await tester.pumpAndSettle();
    expect(find.text('Continue privately'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('privacy-continue')));
    await tester.tap(find.byKey(const Key('privacy-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-ring-scan')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy replay deep link keeps replay mode when going back', (
    tester,
  ) async {
    await _open(tester, location: '/privacy?replay=true');
    await tester.tap(find.byTooltip('Back to welcome'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('intro-replay-explanation')), findsOneWidget);
    expect(find.text('Your privacy'), findsOneWidget);
    expect(find.text('Set up LibreRing'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _open(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  String location = '/you',
  bool largeText = false,
  _RingRepository? ring,
  _JournalRepository? journal,
  _PreferencesRepository? preferences,
}) async {
  tester.view.physicalSize = largeText
      ? const Size(320, 568)
      : const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = largeText ? 2 : 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    LibreRingApp(
      initialLocation: location,
      locale: locale,
      currentLocalTime: DateTime(2026, 9, 5, 14),
      ringDataRepository: ring ?? _RingRepository(),
      journalRepository: journal ?? _JournalRepository(),
      preferencesRepository: preferences ?? _PreferencesRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

class _RingRepository implements RingDataRepository {
  RingSyncDataset? value = RingSyncDataset(
    lastSyncedAtUtc: DateTime.utc(2026, 9, 5, 13),
    source: const RingDataSource(driverId: 'colmi-qring-v1'),
    availability: const {},
    batteryLevel: 38,
  );
  int writes = 0;

  @override
  Future<RingSyncDataset?> read() async => value;

  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async {
    writes++;
    return value = incoming;
  }

  @override
  Future<void> deleteAll() async {
    writes++;
    value = null;
  }
}

class _PreferencesRepository implements PreferencesRepository {
  AppPreferences value = const AppPreferences(
    displayName: 'Zoe',
    dailyStepGoal: 7000,
  );
  int writes = 0;

  @override
  Future<AppPreferences> read() async => value;

  @override
  Future<void> save(AppPreferences preferences) async {
    writes++;
    value = preferences;
  }
}

class _JournalRepository implements JournalRepository {
  List<JournalEntry> value = [
    JournalEntry(
      id: 'check-in-before-replay',
      kind: JournalEntryKind.checkIn,
      occurredAtUtc: DateTime.utc(2026, 9, 5, 9),
      title: 'Caffeine',
      details: 'One morning coffee',
    ),
  ];
  int writes = 0;

  @override
  Future<List<JournalEntry>> read() async => value;

  @override
  Future<List<JournalEntry>> upsert(JournalEntry entry) async {
    writes++;
    return value = [...value, entry];
  }

  @override
  Future<List<JournalEntry>> delete(String id) async {
    writes++;
    return value = value.where((entry) => entry.id != id).toList();
  }

  @override
  Future<void> deleteAll() async {
    writes++;
    value = [];
  }
}
