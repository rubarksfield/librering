import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/storage/data_export_service.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  test('returning production users launch directly into Today', () async {
    expect(
      await resolveInitialLocation(
        demoMode: false,
        captureMode: false,
        ringDataRepository: _MemoryRepository(_dataset()),
      ),
      '/today',
    );
    expect(
      await resolveInitialLocation(
        demoMode: false,
        captureMode: false,
        ringDataRepository: _MemoryRepository(null),
      ),
      '/welcome',
    );
  });

  testWidgets('production screens render stored ring data without scores', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MemoryRepository(_dataset());

    await tester.pumpWidget(
      LibreRingApp(initialLocation: '/today', ringDataRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('8 hours of sleep was recorded.'), findsOneWidget);
    expect(find.byKey(const Key('domain-recovery')), findsOneWidget);
    expect(find.text('Protected'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(find.text('82'), findsNothing);
    expect(find.textContaining('Demo data'), findsNothing);

    await tester.tap(find.text('All signals'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-metrics')), findsOneWidget);
    expect(find.text('500', findRichText: true), findsOneWidget);
    expect(find.textContaining('64 bpm', findRichText: true), findsOneWidget);
    expect(find.textContaining('95–98 %', findRichText: true), findsOneWidget);
  });

  testWidgets(
    'local ring deletion requires confirmation and clears the store',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _MemoryRepository(_dataset());

      await tester.pumpWidget(
        LibreRingApp(
          initialLocation: '/privacy/cycle',
          ringDataRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('delete-ring-data')));
      await tester.tap(find.byKey(const Key('delete-ring-data')));
      await tester.pumpAndSettle();
      expect(find.text('Delete local ring data?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-delete-ring-data')));
      await tester.pumpAndSettle();
      expect(repository.value, isNull);
      expect(repository.deleteCount, 1);
      expect(find.byKey(const Key('delete-ring-data')), findsNothing);
    },
  );

  testWidgets('production journey exposes honest domains and 7/30/90 trends', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      LibreRingApp(
        initialLocation: '/today',
        ringDataRepository: _MemoryRepository(_dataset()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('domain-recovery')));
    await tester.tap(find.byKey(const Key('domain-recovery')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-recovery')), findsOneWidget);
    expect(
      find.text('No Recovery score is the honest result.'),
      findsOneWidget,
    );
    expect(find.text('Excluded'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Trends'));
    await tester.pumpAndSettle();
    for (final key in <String>[
      'trend-sleep',
      'trend-pulse',
      'trend-movement',
      'trend-oxygen',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    expect(find.byKey(const Key('trend-range-selector')), findsOneWidget);
    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(find.textContaining('last 7 days'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('You'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-you')), findsOneWidget);
    expect(find.byKey(const Key('you-ring')), findsOneWidget);
    expect(find.byKey(const Key('you-data')), findsOneWidget);
  });

  testWidgets('expanded analytics expose Q Ring feature depth without scores', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MemoryRepository(_dataset());

    for (final route in <(String, String, List<String>)>[
      (
        '/movement',
        'screen-movement',
        <String>['Today, hour by hour', 'Firmware kcal'],
      ),
      (
        '/sleep',
        'screen-sleep',
        <String>['Night architecture', 'Continuity, without a score'],
      ),
      (
        '/heart',
        'screen-heart',
        <String>['Daily pulse timeline', 'Recent measurements'],
      ),
      (
        '/oxygen',
        'screen-oxygen',
        <String>['Daily range map', 'not exact hourly averages'],
      ),
      (
        '/signals/hrv-index',
        'screen-hrv-index',
        <String>['unitless form', 'unit and calculation are unverified'],
      ),
      (
        '/signals/stress-index',
        'screen-stress-index',
        <String>['unitless form', 'formula and thresholds are unverified'],
      ),
      (
        '/you/ring/capabilities',
        'screen-capabilities',
        <String>['Available locally', 'Not yet available'],
      ),
    ]) {
      await tester.pumpWidget(
        LibreRingApp(
          key: ValueKey<String>('analytics-${route.$1}'),
          initialLocation: route.$1,
          ringDataRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(Key(route.$2)), findsOneWidget, reason: route.$1);
      for (final text in route.$3) {
        expect(find.textContaining(text), findsWidgets, reason: route.$1);
      }
      expect(tester.takeException(), isNull, reason: route.$1);
    }
  });

  testWidgets('data hub creates portable files and deletes ring data only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MemoryRepository(_dataset());
    final exportService = _MemoryExportService();

    await tester.pumpWidget(
      LibreRingApp(
        initialLocation: '/you/data',
        ringDataRepository: repository,
        dataExportService: exportService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('create-data-export')));
    await tester.tap(find.byKey(const Key('create-data-export')));
    await tester.pumpAndSettle();
    expect(find.text('Export ready'), findsOneWidget);
    expect(exportService.callCount, 1);

    await tester.ensureVisible(
      find.byKey(const Key('delete-ring-history-hub')),
    );
    await tester.tap(find.byKey(const Key('delete-ring-history-hub')));
    await tester.pumpAndSettle();
    expect(find.text('Delete all local ring history?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repository.value, isNull);
    expect(repository.deleteCount, 1);
    expect(exportService.callCount, 1);
  });

  testWidgets('priority production screens fit a compact phone at 130% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final route in <String>[
      '/today',
      '/trends',
      '/recovery',
      '/movement',
      '/heart',
      '/oxygen',
      '/journal',
      '/you',
      '/you/ring',
      '/you/data',
    ]) {
      await tester.pumpWidget(
        LibreRingApp(
          key: ValueKey<String>('compact-$route'),
          initialLocation: route,
          ringDataRepository: _MemoryRepository(_dataset()),
          dataExportService: _MemoryExportService(),
        ),
      );
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) fail('$route\n$error');
    }
  });
}

class _MemoryRepository implements RingDataRepository {
  _MemoryRepository(this.value);

  RingSyncDataset? value;
  int deleteCount = 0;

  @override
  Future<void> deleteAll() async {
    deleteCount += 1;
    value = null;
  }

  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async =>
      value = incoming;

  @override
  Future<RingSyncDataset?> read() async => value;
}

class _MemoryExportService implements DataExportService {
  int callCount = 0;

  @override
  Future<LocalExportResult> create({
    required RingSyncDataset dataset,
    required List<JournalEntry> journal,
  }) async {
    callCount += 1;
    return LocalExportResult(
      jsonFile: File('/tmp/librering-test.json'),
      csvFile: File('/tmp/librering-test.csv'),
      rowCount: dataset.recordCount + journal.length,
      sha256: 'a' * 64,
      createdAtUtc: DateTime.utc(2026, 8, 26),
    );
  }
}

RingSyncDataset _dataset() {
  final localNow = DateTime.now();
  final now = DateTime.now().toUtc();
  final todayAtNoonUtc = DateTime(
    localNow.year,
    localNow.month,
    localNow.day,
    12,
  ).toUtc();
  return RingSyncDataset(
    lastSyncedAtUtc: now,
    source: const RingDataSource(
      driverId: 'colmi-qring-v1',
      firmwareVersion: 'RT11CR_1.00.09_260424',
    ),
    availability: const <RingDataKind, RingDataAvailability>{
      RingDataKind.activity: RingDataAvailability.complete,
      RingDataKind.heartRate: RingDataAvailability.complete,
      RingDataKind.sleep: RingDataAvailability.complete,
      RingDataKind.oxygen: RingDataAvailability.complete,
    },
    batteryLevel: 73,
    activity: <RingActivityBucket>[
      RingActivityBucket(
        startedAtUtc: todayAtNoonUtc,
        steps: 500,
        distanceMeters: 400,
        firmwareCalories: 20,
      ),
    ],
    heartRate: <RingHeartRateSample>[
      RingHeartRateSample(
        measuredAtUtc: now.subtract(const Duration(minutes: 15)),
        bpm: 60,
      ),
      RingHeartRateSample(measuredAtUtc: now, bpm: 64),
    ],
    oxygen: <RingOxygenRange>[
      RingOxygenRange(
        hourStartedAtUtc: now.subtract(const Duration(hours: 1)),
        minimumPercent: 95,
        maximumPercent: 98,
      ),
    ],
    vendorIndexes: <RingVendorIndexSample>[
      RingVendorIndexSample(
        measuredAtUtc: now.subtract(const Duration(hours: 2)),
        value: 41,
        kind: RingVendorIndexKind.firmwareHrv,
      ),
      RingVendorIndexSample(
        measuredAtUtc: now.subtract(const Duration(hours: 1)),
        value: 36,
        kind: RingVendorIndexKind.stress,
      ),
    ],
    sleep: <RingSleepSession>[
      RingSleepSession(
        startedAtUtc: now.subtract(const Duration(hours: 9)),
        endedAtUtc: now.subtract(const Duration(hours: 1)),
        stages: <RingSleepStageSpan>[
          RingSleepStageSpan(
            stage: RingSleepStage.deep,
            startedAtUtc: now.subtract(const Duration(hours: 9)),
            durationMinutes: 60,
          ),
        ],
      ),
    ],
  );
}
