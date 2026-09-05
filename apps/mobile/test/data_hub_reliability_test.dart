import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/screens.dart';
import 'package:librering_mobile/src/storage/data_export_service.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    RingDataRepository? ring,
    JournalRepository? journal,
    _PairingController? pairing,
    _Exporter? exporter,
    Widget page = const DataHubScreen(),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ringDataRepositoryProvider.overrideWithValue(
            ring ?? _RingRepository(),
          ),
          journalRepositoryProvider.overrideWithValue(
            journal ?? _JournalRepository(),
          ),
          ringPairingProvider.overrideWith(
            () => pairing ?? _PairingController(),
          ),
          dataExportServiceProvider.overrideWithValue(exporter ?? _Exporter()),
        ],
        child: MaterialApp(
          theme: buildLibreRingTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapAction(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('failed ring deletion retains records and supports retry', (
    tester,
  ) async {
    final ring = _RingRepository()..failDelete = true;
    await open(tester, ring: ring);
    await tapAction(tester, 'delete-ring-history-hub');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(ring.deletes, 1);
    expect(ring.dataset, isNotNull);
    expect(
      find.text(
        'Could not delete ring history. Your records are still available; try again.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    ring.failDelete = false;
    await tapAction(tester, 'delete-ring-history-hub');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(ring.deletes, 2);
    expect(ring.dataset, isNull);
    expect(find.text('Local ring history deleted.'), findsOneWidget);
  });

  testWidgets('ring history cannot be deleted while syncing', (tester) async {
    final ring = _RingRepository();
    final pairing = _PairingController(syncing: true);
    await open(tester, ring: ring, pairing: pairing);
    await tapAction(tester, 'delete-ring-history-hub');
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('delete-ring-history-hub')),
        matching: find.text('Available after the current sync finishes'),
      ),
      findsOneWidget,
    );
    expect(ring.deletes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sync starting during confirmation prevents deletion', (
    tester,
  ) async {
    final ring = _RingRepository();
    final pairing = _PairingController();
    await open(tester, ring: ring, pairing: pairing);
    await tapAction(tester, 'delete-ring-history-hub');
    expect(find.byType(AlertDialog), findsOneWidget);
    pairing.setSync(true);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(ring.deletes, 0);
    expect(ring.dataset, isNotNull);
    expect(
      find.text(
        'A sync has started. Wait for it to finish, then try deleting again.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid delete requests show one dialog and run one mutation', (
    tester,
  ) async {
    final ring = _RingRepository()..deleteGate = Completer<void>();
    await open(tester, ring: ring);
    final delete = find.byKey(const Key('delete-ring-history-hub'));
    await tester.ensureVisible(delete);
    // Exercise two queued callbacks before the disabled state is painted.
    final action = tester
        .widget<InkWell>(
          find.descendant(of: delete, matching: find.byType(InkWell)),
        )
        .onTap!;
    action();
    action();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(ring.deletes, 1);
    await tester.tap(delete);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(ring.deletes, 1);
    ring.deleteGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Local ring history deleted.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed manual deletion retains journal entries', (tester) async {
    final journal = _JournalRepository()..failDelete = true;
    await open(tester, journal: journal);
    await tapAction(tester, 'delete-manual-context');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(journal.deletes, 1);
    expect(journal.entries, hasLength(1));
    expect(
      find.text(
        'Could not delete manual context. Your entries are still available; try again.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('unreadable stores are unavailable, not zero, and block export', (
    tester,
  ) async {
    final exporter = _Exporter();
    await open(
      tester,
      ring: _RingRepository()..failRead = true,
      journal: _JournalRepository()..failRead = true,
      exporter: exporter,
    );
    expect(find.text('Unavailable'), findsNWidgets(2));
    expect(find.text('0'), findsNothing);
    await tapAction(tester, 'create-data-export');
    expect(exporter.calls, 0);
    expect(find.byKey(const Key('retry-data-stores')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed export reports failure and can retry', (tester) async {
    final exporter = _Exporter()..fail = true;
    await open(tester, exporter: exporter);
    await tapAction(tester, 'create-data-export');
    expect(
      find.text(
        'Could not create the export. Your records are still on this phone. Try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Export ready'), findsNothing);
    expect(tester.takeException(), isNull);
    exporter.fail = false;
    await tapAction(tester, 'create-data-export');
    expect(exporter.calls, 2);
    expect(find.text('Export ready'), findsOneWidget);
  });

  for (final ringStore in [true, false]) {
    testWidgets(
      '${ringStore ? 'Ring' : 'Journal'} corrupt-file reset requires confirmation and restores writes',
      (tester) async {
        final directory = Directory.systemTemp.createTempSync(
          'librering-recovery-test-',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final file = File(
          '${directory.path}/librering/${ringStore ? 'ring-data' : 'journal'}-v1.json',
        );
        file.parent.createSync(recursive: true);
        const corruptContents = '{synthetic unreadable test fixture';
        file.writeAsStringSync(corruptContents);
        final ring = FileRingDataRepository(directory);
        final journal = FileJournalRepository(directory);
        await tester.runAsync(() async {
          await open(
            tester,
            ring: ringStore ? ring : null,
            journal: ringStore ? null : journal,
          );
          final container = ProviderScope.containerOf(
            tester.element(find.byType(DataHubScreen)),
          );
          if (ringStore) {
            await expectLater(
              container.read(ringDataProvider.future),
              throwsA(isA<RingDataStoreException>()),
            );
          } else {
            await expectLater(
              container.read(journalProvider.future),
              throwsA(isA<JournalStoreException>()),
            );
          }
          await tester.pumpAndSettle();
          final key = ringStore
              ? 'delete-ring-history-hub'
              : 'delete-manual-context';
          await tapAction(tester, key);
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(
            find.textContaining(
              'contents cannot be previewed. Deleting it cannot be undone.',
            ),
            findsOneWidget,
          );
          await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
          await tester.pumpAndSettle();
          expect(file.readAsStringSync(), corruptContents);
          await tapAction(tester, key);
          await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
          await tester.pumpAndSettle();
          if (ringStore) {
            await container.read(ringDataProvider.notifier).whenIdle;
          } else {
            await container.read(journalProvider.notifier).whenIdle;
          }
          await tester.pumpAndSettle();
          expect(file.existsSync(), isFalse);
          if (ringStore) {
            final incoming = _RingRepository().dataset!;
            await container.read(ringDataProvider.notifier).merge(incoming);
            expect((await ring.read())!.recordCount, incoming.recordCount);
          } else {
            await container
                .read(journalProvider.notifier)
                .saveCheckIn(
                  tags: ['Travel'],
                  note: 'Synthetic recovery entry',
                );
            expect(
              (await journal.read()).single.details,
              'Synthetic recovery entry',
            );
          }
          await tester.pumpAndSettle();
          expect(file.existsSync(), isTrue);
          expect(tester.takeException(), isNull);
        });
      },
    );
  }

  testWidgets('share sheet failure leaves the export available for retry', (
    tester,
  ) async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    var shareCalls = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      shareCalls++;
      throw PlatformException(code: 'unavailable');
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await open(tester);
    await tapAction(tester, 'create-data-export');
    await tapAction(tester, 'share-data-export');
    expect(shareCalls, 1);
    expect(
      find.text(
        'Could not open sharing. Your export is still available; try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Export ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stored history does not claim a live ring connection', (
    tester,
  ) async {
    await open(tester, page: const RingDeviceScreen());
    expect(find.text('History saved on this phone'), findsOneWidget);
    expect(find.text('Connected'), findsNothing);
    expect(find.text('fictional'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final entry in <(String, Widget)>[
    ('Data hub', const DataHubScreen()),
    ('Ring device', const RingDeviceScreen()),
  ]) {
    testWidgets('${entry.$1} supports large text on a small phone', (
      tester,
    ) async {
      await open(tester, page: entry.$2, textScale: 2);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1200),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

class _PairingController extends RingPairingController {
  _PairingController({this.syncing = false});
  final bool syncing;
  @override
  RingPairingState build() => RingPairingState(syncInProgress: syncing);
  void setSync(bool value) => state = state.copyWith(syncInProgress: value);
}

class _RingRepository implements RingDataRepository {
  RingSyncDataset? dataset = RingSyncDataset(
    availability: const {},
    lastSyncedAtUtc: DateTime.utc(2026, 9, 1),
    source: const RingDataSource(
      driverId: 'test',
      firmwareVersion: 'fictional',
    ),
    heartRate: [
      RingHeartRateSample(measuredAtUtc: DateTime.utc(2026, 9, 1), bpm: 62),
    ],
  );
  bool failRead = false;
  bool failDelete = false;
  int deletes = 0;
  Completer<void>? deleteGate;
  @override
  Future<RingSyncDataset?> read() async {
    if (failRead) throw StateError('Fictional read failure');
    return dataset;
  }

  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async =>
      dataset = incoming;
  @override
  Future<void> deleteAll() async {
    deletes++;
    if (deleteGate != null) await deleteGate!.future;
    if (failDelete) throw StateError('Fictional delete failure');
    dataset = null;
  }
}

class _JournalRepository implements JournalRepository {
  List<JournalEntry> entries = [
    JournalEntry(
      id: 'checkIn|fictional',
      kind: JournalEntryKind.checkIn,
      occurredAtUtc: DateTime.utc(2026, 9, 1),
      title: 'Travel',
      details: 'Synthetic test entry',
    ),
  ];
  bool failRead = false;
  bool failDelete = false;
  int deletes = 0;
  @override
  Future<List<JournalEntry>> read() async {
    if (failRead) throw StateError('Fictional read failure');
    return entries;
  }

  @override
  Future<List<JournalEntry>> upsert(JournalEntry entry) async =>
      entries = [...entries, entry];
  @override
  Future<List<JournalEntry>> delete(String id) async =>
      entries = entries.where((e) => e.id != id).toList();
  @override
  Future<void> deleteAll() async {
    deletes++;
    if (failDelete) throw StateError('Fictional delete failure');
    entries = [];
  }
}

class _Exporter implements DataExportService {
  int calls = 0;
  bool fail = false;
  @override
  Future<LocalExportResult> create({
    required RingSyncDataset dataset,
    required List<JournalEntry> journal,
  }) async {
    calls++;
    if (fail) throw StateError('Fictional export failure');
    return LocalExportResult(
      jsonFile: File('/synthetic-export.json'),
      csvFile: File('/synthetic-export.csv'),
      rowCount: dataset.recordCount + journal.length,
      sha256: '0' * 64,
      createdAtUtc: DateTime.utc(2026, 9, 1),
    );
  }
}
