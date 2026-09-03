import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ring_design_system/ring_design_system.dart';

import 'app_state.dart';
import 'ring_analytics.dart';
import 'storage/journal_repository.dart';

String _copy(BuildContext context, String english, String portuguese) =>
    Localizations.localeOf(context).languageCode == 'pt' ? portuguese : english;

class ProductDayTimelineScreen extends ConsumerWidget {
  const ProductDayTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoModeProvider);
    final dataset = demo ? null : ref.watch(ringDataProvider).value;
    final journal = ref.watch(journalProvider).value ?? const <JournalEntry>[];
    final events = <_TimelineEvent>[];
    if (dataset != null) {
      final analytics = RingAnalytics.fromDataset(
        dataset,
        localNow: ref.watch(currentLocalTimeProvider),
      );
      final day = analytics.selectedDay;
      final activity = analytics.activityFor(day);
      final pulse = analytics.pulseFor(day);
      final oxygen = analytics.oxygenFor(day);
      if (dataset.sleep.isNotEmpty) {
        final sessions = dataset.sleep.toList(growable: false)
          ..sort((a, b) => a.endedAtUtc.compareTo(b.endedAtUtc));
        final sleep = sessions.last;
        events.add(
          _TimelineEvent(
            time: _clock(sleep.endedAtUtc),
            title: _copy(
              context,
              'Sleep interval ended',
              'Intervalo de sono terminou',
            ),
            detail: _copy(
              context,
              'Ring-recorded firmware interval',
              'Intervalo do firmware registado pelo anel',
            ),
            provenance: _copy(context, 'Ring-recorded', 'Registado pelo anel'),
          ),
        );
      }
      if (activity.buckets.isNotEmpty) {
        events.add(
          _TimelineEvent(
            time: _clock(activity.buckets.last.startedAtUtc),
            title: _copy(
              context,
              '${activity.steps} steps retained',
              '${activity.steps} passos retidos',
            ),
            detail: _copy(
              context,
              '${activity.coveredHours} covered hours · ${activity.firmwareCalories} firmware kcal',
              '${activity.coveredHours} horas cobertas · ${activity.firmwareCalories} kcal do firmware',
            ),
            provenance: _copy(context, 'Ring estimate', 'Estimativa do anel'),
          ),
        );
      }
      if (pulse.samples.isNotEmpty) {
        events.add(
          _TimelineEvent(
            time: _clock(pulse.samples.last.at),
            title: _copy(
              context,
              '${pulse.samples.last.value} bpm pulse sample',
              'Amostra de pulso de ${pulse.samples.last.value} bpm',
            ),
            detail: _copy(
              context,
              '${pulse.samples.length} measured samples retained for the day',
              '${pulse.samples.length} amostras medidas retidas para o dia',
            ),
            provenance: _copy(context, 'Ring-recorded', 'Registado pelo anel'),
          ),
        );
      }
      if (oxygen.ranges.isNotEmpty) {
        events.add(
          _TimelineEvent(
            time: _clock(oxygen.ranges.last.hourStartedAtUtc),
            title: _copy(
              context,
              'Oxygen sample range retained',
              'Intervalo de oxigénio retido',
            ),
            detail: _copy(
              context,
              'Samples present · no validated result',
              'Amostras presentes · sem resultado validado',
            ),
            provenance: _copy(
              context,
              'Interpret with care',
              'Interpretar com cuidado',
            ),
          ),
        );
      }
    }
    for (final entry in journal) {
      events.add(
        _TimelineEvent(
          time: _clock(entry.occurredAtUtc),
          title: entry.title,
          detail: entry.details,
          provenance: _copy(context, 'Manual', 'Manual'),
        ),
      );
    }
    events.sort((a, b) => b.time.compareTo(a.time));

    return ProductSystemScaffold(
      screenKey: const Key('screen-day-timeline'),
      activePath: '/today',
      showBack: true,
      backLabel: _copy(context, 'Back to Today', 'Voltar a Hoje'),
      backPath: '/today',
      contextLabel: _copy(context, 'Today in context', 'Hoje em contexto'),
      eyebrow: _copy(context, 'Timeline', 'Cronologia'),
      title: _copy(
        context,
        'One day, without blending the sources.',
        'Um dia, sem misturar as fontes.',
      ),
      intro: _copy(
        context,
        'Ring records and manual context share a timeline while keeping their provenance visible.',
        'Os registos do anel e o contexto manual partilham uma cronologia, mantendo a origem visível.',
      ),
      children: <Widget>[
        if (events.isEmpty)
          _StatusPanel(
            title: _copy(
              context,
              'No local events yet.',
              'Ainda não há eventos locais.',
            ),
            body: _copy(
              context,
              'Sync the ring or add manual context. Missing history remains missing.',
              'Sincronize o anel ou adicione contexto manual. O histórico em falta permanece em falta.',
            ),
          )
        else
          for (final event in events) _TimelineRow(event: event),
        const SizedBox(height: 22),
        OutlinedButton(
          onPressed: () => context.go('/activity/sports'),
          child: Text(
            _copy(context, 'Add manual activity', 'Adicionar atividade manual'),
          ),
        ),
      ],
    );
  }
}

