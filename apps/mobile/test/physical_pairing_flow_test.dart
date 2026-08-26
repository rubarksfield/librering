import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/ble/r12_pairing_client.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  testWidgets('production pairing runs the one-button approved suite', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = _FakePairingClient();

    await tester.pumpWidget(
      LibreRingApp(
        initialLocation: '/pairing/scan',
        captureMode: true,
        pairingClient: client,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan-now')));
    await tester.pumpAndSettle();
    expect(find.text('Verify COLMI R12_TEST'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('scan-now')));
    final button = find.descendant(
      of: find.byKey(const Key('scan-now')),
      matching: find.byType(FilledButton),
    );
    expect(button.hitTestable(), findsOneWidget);
    tester.widget<FilledButton>(button).onPressed!();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(client.connectCount, 1);
    expect(find.byKey(const Key('screen-ring-found')), findsOneWidget);
    expect(
      find.text('Command and history services confirmed · No commands sent'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('capture-approved-suite')));
    final captureButton = find.descendant(
      of: find.byKey(const Key('capture-approved-suite')),
      matching: find.byType(FilledButton),
    );
    tester.widget<FilledButton>(captureButton).onPressed!();
    await tester.pumpAndSettle();
    expect(client.approvedSuiteCount, 1);
    expect(find.text('Battery 73% · Firmware R12-1.2.3'), findsOneWidget);
    expect(find.textContaining('2 of 2 sections'), findsOneWidget);
  });

  testWidgets('multiple exact R12 results require an explicit choice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = _FakePairingClient(
      candidates: const <RingPairingCandidate>[
        RingPairingCandidate(
          advertisement: RingAdvertisement(
            deviceId: 'redacted-one',
            name: 'COLMI R12_ONE',
          ),
          exact: true,
        ),
        RingPairingCandidate(
          advertisement: RingAdvertisement(
            deviceId: 'redacted-two',
            name: 'COLMI R12_TWO',
          ),
          exact: true,
        ),
      ],
    );

    await tester.pumpWidget(
      LibreRingApp(initialLocation: '/pairing/scan', pairingClient: client),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan-now')));
    await tester.pumpAndSettle();

    expect(find.text('COLMI R12_ONE'), findsOneWidget);
    expect(find.text('COLMI R12_TWO'), findsOneWidget);
    expect(find.text('Choose a ring above'), findsOneWidget);
    expect(client.connectCount, 0);

    await tester.tap(find.text('COLMI R12_TWO'));
    await tester.pumpAndSettle();
    expect(find.text('Verify COLMI R12_TWO'), findsOneWidget);
  });

  testWidgets('production sync stores the decoded dataset before navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = _FakePairingClient();
    final repository = _MemoryRepository();

    await tester.pumpWidget(
      LibreRingApp(
        initialLocation: '/pairing/scan',
        pairingClient: client,
        ringDataRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan-now')));
    await tester.pumpAndSettle();
    final connectButton = find.descendant(
      of: find.byKey(const Key('scan-now')),
      matching: find.byType(FilledButton),
    );
    tester.widget<FilledButton>(connectButton).onPressed!();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sync-ring-data')));
    await tester.pumpAndSettle();

    expect(client.syncCount, 1);
    expect(client.disconnectCount, 1);
    expect(repository.value, isNotNull);
    expect(find.textContaining('0 records stored locally'), findsOneWidget);
    expect(find.byKey(const Key('found-view-today')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sync-ring-data')));
    await tester.pumpAndSettle();
    expect(client.connectCount, 2);
    expect(client.syncCount, 2);
    expect(client.disconnectCount, 2);
  });

  testWidgets('returning users quick-sync on Today without onboarding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = _FakePairingClient();
    final repository = _MemoryRepository()..value = await client.sync();
    client.syncCount = 0;

    await tester.pumpWidget(
      LibreRingApp(
        initialLocation: '/today',
        pairingClient: client,
        ringDataRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-today')), findsOneWidget);
    expect(find.byKey(const Key('screen-ring-scan')), findsNothing);

    await tester.tap(find.byKey(const Key('today-quick-sync')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen-today')), findsOneWidget);
    expect(find.byKey(const Key('screen-ring-scan')), findsNothing);
    expect(find.text('Ring data refreshed locally.'), findsOneWidget);
    expect(client.connectCount, 1);
    expect(client.syncCount, 1);
    expect(client.disconnectCount, 1);
  });

  testWidgets('quick sync does not choose between multiple nearby R12s', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = _FakePairingClient(
      candidates: const <RingPairingCandidate>[
        RingPairingCandidate(
          advertisement: RingAdvertisement(
            deviceId: 'redacted-one',
            name: 'COLMI R12_ONE',
          ),
          exact: true,
        ),
        RingPairingCandidate(
          advertisement: RingAdvertisement(
            deviceId: 'redacted-two',
            name: 'COLMI R12_TWO',
          ),
          exact: true,
        ),
      ],
    );

    await tester.pumpWidget(
      LibreRingApp(
        initialLocation: '/today',
        pairingClient: client,
        ringDataRepository: _MemoryRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('today-quick-sync')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen-today')), findsOneWidget);
    expect(
      find.text('More than one R12 was found. Use device setup to choose one.'),
      findsOneWidget,
    );
    expect(client.connectCount, 0);
    expect(client.syncCount, 0);
  });
}

class _MemoryRepository implements RingDataRepository {
  RingSyncDataset? value;

  @override
  Future<void> deleteAll() async => value = null;

  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async =>
      value = incoming;

  @override
  Future<RingSyncDataset?> read() async => value;
}

class _FakePairingClient implements RingPairingClient {
  _FakePairingClient({List<RingPairingCandidate>? candidates})
    : candidates =
          candidates ??
          const <RingPairingCandidate>[
            RingPairingCandidate(
              advertisement: RingAdvertisement(
                deviceId: 'redacted-test-id',
                name: 'COLMI R12_TEST',
              ),
              exact: true,
            ),
          ];

  final List<RingPairingCandidate> candidates;
  int connectCount = 0;
  int captureCount = 0;
  int timeSyncCount = 0;
  int approvedSuiteCount = 0;
  int syncCount = 0;
  int disconnectCount = 0;

  @override
  Stream<RingPairingCandidate> scan({required Duration timeout}) =>
      Stream<RingPairingCandidate>.fromIterable(candidates);

  @override
  Future<RingPairingEvidence> connect(RingAdvertisement advertisement) async {
    connectCount += 1;
    return RingPairingEvidence(
      name: advertisement.name,
      capabilities: DeviceCapabilities(
        const <DeviceCapability, CapabilityConfidence>{
          DeviceCapability.battery: CapabilityConfidence.familyCorroborated,
        },
      ),
      supportsBigData: true,
    );
  }

  @override
  Future<RingMetadata> captureMetadata() async {
    captureCount += 1;
    return const RingMetadata(
      batteryLevel: 73,
      charging: false,
      firmwareVersion: 'R12-1.2.3',
    );
  }

  @override
  Future<RingTimeSyncResult> captureTimeSync() async {
    timeSyncCount += 1;
    return RingTimeSyncResult(
      requestedLocalTime: DateTime(2026, 8, 26, 16, 15),
    );
  }

  @override
  Future<RingApprovedSuiteResult> captureApprovedSuite() async {
    approvedSuiteCount += 1;
    return const RingApprovedSuiteResult(
      statuses: <String, String>{'metadata': 'complete', 'history': 'noData'},
      batteryLevel: 73,
      charging: false,
      firmwareVersion: 'R12-1.2.3',
    );
  }

  @override
  Future<RingSyncDataset> sync() async {
    syncCount += 1;
    return RingSyncDataset(
      lastSyncedAtUtc: DateTime.utc(2026, 8, 26, 16, 30),
      source: const RingDataSource(
        driverId: 'colmi-qring-v1',
        firmwareVersion: 'RT11CR_1.00.09_260424',
      ),
      availability: const <RingDataKind, RingDataAvailability>{
        RingDataKind.battery: RingDataAvailability.complete,
      },
      batteryLevel: 73,
      charging: false,
    );
  }

  @override
  Future<void> disconnect() async {
    disconnectCount += 1;
  }
}
