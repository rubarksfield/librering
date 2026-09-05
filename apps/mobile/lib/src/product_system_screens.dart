import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:ring_design_system/ring_design_system.dart';

import 'app_state.dart';
import 'presentation_data.dart';
import 'ring_analytics.dart';
import 'storage/journal_repository.dart';
import 'storage/preferences_repository.dart';
import 'ui/app_chrome.dart';

String _copy(BuildContext context, String english, String portuguese) =>
    Localizations.localeOf(context).languageCode == 'pt' ? portuguese : english;

String _timelineDuration(int minutes) => '${minutes ~/ 60}h ${minutes % 60}m';

class ProductDayTimelineScreen extends ConsumerStatefulWidget {
  const ProductDayTimelineScreen({super.key});
  @override
  ConsumerState<ProductDayTimelineScreen> createState() =>
      _ProductDayTimelineScreenState();
}

class _ProductDayTimelineScreenState
    extends ConsumerState<ProductDayTimelineScreen> {
  DateTime? _selectedDay;
  String _filter = 'All';
  int _visibleLimit = 40;

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(isDemoModeProvider);
    final state = ref.watch(displayRingDataProvider);
    final dataset = state.value;
    final journalState = ref.watch(journalProvider);
    final journal = journalState.value ?? const <JournalEntry>[];
    final preferences =
        ref.watch(appPreferencesProvider).value ?? const AppPreferences();
    final now = ref.watch(currentLocalTimeProvider);
    final today = RingCalendar.day(now);
    final query = GoRouterState.of(context).uri.queryParameters['date'];
    DateTime? requested;
    if (query != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(query)) {
      final parsed = DateTime.tryParse(query);
      if (parsed != null && DateFormat('yyyy-MM-dd').format(parsed) == query) {
        requested = parsed;
      }
    }
    var day = RingCalendar.day(_selectedDay ?? requested ?? today);
    if (day.isAfter(today)) day = today;
    final analytics = dataset == null
        ? null
        : RingAnalytics.fromDataset(dataset, localNow: now, selectedDay: day);
    final journalDays = journal
        .where((entry) => !entry.occurredAtUtc.isAfter(now))
        .map((entry) => RingCalendar.day(entry.occurredAtUtc.toLocal()))
        .toList();
    final earliest = <DateTime>[analytics?.earliestDay ?? today, ...journalDays]
      ..sort();
    String route(String value) =>
        '$value?date=${DateFormat('yyyy-MM-dd').format(day)}';
    final events = <_TimelineEvent>[];
    if (analytics != null) {
      for (final sleep in analytics.sleepOn(day)) {
        events.add(
          _TimelineEvent(
            at: sleep.session.endedAtUtc,
            title: sleep.stages.isEmpty
                ? _copy(
                    context,
                    'Sleep window ended',
                    'Intervalo de sono terminou',
                  )
                : _copy(
                    context,
                    'Estimated sleep · ${_timelineDuration(sleep.asleepStageMinutes)}',
                    'Sono estimado · ${_timelineDuration(sleep.asleepStageMinutes)}',
                  ),
            detail:
                '${_clock(sleep.session.startedAtUtc)} – ${_clock(sleep.session.endedAtUtc)}',
            provenance: _copy(context, 'Ring estimate', 'Estimativa do anel'),
            category: 'Sleep',
            route: route('/sleep'),
          ),
        );
      }
      for (final hour
          in analytics
              .activityFor(day)
              .hourly
              .where((value) => value.hasRecord)) {
        events.add(
          _TimelineEvent(
            at: hour.startedAt,
            title:
                '${NumberFormat.decimalPattern().format(hour.steps)}${_copy(context, ' steps', ' passos')}',
            detail:
                '${preferences.formatDistance(hour.distanceMeters)} · ${hour.firmwareCalories} kcal',
            provenance: _copy(
              context,
              'Ring estimate · hourly',
              'Estimativa do anel · hora',
            ),
            category: 'Activity',
            route: route('/movement'),
          ),
        );
      }
      for (final pulse in analytics.pulseFor(day).samples) {
        events.add(
          _TimelineEvent(
            at: pulse.at,
            title: '${pulse.value} bpm',
            detail: _copy(
              context,
              'Heart rate reading',
              'Leitura da frequência cardíaca',
            ),
            provenance: _copy(context, 'Ring reading', 'Leitura do anel'),
            category: 'Vitals',
            route: route('/heart'),
          ),
        );
      }
      for (final oxygen in analytics.oxygenFor(day).ranges) {
        events.add(
          _TimelineEvent(
            at: oxygen.hourStartedAtUtc,
            title: '${oxygen.minimumPercent}–${oxygen.maximumPercent}%',
            detail: _copy(
              context,
              'Blood oxygen · hourly range',
              'Oxigénio no sangue · intervalo horário',
            ),
            provenance: _copy(context, 'Ring reading', 'Leitura do anel'),
            category: 'Vitals',
            route: route('/oxygen'),
          ),
        );
      }
    }
    for (final entry in journal) {
      if (!RingCalendar.sameDay(entry.occurredAtUtc, day) ||
          entry.occurredAtUtc.isAfter(now)) {
        continue;
      }
      events.add(
        _TimelineEvent(
          at: entry.occurredAtUtc,
          title: entry.title,
          detail: entry.details,
          provenance: _copy(context, 'Added by you', 'Adicionado por si'),
          category: 'Journal',
          route: '/journal',
        ),
      );
    }
    events.sort((a, b) => b.at.compareTo(a.at));
    final visible = events
        .where((event) => _filter == 'All' || event.category == _filter)
        .toList();
    return RingPageScaffold(
      key: const Key('screen-day-timeline'),
      activePath: '/today',
      scrollKey: 'day-timeline',
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              tooltip: _copy(context, 'Back to Today', 'Voltar a Hoje'),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/today'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
            Expanded(
              child: Text(
                _copy(context, 'Your day, in context', 'O seu dia em contexto'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        RingDaySelector(
          selectedDay: day,
          earliestDay: earliest.first,
          latestDay: today,
          onChanged: (value) => setState(() {
            _selectedDay = value;
            _visibleLimit = 40;
          }),
        ),
        const SizedBox(height: 16),
        Text(
          demo
              ? _copy(
                  context,
                  'Example ring data · Your journal stays separate',
                  'Exemplo do anel · O diário permanece separado',
                )
              : _copy(
                  context,
                  'Ring readings and moments you have added.',
                  'Leituras do anel e momentos que adicionou.',
                ),
          style: const TextStyle(fontSize: 13, color: LibreRingTokens.muted),
        ),
        const SizedBox(height: 16),
        if (journalState.hasError) ...<Widget>[
          Text(
            _copy(
              context,
              'Your journal could not be loaded.',
              'Não foi possível abrir o diário.',
            ),
            style: const TextStyle(fontSize: 13),
          ),
          TextButton(
            onPressed: () => ref.invalidate(journalProvider),
            child: Text(
              _copy(context, 'Retry journal', 'Tentar abrir o diário'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final category in const <String>[
              'All',
              'Activity',
              'Sleep',
              'Vitals',
              'Journal',
            ])
              ChoiceChip(
                key: Key('timeline-filter-${category.toLowerCase()}'),
                label: Text(
                  _copy(
                    context,
                    category,
                    const <String, String>{
                      'All': 'Tudo',
                      'Activity': 'Atividade',
                      'Sleep': 'Sono',
                      'Vitals': 'Sinais',
                      'Journal': 'Diário',
                    }[category]!,
                  ),
                ),
                selected: category == _filter,
                onSelected: (_) => setState(() {
                  _filter = category;
                  _visibleLimit = 40;
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (state.isLoading && !state.hasValue) const RingLoadingState(),
        if (state.hasError && !state.hasValue)
          RingEmptyState(
            title: _copy(
              context,
              'Ring data could not be loaded',
              'Não foi possível carregar os dados do anel',
            ),
            body: _copy(
              context,
              'Try opening your saved readings again.',
              'Tente abrir novamente as leituras guardadas.',
            ),
            action: _copy(context, 'Try again', 'Tentar novamente'),
            onAction: () => ref.invalidate(ringDataProvider),
          ),
        if (visible.isEmpty &&
            !state.isLoading &&
            !state.hasError &&
            !journalState.isLoading &&
            !journalState.hasError)
          RingEmptyState(
            title: _copy(
              context,
              'No moments here yet',
              'Ainda não há momentos aqui',
            ),
            body: _copy(
              context,
              'Choose another day or add an activity to your journal.',
              'Escolha outro dia ou adicione uma atividade ao diário.',
            ),
            icon: Icons.event_note_outlined,
          ),
        if (visible.isNotEmpty) ...<Widget>[
          Text(
            visible.length.toString() +
                _copy(
                  context,
                  ' moments · latest first',
                  ' momentos · mais recentes primeiro',
                ),
            style: const TextStyle(fontSize: 12, color: LibreRingTokens.muted),
          ),
          const SizedBox(height: 8),
          for (final event in visible.take(_visibleLimit))
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: event.route == null
                    ? null
                    : () => context.push(event.route!),
                child: _TimelineRow(event: event),
              ),
            ),
          if (visible.length > _visibleLimit)
            TextButton.icon(
              key: const Key('timeline-show-more'),
              onPressed: () => setState(() => _visibleLimit += 40),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(
                _copy(context, 'Show more moments', 'Ver mais momentos'),
              ),
            ),
        ],
        const SizedBox(height: 22),
        LibreRingPrimaryButton(
          label: _copy(context, 'Add an activity', 'Adicionar uma atividade'),
          icon: Icons.add_rounded,
          onPressed: () => context.push(route('/activity/sports')),
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
  bool saving = false;
  String? error;

  void _changed() => setState(() {
    saved = false;
    error = null;
  });

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
          readOnly: saving,
          keyboardType: TextInputType.number,
          onChanged: (_) => _changed(),
          decoration: InputDecoration(
            labelText: _copy(
              context,
              'Duration in minutes',
              'Duração em minutos',
            ),
          ),
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
          onChanged: saving
              ? null
              : (value) => setState(() {
                  effort = value ?? effort;
                  saved = false;
                  error = null;
                }),
        ),
        const SizedBox(height: 16),
        _FieldLabel(
          label: _copy(context, 'Note (optional)', 'Nota (opcional)'),
        ),
        TextField(
          key: const Key('activity-note'),
          controller: note,
          readOnly: saving,
          maxLength: 160,
          maxLines: 3,
          onChanged: (_) => _changed(),
          decoration: InputDecoration(
            labelText: _copy(context, 'Activity note', 'Nota da atividade'),
          ),
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
        if (error != null) ...<Widget>[
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        LibreRingPrimaryButton(
          key: const Key('save-activity'),
          label: saving
              ? _copy(context, 'Saving…', 'A guardar…')
              : saved
              ? _copy(context, 'Saved locally', 'Guardado localmente')
              : _copy(context, 'Save activity', 'Guardar atividade'),
          onPressed: saved || saving
              ? null
              : () async {
                  if (saving || saved) return;
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
                  FocusScope.of(context).unfocus();
                  setState(() {
                    saving = true;
                    error = null;
                  });
                  try {
                    await ref
                        .read(journalProvider.notifier)
                        .saveCheckIn(
                          tags: <String>['Exercise', activityName],
                          note:
                              '$minutes minutes · $effort${note.text.trim().isEmpty ? '' : ' · ${note.text.trim()}'}',
                        );
                    if (mounted) setState(() => saved = true);
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => error = _copy(
                          context,
                          'Could not save this activity. Your entry is still here; try again.',
                          'Não foi possível guardar a atividade. O registo continua aqui; tente novamente.',
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => saving = false);
                  }
                },
        ),
      ],
    );
  }
}

class ProfilePreferencesScreen extends ConsumerStatefulWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  ConsumerState<ProfilePreferencesScreen> createState() =>
      _ProfilePreferencesScreenState();
}

class _ProfilePreferencesScreenState
    extends ConsumerState<ProfilePreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final steps = TextEditingController();
  final sleepHours = TextEditingController();
  UnitSystem units = UnitSystem.metric;
  bool _hydrated = false;
  bool _saved = false;
  bool _saving = false;
  String? _error;

  void _changed() => setState(() {
    _saved = false;
    _error = null;
  });

  @override
  void dispose() {
    name.dispose();
    steps.dispose();
    sleepHours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(appPreferencesProvider);
    final demo = ref.watch(isDemoModeProvider);
    if (!_hydrated && preferences.value != null) {
      final value = preferences.requireValue;
      name.text = value.displayName;
      steps.text = '${value.dailyStepGoal}';
      sleepHours.text = NumberFormat('0.0#')
          .format(value.sleepTargetMinutes / 60);
      units = value.unitSystem;
      _hydrated = true;
    }
    return ProductSystemScaffold(
      screenKey: const Key('screen-profile-preferences'),
      showBack: true,
      backLabel: _copy(context, 'Back to You', 'Voltar ao Perfil'),
      backPath: '/you',
      contextLabel: _copy(context, 'Personal settings', 'Definições pessoais'),
      eyebrow: _copy(
        context,
        'Profile and preferences',
        'Perfil e preferências',
      ),
      title: _copy(context, 'Make it yours.', 'À sua medida.'),
      intro: demo
          ? _copy(
              context,
              'Try your own preferences. Preview settings reset when you close the app.',
              'Experimente as suas preferências. Nesta demonstração, são repostas quando fecha a aplicação.',
            )
          : _copy(
              context,
              'Your name, units and personal targets stay on this phone.',
              'O seu nome, unidades e objetivos pessoais ficam neste telemóvel.',
            ),
      children: <Widget>[
        if (!_hydrated && preferences.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (!_hydrated && preferences.hasError)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusPanel(
                title: _copy(
                  context,
                  'Preferences could not be loaded',
                  'Não foi possível ler as preferências',
                ),
                body: _copy(
                  context,
                  'Your saved file has been kept. Try loading it again.',
                  'O ficheiro guardado foi mantido. Tente voltar a carregá-lo.',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(appPreferencesProvider),
                child: Text(_copy(context, 'Try again', 'Tentar novamente')),
              ),
            ],
          )
        else
          Form(
            key: _formKey,
            onChanged: _changed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _FieldLabel(
                  label: _copy(context, 'Display name', 'Nome de apresentação'),
                ),
                TextFormField(
                  key: const Key('preferences-name'),
                  controller: name,
                  readOnly: _saving,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration: InputDecoration(
                    labelText: _copy(
                      context,
                      'Your name (optional)',
                      'O seu nome (opcional)',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel(label: _copy(context, 'Units', 'Unidades')),
                DropdownButtonFormField<UnitSystem>(
                  key: const Key('preferences-units'),
                  initialValue: units,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _copy(
                      context,
                      'Distance units',
                      'Unidades de distância',
                    ),
                  ),
                  items: <DropdownMenuItem<UnitSystem>>[
                    DropdownMenuItem(
                      value: UnitSystem.metric,
                      child: Text(_copy(context, 'Kilometres', 'Quilómetros')),
                    ),
                    DropdownMenuItem(
                      value: UnitSystem.imperial,
                      child: Text(_copy(context, 'Miles', 'Milhas')),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => units = value ?? units),
                ),
                const SizedBox(height: 16),
                _FieldLabel(
                  label: _copy(
                    context,
                    'Daily step goal',
                    'Objetivo diário de passos',
                  ),
                ),
                TextFormField(
                  key: const Key('preferences-step-goal'),
                  controller: steps,
                  readOnly: _saving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _copy(
                      context,
                      'Steps per day',
                      'Passos por dia',
                    ),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    return parsed == null || parsed < 500 || parsed > 50000
                        ? _copy(
                            context,
                            'Choose 500–50,000 steps.',
                            'Escolha 500–50.000 passos.',
                          )
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                _FieldLabel(
                  label: _copy(context, 'Sleep target', 'Objetivo de sono'),
                ),
                TextFormField(
                  key: const Key('preferences-sleep-target'),
                  controller: sleepHours,
                  readOnly: _saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _copy(
                      context,
                      'Hours per night',
                      'Horas por noite',
                    ),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(
                      value?.trim().replaceAll(',', '.') ?? '',
                    );
                    return parsed == null ||
                            !parsed.isFinite ||
                            parsed < 4 ||
                            parsed > 12
                        ? _copy(
                            context,
                            'Choose 4–12 hours.',
                            'Escolha 4–12 horas.',
                          )
                        : null;
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  _copy(
                    context,
                    'Targets are your own preferences, not a health recommendation.',
                    'Os objetivos são preferências pessoais, não uma recomendação de saúde.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                if (_error != null) ...<Widget>[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                LibreRingPrimaryButton(
                  key: const Key('save-preferences'),
                  label: _saving
                      ? _copy(context, 'Saving…', 'A guardar…')
                      : _saved
                      ? _copy(
                          context,
                          demo
                              ? 'Saved for this preview'
                              : 'Saved on this phone',
                          demo
                              ? 'Guardado nesta demonstração'
                              : 'Guardado neste telemóvel',
                        )
                      : _copy(
                          context,
                          'Save preferences',
                          'Guardar preferências',
                        ),
                  onPressed: _saving || _saved
                      ? null
                      : () async {
                          if (_saving || _saved) return;
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _saving = true;
                            _error = null;
                          });
                          try {
                            await ref
                                .read(appPreferencesProvider.notifier)
                                .save(
                                  AppPreferences(
                                    displayName: name.text.trim(),
                                    unitSystem: units,
                                    dailyStepGoal: int.parse(steps.text.trim()),
                                    sleepTargetMinutes:
                                        (double.parse(
                                                  sleepHours.text
                                                      .trim()
                                                      .replaceAll(',', '.'),
                                                ) *
                                                60)
                                            .round(),
                                  ),
                                );
                            if (mounted) setState(() => _saved = true);
                          } catch (_) {
                            if (mounted) {
                              setState(
                                () => _error = _copy(
                                  context,
                                  'Could not save. Your changes are still here; try again.',
                                  'Não foi possível guardar. As alterações continuam aqui; tente novamente.',
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                ),
              ],
            ),
          ),
      ],
    );
  }
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
      contextLabel: _copy(context, 'Sync support', 'Ajuda com a sincronização'),
      eyebrow: _copy(context, 'Connection', 'Ligação'),
      title: pairing.syncError == null
          ? _copy(
              context,
              'Ready for your next sync.',
              'Pronto para sincronizar.',
            )
          : _copy(context, 'Let’s get you connected.', 'Vamos voltar a ligar.'),
      intro: _copy(
        context,
        'Keep the ring near your phone, enable Bluetooth and close other apps connected to the ring.',
        'Mantenha o anel perto do telemóvel, ative o Bluetooth e feche outras aplicações ligadas ao anel.',
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
                'No sync error has been reported in this session.',
                'Nenhum erro de sincronização foi registado nesta sessão.',
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
  Widget build(BuildContext context) => RingPageScaffold(
    key: screenKey,
    activePath: activePath,
    scrollKey: screenKey.toString(),
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
      const SizedBox(height: 22),
      LibreRingEyebrow(eyebrow),
      const SizedBox(height: 8),
      Text(
        title,
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          color: LibreRingTokens.foreground,
          fontSize: 32,
          height: 1.1,
          letterSpacing: -.9,
        ),
      ),
      if (intro != null) ...<Widget>[
        const SizedBox(height: 12),
        Text(intro!, style: Theme.of(context).textTheme.bodyMedium),
      ],
      const SizedBox(height: 24),
      ...children,
    ],
  );
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.at,
    required this.title,
    required this.detail,
    required this.provenance,
    this.category = 'All',
    this.route,
  });
  final DateTime at;
  String get time => _clock(at);
  final String title;
  final String detail;
  final String provenance;
  final String category;
  final String? route;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});
  final _TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          event.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        if (event.detail.isNotEmpty)
          Text(
            event.detail,
            style: const TextStyle(fontSize: 13, color: LibreRingTokens.muted),
          ),
        const SizedBox(height: 6),
        Text(
          event.provenance,
          style: const TextStyle(fontSize: 12, color: LibreRingTokens.sage),
        ),
      ],
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LibreRingTokens.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: LibreRingTokens.muted,
                  ),
                ),
                const SizedBox(height: 8),
                content,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 58,
                  child: Text(
                    event.time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: LibreRingTokens.muted,
                    ),
                  ),
                ),
                Expanded(child: content),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: LibreRingTokens.muted,
                ),
              ],
            ),
    );
  }
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
