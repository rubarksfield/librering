import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ring_demo/ring_demo.dart';
import 'package:ring_design_system/ring_design_system.dart';

import 'src/app_state.dart';
import 'src/ble/r12_pairing_client.dart';
import 'src/screens.dart';
import 'src/storage/ring_data_repository.dart';

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
    super.key,
  });

  final bool demoMode;
  final bool captureMode;
  final String initialLocation;
  final Locale? locale;
  final RingPairingClient? pairingClient;
  final RingDataRepository? ringDataRepository;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        isDemoModeProvider.overrideWithValue(demoMode),
        isProtocolCaptureModeProvider.overrideWithValue(captureMode),
        if (demoMode)
          dailySnapshotProvider.overrideWithValue(demoDailySnapshot),
        if (pairingClient != null)
          ringPairingClientProvider.overrideWithValue(pairingClient),
        if (ringDataRepository != null)
          ringDataRepositoryProvider.overrideWithValue(ringDataRepository),
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
      _route('/today', const TodayScreen()),
      _route('/metrics', const MetricsScreen()),
      _route('/sleep', const SleepScreen()),
      _route('/sleep/evidence', const EvidenceScreen()),
      _route('/no-result', const NoResultScreen()),
      _route('/trends', const TrendsScreen()),
      _route('/journal/swim', const SwimEntryScreen()),
      _route('/privacy/cycle', const CyclePrivacyScreen()),
    ],
  );

  GoRoute _route(String path, Widget child) => GoRoute(
    path: path,
    pageBuilder: (BuildContext context, GoRouterState state) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
    },
  );

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
