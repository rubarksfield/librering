import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

import 'app_state.dart';
import 'presentation_data.dart';
import 'ring_analytics.dart';
import 'storage/journal_repository.dart';
import 'storage/preferences_repository.dart';
import 'ui/app_chrome.dart';

const _sage = Color(0xFF62806A);

/// All detail pages browse explicit calendar dates, including empty days.
/// They never silently substitute an older reading for today's reading.
mixin _CalendarDetail<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  DateTime? selectedDate;
  int days = 1;

  RingAnalytics? get analytics {
    final dataset = ref.watch(displayRingDataProvider).value;
    if (dataset == null) return null;
    return RingAnalytics.fromDataset(
      dataset,
      localNow: ref.watch(currentLocalTimeProvider),
      selectedDay: selectedDay,
    );
  }

  DateTime get selectedDay {
    final today = RingCalendar.day(ref.watch(currentLocalTimeProvider));
    final query = GoRouterState.of(context).uri.queryParameters['date'];
    DateTime? requested;
    if (query != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(query)) {
      final parsed = DateTime.tryParse(query);
      if (parsed != null && DateFormat('yyyy-MM-dd').format(parsed) == query) {
        requested = parsed;
      }
    }
    final selected = RingCalendar.day(selectedDate ?? requested ?? today);
    return selected.isAfter(today) ? today : selected;
  }

  Widget calendar(RingAnalytics? data, {bool ranges = true}) => Column(
    children: <Widget>[
      RingDaySelector(
        selectedDay: selectedDay,
        earliestDay: data?.earliestDay ?? selectedDay,
        latestDay: RingCalendar.day(ref.watch(currentLocalTimeProvider)),
        onChanged: (value) => setState(() => selectedDate = value),
      ),
      if (ranges) ...<Widget>[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            key: const Key('analytics-range-selector'),
            showSelectedIcon: false,
            segments: const <ButtonSegment<int>>[
              ButtonSegment(value: 1, label: Text('Day')),
              ButtonSegment(value: 7, label: Text('Week')),
              ButtonSegment(value: 30, label: Text('Month')),
            ],
            selected: <int>{days},
            onSelectionChanged: (value) => setState(() => days = value.first),
          ),
        ),
      ],
      const SizedBox(height: 24),
    ],
  );

  DateTime get start => RingCalendar.shift(selectedDay, -(days - 1));
  DateTime get end => RingCalendar.shift(selectedDay, 1);
  String get periodLabel => days == 1
      ? DateFormat('EEEE, d MMM').format(selectedDay)
      : '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM').format(selectedDay)}';
}

class ActivityLabScreen extends ConsumerStatefulWidget {
  const ActivityLabScreen({super.key});
  @override
  ConsumerState<ActivityLabScreen> createState() => _ActivityLabScreenState();
}

