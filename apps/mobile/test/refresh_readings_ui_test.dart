import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/ble/r12_pairing_client.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:librering_mobile/src/ui/app_chrome.dart';
import 'package:ring_core/ring_core.dart';

final _now = DateTime(2026, 9, 7, 14);
const _success =
    'Saved readings refreshed. Use Sync to get new data from your ring.';
const _failure =
    'Could not refresh saved readings. Your data has not been changed. Please try again.';

void main() {
  for (final route in ['/today', '/vitals', '/heart']) {
    testWidgets(
      'iOS pull on $route refreshes without Bluetooth, including short pages',
      (tester) async {
        final repository = _Repository(route == '/vitals' ? null : _dataset());
        final client = _Client(_dataset(updated: true));
        await _open(
          tester,
          route: route,
          repository: repository,
          client: client,
        );
        final beforeReads = repository.reads;
        repository.value = _dataset(updated: true);
        await _pull(tester);
        expect(repository.reads, beforeReads + 1);
        expect(client.operations, isEmpty);
        expect(find.text(_success), findsOneWidget);
        expect(
          route == '/heart'
              ? _primary(tester)
              : tester.widget<Text>(find.text('72')).data,
          '72',
        );
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  for (final route in <String>[
    '/today',
    '/vitals',
    '/trends',
    '/heart',
    '/sleep',
    '/activity',
    '/oxygen',
    '/signals/hrv-index',
    '/signals/stress-index',
    '/day-timeline',
  ]) {
    testWidgets('pull on $route reloads saved readings without Bluetooth', (
      tester,
    ) async {
      final repository = _Repository(_dataset());
      final client = _Client(_dataset(updated: true));
      await _open(tester, route: route, repository: repository, client: client);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      final beforeReads = repository.reads;
      repository.value = _dataset(updated: true);
      await _pull(tester);
      expect(repository.reads, beforeReads + 1);
      expect(repository.merges, 0);
      expect(repository.deletes, 0);
      expect(client.operations, isEmpty);
      expect(find.text(_success), findsOneWidget);
      switch (route) {
        case '/today':
        case '/vitals':
          expect(find.text('72'), findsOneWidget);
          expect(find.text('63'), findsNothing);
        case '/heart':
          expect(_primary(tester), '72');
        case '/activity':
          expect(_primary(tester), '2,222');
        case '/oxygen':
          expect(_primary(tester), '98–99');
        case '/signals/hrv-index':
          expect(_primary(tester), '55');
        case '/signals/stress-index':
          expect(_primary(tester), '48');
        case '/sleep':
          expect(_primary(tester), '3 h 0 min');
        case '/day-timeline':
          expect(find.text('72 bpm'), findsOneWidget);
          expect(find.text('63 bpm'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final route in ['/vitals', '/heart']) {
    testWidgets('pull refresh works on the short empty $route page', (
      tester,
    ) async {
      final repository = _Repository(null);
      final client = _Client(_dataset());
      await _open(tester, route: route, repository: repository, client: client);
      final beforeReads = repository.reads;
      if (route == '/vitals') {
        final scroll = find
            .descendant(
              of: find.byType(RefreshIndicator),
              matching: find.byType(Scrollable),
            )
            .first;
        expect(
          tester.state<ScrollableState>(scroll).position.maxScrollExtent,
          0,
        );
      }
      await _pull(tester);
      expect(repository.reads, beforeReads + 1);
      expect(repository.value, isNull);
      expect(find.text(_success), findsOneWidget);
      expect(client.operations, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in [const Locale('en'), const Locale('pt', 'PT')]) {
    testWidgets(
      'failed pull preserves cached values and gives feedback in $locale',
      (tester) async {
        final original = _dataset();
        final repository = _Repository(original);
        final client = _Client(_dataset(updated: true));
        await _open(
          tester,
          route: '/heart',
          repository: repository,
          client: client,
          locale: locale,
        );
        expect(_primary(tester), '63');
        repository.failReads = true;
        await _pull(tester);
        expect(_primary(tester), '63');
        expect(repository.value, same(original));
        expect(repository.merges + repository.deletes, 0);
        expect(client.operations, isEmpty);
        expect(
          find.text(
            locale.languageCode == 'pt'
                ? 'Não foi possível atualizar as leituras guardadas. Os seus dados não foram alterados. Tente novamente.'
                : _failure,
          ),
          findsOneWidget,
        );
        repository.failReads = false;
        repository.value = _dataset(updated: true);
        await _pull(tester);
        expect(_primary(tester), '72');
        expect(
          find.text(
            locale.languageCode == 'pt'
                ? 'Leituras guardadas atualizadas. Use Sincronizar para obter novos dados do anel.'
                : _success,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final route in [
    '/today',
    '/vitals',
    '/trends',
    '/heart',
    '/day-timeline',
  ]) {
    testWidgets('demo $route does not offer production refresh', (
      tester,
    ) async {
      final repository = _Repository(_dataset());
      final client = _Client(_dataset(updated: true));
      await _open(
        tester,
        route: route,
        repository: repository,
        client: client,
        demo: true,
      );
      final beforeReads = repository.reads;
      expect(find.byType(RefreshIndicator), findsNothing);
      await tester.dragFrom(const Offset(40, 110), const Offset(0, 480));
      await tester.pumpAndSettle();
      expect(repository.reads, beforeReads);
      expect(repository.merges, 0);
      expect(client.operations, isEmpty);
      expect(find.text(_success), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'explicit Sync updates Today and previously visited Vitals without a pull',
    (tester) async {
      final repository = _Repository(_dataset());
      final client = _Client(_dataset(updated: true));
      await _open(
        tester,
        route: '/today',
        repository: repository,
        client: client,
      );
      expect(find.text('63'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tab-vitals')));
      await tester.pumpAndSettle();
      expect(find.text('63'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tab-today')));
      await tester.pumpAndSettle();
      final beforeReads = repository.reads;
      await tester.tap(find.byKey(const Key('today-quick-sync')));
      await tester.pumpAndSettle();
      expect(client.operations, ['scan', 'connect', 'sync', 'disconnect']);
      expect(repository.merges, 1);
      expect(repository.reads, beforeReads);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('63'), findsNothing);
      expect(find.text('Sync complete'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tab-vitals')));
      await tester.pumpAndSettle();
      expect(find.text('72'), findsOneWidget);
      expect(find.text('63'), findsNothing);
      expect(repository.reads, beforeReads);
      expect(find.text(_success), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final route in ['/today', '/heart', '/vitals', '/day-timeline']) {
    testWidgets('pull on $route preserves a selected historical date', (
      tester,
    ) async {
      final repository = _Repository(_dataset());
      final client = _Client(_dataset(updated: true));
      await _open(tester, route: route, repository: repository, client: client);
      await tester.ensureVisible(find.byKey(const Key('previous-day')));
      await tester.tap(find.byKey(const Key('previous-day')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RingDaySelector>(find.byType(RingDaySelector))
            .selectedDay,
        DateTime(2026, 9, 6),
      );
      repository.value = _dataset(updated: true);
      await _pull(tester);
      expect(
        tester
            .widget<RingDaySelector>(find.byType(RingDaySelector))
            .selectedDay,
        DateTime(2026, 9, 6),
      );
      if (route == '/heart') {
        expect(_primary(tester), '54');
      } else if (route == '/day-timeline') {
        expect(find.text('54 bpm'), findsOneWidget);
      } else {
        expect(find.text('54'), findsOneWidget);
        expect(find.text('72'), findsNothing);
      }
      expect(client.operations, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}

String? _primary(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('analytics-primary-value'))).data;

Future<void> _pull(WidgetTester tester) async {
  final scroll = find
      .descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(Scrollable),
      )
      .first;
  tester.state<ScrollableState>(scroll).position.jumpTo(0);
  await tester.pump();
  // Real drag, deliberately outside the chart gesture targets.
  await tester.dragFrom(const Offset(40, 110), const Offset(0, 480));
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester, {
  required String route,
  required _Repository repository,
  required _Client client,
  Locale locale = const Locale('en'),
  bool demo = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    LibreRingApp(
      initialLocation: route,
      locale: locale,
      demoMode: demo,
      currentLocalTime: _now,
      pairingClient: client,
      ringDataRepository: repository,
    ),
  );
  await tester.pumpAndSettle();
}

RingSyncDataset _dataset({bool updated = false}) {
  final at = DateTime(2026, 9, 7, 12).toUtc();
  final yesterday = DateTime(2026, 9, 6, 12).toUtc();
  final end = DateTime(2026, 9, 7, 8).toUtc();
  final start = end.subtract(Duration(hours: updated ? 3 : 2));
  return RingSyncDataset(
    lastSyncedAtUtc: DateTime(2026, 9, 7, 13).toUtc(),
    source: const RingDataSource(driverId: 'colmi-qring-v1'),
    availability: {
      for (final kind in RingDataKind.values)
        kind: RingDataAvailability.complete,
    },
    batteryLevel: 48,
    activity: [
      RingActivityBucket(
        startedAtUtc: at,
        steps: updated ? 2222 : 1111,
        distanceMeters: 500,
        firmwareCalories: 40,
      ),
    ],
    heartRate: [
      RingHeartRateSample(measuredAtUtc: yesterday, bpm: 54),
      RingHeartRateSample(measuredAtUtc: at, bpm: updated ? 72 : 63),
    ],
    oxygen: [
      RingOxygenRange(
        hourStartedAtUtc: at,
        minimumPercent: updated ? 98 : 96,
        maximumPercent: updated ? 99 : 97,
      ),
    ],
    vendorIndexes: [
      RingVendorIndexSample(
        measuredAtUtc: at,
        value: updated ? 55 : 40,
        kind: RingVendorIndexKind.firmwareHrv,
      ),
      RingVendorIndexSample(
        measuredAtUtc: at,
        value: updated ? 48 : 32,
        kind: RingVendorIndexKind.stress,
      ),
    ],
    sleep: [
      RingSleepSession(
        startedAtUtc: start,
        endedAtUtc: end,
        stages: [
          RingSleepStageSpan(
            stage: RingSleepStage.light,
            startedAtUtc: start,
            durationMinutes: updated ? 180 : 120,
          ),
        ],
      ),
    ],
  );
}

class _Repository implements RingDataRepository {
  _Repository(this.value);
  RingSyncDataset? value;
  bool failReads = false;
  int reads = 0;
  int merges = 0;
  int deletes = 0;
  @override
  Future<RingSyncDataset?> read() async {
    reads++;
    if (failReads) throw StateError('Synthetic saved-history read failure');
    return value;
  }

  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async {
    merges++;
    return value = incoming;
  }

  @override
  Future<void> deleteAll() async {
    deletes++;
    value = null;
  }
}

class _Client implements RingPairingClient {
  _Client(this.incoming);
  final RingSyncDataset incoming;
  final operations = <String>[];
  @override
  Stream<RingPairingCandidate> scan({required Duration timeout}) {
    operations.add('scan');
    return Stream.value(
      const RingPairingCandidate(
        advertisement: RingAdvertisement(
          deviceId: 'synthetic-test-ring',
          name: 'COLMI R12_TEST',
        ),
        exact: true,
      ),
    );
  }

  @override
  Future<RingPairingEvidence> connect(RingAdvertisement advertisement) async {
    operations.add('connect');
    return RingPairingEvidence(
      name: advertisement.name,
      capabilities: DeviceCapabilities(const {}),
      supportsBigData: true,
    );
  }

  @override
  Future<RingSyncDataset> sync() async {
    operations.add('sync');
    return incoming;
  }

  @override
  Future<void> disconnect() async => operations.add('disconnect');
  @override
  Future<RingMetadata> captureMetadata() async =>
      throw StateError('Unexpected metadata capture');
  @override
  Future<RingTimeSyncResult> captureTimeSync() async =>
      throw StateError('Unexpected clock command');
  @override
  Future<RingApprovedSuiteResult> captureApprovedSuite() async =>
      throw StateError('Unexpected protocol capture');
}
