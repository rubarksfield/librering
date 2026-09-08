// Actual Flutter release-media captures, deliberately outside test/ so normal
// test discovery does not rewrite public assets. See docs/media/v1.3.2/README.md.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/dashboard_screens.dart';
import 'package:librering_mobile/src/presentation_data.dart';
import 'package:librering_mobile/src/storage/journal_repository.dart';
import 'package:librering_mobile/src/storage/preferences_repository.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:librering_mobile/src/sync_progress.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

final _now = DateTime(2026, 9, 8, 10, 20);
const _captureKey = Key('release-media-boundary');
const _refreshSuccess =
    'Saved readings refreshed. Use Sync to get new data from your ring.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!Platform.isMacOS) {
      throw StateError('Release capture requires the documented macOS fonts.');
    }
    await _loadFont(
      'Helvetica Neue',
      File('/System/Library/Fonts/HelveticaNeue.ttc'),
    );
    await _loadFont('MaterialIcons', _findMaterialIcons());
  });

  for (final entry in <(String, String)>[
    ('today', '/today'),
    ('vitals', '/vitals'),
    ('sleep', '/sleep'),
    ('heart', '/heart'),
    ('activity', '/activity'),
    ('oxygen', '/oxygen'),
    ('hrv-index', '/signals/hrv-index'),
    ('stress-index', '/signals/stress-index'),
    ('trends', '/trends'),
    ('welcome', '/welcome'),
  ]) {
    testWidgets(
      'capture actual ${entry.$1} screen with synthetic saved history',
      (tester) async {
        final repository = await _open(tester, entry.$2);
        if (entry.$1 == 'today') {
          // The production guidance evaluator, not an inserted marketing card.
          expect(find.byKey(const Key('daily-guidance-card')), findsOneWidget);
        }
        if (entry.$1 == 'welcome') {
          expect(find.byKey(const Key('welcome-start')), findsOneWidget);
        }
        await _capture(tester, entry.$1);
        expect(repository.writeAttempts, 0);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  for (final kind in ['hrv', 'stress']) {
    testWidgets('capture actual opened $kind explanation sheet', (
      tester,
    ) async {
      final repository = await _open(tester, '/signals/$kind-index');
      final action = find.byKey(Key('$kind-education-open'));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.text(kind == 'hrv' ? 'HRV, explained' : 'Stress index, explained'),
        findsOneWidget,
      );
      await _capture(tester, '$kind-explained');
      expect(repository.writeAttempts, 0);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

  testWidgets(
    'capture real saved-readings pull-to-refresh success, without Bluetooth',
    (tester) async {
      final repository = await _open(tester, '/vitals');
      final readsBefore = repository.reads;
      await tester.dragFrom(const Offset(40, 110), const Offset(0, 480));
      await tester.pumpAndSettle();
      expect(repository.reads, readsBefore + 1);
      expect(repository.writeAttempts, 0);
      expect(find.text(_refreshSuccess), findsOneWidget);
      await _capture(tester, 'refresh');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'capture real Today widget with explicitly simulated sync progress',
    (tester) async {
      _phone(tester);
      final repository = _ReadOnlyRingRepository(exampleRingHistory(_now));
      final container = ProviderContainer(
        overrides: [
          isDemoModeProvider.overrideWithValue(false),
          currentLocalTimeProvider.overrideWithValue(_now),
          ringPairingClientProvider.overrideWithValue(null),
          ringPairingProvider.overrideWith(_SimulatedSync.new),
          ringDataRepositoryProvider.overrideWithValue(repository),
          journalRepositoryProvider.overrideWithValue(_ReadOnlyJournal()),
          preferencesRepositoryProvider.overrideWithValue(
            _ReadOnlyPreferences(),
          ),
        ],
      );
      final router = GoRouter(
        initialLocation: '/today',
        routes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => const RefinedTodayScreen(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _captureKey,
          child: UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: buildLibreRingTheme(),
              routerConfig: router,
            ),
          ),
        ),
      );
      // Do not settle the deliberately active spinner; freeze one known frame.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Reading activity'), findsOneWidget);
      expect(find.text('Elapsed 12s'), findsOneWidget);
      expect(find.text('2 of 8 days checked'), findsOneWidget);
      expect(container.read(ringPairingClientProvider), isNull);
      await _capture(tester, 'syncing');
      expect(repository.writeAttempts, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<_ReadOnlyRingRepository> _open(WidgetTester tester, String route) async {
  _phone(tester);
  final repository = _ReadOnlyRingRepository(exampleRingHistory(_now));
  await tester.pumpWidget(
    RepaintBoundary(
      key: _captureKey,
      child: LibreRingApp(
        initialLocation: route,
        demoMode: false,
        locale: const Locale('en'),
        currentLocalTime: _now,
        ringDataRepository: repository,
        journalRepository: _ReadOnlyJournal(),
        preferencesRepository: _ReadOnlyPreferences(),
        // pairingClient intentionally omitted: no BLE client is instantiated.
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  expect(container.read(isDemoModeProvider), isFalse);
  expect(container.read(ringPairingClientProvider), isNull);
  return repository;
}

Future<void> _capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
  expect(image, isNotNull);
  try {
    expect(image!.width, 780);
    expect(image.height, 1688);
    await expectLater(
      image,
      matchesGoldenFile('../../../docs/media/v1.3.2/$name.png'),
    );
  } finally {
    image?.dispose();
  }
}

class _ReadOnlyRingRepository implements RingDataRepository {
  _ReadOnlyRingRepository(this.value);
  final RingSyncDataset value;
  int reads = 0;
  int writeAttempts = 0;

  @override
  Future<RingSyncDataset> read() async {
    reads++;
    return value;
  }

  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async {
    writeAttempts++;
    throw StateError('Public media captures must not change saved ring data.');
  }

  @override
  Future<void> deleteAll() async {
    writeAttempts++;
    throw StateError('Public media captures must not delete ring data.');
  }
}

class _ReadOnlyJournal implements JournalRepository {
  @override
  Future<List<JournalEntry>> read() async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Public media captures must not change the journal.');
}

class _ReadOnlyPreferences implements PreferencesRepository {
  @override
  Future<AppPreferences> read() async => const AppPreferences();
  @override
  Future<void> save(AppPreferences preferences) async =>
      throw StateError('Public media captures must not change preferences.');
}

class _SimulatedSync extends RingPairingController {
  @override
  RingPairingState build() => RingPairingState(
    syncInProgress: true,
    syncProgress: RingSyncProgress(
      stage: RingSyncStage.activity,
      startedAtUtc: _now.toUtc(),
      elapsed: const Duration(seconds: 12),
      sinceLastProgress: Duration.zero,
      completedUnits: 2,
      totalUnits: 8,
    ),
  );
}

Future<void> _loadFont(String family, File file) async {
  final bytes = await file.readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

File _findMaterialIcons() {
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.parent.path != directory.path) {
    final candidate = File(
      '${directory.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Flutter MaterialIcons font was not found.');
}
