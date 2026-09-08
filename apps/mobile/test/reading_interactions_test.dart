import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/app.dart';
import 'package:librering_mobile/src/analytics_screens.dart' as analytics;
import 'package:librering_mobile/src/storage/preferences_repository.dart';
import 'package:ring_design_system/ring_design_system.dart';

final _now = DateTime(2026, 9, 7, 18);

void main() {
  final effects = <String>[];
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    effects.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            effects.add(call.arguments as String);
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final portuguese in [false, true]) {
    testWidgets(
      'live pulse help is honest, scrollable and localized ($portuguese)',
      (tester) async {
        phone(tester);
        await tester.pumpWidget(
          LibreRingApp(
            demoMode: true,
            initialLocation: '/heart',
            currentLocalTime: _now,
            locale: Locale(portuguese ? 'pt' : 'en'),
          ),
        );
        await tester.pumpAndSettle();
        final help = find.byKey(const Key('live-pulse-help'));
        await tester.ensureVisible(help);
        await tester.tap(help);
        await tester.pumpAndSettle();
        expect(
          find.text(portuguese ? 'Pulsação em direto' : 'Live pulse'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            portuguese
                ? 'sem um valor utilizável'
                : 'without a usable pulse value',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(portuguese ? 'parar ou cancelar' : 'stop/cancel'),
          findsOneWidget,
        );
        expect(effects, ['HapticFeedbackType.lightImpact']);
        final close = find.widgetWithText(
          LibreRingPrimaryButton,
          portuguese ? 'Entendido' : 'Got it',
        );
        await tester.ensureVisible(close);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(
          find.text(portuguese ? 'Pulsação em direto' : 'Live pulse'),
          findsNothing,
        );
        expect(find.text('Start measurement'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'pulse chart ticks once for a selected sample, not rebuilds or repeated taps',
    (tester) async {
      phone(tester);
      final start = DateTime(2026, 9, 7);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: analytics.RingHistoryChart(
                points: [
                  analytics.RingChartPoint(
                    at: start.add(const Duration(hours: 6)),
                    value: 62,
                  ),
                  analytics.RingChartPoint(
                    at: start.add(const Duration(hours: 18)),
                    value: 74,
                  ),
                ],
                start: start,
                end: start.add(const Duration(days: 1)),
                unit: 'bpm',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(effects, isEmpty);
      final chart = find
          .descendant(
            of: find.byType(analytics.RingHistoryChart),
            matching: find.byType(GestureDetector),
          )
          .first;
      await tester.tapAt(tester.getCenter(chart));
      await tester.pumpAndSettle();
      expect(effects, ['HapticFeedbackType.selectionClick']);
      for (var i = 0; i < 5; i++) {
        await tester.tapAt(tester.getCenter(chart));
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 2));
      expect(effects, ['HapticFeedbackType.selectionClick']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sleep scrubbing inside one interval does not buzz continuously', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      LibreRingApp(
        demoMode: true,
        initialLocation: '/sleep',
        currentLocalTime: _now,
      ),
    );
    await tester.pumpAndSettle();
    final target = find.byKey(const Key('sleep-timeline-touch-target'));
    await tester.ensureVisible(target);
    final rect = tester.getRect(target);
    expect(effects, isEmpty);
    // Tiny movements inside the same first stage still inspect distinct times.
    for (final fraction in [.002, .003, .004, .005]) {
      await tester.tapAt(
        Offset(rect.left + rect.width * fraction, rect.center.dy),
      );
      await tester.pump();
    }
    expect(effects, ['HapticFeedbackType.selectionClick']);
    await tester.pump(const Duration(seconds: 2));
    expect(effects.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dashboard navigation gives one cue; selected trend chip is quiet',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(
        LibreRingApp(
          demoMode: true,
          initialLocation: '/today',
          currentLocalTime: _now,
        ),
      );
      await tester.pumpAndSettle();
      expect(effects, isEmpty);
      await tester.ensureVisible(find.byKey(const Key('daily-signal')));
      await tester.tap(find.byKey(const Key('daily-signal')));
      await tester.pumpAndSettle();
      expect(effects, ['HapticFeedbackType.selectionClick']);
      await tester.tap(find.byKey(const Key('tab-trends')));
      await tester.pumpAndSettle();
      effects.clear();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Sleep'));
      await tester.pumpAndSettle();
      expect(effects, isEmpty);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Steps'));
      await tester.pumpAndSettle();
      expect(effects, ['HapticFeedbackType.selectionClick']);
    },
  );

  for (final fail in [false, true]) {
    testWidgets(
      'preferences haptic reflects actual save result (failure $fail)',
      (tester) async {
        phone(tester);
        final repository = _Preferences();
        await tester.pumpWidget(
          LibreRingApp(
            initialLocation: '/you/profile',
            currentLocalTime: _now,
            preferencesRepository: repository,
          ),
        );
        await tester.pumpAndSettle();
        final save = find.byKey(const Key('save-preferences'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pump();
        expect(repository.writes, 1);
        expect(
          effects,
          isEmpty,
          reason: 'Do not acknowledge persistence before it succeeds.',
        );
        // Saving is disabled, including its tactile feedback.
        expect(tester.widget<LibreRingPrimaryButton>(save).onPressed, isNull);
        if (fail) {
          repository.gate.completeError(StateError('Synthetic save failure'));
        } else {
          repository.gate.complete();
        }
        await tester.pumpAndSettle();
        expect(effects, [
          fail
              ? 'HapticFeedbackType.mediumImpact'
              : 'HapticFeedbackType.lightImpact',
        ]);
        expect(
          find.text(
            fail
                ? 'Could not save. Your changes are still here; try again.'
                : 'Saved on this phone',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Preferences implements PreferencesRepository {
  final gate = Completer<void>();
  int writes = 0;
  @override
  Future<AppPreferences> read() async => const AppPreferences();
  @override
  Future<void> save(AppPreferences preferences) async {
    writes++;
    await gate.future;
  }
}
