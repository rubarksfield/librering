import 'package:ring_core/ring_core.dart';
import 'package:test/test.dart';

void main() {
  test('manual records retain their provenance', () {
    const entry = SwimEntry(
      durationMinutes: 42,
      poolLength: '25 metres',
      effort: 'steady',
      origin: DataOrigin.manual,
    );

    expect(entry.origin, DataOrigin.manual);
    expect(entry.durationMinutes, 42);
  });

  test('undeclared capabilities fail closed', () {
    final capabilities = DeviceCapabilities(
      <DeviceCapability, CapabilityConfidence>{
        DeviceCapability.battery: CapabilityConfidence.familyCorroborated,
      },
    );

    expect(capabilities.supports(DeviceCapability.battery), isTrue);
    expect(capabilities.supports(DeviceCapability.sleep), isFalse);
    expect(
      capabilities.confidenceFor(DeviceCapability.sleep),
      CapabilityConfidence.unavailable,
    );
  });

  test('ring sync records carry provenance and deterministic identities', () {
    final measuredAt = DateTime.utc(2026, 8, 26, 8, 30);
    final dataset = RingSyncDataset(
      lastSyncedAtUtc: DateTime.utc(2026, 8, 26, 9),
      source: const RingDataSource(
        driverId: 'colmi-qring-v1',
        firmwareVersion: 'synthetic-firmware',
      ),
      availability: const <RingDataKind, RingDataAvailability>{
        RingDataKind.heartRate: RingDataAvailability.complete,
      },
      heartRate: <RingHeartRateSample>[
        RingHeartRateSample(measuredAtUtc: measuredAt, bpm: 61),
      ],
    );

    expect(dataset.recordCount, 1);
    expect(dataset.heartRate.single.origin, DataOrigin.ring);
    expect(
      dataset.heartRate.single.recordKey,
      'heartRate|2026-08-26T08:30:00.000Z',
    );
    expect(
      () => dataset.availability[RingDataKind.sleep] =
          RingDataAvailability.complete,
      throwsUnsupportedError,
    );
  });
}
