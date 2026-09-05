import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ring_design_system/ring_design_system.dart';

import '../daily_guidance.dart';
import '../localized_copy.dart';
import 'app_chrome.dart';

/// One optional, explainable nudge. This is not a recovery or readiness score.
class DailyGuidanceCard extends StatelessWidget {
  const DailyGuidanceCard({
    required this.guidance,
    this.demo = false,
    super.key,
  });

  final DailyGuidance guidance;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    String copy(String en, String pt) => copyFor(context, en, pt);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    String duration(int? minutes) =>
        '${(minutes ?? 0) ~/ 60}h ${(minutes ?? 0) % 60}m';
    final (title, body, reason, icon, action) = switch (guidance.kind) {
      DailyGuidanceKind.walk => (
        copy('A little room for a walk.', 'Um momento para caminhar.'),
        copy(
          'If you feel up to it, try a short, comfortable walk. No need to chase the whole goal.',
          'Se lhe apetecer, faça uma caminhada curta, a um ritmo confortável. Não precisa de cumprir o objetivo todo.',
        ),
        copy(
          'Your ring has recorded ${number.format(guidance.recordedSteps)} of your ${number.format(guidance.stepGoal)}-step goal today.',
          'O anel registou ${number.format(guidance.recordedSteps)} passos dos ${number.format(guidance.stepGoal)} do seu objetivo de hoje.',
        ),
        Icons.directions_walk_rounded,
        copy('View activity', 'Ver atividade'),
      ),
      DailyGuidanceKind.windDown => (
        copy('Make space to wind down.', 'Reserve tempo para abrandar.'),
        copy(
          'Consider some quiet, unhurried time to unwind before your next sleep.',
          'Considere algum tempo tranquilo, sem pressa, para descontrair antes de voltar a dormir.',
        ),
        copy(
          'Recorded sleep ending today: ${duration(guidance.sleepMinutes)}, against your ${duration(guidance.sleepTargetMinutes)} target.',
          'Sono registado com fim hoje: ${duration(guidance.sleepMinutes)}, para um objetivo de ${duration(guidance.sleepTargetMinutes)}.',
        ),
        Icons.nights_stay_outlined,
        copy('View sleep', 'Ver sono'),
      ),
      DailyGuidanceKind.pause => (
        copy('A moment to yourself.', 'Um momento para si.'),
        copy(
          'A short pause might feel good. Settle somewhere comfortable and let your breathing find an easy rhythm.',
          'Uma pequena pausa pode saber bem. Instale-se num lugar confortável e deixe a respiração encontrar um ritmo tranquilo.',
        ),
        copy(
          'You logged stress or low energy today. This suggestion comes from your check-in, not the ring’s stress index.',
          'Registou stress ou pouca energia hoje. Esta sugestão baseia-se no seu registo, não no índice de stress do anel.',
        ),
        Icons.spa_outlined,
        copy('Take a moment', 'Fazer uma pausa'),
      ),
      DailyGuidanceKind.takeItEasy => (
        copy('Give yourself some space.', 'Dê algum espaço a si.'),
        copy(
          'You do not need to chase an activity goal today. Let how you feel guide your plans.',
          'Não precisa de perseguir um objetivo de atividade hoje. Oriente os seus planos pelo que sente.',
        ),
        copy(
          'You added an illness check-in today. LibreRing cannot assess illness or decide when exercise is safe.',
          'Registou doença hoje. O LibreRing não avalia doenças nem determina quando é seguro fazer exercício.',
        ),
        Icons.self_improvement_rounded,
        copy('View journal', 'Ver diário'),
      ),
      DailyGuidanceKind.goalReached => (
        copy('Your step goal is covered.', 'Objetivo de passos cumprido.'),
        copy(
          'Take a moment to appreciate it. There is no need to turn the number into a bigger target.',
          'Aprecie o que fez. Não é preciso transformar este número num objetivo maior.',
        ),
        copy(
          'Your ring has recorded ${number.format(guidance.recordedSteps)} steps toward your ${number.format(guidance.stepGoal)}-step goal today.',
          'O anel registou ${number.format(guidance.recordedSteps)} passos para o seu objetivo de ${number.format(guidance.stepGoal)} hoje.',
        ),
        Icons.check_circle_outline_rounded,
        copy('View activity', 'Ver atividade'),
      ),
      DailyGuidanceKind.checkIn => (
        copy('Start with how you feel.', 'Comece pelo que sente.'),
        copy(
          'A little energy, a busy mind, a slower day? Add a check-in to help Today meet you where you are.',
          'Com energia, a mente ocupada ou um dia mais lento? Faça um registo para dar contexto ao seu dia.',
        ),
        copy(
          'There is not enough context for a specific nudge right now. Missing readings are not a sign that you need to rest or exercise.',
          'Ainda não há contexto suficiente para uma sugestão específica. A falta de leituras não significa que precisa de descansar ou fazer exercício.',
        ),
        Icons.edit_note_rounded,
        copy('Check in', 'Fazer registo'),
      ),
    };

