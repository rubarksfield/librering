import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librering_mobile/src/app_state.dart';
import 'package:librering_mobile/src/ble/r12_pairing_client.dart';
import 'package:librering_mobile/src/dashboard_screens.dart';
import 'package:librering_mobile/src/presentation_data.dart';
import 'package:librering_mobile/src/screens.dart';
import 'package:librering_mobile/src/storage/ring_data_repository.dart';
import 'package:librering_mobile/src/sync_progress.dart';
import 'package:librering_mobile/src/ui/sync_status_card.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

final _now = DateTime(2026, 9, 5, 10, 20);

RingPairingState _state(
  RingSyncStage stage, {
  bool active = true,
  int elapsed = 12,
  int waiting = 0,
  String? error,
  int? records,
}) => RingPairingState(
  syncInProgress: active,
  syncError: error,
  lastSyncRecordCount: records,
  lastSyncedAtUtc: records == null ? null : _now.toUtc(),
  syncProgress: RingSyncProgress(
    stage: stage,
    startedAtUtc: _now.toUtc(),
    elapsed: Duration(seconds: elapsed),
    sinceLastProgress: Duration(seconds: waiting),
    completedUnits: stage == RingSyncStage.activity ? 2 : null,
    totalUnits: stage == RingSyncStage.activity ? 8 : null,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!Platform.isMacOS) return;
    await _loadFont(
      'Helvetica Neue',
      File('/System/Library/Fonts/HelveticaNeue.ttc'),
    );
    await _loadFont('MaterialIcons', _findMaterialIcons());
  });

  testWidgets('active sync shows actual stage, elapsed time and days checked', (
    tester,
  ) async {
    await _pumpCard(tester, _state(RingSyncStage.activity));
    expect(find.text('Reading activity'), findsOneWidget);
    expect(find.text('Elapsed 12s'), findsOneWidget);
    expect(find.text('2 of 8 days checked'), findsOneWidget);
    expect(find.byKey(const Key('ring-sync-spinner')), findsOneWidget);
    expect(find.byKey(const Key('ring-sync-retry')), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('remaining'), findsNothing);
  });

  testWidgets(
    'stalled sync replaces animation with an honest warning and recovery',
    (tester) async {
      var help = 0;
      await _pumpCard(
        tester,
        _state(RingSyncStage.sleep, elapsed: 91, waiting: 31),
        onHelp: () => help++,
      );
      expect(find.text('Sync is taking longer'), findsOneWidget);
      expect(find.text('No progress for 31s'), findsOneWidget);
      expect(find.textContaining('Close QRing'), findsOneWidget);
      expect(find.textContaining('close and reopen LibreRing'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('ring-sync-retry')), findsNothing);
      await tester.tap(find.byKey(const Key('ring-sync-status-help')));
      expect(help, 1);
    },
  );

  testWidgets(
    'stage announcement is live but elapsed time is not announced every tick',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpCard(tester, _state(RingSyncStage.sleep));
      final first = tester.getSemantics(
        find.byKey(const Key('ring-sync-announcement')),
      );
      final label = first.label;
      expect(first.flagsCollection.isLiveRegion, isTrue);
      expect(label, contains('Reading sleep history'));
      expect(label, isNot(contains('Elapsed')));
      await _pumpCard(tester, _state(RingSyncStage.sleep, elapsed: 13));
      final second = tester.getSemantics(
        find.byKey(const Key('ring-sync-announcement')),
      );
      expect(second.label, label);
      expect(find.text('Elapsed 13s'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'saving and finishing remain active even if a partial read is known',
    (tester) async {
      for (final stage in [RingSyncStage.saving, RingSyncStage.finishing]) {
        await _pumpCard(
          tester,
          _state(stage, error: 'A history channel timed out.'),
        );
        expect(
          find.text(
            stage == RingSyncStage.saving
                ? 'Saving on your phone'
                : 'Finishing sync',
          ),
          findsOneWidget,
        );
        expect(find.text('Sync couldn’t finish'), findsNothing);
        expect(find.text('Some data saved'), findsNothing);
        expect(find.byKey(const Key('ring-sync-retry')), findsNothing);
      }
    },
  );

  testWidgets(
    'completion persists, states local storage and records its end time',
    (tester) async {
      await _pumpCard(
        tester,
        _state(RingSyncStage.completed, active: false, records: 4),
      );
      await tester.pump(const Duration(minutes: 2));
      expect(find.text('Sync complete'), findsOneWidget);
      expect(find.textContaining('saved on this phone'), findsOneWidget);
      expect(find.byKey(const Key('ring-sync-ended-at')), findsOneWidget);
      expect(find.text('Duration 12s'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('ring-sync-retry')), findsNothing);
    },
  );

  testWidgets(
    'completed empty read explains there is no reading rather than zero data',
    (tester) async {
      await _pumpCard(
        tester,
        _state(RingSyncStage.completed, active: false, records: 0),
      );
      expect(find.text('Sync complete'), findsOneWidget);
      expect(
        find.textContaining('there are no readings to show yet'),
        findsOneWidget,
      );
      expect(find.text('0'), findsNothing);
    },
  );

  testWidgets(
    'partial and failed results explain the outcome and enable a retry',
    (tester) async {
      var retries = 0;
      for (final stage in [RingSyncStage.partial, RingSyncStage.failed]) {
        final error = stage == RingSyncStage.partial
            ? 'Available records were saved; one channel needs another try.'
            : 'The connection failed. Your saved history is unchanged.';
        await _pumpCard(
          tester,
          _state(stage, active: false, error: error),
          onRetry: () => retries++,
        );
        expect(find.text(error), findsOneWidget);
        expect(
          find.text(
            stage == RingSyncStage.partial
                ? 'Some data saved'
                : 'Sync couldn’t finish',
          ),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.tap(find.byKey(const Key('ring-sync-retry')));
      }
      expect(retries, 2);
    },
  );

  testWidgets(
    'Portuguese failures and partial results retain localized recovery advice',
    (tester) async {
      for (final entry in [
        (
          RingSyncStage.failed,
          'More than one R12 was found. Use device setup to choose one.',
          'Foi encontrado mais de um R12. Abra a configuração do anel para escolher um.',
        ),
        (
          RingSyncStage.partial,
          'Some ring data could not be read. Available records were saved; try syncing again.',
          'Não foi possível ler todos os dados do anel. Os registos disponíveis foram guardados; tente sincronizar novamente.',
        ),
      ]) {
        await _pumpCard(
          tester,
          _state(entry.$1, active: false, error: entry.$2),
          locale: const Locale('pt'),
        );
        await tester.pumpAndSettle();
        expect(find.text(entry.$3), findsOneWidget);
        expect(find.text(entry.$2), findsNothing);
        expect(find.text('Tentar novamente'), findsOneWidget);
      }
      await _pumpCard(
        tester,
        _state(
          RingSyncStage.failed,
          active: false,
          error: 'Unknown internal detail',
        ),
        locale: const Locale('pt'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unknown internal detail'), findsNothing);
      expect(
        find.textContaining('As leituras já guardadas estão seguras'),
        findsOneWidget,
      );
    },
  );

  testWidgets('demo and untouched idle states do not show real sync feedback', (
    tester,
  ) async {
    await _pumpCard(tester, _state(RingSyncStage.activity), demo: true);
    expect(find.byKey(const Key('ring-sync-status')), findsNothing);
    await _pumpCard(tester, const RingPairingState());
    expect(find.byKey(const Key('ring-sync-status')), findsNothing);
  });

  testWidgets(
    'reduced motion uses a static icon and narrow large text never overflows',
    (tester) async {
      _phone(tester, width: 320);
      for (final stage in [
        RingSyncStage.activity,
        RingSyncStage.sleep,
        RingSyncStage.partial,
        RingSyncStage.failed,
      ]) {
        await _pumpCard(
          tester,
          _state(
            stage,
            active: ![
              RingSyncStage.partial,
              RingSyncStage.failed,
            ].contains(stage),
            waiting: stage == RingSyncStage.sleep ? 40 : 0,
          ),
          scale: 2,
          reducedMotion: true,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'first sync is visible on Today without a contradictory connect action',
    (tester) async {
      _phone(tester);
      final controller = await _pumpScreen(
        tester,
        _state(RingSyncStage.finding),
      );
      expect(find.text('Finding your ring'), findsOneWidget);
      expect(
        find.text('Your first readings are on their way.'),
        findsOneWidget,
      );
      expect(find.text('Connect your ring'), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const Key('ring-sync-status'))).dy,
        lessThan(160),
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('today-quick-sync')))
            .onPressed,
        isNull,
      );
      controller.setPairing(
        _state(RingSyncStage.completed, active: false, records: 0),
      );
      await tester.pump();
      expect(find.text('No readings yet.'), findsOneWidget);
      expect(find.text('Connect your ring'), findsNothing);
    },
  );

  testWidgets(
    'Today stalled header stops spinning and help navigation preserves feedback',
    (tester) async {
      _phone(tester, width: 320);
      await _pumpScreen(
        tester,
        _state(RingSyncStage.sleep, waiting: 40),
        scale: 2,
      );
      expect(find.text('Waiting'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const Key('ring-sync-status-help')),
      );
      await tester.tap(find.byKey(const Key('ring-sync-status-help')));
      await tester.pumpAndSettle();
      expect(find.text('Sync help destination'), findsOneWidget);
    },
  );

  testWidgets(
    'ring settings and first setup both show the same stage feedback',
    (tester) async {
      _phone(tester);
      for (final route in ['/you/ring', '/pairing/found']) {
        await _pumpScreen(tester, _state(RingSyncStage.saving), route: route);
        expect(find.text('Saving on your phone'), findsOneWidget);
        expect(find.byKey(const Key('ring-sync-retry')), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final stalled in [false, true]) {
    testWidgets('Today ${stalled ? 'stalled' : 'syncing'} matches its golden', (
      tester,
    ) async {
      _phone(tester);
      await _pumpScreen(
        tester,
        _state(
          RingSyncStage.activity,
          elapsed: stalled ? 91 : 12,
          waiting: stalled ? 31 : 0,
        ),
        withHistory: true,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/today_${stalled ? 'sync_stalled' : 'syncing'}.png',
        ),
      );
    }, skip: !Platform.isMacOS);
  }
}

void _phone(WidgetTester tester, {double width = 390}) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpCard(
  WidgetTester tester,
  RingPairingState pairing, {
  bool demo = false,
  bool reducedMotion = false,
  double scale = 1,
  VoidCallback? onRetry,
  VoidCallback? onHelp,
  Locale? locale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('pt')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildLibreRingTheme(),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reducedMotion,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: RingSyncStatusCard(
              pairing: pairing,
              demo: demo,
              onRetry: onRetry ?? () {},
              onHelp: onHelp ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<_ControlledPairing> _pumpScreen(
  WidgetTester tester,
  RingPairingState initial, {
  String route = '/today',
  double scale = 1,
  bool withHistory = false,
}) async {
  final controller = _ControlledPairing(initial);
  final container = ProviderContainer(
    overrides: [
      isDemoModeProvider.overrideWithValue(false),
      currentLocalTimeProvider.overrideWithValue(_now),
      ringPairingProvider.overrideWith(() => controller),
      ringPairingClientProvider.overrideWithValue(_UnusedClient()),
      ringDataRepositoryProvider.overrideWithValue(
        _Repository(withHistory ? exampleRingHistory(_now) : null),
      ),
    ],
  );
  final router = GoRouter(
    initialLocation: route,
    routes: [
      GoRoute(
        path: '/today',
        builder: (context, state) => const RefinedTodayScreen(),
      ),
      GoRoute(
        path: '/you/ring',
        builder: (context, state) => const RingDeviceScreen(),
      ),
      GoRoute(
        path: '/pairing/found',
        builder: (context, state) => const RingFoundScreen(),
      ),
      GoRoute(
        path: '/you/ring/sync-issue',
        builder: (context, state) =>
            const Scaffold(body: Text('Sync help destination')),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        key: UniqueKey(),
        debugShowCheckedModeBanner: false,
        theme: buildLibreRingTheme(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  return controller;
}

class _ControlledPairing extends RingPairingController {
  _ControlledPairing(this.initial);
  final RingPairingState initial;
  @override
  RingPairingState build() => initial;
  void setPairing(RingPairingState value) => state = value;
}

class _UnusedClient implements RingPairingClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('No hardware calls expected in a presentation test.');
}

class _Repository implements RingDataRepository {
  _Repository(this.data);
  RingSyncDataset? data;
  @override
  Future<RingSyncDataset?> read() async => data;
  @override
  Future<RingSyncDataset> merge(RingSyncDataset incoming) async =>
      data = incoming;
  @override
  Future<void> deleteAll() async => data = null;
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