class ActivitySuggestionScreen extends ConsumerWidget {
  const ActivitySuggestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoModeProvider);
    final dataset = demo ? null : ref.watch(ringDataProvider).value;
    final hasSignals =
        demo ||
        (dataset != null &&
            dataset.activity.isNotEmpty &&
            dataset.heartRate.isNotEmpty);
    return ProductSystemScaffold(
      screenKey: const Key('screen-activity-suggestion'),
      activePath: '/vitals',
      showBack: true,
      backLabel: _copy(context, 'Back to Activity', 'Voltar a Atividade'),
      backPath: '/activity',
      contextLabel: demo
          ? _copy(context, 'Illustrative example', 'Exemplo ilustrativo')
          : _copy(context, 'Review required', 'Revisão necessária'),
      eyebrow: _copy(context, 'Possible activity', 'Atividade possível'),
      title: hasSignals
          ? _copy(
              context,
              'A movement and pulse window may be worth labelling.',
              'Pode valer a pena identificar um intervalo de movimento e pulso.',
            )
          : _copy(
              context,
              'There is not enough supported data for a suggestion.',
              'Não há dados compatíveis suficientes para uma sugestão.',
            ),
      intro: _copy(
        context,
        'LibreRing never chooses the sport for you. Confirming adds manual context and does not rewrite ring measurements.',
        'O LibreRing nunca escolhe o desporto por si. Confirmar adiciona contexto manual e não altera as medições do anel.',
      ),
      children: <Widget>[
        _StatusPanel(
          title: hasSignals
              ? _copy(
                  context,
                  '34 minute signal window',
                  'Intervalo de sinal de 34 minutos',
                )
              : _copy(
                  context,
                  'No suggestion available',
                  'Nenhuma sugestão disponível',
                ),
          body: hasSignals
              ? _copy(
                  context,
                  'Movement rose alongside measured pulse. The activity type remains unknown.',
                  'O movimento aumentou juntamente com o pulso medido. O tipo de atividade continua desconhecido.',
                )
              : _copy(
                  context,
                  'A supported movement and pulse window is required before this review appears.',
                  'É necessário um intervalo compatível de movimento e pulso antes desta revisão.',
                ),
        ),
        const SizedBox(height: 18),
        if (hasSignals) ...<Widget>[
          LibreRingPrimaryButton(
            label: _copy(
              context,
              'Choose the activity',
              'Escolher a atividade',
            ),
            onPressed: () => context.go('/activity/sports'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/activity'),
            child: Text(
              _copy(context, 'Dismiss suggestion', 'Ignorar sugestão'),
            ),
          ),
        ],
      ],
    );
  }
}

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider).value ?? const <JournalEntry>[];
    final activityEntries = entries
        .where(
          (entry) =>
              entry.kind == JournalEntryKind.checkIn ||
              entry.kind == JournalEntryKind.swim,
        )
        .toList(growable: false);
    return ProductSystemScaffold(
      screenKey: const Key('screen-activity-detail'),
      activePath: '/vitals',
      showBack: true,
      backLabel: _copy(context, 'Back to Activity', 'Voltar a Atividade'),
      backPath: '/activity',
      contextLabel: _copy(context, 'Activity record', 'Registo de atividade'),
      eyebrow: _copy(context, 'Manual context', 'Contexto manual'),
      title: _copy(
        context,
        'What you add stays separate from what the ring measured.',
        'O que adiciona permanece separado do que o anel mediu.',
      ),
      intro: _copy(
        context,
        'Duration, effort, and notes are user-entered. They never manufacture steps, pulse, calories, or distance.',
        'A duração, o esforço e as notas são inseridos pelo utilizador. Nunca criam passos, pulso, calorias ou distância.',
      ),
      children: <Widget>[
        if (activityEntries.isEmpty)
          _StatusPanel(
            title: _copy(
              context,
              'No manual activities yet.',
              'Ainda não há atividades manuais.',
            ),
            body: _copy(
              context,
              'Add an activity only when it helps explain your own history.',
              'Adicione uma atividade apenas quando ajudar a explicar o seu histórico.',
            ),
          )
        else
          for (final entry in activityEntries)
            _ProductLinkRow(
              title: entry.title,
              detail: entry.details,
              value: _copy(context, 'Manual', 'Manual'),
            ),
        const SizedBox(height: 18),
        LibreRingPrimaryButton(
          label: _copy(context, 'Add activity', 'Adicionar atividade'),
          onPressed: () => context.go('/activity/sports'),
        ),
      ],
    );
  }
}