    return LibreRingCard(
      key: const Key('daily-guidance-card'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: LibreRingTokens.sage, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  demo
                      ? copy('EXAMPLE GUIDANCE', 'EXEMPLO DE SUGESTÃO')
                      : copy('A LITTLE GUIDANCE', 'UMA PEQUENA SUGESTÃO'),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: LibreRingTokens.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              title,
              key: const Key('daily-guidance-title'),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontSize: 26, height: 1.12),
            ),
          ),
          const SizedBox(height: 10),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: LibreRingTokens.sage, width: 2),
              ),
            ),
            child: Text(
              reason,
              key: const Key('daily-guidance-reason'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                key: const Key('daily-guidance-action'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () {
                  switch (guidance.kind) {
                    case DailyGuidanceKind.walk:
                    case DailyGuidanceKind.goalReached:
                      context.push('/activity');
                    case DailyGuidanceKind.windDown:
                      context.push('/sleep');
                    case DailyGuidanceKind.pause:
                      showRingInfo(
                        context,
                        title: copy('A gentle pause', 'Uma pausa tranquila'),
                        closeLabel: copy('Done', 'Concluído'),
                        body: copy(
                          'Find a comfortable place to sit or stand. Let your shoulders settle.\n\nBreathe gently, at a pace that feels natural. Do not force deep breaths or hold your breath. Stop if you feel uncomfortable or dizzy.\n\nTake a few quiet minutes if you like. Nothing to achieve, and nothing to log.\n\nGeneral wellbeing guidance, adapted from NHS “Breathing exercises for stress”. This is not treatment or an assessment of your stress.',
                          'Encontre um lugar confortável para se sentar ou ficar de pé. Relaxe os ombros.\n\nRespire suavemente, a um ritmo natural. Não force respirações profundas nem prenda a respiração. Pare se sentir desconforto ou tonturas.\n\nReserve alguns minutos de tranquilidade, se quiser. Sem objetivos a cumprir nem nada a registar.\n\nOrientações gerais de bem-estar, adaptadas de “Breathing exercises for stress” do NHS. Não são um tratamento nem uma avaliação do seu stress.',
                        ),
                      );
                    case DailyGuidanceKind.checkIn:
                      context.push('/journal/check-in');
                    case DailyGuidanceKind.takeItEasy:
                      context.push('/journal');
                  }
                },
                label: Text(action),
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                iconAlignment: IconAlignment.end,
              ),
              TextButton(
                key: const Key('daily-guidance-why'),
                onPressed: () => showRingInfo(
                  context,
                  title: copy('Why this suggestion?', 'Porquê esta sugestão?'),
                  closeLabel: copy('Got it', 'Entendido'),
                  body:
                      '${demo ? copy('Example data only—not personal advice.\n\n', 'Apenas dados de exemplo—não são conselhos pessoais.\n\n') : ''}$reason\n\n${copy(_englishExplanation, _portugueseExplanation)}',
                ),
                child: Text(copy('Why this?', 'Porquê?')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _englishExplanation = '''A suggestion, not an instruction
These are optional ideas for everyday wellbeing. How you feel, your circumstances and any advice from your clinician come first. The ring cannot decide whether you are ready for a run or need recovery.

What goes into it
Today uses explicit check-in tags, recorded sleep compared with your current sleep target, or recent recorded steps compared with your step goal. Check-ins about illness, stress or low energy take priority. Logged exercise or swimming prevents a below-goal walk nudge.

What stays out
We do not use the ring’s unverified HRV or stress indexes, calories, pulse or oxygen to prescribe activity. Gaps are not inactivity, and even a complete download does not prove a full day of wear. Recorded sleep may miss sleep; it is not a diagnosis of poor sleep.

Keeping it honest
Step nudges need recent readings and are limited to daytime. Incomplete or stale data does not become a personal assessment. Suggestions are calculated on your phone, with no AI service, account or upload. You can update your goals in You → Profile and delete a check-in in your journal.

General background: NHS “Walking for health”, “Breathing exercises for stress” and Every Mind Matters sleep guidance. These sources do not validate ring-based recommendations.''';

const _portugueseExplanation = '''Uma sugestão, não uma instrução
São ideias opcionais para o bem-estar no dia a dia. O que sente, as suas circunstâncias e as orientações do seu médico têm prioridade. O anel não determina se está pronto para correr ou precisa de recuperação.

Em que se baseia
Hoje usa os temas que assinalou nos registos, o sono registado em relação ao seu objetivo atual ou passos recentes em relação ao objetivo de passos. Os registos de doença, stress ou pouca energia têm prioridade. Um registo de exercício ou natação impede sugestões de caminhada por passos abaixo do objetivo.

O que fica de fora
Não usamos os índices de HRV ou stress não verificados, calorias, pulso ou oxigénio para prescrever atividade. Lacunas não são inatividade, e uma transferência completa não prova um dia inteiro de uso. O registo pode não captar todo o sono; não é um diagnóstico de sono insuficiente.

Com transparência
As sugestões de passos exigem leituras recentes e limitam-se ao período diurno. Dados incompletos ou antigos não se tornam numa avaliação pessoal. As sugestões são calculadas no telemóvel, sem serviço de IA, conta ou envio de dados. Pode atualizar os objetivos em Perfil e eliminar um registo no diário.

Informação geral: NHS “Walking for health”, “Breathing exercises for stress” e orientações sobre sono do Every Mind Matters. Estas fontes não validam recomendações baseadas no anel.''';
