import 'dart:io';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librering_mobile/src/daily_guidance.dart';
import 'package:librering_mobile/src/ui/daily_guidance_card.dart';
import 'package:ring_design_system/ring_design_system.dart';

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

  for (final locale in <Locale>[const Locale('en'), const Locale('pt', 'PT')]) {
    final portuguese = locale.languageCode == 'pt';
    for (final example in _examples) {
      testWidgets('${example.kind.name} copy is complete in $locale', (
        tester,
      ) async {
        await _pumpCard(tester, kind: example.kind, locale: locale);
        expect(
          find.text(portuguese ? example.ptTitle : example.enTitle),
          findsOneWidget,
        );
        expect(
          find.text(portuguese ? example.ptAction : example.enAction),
          findsOneWidget,
        );
        expect(
          find.text(portuguese ? 'UMA PEQUENA SUGESTÃO' : 'A LITTLE GUIDANCE'),
          findsOneWidget,
        );
        final reason = tester.widget<Text>(
          find.byKey(const Key('daily-guidance-reason')),
        );
        expect(reason.data, isNotEmpty);
        expect(reason.data, isNot(contains('null')));
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        '${example.kind.name} reflows at 320px and 2x text in $locale',
        (tester) async {
          await _pumpCard(
            tester,
            kind: example.kind,
            locale: locale,
            size: const Size(320, 568),
            textScale: 2,
          );
          expect(tester.takeException(), isNull);
          for (final key in <String>[
            'daily-guidance-title',
            'daily-guidance-reason',
            'daily-guidance-action',
            'daily-guidance-why',
          ]) {
            final element = find.byKey(Key(key));
            await tester.ensureVisible(element);
            await tester.pumpAndSettle();
            final rect = tester.getRect(element);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(320));
            expect(tester.takeException(), isNull);
          }
          await tester.tap(find.byKey(const Key('daily-guidance-why')));
          await tester.pumpAndSettle();
          expect(
            find.text(
              portuguese ? 'Porquê esta sugestão?' : 'Why this suggestion?',
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await _closeGuide(tester, portuguese ? 'Entendido' : 'Got it');
          expect(find.byType(BottomSheet), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('pause guide is optional, safe, and dismissible in $locale', (
      tester,
    ) async {
      await _pumpCard(tester, kind: DailyGuidanceKind.pause, locale: locale);
      await tester.tap(find.byKey(const Key('daily-guidance-action')));
      await tester.pumpAndSettle();
      expect(
        find.text(portuguese ? 'Uma pausa tranquila' : 'A gentle pause'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          portuguese
              ? 'Não force respirações profundas nem prenda a respiração.'
              : 'Do not force deep breaths or hold your breath.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          portuguese
              ? 'Pare se sentir desconforto ou tonturas.'
              : 'Stop if you feel uncomfortable or dizzy.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          portuguese
              ? 'Sem objetivos a cumprir nem nada a registar.'
              : 'Nothing to achieve, and nothing to log.',
        ),
        findsOneWidget,
      );
      await _closeGuide(tester, portuguese ? 'Concluído' : 'Done');
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(const Key('daily-guidance-card')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('why sheet explains evidence and exclusions in $locale', (
      tester,
    ) async {
      await _pumpCard(tester, kind: DailyGuidanceKind.walk, locale: locale);
      final reason = tester
          .widget<Text>(find.byKey(const Key('daily-guidance-reason')))
          .data!;
      await tester.tap(find.byKey(const Key('daily-guidance-why')));
      await tester.pumpAndSettle();
      final body = find.textContaining(
        portuguese
            ? 'Uma sugestão, não uma instrução'
            : 'A suggestion, not an instruction',
      );
      expect(body, findsOneWidget);
      final explanation = tester.widget<Text>(body).data!;
      expect(explanation, startsWith(reason));
      expect(
        explanation,
        contains(
          portuguese
              ? 'Lacunas não são inatividade'
              : 'Gaps are not inactivity',
        ),
      );
      expect(
        explanation,
        contains(
          portuguese
              ? 'sem serviço de IA, conta ou envio de dados'
              : 'with no AI service, account or upload',
        ),
      );
      expect(
        explanation,
        contains(
          portuguese
              ? 'índices de HRV ou stress não verificados'
              : 'unverified HRV or stress indexes',
        ),
      );
      await _closeGuide(tester, portuguese ? 'Entendido' : 'Got it');
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'guidance controls are labelled 48px touch targets in $locale',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _pumpCard(tester, kind: DailyGuidanceKind.walk, locale: locale);
          for (final control in <(String, String)>[
            (
              'daily-guidance-action',
              portuguese ? 'Ver atividade' : 'View activity',
            ),
            ('daily-guidance-why', portuguese ? 'Porquê?' : 'Why this?'),
          ]) {
            final button = find.byKey(Key(control.$1));
            final data = tester.getSemantics(button).getSemanticsData();
            expect(data.label, contains(control.$2));
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.hasAction(SemanticsAction.tap), isTrue);
            final size = tester.getSize(button);
            expect(size.height, greaterThanOrEqualTo(48));
            expect(size.width, greaterThanOrEqualTo(48));
          }
          expect(
            tester
                .getSemantics(find.byKey(const Key('daily-guidance-title')))
                .getSemanticsData()
                .flagsCollection
                .isHeader,
            isTrue,
          );
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('demo guidance is explicitly example-only in $locale', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        kind: DailyGuidanceKind.walk,
        locale: locale,
        demo: true,
      );
      expect(
        find.text(portuguese ? 'EXEMPLO DE SUGESTÃO' : 'EXAMPLE GUIDANCE'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('daily-guidance-why')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          portuguese
              ? 'Apenas dados de exemplo—não são conselhos pessoais.'
              : 'Example data only—not personal advice.',
        ),
        findsOneWidget,
      );
      await _closeGuide(tester, portuguese ? 'Entendido' : 'Got it');
    });
  }

  for (final destination in <(DailyGuidanceKind, String)>[
    (DailyGuidanceKind.checkIn, '/journal/check-in'),
    (DailyGuidanceKind.takeItEasy, '/journal'),
    (DailyGuidanceKind.windDown, '/sleep'),
    (DailyGuidanceKind.walk, '/activity'),
    (DailyGuidanceKind.goalReached, '/activity'),
  ]) {
    testWidgets('${destination.$1.name} action opens ${destination.$2}', (
      tester,
    ) async {
      await _pumpCard(tester, kind: destination.$1);
      await tester.tap(find.byKey(const Key('daily-guidance-action')));
      await tester.pumpAndSettle();
      expect(find.text('Destination: ${destination.$2}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final guide in <(String, String, String)>[
    ('daily-guidance-action', 'A gentle pause', 'Done'),
    ('daily-guidance-why', 'Why this suggestion?', 'Got it'),
  ]) {
    testWidgets('${guide.$2} respects reduced motion', (tester) async {
      await _pumpCard(
        tester,
        kind: DailyGuidanceKind.pause,
        disableAnimations: true,
      );
      await tester.tap(find.byKey(Key(guide.$1)));
      await tester.pump();
      final route = ModalRoute.of(tester.element(find.text(guide.$2)))!;
      expect(route.animation!.status, AnimationStatus.completed);
      await _closeGuide(tester, guide.$3);
      expect(tester.takeException(), isNull);
    });
  }

  for (final kind in <DailyGuidanceKind>[
    DailyGuidanceKind.walk,
    DailyGuidanceKind.pause,
  ]) {
    testWidgets('${kind.name} guidance matches golden', (tester) async {
      await _pumpCard(tester, kind: kind);
      await expectLater(
        find.byKey(const Key('daily-guidance-card')),
        matchesGoldenFile('goldens/daily_guidance_${kind.name}.png'),
      );
    }, skip: !Platform.isMacOS);
  }
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required DailyGuidanceKind kind,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1,
  bool demo = false,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: DailyGuidanceCard(
                demo: demo,
                guidance: DailyGuidance(
                  kind: kind,
                  stepGoal: 5000,
                  sleepTargetMinutes: 480,
                  recordedSteps: kind == DailyGuidanceKind.goalReached
                      ? 6124
                      : 2180,
                  sleepMinutes: 360,
                ),
              ),
            ),
          ),
        ),
      ),
      for (final route in <String>[
        '/activity',
        '/sleep',
        '/journal/check-in',
        '/journal',
      ])
        GoRoute(
          path: route,
          builder: (context, state) =>
              Scaffold(body: Center(child: Text('Destination: $route'))),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: buildLibreRingTheme(),
      locale: locale,
      supportedLocales: const <Locale>[Locale('en'), Locale('pt', 'PT')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _closeGuide(WidgetTester tester, String label) async {
  final close = find.widgetWithText(LibreRingPrimaryButton, label);
  await tester.ensureVisible(close);
  await tester.pumpAndSettle();
  await tester.tap(close);
  await tester.pumpAndSettle();
}

const _examples =
    <
      ({
        DailyGuidanceKind kind,
        String enTitle,
        String ptTitle,
        String enAction,
        String ptAction,
      })
    >[
      (
        kind: DailyGuidanceKind.checkIn,
        enTitle: 'Start with how you feel.',
        ptTitle: 'Comece pelo que sente.',
        enAction: 'Check in',
        ptAction: 'Fazer registo',
      ),
      (
        kind: DailyGuidanceKind.takeItEasy,
        enTitle: 'Give yourself some space.',
        ptTitle: 'Dê algum espaço a si.',
        enAction: 'View journal',
        ptAction: 'Ver diário',
      ),
      (
        kind: DailyGuidanceKind.pause,
        enTitle: 'A moment to yourself.',
        ptTitle: 'Um momento para si.',
        enAction: 'Take a moment',
        ptAction: 'Fazer uma pausa',
      ),
      (
        kind: DailyGuidanceKind.windDown,
        enTitle: 'Make space to wind down.',
        ptTitle: 'Reserve tempo para abrandar.',
        enAction: 'View sleep',
        ptAction: 'Ver sono',
      ),
      (
        kind: DailyGuidanceKind.walk,
        enTitle: 'A little room for a walk.',
        ptTitle: 'Um momento para caminhar.',
        enAction: 'View activity',
        ptAction: 'Ver atividade',
      ),
      (
        kind: DailyGuidanceKind.goalReached,
        enTitle: 'Your step goal is covered.',
        ptTitle: 'Objetivo de passos cumprido.',
        enAction: 'View activity',
        ptAction: 'Ver atividade',
      ),
    ];

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
