import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ring_core/ring_core.dart';

import 'app_state.dart';

/// The same screens serve real records and clearly labelled fictional examples.
/// Demo records are never merged into the production repository.
final displayRingDataProvider = Provider<AsyncValue<RingSyncDataset?>>((ref) {
  if (!ref.watch(isDemoModeProvider)) return ref.watch(ringDataProvider);
  return AsyncData(exampleRingHistory(ref.watch(currentLocalTimeProvider)));
});

RingSyncDataset exampleRingHistory(DateTime now) {
  final activity = <RingActivityBucket>[];
  final pulse = <RingHeartRateSample>[];
  final oxygen = <RingOxygenRange>[];
  final sleep = <RingSleepSession>[];
  final indexes = <RingVendorIndexSample>[];
  for (var offset = 13; offset >= 0; offset--) {
    final day = DateTime(now.year, now.month, now.day - offset);
    for (var hour = 0; hour < 24; hour++) {
      final time = DateTime(day.year, day.month, day.day, hour);
      if (time.isAfter(now)) continue;
      if (hour == 14 || (offset % 3 == 0 && hour == 15)) continue;
      final steps = hour < 7
          ? 0
          : <int>[180, 460, 620, 340, 90, 260, 880, 360][(hour + offset) % 8];
      activity.add(
        RingActivityBucket(
          startedAtUtc: time.toUtc(),
          steps: steps,
          distanceMeters: (steps * .72).round(),
          firmwareCalories: (steps * .039).round(),
          origin: DataOrigin.demo,
        ),
      );
      pulse.add(
        RingHeartRateSample(
          measuredAtUtc: time.toUtc(),
          bpm: hour < 7
              ? 52 + (hour + offset) % 9
              : 65 + (hour * 7 + offset * 3) % 30,
          origin: DataOrigin.demo,
        ),
      );
      oxygen.add(
        RingOxygenRange(
          hourStartedAtUtc: time.toUtc(),
          minimumPercent: 96 + (hour + offset) % 2,
          maximumPercent: 98 + hour % 2,
          origin: DataOrigin.demo,
        ),
      );
      for (final kind in RingVendorIndexKind.values) {
        indexes.add(
          RingVendorIndexSample(
            measuredAtUtc: time.toUtc(),
            value: 31 + (hour * 3 + offset) % 19,
            kind: kind,
            origin: DataOrigin.demo,
          ),
        );
      }
    }
    final start = DateTime(
      day.year,
      day.month,
      day.day - 1,
      23,
      10 + offset % 4 * 8,
    );
    var cursor = start;
    final spans = <RingSleepStageSpan>[];
    for (final span in <(RingSleepStage, int)>[
      (RingSleepStage.light, 52),
      (RingSleepStage.deep, 67),
      (RingSleepStage.light, 48),
      (RingSleepStage.rem, 32),
      (RingSleepStage.awake, 9),
      (RingSleepStage.light, 62),
      (RingSleepStage.deep, 38),
      (RingSleepStage.rem, 45),
      (RingSleepStage.light, 75 + offset % 5),
    ]) {
      spans.add(
        RingSleepStageSpan(
          stage: span.$1,
          startedAtUtc: cursor.toUtc(),
          durationMinutes: span.$2,
        ),
      );
      cursor = cursor.add(Duration(minutes: span.$2));
    }
    if (!cursor.isAfter(now)) {
      sleep.add(
        RingSleepSession(
          startedAtUtc: start.toUtc(),
          endedAtUtc: cursor.toUtc(),
          stages: spans,
          origin: DataOrigin.demo,
        ),
      );
    }
  }
  return RingSyncDataset(
    lastSyncedAtUtc: now.toUtc(),
    source: const RingDataSource(
      driverId: 'fictional-demo',
      firmwareVersion: 'Example data',
    ),
    availability: {
      for (final kind in RingDataKind.values)
        kind: RingDataAvailability.complete,
    },
    activity: activity,
    heartRate: pulse,
    sleep: sleep,
    oxygen: oxygen,
    vendorIndexes: indexes,
    batteryLevel: 78,
    charging: false,
  );
}
