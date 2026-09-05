import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ring_demo/ring_demo.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

import 'src/app_state.dart';
import 'src/analytics_screens.dart';
import 'src/ble/r12_pairing_client.dart';
import 'src/product_system_screens.dart';
import 'src/screens.dart';
import 'src/storage/data_export_service.dart';
import 'src/storage/journal_repository.dart';
import 'src/storage/ring_data_repository.dart';
import 'src/storage/preferences_repository.dart';
import 'src/dashboard_screens.dart';

Future<String> resolveInitialLocation({
  required bool demoMode,
  required bool captureMode,
  RingDataRepository? ringDataRepository,
}) async {
  if (captureMode) return '/pairing/scan';
  if (demoMode || ringDataRepository == null) return '/welcome';
  try {
    return await ringDataRepository.read() == null ? '/welcome' : '/today';
  } catch (_) {
    // Returning users should see the honest unavailable state rather than be
    // sent through onboarding because their local store needs attention.
    return '/today';
  }
}

class LibreRingApp extends StatelessWidget {
  const LibreRingApp({
    this.demoMode = false,
    this.captureMode = false,
    this.initialLocation = '/welcome',
    this.locale,
    this.pairingClient,
    this.ringDataRepository,
    this.journalRepository,
    this.dataExportService,
    this.currentLocalTime,
    this.preferencesRepository,
    super.key,
  });

  final bool demoMode;
  final bool captureMode;
  final String initialLocation;
  final Locale? locale;
  final RingPairingClient? pairingClient;
  final RingDataRepository? ringDataRepository;
  final JournalRepository? journalRepository;
  final DataExportService? dataExportService;
  final DateTime? currentLocalTime;
  final PreferencesRepository? preferencesRepository;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        isDemoModeProvider.overrideWithValue(demoMode),
        isProtocolCaptureModeProvider.overrideWithValue(captureMode),
        if (currentLocalTime != null)
          currentLocalTimeProvider.overrideWithValue(currentLocalTime!),
        if (demoMode)
          dailySnapshotProvider.overrideWithValue(demoDailySnapshot),
        if (pairingClient != null)
          ringPairingClientProvider.overrideWithValue(pairingClient),
        if (ringDataRepository != null)
          ringDataRepositoryProvider.overrideWithValue(ringDataRepository),
        if (journalRepository != null)
          journalRepositoryProvider.overrideWithValue(journalRepository),
        if (dataExportService != null)
          dataExportServiceProvider.overrideWithValue(dataExportService),
        if (preferencesRepository != null)
          preferencesRepositoryProvider.overrideWithValue(
            preferencesRepository,
          ),
      ],
      child: _LibreRingShell(initialLocation: initialLocation, locale: locale),
    );
  }
}

class _LibreRingShell extends StatefulWidget {
  const _LibreRingShell({required this.initialLocation, this.locale});

  final String initialLocation;
  final Locale? locale;

  @override
  State<_LibreRingShell> createState() => _LibreRingShellState();
}

class _LibreRingShellState extends State<_LibreRingShell> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    routes: <RouteBase>[
      _route('/welcome', const WelcomeScreen()),
      _route('/privacy', const PrivacyPromiseScreen()),
      _route('/pairing/scan', const RingScanScreen()),
      _route('/pairing/found', const RingFoundScreen()),
      _route('/onboarding', const ProductOnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => shell,
        branches: [
          StatefulShellBranch(
            routes: [_route('/today', const RefinedTodayScreen())],
          ),
          StatefulShellBranch(
            routes: [_route('/vitals', const RefinedVitalsScreen())],
          ),
          StatefulShellBranch(
            routes: [_route('/trends', const RefinedTrendsScreen())],
          ),
          StatefulShellBranch(routes: [_route('/you', const YouScreen())]),
        ],
      ),
      GoRoute(path: '/metrics', redirect: (context, state) => '/vitals'),
      _route('/sleep', const SleepLabScreen()),
      _route('/recovery', const RecoveryScreen()),
      _route('/movement', const ActivityLabScreen()),
      _route('/activity', const ActivityLabScreen()),
      _route('/day-timeline', const ProductDayTimelineScreen()),
      _route('/activity/detail', const ActivityDetailScreen()),
      _route('/activity/suggestion', const ActivitySuggestionScreen()),
      _route('/activity/sports', const ActivitySportsScreen()),
      _routeBuilder(
        '/activity/log',
        (state) => ActivityLogScreen(
          activityName: state.uri.queryParameters['name'] ?? 'Activity',
        ),
      ),
      _route('/heart', const HeartLabScreen()),
      _route('/vitals/heart', const HeartLabScreen()),
      _route('/vitals/rhr', const RestingPulseBoundaryScreen()),
      _route('/oxygen', const OxygenLabScreen()),
      _route('/vitals/oxygen', const OxygenLabScreen()),
      _route('/vitals/temperature', const TemperatureUnavailableScreen()),
      _route('/vitals/recovery', const RecoveryScreen()),
      _route(
        '/signals/hrv-index',
        const VendorSignalScreen(kind: RingVendorIndexKind.firmwareHrv),
      ),
      _route(
        '/vitals/hrv',
        const VendorSignalScreen(kind: RingVendorIndexKind.firmwareHrv),
      ),
      _route(
        '/signals/stress-index',
        const VendorSignalScreen(kind: RingVendorIndexKind.stress),
      ),
      _route('/sport', const SportRecordScreen()),
      _route('/sleep/evidence', const EvidenceScreen()),
      _route('/no-result', const NoResultScreen()),
      _route('/journal', const JournalScreen()),
      _route('/journal/check-in', const CheckInScreen()),
      _route('/journal/swim', const SwimEntryScreen()),
      _route('/you/profile', const ProfilePreferencesScreen()),
      _route('/you/ring', const RingDeviceScreen()),
      _route('/you/ring/sync-issue', const SyncIssueScreen()),
      _route('/you/ring/capabilities', const CapabilitiesScreen()),
      _route('/you/data', const DataHubScreen()),
      _route('/you/about', const AboutScreen()),
      _route('/privacy/cycle', const CyclePrivacyScreen()),
    ],
  );

  GoRoute _route(String path, Widget child) => GoRoute(
    path: path,
    pageBuilder: (BuildContext context, GoRouterState state) =>
        _page(context, state, child),
  );

  GoRoute _routeBuilder(
    String path,
    Widget Function(GoRouterState state) builder,
  ) => GoRoute(
    path: path,
    pageBuilder: (BuildContext context, GoRouterState state) {
      return _page(context, state, builder(state));
    },
  );

  Page<void> _page(BuildContext context, GoRouterState state, Widget child) {
    // Root destinations retain independent navigation/scroll state. Detail
    // pages use platform transitions, including the native iOS back gesture.
    if (const [
      '/today',
      '/vitals',
      '/trends',
      '/you',
    ].contains(state.uri.path)) {
      return NoTransitionPage<void>(key: state.pageKey, child: child);
    }
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduceMotion) {
      return MaterialPage<void>(key: state.pageKey, child: child);
    }
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: reduceMotion
          ? Duration.zero
          : LibreRingTokens.standard,
      reverseTransitionDuration: reduceMotion
          ? Duration.zero
          : LibreRingTokens.fast,
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondary,
            Widget child,
          ) {
            if (reduceMotion) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: LibreRingTokens.curve,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(.025, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LibreRing',
      debugShowCheckedModeBanner: false,
      theme: buildLibreRingTheme(),
      routerConfig: _router,
      locale: widget.locale,
      supportedLocales: const <Locale>[Locale('en'), Locale('pt', 'PT')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
