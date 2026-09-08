import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/presentation_data.dart';
import 'package:librering_mobile/src/ring_analytics.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:ring_core/ring_core.dart';

void main() {
  test(
    'refresh publishes saved readings to display consumers without a merge',
    () async {
      final repository = _Repository(_dataset(51));
      final container = _container(repository);
      final observed = <RingSyncDataset?>[];
      final subscription = container.listen(displayRingDataProvider, (_, next) {
        if (next.hasValue) observed.add(next.value);
      });
      addTearDown(subscription.close);
      await container.read(ringDataProvider.future);
      final incoming = _dataset(68);
      repository.value = incoming;
      await container.read(ringDataProvider.notifier).refresh();
      expect(
        container.read(displayRingDataProvider).requireValue,
        same(incoming),
      );
      expect(observed.last, same(incoming));
      expect(repository.reads, 2);
      expect(repository.merges, 0);
      expect(repository.deletes, 0);
      expect(container.exists(ringPairingProvider), isFalse);
    },
  );

  test(
    'refresh preserves visible readings until the fresh local read finishes',
    () async {
      final original = _dataset(51);
      final repository = _Repository(original);
      final container = _container(repository);
      await container.read(ringDataProvider.future);
      repository.readGate = Completer<void>();
      final pending = container.read(ringDataProvider.notifier).refresh();
      await _tick();
      expect(container.read(ringDataProvider).value, same(original));
      expect(container.read(ringDataProvider).isLoading, isFalse);
      repository.value = _dataset(68);
      repository.readGate!.complete();
      await pending;
      expect(
        container.read(ringDataProvider).requireValue!.heartRate.single.bpm,
        68,
      );
    },
  );

  test(
    'failed refresh retains cached data and surfaces failure to its caller',
    () async {
      final original = _dataset(51);
      final repository = _Repository(original);
      final container = _container(repository);
      await container.read(ringDataProvider.future);
      repository.failRead = true;
      await expectLater(
        container.read(ringDataProvider.notifier).refresh(),
        throwsStateError,
      );
      expect(container.read(ringDataProvider).value, same(original));
      expect(repository.value, same(original));
      expect(repository.merges + repository.deletes, 0);
      repository.failRead = false;
      repository.value = _dataset(68);
      await container.read(ringDataProvider.notifier).refresh();
      expect(
        container.read(ringDataProvider).requireValue!.heartRate.single.bpm,
        68,
      );
    },
  );

  test(
    'refresh waits for a pending merge and cannot republish older history',
    () async {
      final repository = _Repository(_dataset(51));
      final container = _container(repository);
      await container.read(ringDataProvider.future);
      final controller = container.read(ringDataProvider.notifier);
      repository.mergeGate = Completer<void>();
      final incoming = _dataset(68);
      final merging = controller.merge(incoming);
      await _tick();
      final refreshing = controller.refresh();
      await _tick();
      expect(repository.reads, 1);
      expect(repository.merges, 1);
      repository.mergeGate!.complete();
      await Future.wait([merging, refreshing]);
      expect(repository.events, ['read', 'merge', 'read']);
      expect(container.read(ringDataProvider).requireValue, same(incoming));
    },
  );

  test(
    'a merge queued behind refresh wins after fresh history is published',
    () async {
      final repository = _Repository(_dataset(51));
      final container = _container(repository);
      await container.read(ringDataProvider.future);
      final controller = container.read(ringDataProvider.notifier);
      repository.readGate = Completer<void>();
      final refreshing = controller.refresh();
      await _tick();
      final incoming = _dataset(68);
      final merging = controller.merge(incoming);
      await _tick();
      expect(repository.merges, 0);
      repository.readGate!.complete();
      await Future.wait([refreshing, merging]);
      expect(repository.events, ['read', 'read', 'merge']);
      expect(container.read(ringDataProvider).requireValue, same(incoming));
    },
  );

  test(
    'deletion queued behind refresh cannot restore the removed dataset',
    () async {
      final repository = _Repository(_dataset(51));
      final container = _container(repository);
      await container.read(ringDataProvider.future);
      final controller = container.read(ringDataProvider.notifier);
      repository.readGate = Completer<void>();
      final refreshing = controller.refresh();
      await _tick();
      final deleting = controller.deleteAll();
      repository.readGate!.complete();
      await Future.wait([refreshing, deleting]);
      expect(repository.events, ['read', 'read', 'delete']);
      expect(container.read(ringDataProvider).requireValue, isNull);
      expect(repository.value, isNull);
    },
  );

  test(
    'refresh waits for initialization instead of racing the first snapshot',
    () async {
      final original = _dataset(51);
      final initial = Completer<RingSyncDataset?>();
      final repository = _Repository(_dataset(68))..firstRead = initial.future;
      final container = _container(repository);
      final refreshing = container.read(ringDataProvider.notifier).refresh();
      await _tick();
      expect(repository.reads, 1);
      initial.complete(original);
      await refreshing;
      await _tick();
      expect(repository.reads, 2);
      expect(
        container.read(ringDataProvider).requireValue!.heartRate.single.bpm,
        68,
      );
    },
  );

  test('successful refresh recovers an initial read failure without deleting history', () async {
    final repository = _Repository(_dataset(51))..failRead = true;
    final container = _container(repository);
    await expectLater(
      container.read(ringDataProvider.future),
      throwsStateError,
    );
    final controller = container.read(ringDataProvider.notifier);
    await expectLater(controller.refresh(), throwsStateError);
    expect(container.read(ringDataProvider).hasError, isTrue);
    await expectLater(controller.merge(_dataset(68)), throwsStateError);
    expect(repository.merges, 0);
    repository.failRead = false;
    await controller.refresh();
    expect(
      container.read(ringDataProvider).requireValue!.heartRate.single.bpm,
      51,
    );
    await controller.merge(_dataset(68));
    expect(
      container.read(ringDataProvider).requireValue!.heartRate.single.bpm,
      68,
    );
    expect(repository.merges, 1);
    expect(repository.deletes, 0);
  });

  test('a confirmed missing local file clears cached history without inventing zeroes', () async {
    final repository = _Repository(_dataset(51));
    final container = _container(repository);
    await container.read(ringDataProvider.future);
    repository.value = null;
    await container.read(ringDataProvider.notifier).refresh();
    expect(container.read(ringDataProvider).requireValue, isNull);
    expect(repository.merges + repository.deletes, 0);
  });

  test('missing repository reports unavailable instead of treating refresh as a sync', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(ringDataProvider.future);
    await expectLater(
      container.read(ringDataProvider.notifier).refresh(),
      throwsStateError,
    );
    expect(container.read(ringDataProvider).requireValue, isNull);
    expect(container.exists(ringPairingProvider), isFalse);
  });

  test(
    'whenIdle waits for a reload before an export can snapshot history',
    () async {
      final repository = _Repository(_dataset(51));
      final container = _container(repository);
      await container.read(ringDataProvider.future);
      final controller = container.read(ringDataProvider.notifier);
      repository.readGate = Completer<void>();
      final refreshing = controller.refresh();
      var idle = false;
      final waiting = controller.whenIdle.then((_) => idle = true);
      await _tick();
      expect(idle, isFalse);
      repository.readGate!.complete();
      await Future.wait([refreshing, waiting]);
      expect(idle, isTrue);
    },
  );

  test('real file merge is immediately visible and refresh reads the durable result', () async {
    final directory = await Directory.systemTemp.createTemp(
      'librering-refresh-test-',
    );
    addTearDown(() async => directory.delete(recursive: true));
    final repository = FileRingDataRepository(directory);
    final container = _container(repository);
    await container.read(ringDataProvider.future);
    final controller = container.read(ringDataProvider.notifier);
    final first = await controller.merge(_dataset(51));
    expect(container.read(displayRingDataProvider).requireValue, same(first));
    final updated = await controller.merge(_dataset(68));
    expect(container.read(displayRingDataProvider).requireValue, same(updated));
    await controller.refresh();
    final refreshed = container.read(displayRingDataProvider).requireValue!;
    expect(refreshed.heartRate.single.bpm, 68);
    expect(refreshed.lastSyncedAtUtc, updated.lastSyncedAtUtc);
    expect(
      refreshed.heartRate.single.measuredAtUtc,
      updated.heartRate.single.measuredAtUtc,
    );
    expect(refreshed.recordCount, 1);
  });

  for (final operation in ['merge', 'refresh']) {
    test(
      '$operation advances the cached clock so newly collected readings are not hidden',
      () async {
        final repository = _Repository(null);
        final container = _container(repository);
        await container.read(ringDataProvider.future);
        final cachedNow = container.read(currentLocalTimeProvider);
        await Future<void>.delayed(const Duration(milliseconds: 2));
        final measuredAt = DateTime.now();
        expect(measuredAt.isAfter(cachedNow), isTrue);
        final collected = RingSyncDataset(
          lastSyncedAtUtc: measuredAt.toUtc(),
          source: const RingDataSource(driverId: 'colmi-qring-v1'),
          availability: const {
            RingDataKind.heartRate: RingDataAvailability.complete,
          },
          heartRate: [
            RingHeartRateSample(measuredAtUtc: measuredAt.toUtc(), bpm: 72),
          ],
        );
        // A real new reading is newer than the pre-sync cached clock, so the
        // intentional future-data filter excludes it until that clock advances.
        final before = RingAnalytics.fromDataset(
          collected,
          localNow: cachedNow,
        );
        expect(before.pulseFor(cachedNow).samples, isEmpty);
        final controller = container.read(ringDataProvider.notifier);
        if (operation == 'merge') {
          await controller.merge(collected);
        } else {
          repository.value = collected;
          await controller.refresh();
        }
        final visibleNow = container.read(currentLocalTimeProvider);
        expect(visibleNow.isBefore(measuredAt), isFalse);
        final after = RingAnalytics.fromDataset(
          container.read(displayRingDataProvider).requireValue!,
          localNow: visibleNow,
        );
        expect(after.pulseFor(visibleNow).samples.single.value, 72);
      },
    );
  }

  test('a failed refresh does not advance the cached clock', () async {
    final repository = _Repository(_dataset(51));
    final container = _container(repository);
    await container.read(ringDataProvider.future);
    final cachedNow = container.read(currentLocalTimeProvider);
    repository.failRead = true;
    await expectLater(
      container.read(ringDataProvider.notifier).refresh(),
      throwsStateError,
    );
    expect(container.read(currentLocalTimeProvider), same(cachedNow));
  });
}

