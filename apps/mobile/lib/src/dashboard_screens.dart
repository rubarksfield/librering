import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

import 'app_state.dart';
import 'presentation_data.dart';
import 'ring_analytics.dart';
import 'storage/preferences_repository.dart';
import 'ui/app_chrome.dart';

String _number(num value) =>
    NumberFormat.decimalPattern().format(value.round());
String _duration(num minutes) =>
    '${minutes.round() ~/ 60}h ${minutes.round() % 60}m';
String _clock(DateTime value) => DateFormat('HH:mm').format(value.toLocal());
String _dateRoute(String route, DateTime day) =>
    '$route?date=${DateFormat('yyyy-MM-dd').format(day)}';

class RefinedTodayScreen extends ConsumerStatefulWidget {
  const RefinedTodayScreen({super.key});
  @override
  ConsumerState<RefinedTodayScreen> createState() => _RefinedTodayScreenState();
}

class _RefinedTodayScreenState extends ConsumerState<RefinedTodayScreen>
    with WidgetsBindingObserver {
  DateTime? _day;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(currentLocalTimeProvider);
    }
  }

  Future<void> _sync() async {
    if (ref.read(isDemoModeProvider) ||
        ref.read(ringPairingProvider).syncInProgress) {
      return;
    }
    if (ref.read(ringPairingClientProvider) == null) {
      if (mounted) context.push('/pairing/scan');
      return;
    }
    await ref.read(ringPairingProvider.notifier).quickSync();
    if (!mounted) return;
    final error = ref.read(ringPairingProvider).syncError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Your ring is up to date.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(displayRingDataProvider);
    final now = ref.watch(currentLocalTimeProvider);
    final demo = ref.watch(isDemoModeProvider);
    final preferences =
        ref.watch(appPreferencesProvider).value ?? const AppPreferences();
    final pairing = ref.watch(ringPairingProvider);
    final dataset = data.value;
    final analytics = dataset == null
        ? null
        : RingAnalytics.fromDataset(dataset, localNow: now, selectedDay: _day);
    final day = analytics?.selectedDay ?? RingCalendar.day(now);
    final activity = analytics?.activityFor(day);
    final pulse = analytics?.pulseFor(day);
    final oxygen = analytics?.oxygenFor(day);
    final sleep = analytics?.sleepFor(day);
    final isToday = RingCalendar.sameDay(day, now);
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return RingPageScaffold(
      key: const Key('screen-today'),
      activePath: '/today',
      scrollKey: 'today',
      onRefresh: demo ? null : _sync,
      children: [
        _DashboardHeader(
          title: 'Today',
          subtitle:
              '${isToday ? greeting : DateFormat('EEEE').format(day)}${preferences.displayName.isEmpty ? '' : ', ${preferences.displayName}'}',
          trailing: _SyncButton(
            dataset: dataset,
            syncing: pairing.syncInProgress,
            demo: demo,
            onTap: _sync,
          ),
        ),
        if (demo) const _ExampleLabel(),
        if (data.isLoading && dataset == null)
          const RingLoadingState()
        else if (data.hasError && dataset == null)
          _ReadError(onRetry: () => ref.invalidate(ringDataProvider))
        else if (analytics == null)
          RingEmptyState(
            title: 'Your day starts here.',
            body: 'Connect your COLMI R12 to bring your sleep, movement and daily readings together.',
            action: 'Connect your ring',
            onAction: () => context.push('/pairing/scan'),
          )
        else ...[
          RingDaySelector(
            selectedDay: day,
            earliestDay: analytics.earliestDay,
            latestDay: RingCalendar.day(now),
            onChanged: (value) => setState(() => _day = value),
          ),
          const SizedBox(height: 14),
          if (pairing.syncError != null)
            _SyncNotice(onTap: () => context.push('/you/ring/sync-issue')),
          _SleepHero(
            sleep: sleep,
            dailyAsleepMinutes: analytics.asleepMinutesFor(day),
            sessionCount: analytics.sleepOn(day).length,
            day: day,
            target: preferences.sleepTargetMinutes,
            onTap: () => context.push(_dateRoute('/sleep', day)),
          ),
          const SizedBox(height: 22),
          RingSectionHeader(
            title: 'At a glance',
            action: 'All signals',
            onAction: () => context.go(_dateRoute('/vitals', day)),
          ),
          _MetricGrid(
            items: [
              _MetricTile(
                key: const Key('domain-movement'),
                title: 'Steps',
                value: activity?.hasRecords == true
                    ? _number(activity!.steps)
                    : '—',
                detail: activity?.hasRecords == true
                    ? 'of ${_number(preferences.dailyStepGoal)} daily goal'
                    : 'No reading this day',
                icon: Icons.directions_walk_rounded,
                color: LibreRingTokens.sage,
                onTap: () => context.push(_dateRoute('/activity', day)),
              ),
              _MetricTile(
                title: 'Pulse',
                value: pulse?.latest == null ? '—' : '${pulse!.latest}',
                unit: 'bpm',
                detail: pulse?.samples.isNotEmpty == true
                    ? 'Latest at ${_clock(pulse!.samples.last.at)}'
                    : 'No reading this day',
                icon: Icons.favorite_outline_rounded,
                color: LibreRingTokens.accent,
                onTap: () => context.push(_dateRoute('/heart', day)),
              ),
              _MetricTile(
                title: 'Blood oxygen',
                value: oxygen?.minimum == null
                    ? '—'
                    : '${oxygen!.minimum}–${oxygen.maximum}',
                unit: '%',
                detail: 'Recorded range',
                icon: Icons.water_drop_outlined,
                color: const Color(0xFF527C91),
                onTap: () => context.push(_dateRoute('/oxygen', day)),
              ),
              _MetricTile(
                title: 'Distance',
                value: activity?.hasRecords == true
                    ? preferences.formatDistance(activity!.distanceMeters)
                    : '—',
                detail: 'Estimated by your ring',
                icon: Icons.route_outlined,
                color: LibreRingTokens.sage,
                onTap: () => context.push(_dateRoute('/activity', day)),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (activity?.hasRecords == true) ...[
            _MovementGoal(
              activity: activity!,
              preferences: preferences,
              onTap: () => context.push('/you/profile'),
            ),
            const SizedBox(height: 22),
          ],
          RingSectionHeader(title: 'Make sense of your day'),
          _ActionRow(
            icon: Icons.timeline_rounded,
            title: 'Your daily timeline',
            subtitle: 'Sleep, readings and the moments you add',
            onTap: () => context.push(_dateRoute('/day-timeline', day)),
          ),
          const SizedBox(height: 10),
          _ActionRow(
            icon: Icons.edit_note_rounded,
            title: 'How are you feeling?',
            subtitle: 'A quick check-in for your personal journal',
            onTap: () => context.push('/journal/check-in'),
          ),
          const SizedBox(height: 22),
          const RingSectionHeader(title: 'From your ring'),
          _IndexRows(analytics: analytics, day: day),
          const SizedBox(height: 16),
          _DataFootnote(dataset: dataset!, now: now, demo: demo),
        ],
      ],
    );
  }
}

class RefinedVitalsScreen extends ConsumerStatefulWidget {
  const RefinedVitalsScreen({super.key});
  @override
  ConsumerState<RefinedVitalsScreen> createState() =>
      _RefinedVitalsScreenState();
}

class _RefinedVitalsScreenState extends ConsumerState<RefinedVitalsScreen> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(displayRingDataProvider);
    final now = ref.watch(currentLocalTimeProvider);
    final prefs =
        ref.watch(appPreferencesProvider).value ?? const AppPreferences();
    final dataset = data.value;
    final query = GoRouterState.of(context).uri.queryParameters['date'];
    final parsed =
        query != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(query)
        ? DateTime.tryParse(query)
        : null;
    final requestedDay =
        parsed != null && DateFormat('yyyy-MM-dd').format(parsed) == query
        ? parsed
        : null;
    final analytics = dataset == null
        ? null
        : RingAnalytics.fromDataset(
            dataset,
            localNow: now,
            selectedDay: requestedDay,
          );
    final day = analytics?.selectedDay ?? RingCalendar.day(now);
    final pulse = analytics?.pulseFor(day);
    final oxygen = analytics?.oxygenFor(day);
    final activity = analytics?.activityFor(day);
    final sleep = analytics?.sleepFor(day);
    return RingPageScaffold(
      key: const Key('screen-metrics'),
      activePath: '/vitals',
      scrollKey: 'vitals',
      children: [
        _DashboardHeader(
          title: 'Vitals',
          subtitle: 'A closer look at you',
          trailing: IconButton(
            tooltip: 'About your readings',
            onPressed: () => showRingInfo(
              context,
              title: 'About your readings',
              body: 'Pulse samples and hourly oxygen ranges come from your ring. Sleep stages, steps, distance and calories are ring estimates. HRV and stress are firmware indexes with unverified units and thresholds.\n\nMissing readings stay empty. Tap any signal to see its history and source details.',
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ),
        if (ref.watch(isDemoModeProvider)) const _ExampleLabel(),
        if (data.isLoading && dataset == null)
          const RingLoadingState()
        else if (data.hasError && dataset == null)
          _ReadError(onRetry: () => ref.invalidate(ringDataProvider))
        else if (analytics == null)
          RingEmptyState(
            title: 'Meet your daily signals.',
            body: 'Your readings will appear here after the first sync.',
            action: 'Connect your ring',
            onAction: () => context.push('/pairing/scan'),
          )
        else ...[
          RingDaySelector(
            selectedDay: day,
            earliestDay: analytics.earliestDay,
            latestDay: RingCalendar.day(now),
            onChanged: (value) => context.go(_dateRoute('/vitals', value)),
          ),
          const SizedBox(height: 16),
          _MetricGrid(
            items: [
              _MetricTile(
                title: 'Pulse',
                value: pulse?.latest == null ? '—' : '${pulse!.latest}',
                unit: 'bpm',
                detail: pulse?.mean == null
                    ? 'No reading this day'
                    : '${pulse!.mean} bpm average',
                icon: Icons.favorite_outline_rounded,
                color: LibreRingTokens.accent,
                onTap: () => context.push(_dateRoute('/heart', day)),
              ),
              _MetricTile(
                title: 'Blood oxygen',
                value: oxygen?.minimum == null
                    ? '—'
                    : '${oxygen!.minimum}–${oxygen.maximum}',
                unit: '%',
                detail: '${oxygen?.ranges.length ?? 0} hourly ranges',
                icon: Icons.water_drop_outlined,
                color: const Color(0xFF527C91),
                onTap: () => context.push(_dateRoute('/oxygen', day)),
              ),
              _MetricTile(
                key: const Key('domain-sleep'),
                title: 'Sleep',
                value: analytics.asleepMinutesFor(day) == null
                    ? '—'
                    : _duration(analytics.asleepMinutesFor(day)!),
                detail: sleep == null
                    ? 'No session this day'
                    : analytics.asleepMinutesFor(day) == null
                    ? 'Sleep stages unavailable'
                    : '${analytics.sleepOn(day).length} recorded ${analytics.sleepOn(day).length == 1 ? 'session' : 'sessions'} · estimated asleep',
                icon: Icons.bedtime_outlined,
                color: LibreRingTokens.sage,
                onTap: () => context.push(_dateRoute('/sleep', day)),
              ),
              _MetricTile(
                title: 'Steps',
                value: activity?.hasRecords == true
                    ? _number(activity!.steps)
                    : '—',
                detail: 'Ring estimate',
                icon: Icons.directions_walk_rounded,
                color: LibreRingTokens.sage,
                onTap: () => context.push(_dateRoute('/activity', day)),
              ),
              _MetricTile(
                title: 'Distance',
                value: activity?.hasRecords == true
                    ? prefs.formatDistance(activity!.distanceMeters)
                    : '—',
                detail: 'Ring estimate',
                icon: Icons.route_outlined,
                color: LibreRingTokens.sage,
                onTap: () => context.push(_dateRoute('/activity', day)),
              ),
              _MetricTile(
                title: 'Energy',
                value: activity?.hasRecords == true
                    ? '${activity!.firmwareCalories}'
                    : '—',
                unit: 'kcal',
                detail: 'Ring estimate',
                icon: Icons.local_fire_department_outlined,
                color: LibreRingTokens.accent,
                onTap: () => context.push(_dateRoute('/activity', day)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const RingSectionHeader(title: 'Firmware indexes'),
          _IndexRows(analytics: analytics, day: day),
          const SizedBox(height: 18),
          _ActionRow(
            icon: Icons.sensors_outlined,
            title: 'What your ring supports',
            subtitle: 'Data sources and supported features',
            onTap: () => context.push('/you/ring/capabilities'),
          ),
          const SizedBox(height: 16),
          _DataFootnote(
            dataset: dataset!,
            now: now,
            demo: ref.watch(isDemoModeProvider),
          ),
        ],
      ],
    );
  }
}

enum _TrendMetric { sleep, steps, pulse, oxygen, hrv, stress }

class RefinedTrendsScreen extends ConsumerStatefulWidget {
  const RefinedTrendsScreen({super.key});
  @override
  ConsumerState<RefinedTrendsScreen> createState() =>
      _RefinedTrendsScreenState();
}

class _RefinedTrendsScreenState extends ConsumerState<RefinedTrendsScreen> {
  int _days = 30;
  int? _selected;
  _TrendMetric _metric = _TrendMetric.sleep;
  String get _name => switch (_metric) {
    _TrendMetric.sleep => 'Sleep',
    _TrendMetric.steps => 'Steps',
    _TrendMetric.pulse => 'Pulse',
    _TrendMetric.oxygen => 'Oxygen',
    _TrendMetric.hrv => 'HRV index',
    _TrendMetric.stress => 'Stress index',
  };
  String get _unit => switch (_metric) {
    _TrendMetric.sleep => 'estimated asleep',
    _TrendMetric.steps => 'steps',
    _TrendMetric.pulse => 'bpm',
    _TrendMetric.oxygen => '% minimum',
    _ => 'index',
  };
  String get _route => switch (_metric) {
    _TrendMetric.sleep => '/sleep',
    _TrendMetric.steps => '/activity',
    _TrendMetric.pulse => '/heart',
    _TrendMetric.oxygen => '/oxygen',
    _TrendMetric.hrv => '/signals/hrv-index',
    _TrendMetric.stress => '/signals/stress-index',
  };
  String _format(double? value) => value == null
      ? '—'
      : _metric == _TrendMetric.sleep
      ? _duration(value)
      : _number(value);
  double? _value(RingAnalytics analytics, DateTime day) => switch (_metric) {
    _TrendMetric.sleep => analytics.asleepMinutesFor(day)?.toDouble(),
    _TrendMetric.steps =>
      analytics.activityFor(day).hasRecords
          ? analytics.activityFor(day).steps.toDouble()
          : null,
    _TrendMetric.pulse => analytics.pulseFor(day).mean?.toDouble(),
    _TrendMetric.oxygen => analytics.oxygenFor(day).minimum?.toDouble(),
    _TrendMetric.hrv =>
      analytics
          .vendorIndexFor(day, RingVendorIndexKind.firmwareHrv)
          .median
          ?.toDouble(),
    _TrendMetric.stress =>
      analytics
          .vendorIndexFor(day, RingVendorIndexKind.stress)
          .median
          ?.toDouble(),
  };
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(displayRingDataProvider);
    final now = ref.watch(currentLocalTimeProvider);
    final analytics = data.value == null
        ? null
        : RingAnalytics.fromDataset(data.value!, localNow: now);
    final dates = List.generate(
      _days,
      (i) => RingCalendar.shift(RingCalendar.day(now), i - _days + 1),
    );
    final values = analytics == null
        ? <double?>[]
        : dates.map((day) => _value(analytics, day)).toList();
    final known = values.whereType<double>().toList();
    final average = known.isEmpty
        ? null
        : known.reduce((a, b) => a + b) / known.length;
    final priorDates = List.generate(
      _days,
      (i) => RingCalendar.shift(dates.first, i - _days),
    );
    final prior = analytics == null
        ? <double>[]
        : priorDates
              .map((day) => _value(analytics, day))
              .whereType<double>()
              .toList();
    final priorAverage = prior.isEmpty
        ? null
        : prior.reduce((a, b) => a + b) / prior.length;
    final inspected = _selected != null && _selected! < values.length
        ? _selected
        : null;
    final shown = inspected == null ? average : values[inspected];
    return RingPageScaffold(
      key: const Key('screen-trends'),
      activePath: '/trends',
      scrollKey: 'trends',
      children: [
        _DashboardHeader(
          title: 'Trends',
          subtitle: 'Your patterns, over time',
          trailing: IconButton(
            tooltip: 'How trends work',
            onPressed: () => showRingInfo(
              context,
              title: 'Your history, clearly',
              body: 'Each point represents one calendar day. Missing days remain gaps, and recorded zero steps remain zero.\n\nSleep adds the classified asleep minutes of sessions ending that day. Pulse uses the daily sample mean. Oxygen shows the lowest value in the day’s hourly ranges. Firmware indexes use a daily median.\n\nPeriod averages and comparisons use recorded days only. Different amounts of wear time can affect comparisons.',
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ),
        if (ref.watch(isDemoModeProvider)) const _ExampleLabel(),
        if (data.isLoading && data.value == null)
          const RingLoadingState()
        else if (data.hasError && data.value == null)
          _ReadError(onRetry: () => ref.invalidate(ringDataProvider))
        else if (analytics == null)
          RingEmptyState(
            title: 'Small days. Bigger picture.',
            body: 'Sync your ring to start exploring patterns in your sleep, activity and readings.',
            action: 'Connect your ring',
            onAction: () => context.push('/pairing/scan'),
          )
        else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _TrendMetric.values
                  .map(
                    (metric) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(switch (metric) {
                          _TrendMetric.sleep => 'Sleep',
                          _TrendMetric.steps => 'Steps',
                          _TrendMetric.pulse => 'Pulse',
                          _TrendMetric.oxygen => 'Oxygen',
                          _TrendMetric.hrv => 'HRV index',
                          _TrendMetric.stress => 'Stress index',
                        }),
                        selected: _metric == metric,
                        showCheckmark: false,
                        selectedColor: LibreRingTokens.sageSoft,
                        onSelected: (_) => setState(() {
                          _metric = metric;
                          _selected = null;
                        }),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              key: const Key('trend-range-selector'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 7, label: Text('7 days')),
                ButtonSegment(value: 30, label: Text('30 days')),
                ButtonSegment(value: 90, label: Text('90 days')),
              ],
              selected: {_days},
              onSelectionChanged: (value) => setState(() {
                _days = value.first;
                _selected = null;
              }),
            ),
          ),
          const SizedBox(height: 22),
          LibreRingCard(
            key: Key(
              'trend-${_metric == _TrendMetric.steps ? 'movement' : _metric.name}',
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inspected == null
                      ? '$_name · recorded-day average'
                      : DateFormat('EEEE, d MMM').format(dates[inspected]),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  children: [
                    Text(
                      _format(shown),
                      key: const Key('trend-inspected-value'),
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -1.8,
                        height: 1.1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        _unit,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (known.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No readings in this period. Try another range.',
                    ),
                  )
                else
                  RingHistoryChart(
                    values: values,
                    labels: dates
                        .map((date) => DateFormat('d MMM').format(date))
                        .toList(),
                    selected: inspected,
                    formatter: _format,
                    axisFormatter: _metric == _TrendMetric.sleep
                        ? (value) =>
                              '${value.round() ~/ 60}h${(value.round() % 60).toString().padLeft(2, '0')}'
                        : _number,
                    onSelected: (index) => setState(() => _selected = index),
                  ),
                const SizedBox(height: 14),
                Text(
                  '${known.length} of the last $_days days recorded',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (inspected != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () =>
                        context.push(_dateRoute(_route, dates[inspected])),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    label: const Text('Explore this day'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selected = null),
                    child: const Text('Back to period average'),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Tap the chart to explore a day.',
                      style: TextStyle(
                        fontSize: 12,
                        color: LibreRingTokens.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (average != null)
            LibreRingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The bigger picture',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _SummaryLine(
                    label: 'Lowest recorded day',
                    value: _format(known.reduce(math.min)),
                  ),
                  _SummaryLine(
                    label: 'Highest recorded day',
                    value: _format(known.reduce(math.max)),
                  ),
                  if (priorAverage != null) ...[
                    const Divider(height: 28),
                    _SummaryLine(
                      label: 'Previous $_days days',
                      value: _format(priorAverage),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${prior.length} recorded days in the previous period. Comparisons reflect available readings, not complete wear time.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      'A comparison will appear once there are readings in the previous period.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 22),
          _ActionRow(
            key: const Key('trend-add-context'),
            icon: Icons.edit_note_rounded,
            title: 'Keep a little context',
            subtitle: 'Add a check-in, activity or note to your journal',
            onTap: () => context.push('/journal'),
          ),
        ],
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Padding(padding: const EdgeInsets.only(left: 12), child: trailing!),
      ],
    ),
  );
}

class _ExampleLabel extends StatelessWidget {
  const _ExampleLabel();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 10),
    child: Text(
      'Example data · explore how LibreRing works',
      style: TextStyle(fontSize: 12, color: LibreRingTokens.accent),
    ),
  );
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({
    required this.dataset,
    required this.syncing,
    required this.demo,
    required this.onTap,
  });
  final RingSyncDataset? dataset;
  final bool syncing;
  final bool demo;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: demo
        ? 'Example battery, ${dataset?.batteryLevel ?? 78} percent'
        : syncing
        ? 'Syncing your ring'
        : 'Sync ring${dataset?.batteryLevel == null ? '' : ', last reported battery ${dataset!.batteryLevel} percent'}',
    button: true,
    enabled: !syncing && !demo,
    onTap: syncing || demo ? null : onTap,
    excludeSemantics: true,
    child: TextButton.icon(
      key: const Key('today-quick-sync'),
      style: TextButton.styleFrom(
        backgroundColor: LibreRingTokens.sageSoft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: syncing || demo ? null : onTap,
      icon: syncing
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync_rounded, size: 18),
      label: Text(
        syncing
            ? 'Syncing'
            : dataset?.batteryLevel == null
            ? 'Sync'
            : '${dataset!.batteryLevel}%',
        style: const TextStyle(fontSize: 12),
      ),
    ),
  );
}

class _ReadError extends StatelessWidget {
  const _ReadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => RingEmptyState(
    key: const Key('data-read-error'),
    title: 'Your history needs a moment.',
    body: 'We couldn’t open the saved data. Try again, or visit your ring settings for help.',
    icon: Icons.cloud_off_outlined,
    action: 'Try again',
    onAction: onRetry,
  );
}

class _SyncNotice extends StatelessWidget {
  const _SyncNotice({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: _ActionRow(
      icon: Icons.sync_problem_rounded,
      title: 'Couldn’t refresh your ring',
      subtitle: 'Your saved readings are still available',
      onTap: onTap,
    ),
  );
}

class _SleepHero extends StatelessWidget {
  const _SleepHero({
    required this.sleep,
    required this.dailyAsleepMinutes,
    required this.sessionCount,
    required this.day,
    required this.target,
    required this.onTap,
  });
  final SleepAnalytics? sleep;
  final int? dailyAsleepMinutes;
  final int sessionCount;
  final DateTime day;
  final int target;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    onTap: onTap,
    excludeSemantics: true,
    label: sleep == null
        ? 'Sleep, no session this day'
        : '${dailyAsleepMinutes == null ? 'Latest recorded sleep window' : 'Daily estimated sleep'}, ${_duration(dailyAsleepMinutes ?? sleep!.intervalMinutes)} from $sessionCount ${sessionCount == 1 ? 'session' : 'sessions'}. Open sleep detail',
    child: Material(
      color: LibreRingTokens.sageSoft,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        key: const Key('daily-signal'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bedtime_outlined,
                    size: 19,
                    color: LibreRingTokens.sage,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Your sleep',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_outward_rounded, size: 20),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                sleep == null
                    ? 'No sleep recorded.'
                    : _duration(dailyAsleepMinutes ?? sleep!.intervalMinutes),
                style: TextStyle(
                  fontSize: sleep == null ? 29 : 46,
                  height: 1.1,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sleep == null
                    ? 'No session for ${DateFormat('d MMM').format(day)}. Wear your ring overnight and sync to see your sleep.'
                    : sessionCount > 1
                    ? '$sessionCount sessions · ${dailyAsleepMinutes == null ? 'stages unavailable' : 'total estimated asleep'}'
                    : '${_clock(sleep!.session.startedAtUtc)}–${_clock(sleep!.session.endedAtUtc)} · ${dailyAsleepMinutes == null ? 'recorded window · stages unavailable' : 'estimated asleep'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: LibreRingTokens.muted,
                ),
              ),
              if (sleep != null) ...[
                const SizedBox(height: 20),
                if (sessionCount > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Latest session · ${_clock(sleep!.session.startedAtUtc)}–${_clock(sleep!.session.endedAtUtc)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 24,
                    child: CustomPaint(
                      size: const Size(double.infinity, 24),
                      painter: _SleepRibbonPainter(sleep!),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  dailyAsleepMinutes == null
                      ? 'No sleep-stage estimate available'
                      : '${dailyAsleepMinutes! >= target ? 'Your sleep target was met' : '${_duration(target)} personal sleep target'}${sleep!.unclassifiedMinutes > 0 ? ' · partial stages' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: LibreRingTokens.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _SleepRibbonPainter extends CustomPainter {
  _SleepRibbonPainter(this.sleep);
  final SleepAnalytics sleep;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = LibreRingTokens.border,
    );
    if (sleep.intervalMinutes <= 0) return;
    for (final span in sleep.stages) {
      final left =
          span.startedAtUtc.difference(sleep.session.startedAtUtc).inSeconds /
          (sleep.intervalMinutes * 60) *
          size.width;
      final width = span.durationMinutes / sleep.intervalMinutes * size.width;
      canvas.drawRect(
        Rect.fromLTWH(left, 0, math.max(0, width - 1), size.height),
        Paint()
          ..color = switch (span.stage) {
            RingSleepStage.deep => LibreRingTokens.sage,
            RingSleepStage.light => const Color(0xFFA0B69C),
            RingSleepStage.rem => const Color(0xFFCDD8C5),
            RingSleepStage.awake => LibreRingTokens.accent,
          },
      );
    }
  }

  @override
  bool shouldRepaint(_SleepRibbonPainter oldDelegate) =>
      oldDelegate.sleep != sleep;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});
  final List<Widget> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
              constraints.maxWidth < 280
          ? 1
          : 2;
      return Column(
        children: [
          for (var i = 0; i < items.length; i += columns)
            Padding(
              padding: EdgeInsets.only(
                bottom: i + columns < items.length ? 12 : 0,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < columns; j++) ...[
                      if (j > 0) const SizedBox(width: 12),
                      Expanded(
                        child: i + j < items.length
                            ? items[i + j]
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
    this.unit,
    super.key,
  });
  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final String? unit;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title, $value ${unit ?? ''}, $detail',
    onTap: onTap,
    excludeSemantics: true,
    child: Material(
      color: LibreRingTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: LibreRingTokens.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -1,
                      height: 1.15,
                    ),
                  ),
                  if (unit != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        unit!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 11,
                  color: LibreRingTokens.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MovementGoal extends StatelessWidget {
  const _MovementGoal({
    required this.activity,
    required this.preferences,
    required this.onTap,
  });
  final ActivityDay activity;
  final AppPreferences preferences;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => LibreRingCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'A little movement adds up.',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              tooltip: 'Edit your daily goals',
              onPressed: onTap,
              icon: const Icon(Icons.tune_rounded, size: 19),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: (activity.steps / preferences.dailyStepGoal).clamp(0, 1),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          color: LibreRingTokens.sage,
          backgroundColor: LibreRingTokens.sageSoft,
          semanticsLabel:
              'Daily step goal, ${_number(activity.steps)} of ${_number(preferences.dailyStepGoal)} steps',
        ),
        const SizedBox(height: 12),
        Text(
          activity.steps >= preferences.dailyStepGoal
              ? 'Daily goal reached · ${_number(activity.steps)} steps'
              : '${_number(math.max(0, preferences.dailyStepGoal - activity.steps))} steps to your daily goal',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _IndexRows extends StatelessWidget {
  const _IndexRows({required this.analytics, required this.day});
  final RingAnalytics analytics;
  final DateTime day;
  @override
  Widget build(BuildContext context) => LibreRingCard(
    child: Column(
      children: [
        for (final kind in RingVendorIndexKind.values) ...[
          if (kind != RingVendorIndexKind.values.first)
            const Divider(height: 20),
          _ActionRow(
            plain: true,
            icon: kind == RingVendorIndexKind.stress
                ? Icons.spa_outlined
                : Icons.monitor_heart_outlined,
            title: kind == RingVendorIndexKind.stress
                ? 'Stress index'
                : 'HRV index',
            subtitle: 'Firmware index · unvalidated',
            value: '${analytics.vendorIndexFor(day, kind).latest ?? '—'}',
            onTap: () => context.push(
              _dateRoute(
                kind == RingVendorIndexKind.stress
                    ? '/signals/stress-index'
                    : '/signals/hrv-index',
                day,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.value,
    this.plain = false,
    super.key,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? value;
  final bool plain;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    onTap: onTap,
    label: '$title${value == null ? '' : ', $value'}. $subtitle',
    excludeSemantics: true,
    child: Material(
      color: plain ? Colors.transparent : LibreRingTokens.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: plain ? 0 : 16,
            vertical: plain ? 8 : 17,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: LibreRingTokens.sage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LibreRingTokens.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    value!,
                    style: const TextStyle(fontSize: 25, letterSpacing: -1),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: LibreRingTokens.muted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _DataFootnote extends StatelessWidget {
  const _DataFootnote({
    required this.dataset,
    required this.now,
    required this.demo,
  });
  final RingSyncDataset dataset;
  final DateTime now;
  final bool demo;
  @override
  Widget build(BuildContext context) {
    final synced = dataset.lastSyncedAtUtc.toLocal();
    return TextButton.icon(
      onPressed: () => context.push('/you/ring'),
      icon: const Icon(Icons.lock_outline_rounded, size: 13),
      label: Text(
        demo
            ? 'Fictional example data'
            : 'On this phone · synced ${RingCalendar.sameDay(synced, now) ? _clock(synced) : DateFormat('d MMM, HH:mm').format(synced)}',
        style: const TextStyle(fontSize: 12, color: LibreRingTokens.muted),
      ),
    );
  }
}

/// Calendar-spaced values, including explicit gaps. Values are also reachable
/// through screen-reader increase/decrease actions and keyboard arrow keys.
class RingHistoryChart extends StatelessWidget {
  const RingHistoryChart({
    required this.values,
    required this.labels,
    required this.selected,
    required this.formatter,
    required this.onSelected,
    this.axisFormatter,
    super.key,
  });
  final List<double?> values;
  final List<String> labels;
  final int? selected;
  final String Function(double?) formatter;
  final String Function(double)? axisFormatter;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final known = values.whereType<double>().toList();
    if (known.isEmpty) return const SizedBox(height: 180);
    final current = selected ?? values.lastIndexWhere((value) => value != null);
    void step(int delta) =>
        onSelected((current + delta).clamp(0, values.length - 1));
    return Column(
      children: [
        Semantics(
          label: 'Daily history chart',
          value: '${labels[current]}, ${formatter(values[current])}',
          increasedValue: current < values.length - 1
              ? '${labels[current + 1]}, ${formatter(values[current + 1])}'
              : null,
          decreasedValue: current > 0
              ? '${labels[current - 1]}, ${formatter(values[current - 1])}'
              : null,
          onIncrease: current < values.length - 1 ? () => step(1) : null,
          onDecrease: current > 0 ? () => step(-1) : null,
          child: Focus(
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                step(1);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                step(-1);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                void choose(Offset point) {
                  final index =
                      ((point.dx - 4) /
                              math.max(1, constraints.maxWidth - 42) *
                              (values.length - 1))
                          .round()
                          .clamp(0, values.length - 1);
                  onSelected(index);
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (event) => choose(event.localPosition),
                  onHorizontalDragUpdate: (event) =>
                      choose(event.localPosition),
                  child: SizedBox(
                    height: 188,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _HistoryPainter(
                        values: values,
                        selected: selected,
                        axisFormatter: axisFormatter ?? _number,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                labels.first,
                style: const TextStyle(
                  fontSize: 11,
                  color: LibreRingTokens.muted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                labels.last,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 11,
                  color: LibreRingTokens.muted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter({
    required this.values,
    required this.selected,
    required this.axisFormatter,
  });
  final List<double?> values;
  final int? selected;
  final String Function(double) axisFormatter;
  @override
  void paint(Canvas canvas, Size size) {
    final known = values.whereType<double>().toList();
    if (known.isEmpty) return;
    final min = known.reduce(math.min);
    final max = known.reduce(math.max);
    final spread = math.max(4.0, max - min);
    final low = math.max(0.0, min - spread * .15);
    final high = max + spread * .15;
    final width = size.width - 34;
    final height = size.height - 20;
    for (var i = 0; i < 3; i++) {
      final y = 10 + height * i / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        Paint()
          ..color = LibreRingTokens.border
          ..strokeWidth = 1,
      );
      final label = TextPainter(
        text: TextSpan(
          text: axisFormatter(high - (high - low) * i / 2),
          style: const TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 10,
            color: LibreRingTokens.muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 32);
      label.paint(canvas, Offset(width + 4, y - label.height / 2));
    }
    Offset point(int i, double v) => Offset(
      4 + (width - 8) * i / math.max(1, values.length - 1),
      10 + height * (1 - (v - low) / (high - low)),
    );
    final stroke = Paint()
      ..color = LibreRingTokens.sage
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    Offset? previous;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) {
        previous = null;
        continue;
      }
      final p = point(i, value);
      if (previous != null) canvas.drawLine(previous, p, stroke);
      canvas.drawCircle(
        p,
        i == selected ? 5 : 3,
        Paint()
          ..color = i == selected
              ? LibreRingTokens.accent
              : LibreRingTokens.sage,
      );
      previous = p;
    }
    if (selected != null) {
      final x = point(selected!, values[selected!] ?? low).dx;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = LibreRingTokens.accent.withValues(alpha: .25)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_HistoryPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.selected != selected ||
      oldDelegate.axisFormatter != axisFormatter;
}
