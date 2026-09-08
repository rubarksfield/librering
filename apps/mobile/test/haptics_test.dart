import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librering_mobile/src/ui/app_chrome.dart';
import 'package:librering_mobile/src/ui/haptics.dart';
import 'package:ring_design_system/ring_design_system.dart'
    show LibreRingPrimaryButton, buildLibreRingTheme;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final effects = <String>[];

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

  test('semantic effects use single restrained native haptics', () async {
    await RingHaptics.selection();
    await RingHaptics.action();
    await RingHaptics.success();
    await RingHaptics.error();
    expect(effects, <String>[
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
  });

  test('disabled effects never contact the haptic channel', () async {
    await RingHaptics.selection(enabled: false);
    await RingHaptics.action(enabled: false);
    await RingHaptics.success(enabled: false);
    await RingHaptics.error(enabled: false);
    expect(effects, isEmpty);
  });

  test('unavailable or failing native haptics do not fail an action', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (_) async {
      throw MissingPluginException('No haptic device');
    });
    await expectLater(RingHaptics.action(), completes);
    messenger.setMockMethodCallHandler(SystemChannels.platform, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    await expectLater(RingHaptics.selection(), completes);
  });

  test(
    'chart ticks deduplicate and discard rapid changes without a queue',
    () async {
      var time = Duration.zero;
      final feedback = RingSelectionHaptics(elapsed: () => time);
      await feedback.selection('08:00');
      await feedback.selection('08:00');
      time = const Duration(milliseconds: 90);
      await feedback.selection('09:00');
      expect(effects, hasLength(1));
      time = const Duration(milliseconds: 110);
      await feedback.selection('09:00');
      expect(
        effects,
        hasLength(1),
        reason: 'No delayed tick for a skipped point',
      );
      await feedback.selection('10:00');
      expect(effects, hasLength(2));
      time = const Duration(seconds: 10);
      await feedback.selection('10:00');
      expect(effects, hasLength(2), reason: 'A held point is silent');
      feedback.reset();
      await feedback.selection('10:00');
      expect(effects, hasLength(3));
      feedback.reset();
      await feedback.selection('11:00');
      expect(
        effects,
        hasLength(3),
        reason: 'Reset does not bypass rate limiting',
      );
    },
  );

  test(
    'disabled chart feedback does not consume an enabled selection',
    () async {
      final feedback = RingSelectionHaptics();
      await feedback.selection(1, enabled: false);
      expect(effects, isEmpty);
      await feedback.selection(1);
      expect(effects, <String>['HapticFeedbackType.selectionClick']);
    },
  );

  testWidgets(
    'primary action gives one haptic; rebuild and scrolling are quiet',
    (tester) async {
      var activations = 0;
      await tester.pumpWidget(
        _host(
          ListView(
            children: [
              LibreRingPrimaryButton(
                label: 'Save',
                onPressed: () => activations++,
              ),
              const SizedBox(height: 1500),
            ],
          ),
        ),
      );
      expect(effects, isEmpty);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(activations, 1);
      expect(effects, <String>['HapticFeedbackType.lightImpact']);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style!.enableFeedback, isFalse);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(effects, hasLength(1));
    },
  );

  testWidgets(
    'disabled and explicitly silent primary controls do not vibrate',
    (tester) async {
      var activations = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const LibreRingPrimaryButton(label: 'Disabled', onPressed: null),
              LibreRingPrimaryButton(
                label: 'Silent',
                hapticsEnabled: false,
                onPressed: () => activations++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Disabled'));
      await tester.tap(find.text('Silent'));
      await tester.pumpAndSettle();
      expect(activations, 1);
      expect(effects, isEmpty);
    },
  );

  testWidgets('calendar haptics acknowledge changes, not disabled bounds', (
    tester,
  ) async {
    final changes = <DateTime>[];
    await tester.pumpWidget(
      _host(
        RingDaySelector(
          selectedDay: DateTime(2026, 9, 7),
          earliestDay: DateTime(2026, 9, 6),
          latestDay: DateTime(2026, 9, 7),
          onChanged: changes.add,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('next-day')));
    await tester.pumpAndSettle();
    expect(effects, isEmpty);
    expect(changes, isEmpty);
    await tester.tap(find.byKey(const Key('previous-day')));
    await tester.pumpAndSettle();
    expect(changes, <DateTime>[DateTime(2026, 9, 6)]);
    expect(effects, <String>['HapticFeedbackType.selectionClick']);
  });

  testWidgets('confirming the same calendar day adds no selection effect', (
    tester,
  ) async {
    final changes = <DateTime>[];
    await tester.pumpWidget(
      _host(
        RingDaySelector(
          selectedDay: DateTime(2026, 9, 7),
          earliestDay: DateTime(2026, 9, 6),
          latestDay: DateTime(2026, 9, 7),
          onChanged: changes.add,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('select-day')));
    await tester.pumpAndSettle();
    expect(effects, <String>['HapticFeedbackType.lightImpact']);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(effects, hasLength(1));
  });

  testWidgets('navigation emits once only when changing destination', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/today',
      routes: [
        for (final path in ['/today', '/vitals'])
          GoRoute(
            path: path,
            builder: (context, state) =>
                RingPageScaffold(activePath: path, children: [Text(path)]),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: buildLibreRingTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-today')));
    await tester.pumpAndSettle();
    expect(effects, isEmpty);
    await tester.tap(find.byKey(const Key('tab-vitals')));
    await tester.pumpAndSettle();
    expect(find.text('/vitals'), findsOneWidget);
    expect(effects, <String>['HapticFeedbackType.selectionClick']);
    await tester.tap(find.byKey(const Key('tab-vitals')));
    await tester.pumpAndSettle();
    expect(effects, hasLength(1));
  });

  testWidgets('section action emits only for its enabled callback', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            RingSectionHeader(
              title: 'Activity',
              action: 'Details',
              onAction: () => activations++,
            ),
            const RingSectionHeader(title: 'Sleep', action: 'Unavailable'),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Unavailable'));
    await tester.pumpAndSettle();
    expect(effects, isEmpty);
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(activations, 1);
    expect(effects, <String>['HapticFeedbackType.lightImpact']);
  });

  testWidgets('information sheet opening and closing each emit once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showRingInfo(
              context,
              title: 'A helpful explanation',
              body: 'Details about your ring.',
            ),
            child: const Text('Explain'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Explain'));
    await tester.pumpAndSettle();
    expect(effects, <String>['HapticFeedbackType.lightImpact']);
    await tester.pump(const Duration(seconds: 30));
    expect(effects, hasLength(1));
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(effects, <String>[
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.lightImpact',
    ]);
  });
}

Widget _host(Widget child) => MaterialApp(
  theme: buildLibreRingTheme(),
  home: Scaffold(body: child),
);