class ActivitySportsScreen extends StatefulWidget {
  const ActivitySportsScreen({super.key});

  @override
  State<ActivitySportsScreen> createState() => _ActivitySportsScreenState();
}

class _ActivitySportsScreenState extends State<ActivitySportsScreen> {
  String query = '';

  static const sports = <String>[
    'Walking',
    'Running',
    'Cycling',
    'Swimming',
    'Strength training',
    'Yoga',
    'Hiking',
    'Football',
    'Tennis',
    'Other activity',
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = sports
        .where((sport) => sport.toLowerCase().contains(query.toLowerCase()))
        .toList(growable: false);
    return ProductSystemScaffold(
      screenKey: const Key('screen-activity-sports'),
      showBack: true,
      backLabel: _copy(context, 'Back to Activity', 'Voltar a Atividade'),
      backPath: '/activity',
      contextLabel: _copy(context, 'Manual activity', 'Atividade manual'),
      eyebrow: _copy(context, 'Add activity', 'Adicionar atividade'),
      title: _copy(context, 'Choose how you moved.', 'Escolha como se moveu.'),
      intro: _copy(
        context,
        'Any sport can be logged. Only the fields you enter will be saved.',
        'Pode registar qualquer desporto. Apenas os campos que inserir serão guardados.',
      ),
      children: <Widget>[
        TextField(
          key: const Key('activity-sport-search'),
          onChanged: (value) => setState(() => query = value),
          decoration: InputDecoration(
            hintText: _copy(context, 'Search sports', 'Pesquisar desportos'),
            prefixIcon: const Icon(Icons.search, size: 20),
          ),
        ),
        const SizedBox(height: 18),
        if (filtered.isEmpty)
          _StatusPanel(
            title: _copy(
              context,
              'No matching sport.',
              'Nenhum desporto correspondente.',
            ),
            body: _copy(
              context,
              'Choose Other activity and name it in your note.',
              'Escolha Outra atividade e dê-lhe um nome na nota.',
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filtered
                .map(
                  (sport) => ActionChip(
                    label: Text(sport),
                    onPressed: () => context.go(
                      '/activity/log?name=${Uri.encodeComponent(sport)}',
                    ),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({required this.activityName, super.key});

  final String activityName;

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  final duration = TextEditingController(text: '30');
  final note = TextEditingController();
  String effort = 'Moderate';
  bool saved = false;

  @override
  void dispose() {
    duration.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityName = widget.activityName.trim().isEmpty
        ? _copy(context, 'Activity', 'Atividade')
        : widget.activityName;
    return ProductSystemScaffold(
      screenKey: const Key('screen-activity-log'),
      showBack: true,
      backLabel: _copy(context, 'Back to sports', 'Voltar aos desportos'),
      backPath: '/activity/sports',
      contextLabel: _copy(context, 'Manual source', 'Fonte manual'),
      eyebrow: _copy(context, 'Log activity', 'Registar atividade'),
      title: _copy(
        context,
        'Add $activityName in your own words.',
        'Adicione $activityName pelas suas palavras.',
      ),
      intro: _copy(
        context,
        'This context stays separate from ring-recorded movement and vital samples.',
        'Este contexto permanece separado do movimento e sinais vitais registados pelo anel.',
      ),
      children: <Widget>[
        _FieldLabel(label: _copy(context, 'Minutes', 'Minutos')),
        TextField(
          key: const Key('activity-duration'),
          controller: duration,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _FieldLabel(label: _copy(context, 'Effort', 'Esforço')),
        DropdownButtonFormField<String>(
          initialValue: effort,
          isExpanded: true,
          items: <String>['Easy', 'Moderate', 'Hard']
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => effort = value ?? effort),
        ),
        const SizedBox(height: 16),
        _FieldLabel(
          label: _copy(context, 'Note (optional)', 'Nota (opcional)'),
        ),
        TextField(
          key: const Key('activity-note'),
          controller: note,
          maxLength: 160,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _SourceNote(
          text: _copy(
            context,
            'Source: Manual. Saving this entry will not alter ring-recorded steps, pulse, calories, or distance.',
            'Fonte: Manual. Guardar este registo não altera passos, pulso, calorias ou distância registados pelo anel.',
          ),
        ),
        const SizedBox(height: 18),
        LibreRingPrimaryButton(
          key: const Key('save-activity'),
          label: saved
              ? _copy(context, 'Saved locally', 'Guardado localmente')
              : _copy(context, 'Save activity', 'Guardar atividade'),
          onPressed: saved
              ? null
              : () async {
                  final minutes = int.tryParse(duration.text.trim());
                  if (minutes == null || minutes < 1 || minutes > 1440) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _copy(
                            context,
                            'Enter 1 to 1,440 minutes.',
                            'Introduza entre 1 e 1.440 minutos.',
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  await ref
                      .read(journalProvider.notifier)
                      .saveCheckIn(
                        tags: <String>['Exercise', activityName],
                        note:
                            '$minutes minutes · $effort${note.text.trim().isEmpty ? '' : ' · ${note.text.trim()}'}',
                      );
                  if (mounted) setState(() => saved = true);
                },
        ),
      ],
    );
  }
}

class ProfilePreferencesScreen extends StatefulWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  State<ProfilePreferencesScreen> createState() =>
      _ProfilePreferencesScreenState();
}

class _ProfilePreferencesScreenState extends State<ProfilePreferencesScreen> {
  final name = TextEditingController();
  String units = 'Metric';
  String focus = 'Balanced';
  String notifications = 'Important insights only';

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProductSystemScaffold(
    screenKey: const Key('screen-profile-preferences'),
    showBack: true,
    backLabel: _copy(context, 'Back to You', 'Voltar ao Perfil'),
    backPath: '/you',
    contextLabel: _copy(context, 'Personal settings', 'Definições pessoais'),
    eyebrow: _copy(context, 'Profile and preferences', 'Perfil e preferências'),
    title: _copy(
      context,
      'Make the product useful without making it noisy.',
      'Torne o produto útil sem o tornar ruidoso.',
    ),
    children: <Widget>[
      _FieldLabel(
        label: _copy(context, 'Display name', 'Nome de apresentação'),
      ),
      TextField(controller: name, textCapitalization: TextCapitalization.words),
      const SizedBox(height: 16),
      _FieldLabel(label: _copy(context, 'Units', 'Unidades')),
      DropdownButtonFormField<String>(
        initialValue: units,
        isExpanded: true,
        items: <String>['Metric', 'Imperial']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(growable: false),
        onChanged: (value) => setState(() => units = value ?? units),
      ),
      const SizedBox(height: 16),
      _FieldLabel(label: _copy(context, 'Daily emphasis', 'Ênfase diária')),
      DropdownButtonFormField<String>(
        initialValue: focus,
        isExpanded: true,
        items: <String>['Balanced', 'Sleep', 'Activity']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(growable: false),
        onChanged: (value) => setState(() => focus = value ?? focus),
      ),
      const SizedBox(height: 16),
      _FieldLabel(label: _copy(context, 'Notifications', 'Notificações')),
      DropdownButtonFormField<String>(
        initialValue: notifications,
        isExpanded: true,
        items: <String>['Important insights only', 'Morning and evening', 'Off']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(growable: false),
        onChanged: (value) =>
            setState(() => notifications = value ?? notifications),
      ),
      const SizedBox(height: 20),
      LibreRingPrimaryButton(
        label: _copy(
          context,
          'Save for this session',
          'Guardar para esta sessão',
        ),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _copy(
                context,
                'Preferences applied for this session.',
                'Preferências aplicadas a esta sessão.',
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class SyncIssueScreen extends ConsumerWidget {
  const SyncIssueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairing = ref.watch(ringPairingProvider);
    return ProductSystemScaffold(
      screenKey: const Key('screen-sync-issue'),
      showBack: true,
      backLabel: _copy(context, 'Back to Device', 'Voltar ao Dispositivo'),
      backPath: '/you/ring',
      contextLabel: _copy(
        context,
        'Past sync issue',
        'Problema de sincronização anterior',
      ),
      eyebrow: _copy(context, 'Connection history', 'Histórico de ligação'),
      title: _copy(
        context,
        'The ring moved out of range.',
        'O anel ficou fora de alcance.',
      ),
      intro: _copy(
        context,
        'No local records were deleted. A later successful sync can complete a missing interval.',
        'Nenhum registo local foi eliminado. Uma sincronização posterior pode completar um intervalo em falta.',
      ),
      children: <Widget>[
        _StatusPanel(
          title: pairing.syncError == null
              ? _copy(context, 'Local data safe', 'Dados locais seguros')
              : _copy(
                  context,
                  'Latest attempt needs attention',
                  'A última tentativa requer atenção',
                ),
          body:
              pairing.syncError ??
              _copy(
                context,
                'Connection history is informational. Missing data is never shown as zero.',
                'O histórico de ligação é informativo. Dados em falta nunca são mostrados como zero.',
              ),
        ),
        const SizedBox(height: 18),
        LibreRingPrimaryButton(
          label: pairing.syncInProgress
              ? _copy(context, 'Syncing…', 'A sincronizar…')
              : _copy(context, 'Run a new sync', 'Executar nova sincronização'),
          onPressed: pairing.syncInProgress
              ? null
              : ref.read(ringPairingProvider.notifier).quickSync,
        ),
      ],
    );
  }
}

class TemperatureUnavailableScreen extends StatelessWidget {
  const TemperatureUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) => ProductSystemScaffold(
    screenKey: const Key('screen-temperature-unavailable'),
    activePath: '/vitals',
    showBack: true,
    backLabel: _copy(context, 'Back to Vitals', 'Voltar a Sinais Vitais'),
    backPath: '/vitals',
    contextLabel: _copy(context, 'Device boundary', 'Limite do dispositivo'),
    eyebrow: _copy(context, 'Temperature deviation', 'Desvio de temperatura'),
    title: _copy(
      context,
      'This ring does not provide temperature data.',
      'Este anel não fornece dados de temperatura.',
    ),
    intro: _copy(
      context,
      'LibreRing will not substitute an estimate or display unavailable data as zero.',
      'O LibreRing não substitui uma estimativa nem mostra dados indisponíveis como zero.',
    ),
    children: <Widget>[
      _StatusPanel(
        title: _copy(context, 'Unsupported', 'Não compatível'),
        body: _copy(
          context,
          'Connected device capability · no temperature sensor exposed to LibreRing.',
          'Capacidade do dispositivo ligado · nenhum sensor de temperatura exposto ao LibreRing.',
        ),
      ),
    ],
  );
}

class RestingPulseBoundaryScreen extends StatelessWidget {
  const RestingPulseBoundaryScreen({super.key});

  @override
  Widget build(BuildContext context) => ProductSystemScaffold(
    screenKey: const Key('screen-resting-pulse-boundary'),
    activePath: '/vitals',
    showBack: true,
    backLabel: _copy(context, 'Back to Vitals', 'Voltar a Sinais Vitais'),
    backPath: '/vitals',
    contextLabel: _copy(context, 'Calculation boundary', 'Limite de cálculo'),
    eyebrow: _copy(
      context,
      'Resting heart rate',
      'Frequência cardíaca em repouso',
    ),
    title: _copy(
      context,
      'Measured pulse is available. A resting result is not yet validated.',
      'O pulso medido está disponível. Um resultado em repouso ainda não está validado.',
    ),
    intro: _copy(
      context,
      'LibreRing keeps raw pulse history visible without labelling an unverified subset as resting heart rate.',
      'O LibreRing mantém o histórico de pulso visível sem classificar um subconjunto não verificado como frequência em repouso.',
    ),
    children: <Widget>[
      _ProductLinkRow(
        title: _copy(
          context,
          'Measured pulse history',
          'Histórico de pulso medido',
        ),
        detail: _copy(
          context,
          'Ring-recorded samples',
          'Amostras registadas pelo anel',
        ),
        value: _copy(context, 'Open', 'Abrir'),
        onTap: () => context.go('/heart'),
      ),
      const _SourceNote(text: 'Unavailable is not zero.'),
    ],
  );
}

class ProductOnboardingScreen extends StatefulWidget {
  const ProductOnboardingScreen({super.key});

  @override
  State<ProductOnboardingScreen> createState() =>
      _ProductOnboardingScreenState();
}

class _ProductOnboardingScreenState extends State<ProductOnboardingScreen> {
  int step = 0;

  @override
  Widget build(BuildContext context) {
    final steps = <(String, String, String)>[
      (
        _copy(context, 'Privacy', 'Privacidade'),
        _copy(context, 'Private by default.', 'Privado por predefinição.'),
        _copy(
          context,
          'LibreRing keeps ring records local unless you choose to export them.',
          'O LibreRing mantém os registos do anel localmente, salvo se optar por exportá-los.',
        ),
      ),
      (
        _copy(context, 'Pairing', 'Emparelhamento'),
        _copy(context, 'Pair the ring nearby.', 'Emparelhe o anel por perto.'),
        _copy(
          context,
          'Bluetooth is used for a direct local sync. Device identifiers stay out of normal product screens.',
          'O Bluetooth é usado para uma sincronização local direta. Os identificadores ficam fora dos ecrãs normais.',
        ),
      ),
      (
        _copy(context, 'Ready', 'Pronto'),
        _copy(
          context,
          'Start with one clear answer.',
          'Comece com uma resposta clara.',
        ),
        _copy(
          context,
          'Today explains what matters first. Detailed records remain one tap deeper.',
          'Hoje explica primeiro o que importa. Os registos detalhados ficam a um toque.',
        ),
      ),
    ];
    final item = steps[step];
    return Scaffold(
      key: const Key('screen-product-onboarding'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const LibreRingWordmark(),
              const Spacer(),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : LibreRingTokens.slow,
                switchInCurve: LibreRingTokens.curve,
                switchOutCurve: LibreRingTokens.curve,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey<int>(step),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    LibreRingEyebrow(item.$1),
                    const SizedBox(height: 10),
                    Text(
                      item.$2,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: LibreRingTokens.accent,
                            fontSize: 52,
                            height: .98,
                            letterSpacing: -2.2,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Text(item.$3, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: List<Widget>.generate(
                  steps.length,
                  (index) => AnimatedContainer(
                    duration: LibreRingTokens.fast,
                    margin: const EdgeInsets.only(right: 6),
                    width: index == step ? 28 : 8,
                    height: 3,
                    color: index == step
                        ? LibreRingTokens.accent
                        : LibreRingTokens.border,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LibreRingPrimaryButton(
                label: step == steps.length - 1
                    ? _copy(context, 'Begin setup', 'Começar configuração')
                    : _copy(context, 'Continue', 'Continuar'),
                onPressed: () {
                  if (step == steps.length - 1) {
                    context.go('/privacy');
                  } else {
                    setState(() => step += 1);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductSystemScaffold extends StatelessWidget {
  const ProductSystemScaffold({
    required this.screenKey,
    required this.eyebrow,
    required this.title,
    required this.children,
    this.contextLabel,
    this.intro,
    this.activePath,
    this.showBack = false,
    this.backLabel,
    this.backPath,
    super.key,
  });

  final Key screenKey;
  final String eyebrow;
  final String title;
  final String? contextLabel;
  final String? intro;
  final String? activePath;
  final bool showBack;
  final String? backLabel;
  final String? backPath;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: screenKey,
    body: SafeArea(
      bottom: activePath == null,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (showBack)
                  IconButton(
                    tooltip: backLabel,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(backPath ?? '/today'),
                    icon: const Icon(Icons.arrow_back, size: 20),
                  )
                else
                  const LibreRingWordmark(),
                const Spacer(),
                if (!showBack)
                  Text(
                    _copy(context, 'Stored locally', 'Guardado localmente'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: LibreRingTokens.muted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            if (contextLabel != null) ...<Widget>[
              Text(
                contextLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  color: LibreRingTokens.muted,
                ),
              ),
              const SizedBox(height: 8),
            ],
            LibreRingEyebrow(eyebrow),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: LibreRingTokens.accent,
                fontSize: 42,
                height: 1.02,
                letterSpacing: -1.8,
              ),
            ),
            if (intro != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(intro!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 30),
            ...children,
          ],
        ),
      ),
    ),
    bottomNavigationBar: activePath == null
        ? null
        : _ProductBottomNav(activePath: activePath!),
  );
}

class _ProductBottomNav extends StatelessWidget {
  const _ProductBottomNav({required this.activePath});

  final String activePath;

  @override
  Widget build(BuildContext context) {
    const items = <(String, String)>[
      ('/today', 'Today'),
      ('/vitals', 'Vitals'),
      ('/trends', 'Trends'),
      ('/you', 'You'),
    ];
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 14),
      child: Center(
        heightFactor: 1,
        child: Container(
          width: MediaQuery.sizeOf(context).width - 32,
          constraints: const BoxConstraints(maxWidth: 430),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: LibreRingTokens.foreground,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: items
                .map((item) {
                  final selected = item.$1 == activePath;
                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: item.$2,
                      child: ExcludeSemantics(
                        child: TextButton(
                          onPressed: () => context.go(item.$1),
                          style: TextButton.styleFrom(
                            foregroundColor: selected
                                ? Colors.white
                                : const Color(0xFFC5C2BC),
                            minimumSize: const Size(64, 48),
                            padding: EdgeInsets.zero,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                item.$2,
                                textScaler: TextScaler.noScaling,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedContainer(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : LibreRingTokens.fast,
                                curve: LibreRingTokens.curve,
                                width: selected ? 18 : 0,
                                height: 2,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.time,
    required this.title,
    required this.detail,
    required this.provenance,
  });
  final String time;
  final String title;
  final String detail;
  final String provenance;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});
  final _TimelineEvent event;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 88),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: LibreRingTokens.border)),
    ),
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 52,
          child: Text(
            event.time,
            style: const TextStyle(fontSize: 11, color: LibreRingTokens.muted),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                event.detail,
                style: const TextStyle(
                  fontSize: 11,
                  color: LibreRingTokens.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          event.provenance,
          style: const TextStyle(fontSize: 9, color: LibreRingTokens.accent),
        ),
      ],
    ),
  );
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: LibreRingTokens.surface,
      borderRadius: BorderRadius.circular(LibreRingTokens.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(body, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _ProductLinkRow extends StatelessWidget {
  const _ProductLinkRow({
    required this.title,
    required this.detail,
    required this.value,
    this.onTap,
  });
  final String title;
  final String detail;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 76),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LibreRingTokens.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: LibreRingTokens.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 11, color: LibreRingTokens.muted),
          ),
        ],
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class _SourceNote extends StatelessWidget {
  const _SourceNote({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: LibreRingTokens.accent, width: 2)),
      color: LibreRingTokens.soft,
    ),
    child: Text(text, style: const TextStyle(fontSize: 11, height: 1.4)),
  );
}

String _clock(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