class _ActivityLabScreenState extends ConsumerState<ActivityLabScreen>
    with _CalendarDetail<ActivityLabScreen> {
  @override
  Widget build(BuildContext context) {
    final data = analytics;
    final history = data?.activityHistory(days: days) ?? <ActivityDay>[];
    final preferences =
        ref.watch(appPreferencesProvider).value ?? const AppPreferences();
    final distanceDivisor = preferences.unitSystem == UnitSystem.imperial
        ? 1609.344
        : 1000;
    final distanceUnit = preferences.unitSystem == UnitSystem.imperial
        ? 'mi'
        : 'km';
    final present = history.where((value) => value.buckets.isNotEmpty).toList();
    final steps = present.fold(0, (sum, value) => sum + value.steps);
    final meters = present.fold(0, (sum, value) => sum + value.distanceMeters);
    final kcal = present.fold(0, (sum, value) => sum + value.firmwareCalories);
    List<RingChartPoint> points(
      int Function(HourlyActivityValue) hourly,
      int Function(ActivityDay) daily,
    ) => days == 1
        ? <RingChartPoint>[
            for (final hour
                in history.firstOrNull?.hourly ?? <HourlyActivityValue>[])
              if (hour.hasRecord)
                RingChartPoint(
                  at: hour.startedAt,
                  value: hourly(hour).toDouble(),
                ),
          ]
        : <RingChartPoint>[
            for (final day in present)
              RingChartPoint(
                at: _midday(day.day),
                value: daily(day).toDouble(),
                label: '${DateFormat('d MMM').format(day.day)} · Daily total',
              ),
          ];
    return _AnalyticsScreen(
      key: const Key('screen-movement'),
      activePath: '/vitals',
      children: <Widget>[
        const _AnalyticsTopBar(title: 'Activity', fallbackPath: '/vitals'),
        calendar(data),
        _MetricHeader(
          label: days == 1 ? 'Steps' : 'Total steps',
          value: present.isEmpty
              ? '—'
              : NumberFormat.decimalPattern().format(steps),
          note: present.isEmpty
              ? 'No activity recorded for this period'
              : periodLabel,
          icon: Icons.directions_walk_rounded,
          color: _sage,
        ),
        const SizedBox(height: 20),
        if (present.isEmpty)
          const _EmptyCard(
            'No activity has been received for this period. Try another date or sync your ring.',
          )
        else ...<Widget>[
          if (days == 1) ...<Widget>[
            _GoalProgress(
              value: steps,
              target: preferences.dailyStepGoal,
              label: 'Your daily step goal',
              targetLabel:
                  '${NumberFormat.decimalPattern().format(preferences.dailyStepGoal)} steps',
              color: _sage,
            ),
            const SizedBox(height: 20),
          ],
          _HeroMetricCard(
            title: days == 1 ? 'Hour by hour' : 'Daily activity',
            child: RingHistoryChart(
              key: const Key('activity-steps-chart'),
              points: points((h) => h.steps, (d) => d.steps),
              start: start,
              end: end,
              unit: 'steps',
              kind: RingChartKind.bars,
              color: _sage,
            ),
          ),
          const SizedBox(height: 14),
          _HeroMetricCard(
            title: 'Movement summary',
            child: _ThreeStats(
              values: <_StatValue>[
                _StatValue(preferences.formatDistance(meters), 'Distance'),
                _StatValue('$kcal kcal', 'Active energy'),
                _StatValue(
                  days == 1
                      ? '${present.first.coveredHours}'
                      : '${present.length}',
                  days == 1 ? 'Hours recorded' : 'Days recorded',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _HeroMetricCard(
            title: 'Distance',
            child: RingHistoryChart(
              points: points((h) => h.distanceMeters, (d) => d.distanceMeters)
                  .map(
                    (p) => RingChartPoint(
                      at: p.at,
                      value: p.value / distanceDivisor,
                      label: p.label,
                    ),
                  )
                  .toList(),
              start: start,
              end: end,
              unit: distanceUnit,
              kind: RingChartKind.bars,
              color: _sage,
            ),
          ),
          const SizedBox(height: 14),
          _HeroMetricCard(
            title: 'Active energy',
            child: RingHistoryChart(
              points: points(
                (h) => h.firmwareCalories,
                (d) => d.firmwareCalories,
              ),
              start: start,
              end: end,
              unit: 'kcal',
              kind: RingChartKind.bars,
              color: LibreRingTokens.accent,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _ActionRow(
          icon: Icons.add_rounded,
          title: 'Add an activity',
          subtitle: 'Keep a personal record of your workout',
          onTap: () => context.push('/activity/sports'),
        ),
        const _SourceDisclosure(
          'Steps, distance and active energy are estimates from your ring. '
          'The chart shows recorded hours only; a gap means no record was received. '
          'Active energy is not food intake or total daily energy expenditure.',
        ),
      ],
    );
  }
}

class SleepLabScreen extends ConsumerStatefulWidget {
  const SleepLabScreen({super.key});
  @override
  ConsumerState<SleepLabScreen> createState() => _SleepLabScreenState();
}

class _SleepLabScreenState extends ConsumerState<SleepLabScreen>
    with _CalendarDetail<SleepLabScreen> {
  DateTime? _sessionEnd;
  @override
  Widget build(BuildContext context) {
    final data = analytics;
    final sessions = data?.sleepOn(selectedDay) ?? <SleepAnalytics>[];
    final preferences =
        ref.watch(appPreferencesProvider).value ?? const AppPreferences();
    final sleep =
        sessions
            .where((s) => s.session.endedAtUtc == _sessionEnd)
            .firstOrNull ??
        data?.sleepFor(selectedDay);
    final session = sleep?.session;
    return _AnalyticsScreen(
      key: const Key('screen-sleep'),
      activePath: '/vitals',
      children: <Widget>[
        const _AnalyticsTopBar(title: 'Sleep', fallbackPath: '/vitals'),
        calendar(data, ranges: false),
        _MetricHeader(
          label: sleep?.stages.isEmpty == true
              ? 'Recorded sleep window'
              : 'Estimated time asleep',
          value: sleep == null
              ? '—'
              : _minutes(
                  sleep.stages.isEmpty
                      ? sleep.intervalMinutes
                      : sleep.asleepStageMinutes,
                ),
          note: session == null
              ? 'No sleep recorded for this date'
              : '${_clock(session.startedAtUtc)} – ${_clock(session.endedAtUtc)} · Sleep window ${_minutes(sleep!.intervalMinutes)}',
          icon: Icons.bedtime_outlined,
          color: const Color(0xFF776C91),
        ),
        if (sessions.length > 1) ...<Widget>[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final item in sessions)
                ChoiceChip(
                  label: Text(
                    '${_clock(item.session.startedAtUtc)} – ${_clock(item.session.endedAtUtc)}',
                  ),
                  selected: item.session.endedAtUtc == session?.endedAtUtc,
                  onSelected: (_) =>
                      setState(() => _sessionEnd = item.session.endedAtUtc),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        if (sleep == null)
          _EmptyCard(
            RingCalendar.sameDay(
                  selectedDay,
                  ref.watch(currentLocalTimeProvider),
                )
                ? 'Wear your ring tonight. Your sleep will be here after you sync in the morning.'
                : 'There is no saved sleep session for this date. Choose another night to explore your history.',
          )
        else ...<Widget>[
          if (sleep.stages.isNotEmpty) ...<Widget>[
            _GoalProgress(
              value: sleep.asleepStageMinutes,
              target: preferences.sleepTargetMinutes,
              label: 'Your sleep target',
              targetLabel: _minutes(preferences.sleepTargetMinutes),
              color: const Color(0xFF776C91),
            ),
            const SizedBox(height: 20),
          ],
          _HeroMetricCard(
            title: 'Sleep stages',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SleepTimeline(session: session!, stages: sleep.stages),
                const SizedBox(height: 20),
                for (final stage in RingSleepStage.values)
                  _StageRow(
                    label: _stageName(stage),
                    minutes: sleep.stageMinutes[stage] ?? 0,
                    percent: sleep.percentFor(stage),
                    color: _stageColor(stage),
                  ),
                if (sleep.unclassifiedMinutes > 0)
                  _StageRow(
                    label: 'Unclassified',
                    minutes: sleep.unclassifiedMinutes,
                    percent: sleep.intervalMinutes == 0
                        ? 0
                        : (sleep.unclassifiedMinutes *
                                  100 /
                                  sleep.intervalMinutes)
                              .round(),
                    color: LibreRingTokens.border,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _HeroMetricCard(
            title: 'Sleep continuity',
            child: _ThreeStats(
              values: <_StatValue>[
                _StatValue(
                  sleep.stages.isEmpty ? '—' : '${sleep.awakeSpans}',
                  'Awake periods',
                ),
                _StatValue(
                  sleep.stages.isEmpty
                      ? '—'
                      : _minutes(sleep.longestSleepRunMinutes),
                  'Longest sleep stretch',
                ),
                _StatValue(
                  sleep.stages.isEmpty
                      ? '—'
                      : _minutes(sleep.stageMinutes[RingSleepStage.awake] ?? 0),
                  'Awake time',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _HeroMetricCard(
            title: 'Overnight vitals',
            child: Column(
              children: <Widget>[
                _EvidenceRow(
                  icon: Icons.favorite_outline,
                  title: 'Median pulse',
                  value: sleep.sleepPulseMedian == null
                      ? '—'
                      : '${sleep.sleepPulseMedian} bpm',
                  detail: sleep.sleepPulse.isEmpty
                      ? 'No readings during this sleep window'
                      : '${sleep.sleepPulse.length} readings during this sleep window',
                ),
                _EvidenceRow(
                  icon: Icons.water_drop_outlined,
                  title: 'Blood oxygen range',
                  value: sleep.oxygenMinimum == null
                      ? '—'
                      : '${sleep.oxygenMinimum}–${sleep.oxygenMaximum}%',
                  detail: sleep.oxygenRanges.isEmpty
                      ? 'No complete hourly ranges in this window'
                      : '${sleep.oxygenRanges.length} complete hours within this sleep window',
                ),
              ],
            ),
          ),
        ],
        if (data != null && data.availableSleepDays.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          const RingSectionHeader(title: 'Recent nights'),
          const SizedBox(height: 8),
          for (final day in data.availableSleepDays.take(7))
            _ActionRow(
              icon: Icons.bedtime_outlined,
              title: DateFormat('EEE, d MMM').format(day),
              subtitle: data.sleepFor(day)!.stages.isEmpty
                  ? '${_minutes(data.sleepFor(day)!.intervalMinutes)} sleep window'
                  : '${_minutes(data.sleepFor(day)!.asleepStageMinutes)} estimated asleep',
              selected: RingCalendar.sameDay(day, selectedDay),
              onTap: () => setState(() {
                selectedDate = day;
                _sessionEnd = null;
              }),
            ),
        ],
        const _SourceDisclosure(
          'Sleep stages are estimated by your ring. Time asleep adds light, deep and REM stages; '
          'the sleep window also includes awake and unclassified time. Overnight pulse uses readings inside this '
          'session, and oxygen includes only whole recorded hours inside it. These estimates are not a medical sleep assessment.',
        ),
      ],
    );
  }
}

class HeartLabScreen extends ConsumerStatefulWidget {
  const HeartLabScreen({super.key});
  @override
  ConsumerState<HeartLabScreen> createState() => _HeartLabScreenState();
}

class _HeartLabScreenState extends ConsumerState<HeartLabScreen>
    with _CalendarDetail<HeartLabScreen> {
  @override
  Widget build(BuildContext context) {
    final data = analytics;
    final series = data?.pulsePeriod(days: days);
    final points = days == 1
        ? <RingChartPoint>[
            for (final p in series?.samples ?? <TimedValue>[])
              RingChartPoint(at: p.at, value: p.value.toDouble()),
          ]
        : <RingChartPoint>[
            for (final p in data?.pulseHistory(days: days) ?? <DailyValue>[])
              if (p.value != null)
                RingChartPoint(
                  at: _midday(p.day),
                  value: p.value!,
                  label: '${DateFormat('d MMM').format(p.day)} · Daily median',
                ),
          ];
    return _AnalyticsScreen(
      key: const Key('screen-heart'),
      activePath: '/vitals',
      children: <Widget>[
        const _AnalyticsTopBar(title: 'Heart rate', fallbackPath: '/vitals'),
        calendar(data),
        _MetricHeader(
          label: days == 1 ? 'Latest heart rate' : 'Median heart rate',
          value:
              (days == 1 ? series?.latest : series?.median)?.toString() ?? '—',
          unit: 'bpm',
          note: series?.samples.isNotEmpty == true
              ? days == 1
                    ? 'Recorded at ${_clock(series!.samples.last.at)}'
                    : periodLabel
              : 'No heart rate readings in this period',
          icon: Icons.favorite_outline,
          color: LibreRingTokens.accent,
        ),
        const SizedBox(height: 20),
        _HeroMetricCard(
          title: days == 1 ? 'Daily pulse timeline' : 'Daily median pulse',
          child: RingHistoryChart(
            key: const Key('heart-history-chart'),
            points: points,
            start: start,
            end: end,
            unit: 'bpm',
            maximumLineGap: days == 1
                ? const Duration(minutes: 90)
                : const Duration(hours: 26),
            color: LibreRingTokens.accent,
          ),
        ),
        const SizedBox(height: 14),
        _HeroMetricCard(
          title: 'Observed range',
          child: _ThreeStats(
            values: <_StatValue>[
              _StatValue('${series?.mean ?? '—'}', 'Average bpm'),
              _StatValue('${series?.minimum ?? '—'}', 'Lowest bpm'),
              _StatValue('${series?.maximum ?? '—'}', 'Highest bpm'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RecentValuesCard(
          title: 'Recent measurements',
          values: series?.samples.reversed.take(12).toList() ?? <TimedValue>[],
          unit: 'bpm',
        ),
        const _SourceDisclosure(
          'These are occasional readings captured by your ring, not a continuous heart rhythm recording. '
          'Daily and period summaries use only the readings shown. Gaps remain where readings are missing. '
          'A reading alone cannot diagnose a condition.',
        ),
      ],
    );
  }
}

class OxygenLabScreen extends ConsumerStatefulWidget {
  const OxygenLabScreen({super.key});
  @override
  ConsumerState<OxygenLabScreen> createState() => _OxygenLabScreenState();
}

class _OxygenLabScreenState extends ConsumerState<OxygenLabScreen>
    with _CalendarDetail<OxygenLabScreen> {
  @override
  Widget build(BuildContext context) {
    final data = analytics;
    final series = data?.oxygenPeriod(days: days);
    final ranges = series?.ranges ?? <RingOxygenRange>[];
    final grouped = <DateTime, List<RingOxygenRange>>{};
    for (final range in ranges) {
      grouped
          .putIfAbsent(
            RingCalendar.day(range.hourStartedAtUtc.toLocal()),
            () => <RingOxygenRange>[],
          )
          .add(range);
    }
    final points = days == 1
        ? <RingChartPoint>[
            for (final range in ranges)
              RingChartPoint(
                at: range.hourStartedAtUtc,
                value: range.minimumPercent.toDouble(),
                upper: range.maximumPercent.toDouble(),
              ),
          ]
        : <RingChartPoint>[
            for (final day in grouped.entries)
              RingChartPoint(
                at: _midday(day.key),
                value: day.value
                    .map((r) => r.minimumPercent)
                    .reduce(math.min)
                    .toDouble(),
                upper: day.value
                    .map((r) => r.maximumPercent)
                    .reduce(math.max)
                    .toDouble(),
                label: '${DateFormat('d MMM').format(day.key)} · Daily range',
              ),
          ];
    return _AnalyticsScreen(
      key: const Key('screen-oxygen'),
      activePath: '/vitals',
      children: <Widget>[
        const _AnalyticsTopBar(title: 'Blood oxygen', fallbackPath: '/vitals'),
        calendar(data),
        _MetricHeader(
          label: 'Recorded oxygen range',
          value: series?.minimum == null
              ? '—'
              : '${series!.minimum}–${series.maximum}',
          unit: '%',
          note: ranges.isEmpty
              ? 'No oxygen readings in this period'
              : '${series!.coveredHours} hours recorded · $periodLabel',
          icon: Icons.water_drop_outlined,
          color: const Color(0xFF527E9B),
        ),
        const SizedBox(height: 20),
        _HeroMetricCard(
          title: days == 1 ? 'Daily range map' : 'Daily oxygen ranges',
          child: RingHistoryChart(
            key: const Key('oxygen-history-chart'),
            points: points,
            start: start,
            end: end,
            unit: '%',
            kind: RingChartKind.ranges,
            color: const Color(0xFF527E9B),
          ),
        ),
        const SizedBox(height: 14),
        _HeroMetricCard(
          title: 'Captured range',
          child: _ThreeStats(
            values: <_StatValue>[
              _StatValue(
                series?.minimum == null ? '—' : '${series!.minimum}%',
                'Lowest bound',
              ),
              _StatValue(
                series?.maximum == null ? '—' : '${series!.maximum}%',
                'Highest bound',
              ),
              _StatValue('${series?.coveredHours ?? 0}', 'Hours recorded'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _HeroMetricCard(
          title: 'Recent readings',
          child: Column(
            children: <Widget>[
              if (ranges.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No readings yet'),
                ),
              for (final value in ranges.reversed.take(12))
                _EvidenceRow(
                  icon: Icons.water_drop_outlined,
                  title: '${value.minimumPercent}–${value.maximumPercent}%',
                  value: _clock(value.hourStartedAtUtc),
                  detail: DateFormat('EEE, d MMM')
                      .format(value.hourStartedAtUtc.toLocal()),
                ),
            ],
          ),
        ),
        const _SourceDisclosure(
          'Your ring stores the lowest and highest oxygen values within each recorded hour. '
          'The day chart preserves those hourly ranges; week and month combine them into each day’s lowest and highest bounds. '
          'No hourly averages are inferred. These are historical wellness readings, not live medical measurements.',
        ),
      ],
    );
  }
}

class VendorSignalScreen extends ConsumerStatefulWidget {
  const VendorSignalScreen({required this.kind, super.key});
  final RingVendorIndexKind kind;
  @override
  ConsumerState<VendorSignalScreen> createState() => _VendorSignalScreenState();
}

class _VendorSignalScreenState extends ConsumerState<VendorSignalScreen>
    with _CalendarDetail<VendorSignalScreen> {
  @override
  Widget build(BuildContext context) {
    final data = analytics;
    final series = data?.vendorPeriod(widget.kind, days: days);
    final stress = widget.kind == RingVendorIndexKind.stress;
    final label = stress ? 'Stress index' : 'HRV index';
    final points = days == 1
        ? <RingChartPoint>[
            for (final p in series?.samples ?? <TimedValue>[])
              RingChartPoint(at: p.at, value: p.value.toDouble()),
          ]
        : <RingChartPoint>[
            for (final p
                in data?.vendorHistory(widget.kind, days: days) ??
                    <DailyValue>[])
              if (p.value != null)
                RingChartPoint(
                  at: _midday(p.day),
                  value: p.value!,
                  label: '${DateFormat('d MMM').format(p.day)} · Daily median',
                ),
          ];
    return _AnalyticsScreen(
      key: Key(stress ? 'screen-stress-index' : 'screen-hrv-index'),
      activePath: '/vitals',
      children: <Widget>[
        _AnalyticsTopBar(title: label, fallbackPath: '/vitals'),
        calendar(data),
        _MetricHeader(
          label: days == 1 ? 'Latest ring index' : 'Median ring index',
          value:
              (days == 1 ? series?.latest : series?.median)?.toString() ?? '—',
          note: 'Ring estimate · unitless index',
          icon: stress ? Icons.spa_outlined : Icons.monitor_heart_outlined,
          color: _sage,
        ),
        const SizedBox(height: 12),
        Text(
          stress
              ? 'An estimate calculated by your ring. Its scale has not been independently verified.'
              : 'The ring reports this as an HRV index. The unit is unverified, so it is not shown in milliseconds.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        _HeroMetricCard(
          title: days == 1 ? 'Captured index timeline' : 'Daily median index',
          child: RingHistoryChart(
            key: const Key('vendor-history-chart'),
            points: points,
            start: start,
            end: end,
            unit: 'index',
            color: _sage,
            maximumLineGap: days == 1
                ? const Duration(minutes: 90)
                : const Duration(hours: 26),
          ),
        ),
        const SizedBox(height: 14),
        _HeroMetricCard(
          title: 'Observed values',
          child: _ThreeStats(
            values: <_StatValue>[
              _StatValue('${series?.median ?? '—'}', 'Median index'),
              _StatValue('${series?.minimum ?? '—'}', 'Lowest index'),
              _StatValue('${series?.maximum ?? '—'}', 'Highest index'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RecentValuesCard(
          title: 'Recent captured values',
          values: series?.samples.reversed.take(12).toList() ?? <TimedValue>[],
          unit: 'index',
        ),
        _SourceDisclosure(
          stress
              ? 'This field comes from the ring firmware. Its formula and thresholds are unverified, so LibreRing does not classify these values as relaxed, normal or high.'
              : 'The firmware exposes an HRV index, but its unit and calculation are unverified. LibreRing preserves the index and does not use it to calculate a recovery score.',
        ),
      ],
    );
  }
}

class SportRecordScreen extends ConsumerWidget {
  const SportRecordScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider).value ?? <JournalEntry>[];
    final sports =
        entries
            .where(
              (e) =>
                  e.kind == JournalEntryKind.swim || e.durationMinutes != null,
            )
            .toList()
          ..sort((a, b) => b.occurredAtUtc.compareTo(a.occurredAtUtc));
    final minutes = sports.fold(0, (sum, e) => sum + (e.durationMinutes ?? 0));
    return _AnalyticsScreen(
      key: const Key('screen-sport-record'),
      activePath: '/trends',
      children: <Widget>[
        const _AnalyticsTopBar(title: 'Activities', fallbackPath: '/movement'),
        const SizedBox(height: 20),
        _MetricHeader(
          label: 'Your activity log',
          value: '${sports.length}',
          unit: sports.length == 1 ? 'activity' : 'activities',
          note: '${_minutes(minutes)} logged · Added by you',
          icon: Icons.directions_run_rounded,
          color: _sage,
        ),
        const SizedBox(height: 20),
        LibreRingPrimaryButton(
          label: 'Add an activity',
          icon: Icons.add,
          onPressed: () => context.push('/activity/sports'),
        ),
        const SizedBox(height: 20),
        if (sports.isEmpty)
          const _EmptyCard(
            'Your workouts have a place here. Add your first activity to get started.',
          ),
        for (final entry in sports)
          _ActionRow(
            icon: Icons.directions_run_outlined,
            title: entry.title,
            subtitle:
                '${DateFormat('EEE, d MMM · HH:mm').format(entry.occurredAtUtc.toLocal())} · ${_minutes(entry.durationMinutes ?? 0)}',
            onTap: () => context.push('/journal'),
          ),
        const _SourceDisclosure(
          'These are activities you have logged. They add context to your day and remain separate from ring measurements.',
        ),
      ],
    );
  }
}

class CapabilitiesScreen extends ConsumerWidget {
  const CapabilitiesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(displayRingDataProvider).value;
    return _AnalyticsScreen(
      key: const Key('screen-capabilities'),
      activePath: '/you',
      children: <Widget>[
        const _AnalyticsTopBar(
          title: 'Ring features',
          fallbackPath: '/you/ring',
        ),
        const SizedBox(height: 20),
        const _MetricHeader(
          label: 'COLMI R12',
          value: 'What works now',
          note: 'Features supported by this version of LibreRing',
          icon: Icons.radio_button_checked,
          color: _sage,
        ),
        const SizedBox(height: 20),
        _HeroMetricCard(
          title: 'Supported readings',
          child: Column(
            children: <Widget>[
              _EvidenceRow(
                icon: Icons.battery_5_bar_outlined,
                title: 'Battery',
                value: data?.batteryLevel == null
                    ? '—'
                    : '${data!.batteryLevel}%',
                detail: 'At last sync',
              ),
              _EvidenceRow(
                icon: Icons.directions_walk_rounded,
                title: 'Activity',
                value: '${data?.activity.length ?? 0}',
                detail: 'Steps, distance and active energy records',
              ),
              _EvidenceRow(
                icon: Icons.favorite_outline,
                title: 'Heart rate',
                value: '${data?.heartRate.length ?? 0}',
                detail: 'Historical readings',
              ),
              _EvidenceRow(
                icon: Icons.bedtime_outlined,
                title: 'Sleep',
                value: '${data?.sleep.length ?? 0}',
                detail: 'Sleep sessions and estimated stages',
              ),
              _EvidenceRow(
                icon: Icons.water_drop_outlined,
                title: 'Blood oxygen',
                value: '${data?.oxygen.length ?? 0}',
                detail: 'Hourly minimum–maximum ranges',
              ),
              _EvidenceRow(
                icon: Icons.monitor_heart_outlined,
                title: 'HRV and stress indexes',
                value: '${data?.vendorIndexes.length ?? 0}',
                detail: 'Ring estimates · unitless values',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _HeroMetricCard(
          title: 'Not available in LibreRing yet',
          child: Column(
            children: <Widget>[
              _EvidenceRow(
                icon: Icons.touch_app_outlined,
                title: 'Ring controls',
                value: '',
                detail: 'Gestures, display, find ring and camera shutter',
              ),
              _EvidenceRow(
                icon: Icons.schedule,
                title: 'Monitoring schedules',
                value: '',
                detail: 'Configuring when the ring takes readings',
              ),
              _EvidenceRow(
                icon: Icons.sensors,
                title: 'Live measurements',
                value: '',
                detail: 'Starting pulse and oxygen readings on demand',
              ),
              _EvidenceRow(
                icon: Icons.favorite_border,
                title: 'Apple Health',
                value: '',
                detail: 'HealthKit integration',
              ),
              _EvidenceRow(
                icon: Icons.system_update_alt,
                title: 'Firmware updates',
                value: '',
                detail: 'Updating the software on the ring',
              ),
            ],
          ),
        ),
        const _SourceDisclosure(
          'Availability describes what this version of LibreRing supports. Different rings and firmware may behave differently. '
          'Features appear when their behavior has been verified for the supported R12 protocol.',
        ),
      ],
    );
  }
}

class _AnalyticsScreen extends ConsumerWidget {
  const _AnalyticsScreen({
    required this.children,
    required this.activePath,
    super.key,
  });
  final List<Widget> children;
  final String activePath;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(displayRingDataProvider);
    return RingPageScaffold(
      activePath: activePath,
      scrollKey: key.toString(),
      children: <Widget>[
        if (ref.watch(isDemoModeProvider))
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Example data',
              style: TextStyle(fontSize: 12, color: LibreRingTokens.muted),
            ),
          ),
        if (state.isLoading && !state.hasValue)
          const RingLoadingState()
        else if (state.hasError && !state.hasValue)
          RingEmptyState(
            title: 'Your saved data could not be opened',
            body: 'Try loading it again. Your ring readings have not been changed.',
            icon: Icons.refresh_rounded,
            action: 'Try again',
            onAction: () => ref.invalidate(ringDataProvider),
          )
        else
          ...children,
      ],
    );
  }
}

class _AnalyticsTopBar extends StatelessWidget {
  const _AnalyticsTopBar({required this.title, required this.fallbackPath});
  final String title;
  final String fallbackPath;
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      IconButton(
        tooltip: 'Back',
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(fallbackPath),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      ),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(width: 12),
    ],
  );
}

class _MetricHeader extends StatelessWidget {
  const _MetricHeader({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.color,
    this.unit,
  });
  final String label, value, note;
  final String? unit;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: LibreRingTokens.muted,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 8,
        children: <Widget>[
          Text(
            value,
            key: const Key('analytics-primary-value'),
            style: TextStyle(
              fontSize: value.length > 16 ? 34 : 48,
              fontWeight: FontWeight.w400,
              letterSpacing: -1.8,
              height: 1.08,
            ),
          ),
          if (unit != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                unit!,
                style: const TextStyle(
                  fontSize: 20,
                  color: LibreRingTokens.muted,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        note,
        style: const TextStyle(
          fontSize: 13,
          color: LibreRingTokens.muted,
          height: 1.45,
        ),
      ),
    ],
  );
}

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => LibreRingCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}

class _GoalProgress extends StatelessWidget {
  const _GoalProgress({
    required this.value,
    required this.target,
    required this.label,
    required this.targetLabel,
    required this.color,
  });
  final int value, target;
  final String label, targetLabel;
  final Color color;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '$label, $targetLabel. ${(value / target * 100).round()} percent reached.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: LibreRingTokens.muted,
              ),
            ),
            Text(
              targetLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / target).clamp(0, 1),
            minHeight: 5,
            color: color,
            backgroundColor: LibreRingTokens.border.withValues(alpha: .4),
          ),
        ),
      ],
    ),
  );
}

class _StatValue {
  const _StatValue(this.value, this.label);
  final String value, label;
}

class _ThreeStats extends StatelessWidget {
  const _ThreeStats({required this.values});
  final List<_StatValue> values;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stack =
          MediaQuery.textScalerOf(context).scale(1) > 1.35 ||
          constraints.maxWidth < 260;
      Widget stat(_StatValue item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w500,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.label,
            style: const TextStyle(fontSize: 12, color: LibreRingTokens.muted),
          ),
        ],
      );
      return stack
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final item in values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: stat(item),
                  ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final item in values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: stat(item),
                    ),
                  ),
              ],
            );
    },
  );
}

enum RingChartKind { line, bars, ranges }

@immutable
class RingChartPoint {
  const RingChartPoint({
    required this.at,
    required this.value,
    this.upper,
    this.label,
  });
  final DateTime at;
  final double value;
  final double? upper;
  final String? label;
}

/// The domain is explicit and includes missing intervals. Sample coordinates
/// must not expand to fill the domain when the ring has only sparse history.
class RingHistoryChart extends StatefulWidget {
  const RingHistoryChart({
    required this.points,
    required this.start,
    required this.end,
    required this.unit,
    this.kind = RingChartKind.line,
    this.color = _sage,
    this.maximumLineGap = const Duration(minutes: 90),
    super.key,
  });
  final List<RingChartPoint> points;
  final DateTime start, end;
  final String unit;
  final RingChartKind kind;
  final Color color;
  final Duration maximumLineGap;
  @override
  State<RingHistoryChart> createState() => _RingHistoryChartState();
}

class _RingHistoryChartState extends State<RingHistoryChart> {
  int? _selected;
  List<RingChartPoint> get points =>
      widget.points
          .where(
            (p) => !p.at.isBefore(widget.start) && p.at.isBefore(widget.end),
          )
          .toList()
        ..sort((a, b) => a.at.compareTo(b.at));
  @override
  void didUpdateWidget(covariant RingHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.start != oldWidget.start ||
        widget.end != oldWidget.end ||
        widget.points.length != oldWidget.points.length) {
      _selected = null;
    }
  }

  String describe(RingChartPoint p) =>
      '${p.label ?? DateFormat('d MMM, HH:mm').format(p.at.toLocal())} · '
      '${_number(p.value)}${p.upper == null ? '' : '–${_number(p.upper!)}'} ${widget.unit}';

  @override
  Widget build(BuildContext context) {
    final data = points;
    if (data.isEmpty) return const _EmptyChart();
    final selected = _selected == null
        ? null
        : data[_selected!.clamp(0, data.length - 1)];
    final maxValue = data.map((p) => p.upper ?? p.value).reduce(math.max);
    final minValue = data.map((p) => p.value).reduce(math.min);
    final bottom = widget.kind == RingChartKind.bars
        ? 0.0
        : math.max(
            0.0,
            (minValue - math.max(2, (maxValue - minValue) * .2))
                .floorToDouble(),
          );
    final top = widget.kind == RingChartKind.ranges
        ? math.min(100.0, (maxValue + 1).ceilToDouble())
        : math.max(
            bottom + 1,
            (maxValue + math.max(1, (maxValue - bottom) * .12)).ceilToDouble(),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(
            selected == null ? 'Tap a reading to explore' : describe(selected),
            key: const Key('chart-selection'),
            style: TextStyle(
              fontSize: 12,
              color: selected == null ? LibreRingTokens.muted : widget.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            void pick(double dx) {
              final fraction =
                  ((dx - RingHistoryPainter.leftInset) /
                          math.max(
                            1,
                            constraints.maxWidth -
                                RingHistoryPainter.leftInset -
                                6,
                          ))
                      .clamp(0.0, 1.0);
              final timestamp =
                  widget.start.millisecondsSinceEpoch +
                  (widget.end.millisecondsSinceEpoch -
                          widget.start.millisecondsSinceEpoch) *
                      fraction;
              var nearest = 0;
              for (var i = 1; i < data.length; i++) {
                if ((data[i].at.millisecondsSinceEpoch - timestamp).abs() <
                    (data[nearest].at.millisecondsSinceEpoch - timestamp)
                        .abs()) {
                  nearest = i;
                }
              }
              setState(() => _selected = nearest);
            }

            return Semantics(
              label:
                  '${widget.unit} history. ${data.length} recorded readings. Swipe up or down to inspect readings.',
              value: selected == null
                  ? 'No reading selected'
                  : describe(selected),
              increasedValue: describe(
                data[((_selected ?? -1) + 1).clamp(0, data.length - 1)],
              ),
              decreasedValue: describe(
                data[((_selected ?? data.length) - 1).clamp(
                  0,
                  data.length - 1,
                )],
              ),
              onIncrease: () => setState(
                () => _selected = ((_selected ?? -1) + 1).clamp(
                  0,
                  data.length - 1,
                ),
              ),
              onDecrease: () => setState(
                () => _selected = ((_selected ?? data.length) - 1).clamp(
                  0,
                  data.length - 1,
                ),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (e) => pick(e.localPosition.dx),
                onHorizontalDragUpdate: (e) => pick(e.localPosition.dx),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: RingHistoryPainter(
                      points: data,
                      start: widget.start,
                      end: widget.end,
                      minimum: bottom,
                      maximum: top,
                      kind: widget.kind,
                      color: widget.color,
                      selectedIndex: _selected,
                      maximumLineGap: widget.maximumLineGap,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: RingHistoryPainter.leftInset),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: _AxisText(
                  widget.end.difference(widget.start).inHours <= 25
                      ? '00:00'
                      : DateFormat('d MMM').format(widget.start),
                ),
              ),
              if (MediaQuery.textScalerOf(context).scale(1) <= 1.3 &&
                  !const <int>[
                    23,
                    25,
                  ].contains(widget.end.difference(widget.start).inHours))
                Expanded(
                  child: _AxisText(
                    widget.end.difference(widget.start).inHours <= 25
                        ? '12:00'
                        : DateFormat('d MMM').format(
                            widget.start.add(
                              widget.end.difference(widget.start) ~/ 2,
                            ),
                          ),
                    align: TextAlign.center,
                  ),
                ),
              Expanded(
                child: _AxisText(
                  widget.end.difference(widget.start).inHours <= 25
                      ? '24:00'
                      : DateFormat('d MMM').format(
                          widget.end.subtract(const Duration(minutes: 1)),
                        ),
                  align: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Gaps mean no reading was recorded.',
          style: TextStyle(fontSize: 12, color: LibreRingTokens.muted),
        ),
      ],
    );
  }
}

class RingHistoryPainter extends CustomPainter {
  RingHistoryPainter({
    required this.points,
    required this.start,
    required this.end,
    required this.minimum,
    required this.maximum,
    required this.kind,
    required this.color,
    this.selectedIndex,
    this.maximumLineGap = const Duration(minutes: 90),
  });
  static const leftInset = 32.0;
  final List<RingChartPoint> points;
  final DateTime start, end;
  final double minimum, maximum;
  final RingChartKind kind;
  final Color color;
  final int? selectedIndex;
  final Duration maximumLineGap;

  double xFor(DateTime at, Size size) =>
      leftInset +
      (at.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
          math.max(
            1,
            end.millisecondsSinceEpoch - start.millisecondsSinceEpoch,
          ) *
          (size.width - leftInset - 6);
  double yFor(double value, Size size) =>
      8 +
      (maximum - value) / math.max(.01, maximum - minimum) * (size.height - 20);

  bool connectsPrevious(int index) =>
      index > 0 &&
      points[index].at.difference(points[index - 1].at) <= maximumLineGap;
  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 12;
    for (var i = 0; i < 3; i++) {
      final v = minimum + (maximum - minimum) * i / 2;
      final y = yFor(v, size);
      canvas.drawLine(
        Offset(leftInset, y),
        Offset(size.width, y),
        Paint()..color = LibreRingTokens.border.withValues(alpha: .55),
      );
      final label = TextPainter(
        text: TextSpan(
          text: _number(v),
          style: const TextStyle(
            fontFamily: 'Helvetica Neue',
            fontFamilyFallback: <String>['Arial', 'sans-serif'],
            fontSize: 10,
            color: LibreRingTokens.muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftInset - 4);
      label.paint(canvas, Offset(0, y - label.height / 2));
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final x = xFor(p.at, size);
      final y = yFor(p.value, size);
      if (kind == RingChartKind.bars) {
        final width = math.min(
          10.0,
          math.max(
            3.0,
            (size.width - leftInset) /
                math.max(24, end.difference(start).inHours) *
                .65,
          ),
        );
        if (p.value == 0) {
          canvas.drawCircle(Offset(x, baseline), 2.5, paint);
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(x - width / 2, y, x + width / 2, baseline),
              const Radius.circular(3),
            ),
            paint,
          );
        }
      } else if (kind == RingChartKind.ranges) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, yFor(p.upper ?? p.value, size)),
          Paint()
            ..color = color
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
      } else {
        if (connectsPrevious(i)) {
          canvas.drawLine(
            Offset(
              xFor(points[i - 1].at, size),
              yFor(points[i - 1].value, size),
            ),
            Offset(x, y),
            paint,
          );
        }
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
      if (i == selectedIndex) {
        canvas.drawLine(
          Offset(x, 2),
          Offset(x, size.height),
          Paint()
            ..color = color.withValues(alpha: .35)
            ..strokeWidth = 1,
        );
        canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(x, y), 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RingHistoryPainter oldDelegate) => true;
}

class _AxisText extends StatelessWidget {
  const _AxisText(this.value, {this.align = TextAlign.left});
  final String value;
  final TextAlign align;
  @override
  Widget build(BuildContext context) => Text(
    value,
    textAlign: align,
    style: const TextStyle(fontSize: 11, color: LibreRingTokens.muted),
  );
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 36),
    child: Center(
      child: Column(
        children: <Widget>[
          Icon(Icons.show_chart_rounded, color: LibreRingTokens.muted),
          SizedBox(height: 12),
          Text(
            'No readings in this period',
            style: TextStyle(color: LibreRingTokens.muted),
          ),
        ],
      ),
    ),
  );
}

class _SleepTimeline extends StatefulWidget {
  const _SleepTimeline({required this.session, required this.stages});
  final RingSleepSession session;
  final List<RingSleepStageSpan> stages;
  @override
  State<_SleepTimeline> createState() => _SleepTimelineState();
}

class _SleepTimelineState extends State<_SleepTimeline> {
  RingSleepStageSpan? selected;
  @override
  void didUpdateWidget(covariant _SleepTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final stages = widget.stages;
    final length = widget.session.endedAtUtc
        .difference(widget.session.startedAtUtc)
        .inMilliseconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          selected == null
              ? 'Tap a stage to explore'
              : '${_stageName(selected!.stage)} · ${_minutes(selected!.durationMinutes)} · ${_clock(selected!.startedAtUtc)}',
          style: const TextStyle(fontSize: 12, color: LibreRingTokens.muted),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 112,
            child: Stack(
              children: <Widget>[
                for (final stage in stages)
                  Positioned(
                    left:
                        stage.startedAtUtc
                            .difference(widget.session.startedAtUtc)
                            .inMilliseconds /
                        math.max(1, length) *
                        constraints.maxWidth,
                    width:
                        stage.durationMinutes *
                        60000 /
                        math.max(1, length) *
                        constraints.maxWidth,
                    top: 0,
                    bottom: 0,
                    child: Semantics(
                      button: true,
                      label:
                          '${_stageName(stage.stage)}, ${_minutes(stage.durationMinutes)}, ${_clock(stage.startedAtUtc)}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => selected = stage),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            widthFactor: .97,
                            heightFactor: switch (stage.stage) {
                              RingSleepStage.awake => 1,
                              RingSleepStage.rem => .8,
                              RingSleepStage.light => .6,
                              RingSleepStage.deep => .35,
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _stageColor(stage.stage),
                                borderRadius: BorderRadius.circular(4),
                                border: selected == stage
                                    ? Border.all(
                                        color: LibreRingTokens.foreground,
                                        width: 2,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _AxisText(_clock(widget.session.startedAtUtc)),
            _AxisText(_clock(widget.session.endedAtUtc)),
          ],
        ),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.label,
    required this.minutes,
    required this.percent,
    required this.color,
  });
  final String label;
  final int minutes, percent;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      children: <Widget>[
        if (MediaQuery.textScalerOf(context).scale(1) > 1.3)
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: const TextStyle(fontSize: 13)),
                Text(
                  '${_minutes(minutes)} · $percent%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: LibreRingTokens.muted,
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: <Widget>[
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 13)),
              ),
              Text(
                '${_minutes(minutes)} · $percent%',
                style: const TextStyle(
                  fontSize: 12,
                  color: LibreRingTokens.muted,
                ),
              ),
            ],
          ),
        const SizedBox(height: 7),
        Semantics(
          label: '$label, $percent percent',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 100) / 100,
              minHeight: 6,
              color: color,
              backgroundColor: LibreRingTokens.background,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RecentValuesCard extends StatelessWidget {
  const _RecentValuesCard({
    required this.title,
    required this.values,
    required this.unit,
  });
  final String title, unit;
  final List<TimedValue> values;
  @override
  Widget build(BuildContext context) => _HeroMetricCard(
    title: title,
    child: Column(
      children: <Widget>[
        if (values.isEmpty)
          const Text(
            'No readings yet',
            style: TextStyle(color: LibreRingTokens.muted),
          ),
        for (final value in values)
          _EvidenceRow(
            icon: Icons.circle_outlined,
            title: '${value.value} $unit',
            value: _clock(value.at),
            detail: DateFormat('EEE, d MMM').format(value.at.toLocal()),
          ),
      ],
    ),
  );
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });
  final IconData icon;
  final String title, value, detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 19, color: _sage),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 12,
                  color: LibreRingTokens.muted,
                ),
              ),
              if (MediaQuery.textScalerOf(context).scale(1) > 1.3 &&
                  value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (MediaQuery.textScalerOf(context).scale(1) <= 1.3 &&
            value.isNotEmpty) ...<Widget>[
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
    this.selected = false,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? _sage.withValues(alpha: .09) : Colors.transparent,
    borderRadius: BorderRadius.circular(14),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: _sage),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: LibreRingTokens.muted),
      ),
      trailing: Icon(
        selected ? Icons.check_rounded : Icons.chevron_right_rounded,
        size: 20,
      ),
      onTap: onTap,
    ),
  );
}