ProviderContainer _container(RingDataRepository repository) {
  final container = ProviderContainer(
    overrides: [ringDataRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _tick() => Future<void>.delayed(Duration.zero);

RingSyncDataset _dataset(int bpm) => RingSyncDataset(
  lastSyncedAtUtc: DateTime.utc(2026, 9, 7, 12),
  source: const RingDataSource(driverId: 'colmi-qring-v1'),
  availability: const {RingDataKind.heartRate: RingDataAvailability.complete},
  heartRate: [
    RingHeartRateSample(measuredAtUtc: DateTime.utc(2026, 9, 7, 11), bpm: bpm),
  ],
);

class _Repository implements RingDataRepository {
  _Repository(this.value);

  RingSyncDataset? value;
  Future<RingSyncDataset?>? firstRead;
  Completer<void>? readGate;
  Completer<void>? mergeGate;
  bool failRead = false;
  int reads = 0;
  int merges = 0;
  int deletes = 0;
  final events = <String>[];

  @override
  Future<RingSyncDataset?> read() async {
    events.add('read');
    reads++;
    if (reads == 1 && firstRead != null) return firstRead!;
    await readGate?.future;
    if (failRead) throw StateError('Synthetic local read failure');
    return value;
  }

  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async {
    events.add('merge');
    merges++;
    await mergeGate?.future;
    return value = incoming;
  }

  @override
  Future<void> deleteAll() async {
    events.add('delete');
    deletes++;
    value = null;
  }
}
