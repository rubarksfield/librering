import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/ble/r12_pairing_client.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  testWidgets('production pairing verifies services without a command write', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = _FakePairingClient();

    await tester.pumpWidget(
      LibreRingApp(initialLocation: '/pairing/scan', pairingClient: client),
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
  Future<void> disconnect() async {}
}