class _SourceDisclosure extends StatelessWidget {
  const _SourceDisclosure(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const Key('analytics-source-disclosure'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        leading: const Icon(
          Icons.info_outline_rounded,
          size: 20,
          color: LibreRingTokens.muted,
        ),
        title: const Text(
          'About this data',
          style: TextStyle(fontSize: 14, color: LibreRingTokens.muted),
        ),
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: LibreRingTokens.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => LibreRingCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: <Widget>[
          const Icon(Icons.nights_stay_outlined, size: 28, color: _sage),
          const SizedBox(height: 16),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: LibreRingTokens.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}

Color _stageColor(RingSleepStage stage) => switch (stage) {
  RingSleepStage.awake => const Color(0xFFD4AA66),
  RingSleepStage.rem => const Color(0xFFB3A8C8),
  RingSleepStage.light => const Color(0xFF8D7DA6),
  RingSleepStage.deep => const Color(0xFF5C4D76),
};
String _stageName(RingSleepStage stage) => switch (stage) {
  RingSleepStage.awake => 'Awake',
  RingSleepStage.rem => 'REM',
  RingSleepStage.light => 'Light',
  RingSleepStage.deep => 'Deep',
};
DateTime _midday(DateTime day) => DateTime(day.year, day.month, day.day, 12);
String _clock(DateTime value) => DateFormat('HH:mm').format(value.toLocal());
String _minutes(int value) =>
    value < 60 ? '$value min' : '${value ~/ 60} h ${value % 60} min';
String _number(double value) => NumberFormat(
  value.abs() < 10 && value != value.roundToDouble() ? '0.#' : '#,##0',
).format(value);
