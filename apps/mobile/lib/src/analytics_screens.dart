import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

import 'app_state.dart';
import 'ring_analytics.dart';
import 'storage/journal_repository.dart';

class ActivityLabScreen extends ConsumerStatefulWidget {
  const ActivityLabScreen({super.key});

  @override
  ConsumerState<ActivityLabScreen> createState() => _ActivityLabScreenState();
}

class _ActivityLabScreenState extends ConsumerState<ActivityLabScreen> {
  int _days = 1;

  @override
  Widget build(BuildContext context) {
    final dataset = ref.watch(isDemoModeProvider)
        ? null
        : ref.watch(ringDataProvider).value;
    final analytics = dataset == null
        ? null
        : RingAnalytics.fromDataset(
            dataset,
            localNow: ref.watch(currentLocalTimeProvider),
          );
    final day = analytics?.activityFor(analytics.selectedDay);
    final history = analytics?.activityHistory(days: _days == 1 ? 7 : _days);
    final summaryDays = _days == 1
        ? <ActivityDay>[?day]
        : history ?? const <ActivityDay>[];
    final summarySteps = summaryDays.fold<int>(
      0,
      (sum, value) => sum + value.steps,
    );
    final summaryDistance = summaryDays.fold<int>(
      0,
      (sum, value) => sum + value.distanceMeters,
    );
    final summaryCalories = summaryDays.fold<int>(
      0,
      (sum, value) => sum + value.firmwareCalories,
    );
    final daysWithData = summaryDays
        .where((value) => value.buckets.isNotEmpty)
        .length;
    final values = _days == 1
        ? day?.hourly.map((value) => value.steps.toDouble()).toList()
        : history?.map((value) => value.steps.toDouble()).toList();
    final distanceValues = _days == 1
        ? day?.hourly.map((value) => value.distanceMeters.toDouble()).toList()
        : history?.map((value) => value.distanceMeters.toDouble()).toList();
    final calorieValues = _days == 1
        ? day?.hourly.map((value) => value.firmwareCalories.toDouble()).toList()
        : history?.map((value) => value.firmwareCalories.toDouble()).toList();
    return _AnalyticsScreen(
      key: const Key('screen-movement'),
      activePath: '/today',
      children: <Widget>[
        const _AnalyticsTopBar(title: 'Activity', fallbackPath: '/today'),
        const SizedBox(height: 26),
        _RangeSelector(
          selected: _days,
          onChanged: (value) => setState(() => _days = value),
        ),
        const SizedBox(height: 24),
        _Eyebrow(
          analytics == null
              ? 'Ring estimates'
              : _days == 1
              ? '${DateFormat('EEE, d MMM').format(analytics.selectedDay)} · ${day?.coveredHours ?? 0} recorded hours'
              : 'Last $_days days · $daysWithData days with records',
        ),
        const SizedBox(height: 8),
        _Display(
          day == null || summarySteps == 0
              ? 'No activity yet'
              : '$summarySteps steps',
        ),
        const SizedBox(height: 14),
        Text(
          day == null
              ? 'Sync the ring to load decoded hourly activity buckets.'
              : 'Distance and calories below are retained firmware estimates. Missing hours stay visible as gaps.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        _HeroMetricCard(
          title: _days == 1
              ? 'Today, hour by hour'
              : 'Activity across $_days days',
          child: Column(
            children: <Widget>[
              _ThreeStats(
                values: <_StatValue>[
                  _StatValue('$summarySteps', 'Steps'),
                  _StatValue(_distance(summaryDistance), 'Distance'),
                  _StatValue('$summaryCalories', 'Firmware kcal'),
                ],
              ),
              const SizedBox(height: 28),
              _BarChart(
                values: values ?? const <double>[],
                color: LibreRingTokens.foreground,
              ),
              const SizedBox(height: 10),
              _AxisLabels(
                left: _days == 1 ? '00' : 'Earlier',
                right: _days == 1 ? '23' : 'Latest',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _MetricTimelineCard(
          title: 'Distance',
          value: _distance(summaryDistance),
          note: 'Firmware estimate',
          values: distanceValues ?? const <double>[],
          color: const Color(0xFF727A65),
        ),
        const SizedBox(height: 14),
        _MetricTimelineCard(
          title: 'Energy',
          value: '$summaryCalories kcal',
          note: 'Firmware estimate · not independently validated',
          values: calorieValues ?? const <double>[],
          color: LibreRingTokens.accent,
        ),
        const SizedBox(height: 18),
        _Callout(
          icon: Icons.pool_outlined,
          title: 'Sport record',
          body: 'Ring buckets and manual activities remain separate, so a swim is never turned into invented steps.',
          action: 'Open journal',
          onTap: () => context.go('/sport'),
        ),
      ],
    );
  }
}

class SleepLabScreen extends ConsumerWidget {
  const SleepLabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(isDemoModeProvider)
        ? null
        : ref.watch(ringDataProvider).value;
    final analytics = dataset == null
        ? null
        : RingAnalytics.fromDataset(
            dataset,
            localNow: ref.watch(currentLocalTimeProvider),
          );
    final sleep = analytics?.latestSleep;
    final session = sleep?.session;
    return _AnalyticsScreen(
      key: const Key('screen-sleep'),
      activePath: '/today',
      children: <Widget>[
        _AnalyticsTopBar(
          title: 'Sleep',
          fallbackPath: '/metrics',
          trailing: IconButton(
            tooltip: 'View sleep evidence',
            onPressed: () => context.go('/sleep/evidence'),
            icon: const Icon(Icons.description_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 26),
        _Eyebrow(
          session == null
              ? 'Latest firmware session'
              : '${DateFormat('EEE, d MMM').format(session.endedAtUtc.toLocal())} · firmware estimate',
        ),
        const SizedBox(height: 8),
        _Display(
          sleep == null ? 'No sleep session' : _minutes(sleep.intervalMinutes),
        ),
        const SizedBox(height: 10),
        Text(
          sleep == null
              ? 'Sync the ring to load supported sleep history.'
              : '${_clock(session!.startedAtUtc)}–${_clock(session.endedAtUtc)} · No sleep score is invented.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        if (sleep == null)
          const _EmptyCard('No retained sleep stage runs are available.')
        else ...<Widget>[
          _HeroMetricCard(
            title: 'Night architecture',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SleepRibbon(session!.stages),
                const SizedBox(height: 12),
                _AxisLabels(
                  left: _clock(session.startedAtUtc),
                  right: _clock(session.endedAtUtc),
                ),
                const SizedBox(height: 28),
                for (final stage in RingSleepStage.values)
                  _StageRow(
                    stage: stage,
                    minutes: sleep.stageMinutes[stage] ?? 0,
                    percent: sleep.percentFor(stage),
                  ),
                if (sleep.unclassifiedMinutes > 0)
                  _StageRow(
                    label: 'Unclassified interval',
                    minutes: sleep.unclassifiedMinutes,
                    percent:
                        ((sleep.unclassifiedMinutes / sleep.intervalMinutes) *
                                100)
                            .round(),
                    color: LibreRingTokens.border,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _HeroMetricCard(
            title: 'Continuity, without a score',
            child: _ThreeStats(
              values: <_StatValue>[
                _StatValue('${sleep.awakeSpans}', 'Awake runs'),
                _StatValue(
                  _minutes(sleep.longestSleepRunMinutes),
                  'Longest run',
                ),
                _StatValue('${sleep.recordedStageMinutes}', 'Stage min'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _HeroMetricCard(
            title: 'Signals captured during the interval',
            child: Column(
              children: <Widget>[
                _EvidenceRow(
                  icon: Icons.favorite_outline,
                  title: 'Pulse',
                  value: sleep.sleepPulseMedian == null
                      ? '—'
                      : '${sleep.sleepPulseMedian} bpm',
                  detail: sleep.sleepPulse.isEmpty
                      ? 'No measured pulse sample landed inside this interval'
                      : '${sleep.sleepPulse.length} samples · median shown',
                ),
                _EvidenceRow(
                  icon: Icons.water_drop_outlined,
                  title: 'Oxygen',
                  value: sleep.oxygenMinimum == null
                      ? '—'
                      : '${sleep.oxygenMinimum}–${sleep.oxygenMaximum}%',
                  detail:
                      '${sleep.oxygenRanges.length} hourly ranges · no invented average',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _RecentSleepCard(sessions: analytics!.sleepHistory()),
        ],
        const SizedBox(height: 18),
        _Callout(
          icon: Icons.fact_check_outlined,
          title: 'How this was calculated',
          body: 'Stage labels come from ring firmware. They are not EEG measurements or a medical sleep assessment.',
          action: 'View evidence',
          onTap: () => context.go('/sleep/evidence'),
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

class _HeartLabScreenState extends ConsumerState<HeartLabScreen> {
  int _days = 1;

  @override
  Widget build(BuildContext context) {
    final dataset = ref.watch(isDemoModeProvider)
        ? null
        : ref.watch(ringDataProvider).value;
    final analytics = dataset == null
        ? null
        : RingAnalytics.fromDataset(
            dataset,
            localNow: ref.watch(currentLocalTimeProvider),
          );
    final series = analytics?.pulseFor(analytics.selectedDay);
    final periodStart = analytics?.selectedDay.subtract(
      Duration(days: math.max(0, _days - 1)),
    );
    final periodSamples =
        dataset == null
              ? <TimedValue>[]
              : dataset.heartRate
                    .where(
                      (value) =>
                          !value.measuredAtUtc.toLocal().isBefore(periodStart!),
                    )
                    .map((value) => TimedValue(value.measuredAtUtc, value.bpm))
                    .toList()
          ..sort((left, right) => left.at.compareTo(right.at));
    final periodSeries = _days == 1 || analytics == null
        ? series
        : SampleSeries(day: analytics.selectedDay, samples: periodSamples);
    final history = analytics?.pulseHistory(days: _days == 1 ? 7 : _days);
    final chartValues = _days == 1
        ? series?.samples
              .map((value) => _TimedPlotValue(value.at, value.value.toDouble()))
              .toList()
        : history
              ?.where((value) => value.value != null)
              .map((value) => _TimedPlotValue(value.day, value.value!))
              .toList();
    return _AnalyticsScreen(
      key: const Key('screen-heart'),
      activePath: '/today',
      children: <Widget>[
        const _AnalyticsTopBar(title: 'Heart', fallbackPath: '/today'),
        const SizedBox(height: 26),
        _RangeSelector(
          selected: _days,
          onChanged: (value) => setState(() => _days = value),
        ),
        const SizedBox(height: 24),
        const _Eyebrow('Measured spot samples'),
        const SizedBox(height: 8),
        _Display(
          periodSeries?.latest == null
              ? 'No pulse yet'
              : '${periodSeries!.latest} bpm',
        ),
        const SizedBox(height: 12),
        Text(
          periodSeries == null
              ? 'Sync the ring to load measured pulse history.'
              : _days == 1
              ? '${periodSeries.samples.length} samples across ${periodSeries.coveredHours} hours on the latest recorded day.'
              : '${periodSeries.samples.length} samples retained across the last $_days days.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        _HeroMetricCard(
          title: _days == 1
              ? 'Daily pulse timeline'
              : 'Median pulse across $_days days',
          child: Column(
            children: <Widget>[
              _TimedLineChart(values: chartValues ?? const <_TimedPlotValue>[]),
              const SizedBox(height: 10),
              _AxisLabels(
                left: _days == 1 ? '00:00' : 'Earlier',
                right: _days == 1 ? '23:59' : 'Latest',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _HeroMetricCard(
          title: 'Observed range',
          child: _ThreeStats(
            values: <_StatValue>[
              _StatValue('${periodSeries?.mean ?? '—'}', 'Mean bpm'),
              _StatValue('${periodSeries?.minimum ?? '—'}', 'Minimum'),
              _StatValue('${periodSeries?.maximum ?? '—'}', 'Maximum'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RecentValuesCard(
          title: 'Recent measurements',
          values:
              periodSeries?.samples.reversed.take(7).toList() ??
              const <TimedValue>[],
          unit: 'bpm',
        ),
        const SizedBox(height: 18),
        const _Disclosure(
          'These are retained spot measurements—not continuous ECG, a rhythm diagnosis, or a statement that a value is healthy.',
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

class _OxygenLabScreenState extends ConsumerState<OxygenLabScreen> {
  int _days = 1;

  @override
  Widget build(BuildContext context) {
    final dataset = ref.watch(isDemoModeProvider)
        ? null
        : ref.watch(ringDataProvider).value;
    final analytics = dataset == null
        ? null
        : RingAnalytics.fromDataset(
            dataset,
            localNow: ref.watch(currentLocalTimeProvider),
          );
    final series = analytics?.oxygenFor(analytics.selectedDay);
    final allRanges = dataset?.oxygen.toList(growable: false)
      ?..sort((a, b) => a.hourStartedAtUtc.compareTo(b.hourStartedAtUtc));
    final periodStart = analytics?.selectedDay.subtract(
      Duration(days: math.max(0, _days - 1)),
    );
    final visible = _days == 1
        ? series?.ranges ?? const <RingOxygenRange>[]
        : allRanges
                  ?.where(
                    (value) => !value.hourStartedAtUtc.toLocal().isBefore(
                      periodStart!,
                    ),
                  )
                  .toList(growable: false) ??
              const <RingOxygenRange>[];
    final periodSeries = analytics == null
        ? null
        : OxygenSeries(day: analytics.selectedDay, ranges: visible);
    return _AnalyticsScreen(
      key: const Key('screen-oxygen'),
      activePath: '/today',
      children: <Widget>[
        const _AnalyticsTopBar(title: 'Oxygen', fallbackPath: '/today'),
        const SizedBox(height: 26),
        _RangeSelector(
          selected: _days,
          onChanged: (value) => setState(() => _days = value),
        ),
        const SizedBox(height: 24),
        const _Eyebrow('Hourly firmware ranges'),
        const SizedBox(height: 8),
        _Display(
          periodSeries?.minimum == null
              ? 'No ranges yet'
              : '${periodSeries!.minimum}–${periodSeries.maximum}%',
        ),
        const SizedBox(height: 12),
        Text(
          periodSeries == null
              ? 'Sync the ring to load supported oxygen history.'
              : _days == 1
              ? '${periodSeries.ranges.length} ranges across ${periodSeries.coveredHours} hours. LibreRing keeps their shape intact.'
              : '${periodSeries.ranges.length} hourly ranges retained across the last $_days days.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        _HeroMetricCard(
          title: _days == 1 ? 'Daily range map' : 'Range map · $_days days',
          child: Column(
            children: <Widget>[
              SizedBox(height: 190, child: _OxygenBandChart(ranges: visible)),
              const SizedBox(height: 10),
              _AxisLabels(
                left: _days == 1 ? '00:00' : 'Earlier',
                right: _days == 1 ? '23:59' : 'Latest',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _HeroMetricCard(
          title: 'Captured range',
          child: _ThreeStats(
            values: <_StatValue>[
              _StatValue('${periodSeries?.minimum ?? '—'}%', 'Lowest bound'),
              _StatValue('${periodSeries?.maximum ?? '—'}%', 'Highest bound'),
              _StatValue('${periodSeries?.coveredHours ?? 0}', 'Covered hours'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RangeListCard(
          ranges:
              periodSeries?.ranges.reversed.take(7).toList() ??
              const <RingOxygenRange>[],
        ),
        const SizedBox(height: 18),
        const _Disclosure(
          'The decoder supplies minimum–maximum ranges, not exact hourly averages. This is stored history, not a live medical reading.',
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

class _VendorSignalScreenState extends ConsumerState<VendorSignalScreen> {
  int _days = 1;

  @override
  Widget build(BuildContext context) {
    final dataset = ref.watch(isDemoModeProvider)
        ? null
        : ref.watch(ringDataProvider).value;
    final analytics = dataset == null
        ? null
        : RingAnalytics.fromDataset(
            dataset,
            localNow: ref.watch(currentLocalTimeProvider),
          );
    final series = analytics?.vendorIndexFor(
      analytics.selectedDay,
      widget.kind,
    );
    final periodStart = analytics?.selectedDay.subtract(
      Duration(days: math.max(0, _days - 1)),
    );
    final periodSamples =
        dataset == null
              ? <TimedValue>[]
              : dataset.vendorIndexes
                    .where(
                      (value) =>
                          value.kind == widget.kind &&
                          !value.measuredAtUtc.toLocal().isBefore(periodStart!),
                    )
                    .map(
                      (value) => TimedValue(value.measuredAtUtc, value.value),
                    )
                    .toList()
          ..sort((left, right) => left.at.compareTo(right.at));
    final periodSeries = _days == 1 || analytics == null
        ? series
        : SampleSeries(day: analytics.selectedDay, samples: periodSamples);
    final history = analytics?.vendorHistory(
      widget.kind,
      days: _days == 1 ? 7 : _days,
    );
    final chartValues = _days == 1
        ? series?.samples
              .map((value) => _TimedPlotValue(value.at, value.value.toDouble()))
              .toList()
        : history
              ?.where((value) => value.value != null)
              .map((value) => _TimedPlotValue(value.day, value.value!))
              .toList();
    final isStress = widget.kind == RingVendorIndexKind.stress;
    final label = isStress ? 'Firmware stress index' : 'Firmware HRV index';
    return _AnalyticsScreen(
      key: Key(isStress ? 'screen-stress-index' : 'screen-hrv-index'),
      activePath: '/today',
      children: <Widget>[
        _AnalyticsTopBar(title: label, fallbackPath: '/metrics'),
        const SizedBox(height: 26),
        _RangeSelector(
          selected: _days,
          onChanged: (value) => setState(() => _days = value),
        ),
        const SizedBox(height: 24),
        const _Eyebrow('Opaque vendor field · exploratory'),
        const SizedBox(height: 8),
        _Display(
          periodSeries?.latest == null
              ? 'No index yet'
              : '${periodSeries!.latest} index',
        ),
        const SizedBox(height: 12),
        Text(
          periodSeries == null
              ? 'No decoded vendor index is stored.'
              : _days == 1
              ? '${periodSeries.samples.length} values across ${periodSeries.coveredHours} hours. The value is shown only in its original unitless form.'
              : '${periodSeries.samples.length} unitless values retained across the last $_days days.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        _HeroMetricCard(
          title: _days == 1
              ? 'Captured index timeline'
              : 'Median index across $_days days',
          child: Column(
            children: <Widget>[
              _TimedLineChart(
                values: chartValues ?? const <_TimedPlotValue>[],
                accent: true,
              ),
              const SizedBox(height: 10),
              _AxisLabels(
                left: _days == 1 ? '00:00' : 'Earlier',
                right: _days == 1 ? '23:59' : 'Latest',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _HeroMetricCard(
          title: 'Observed values',
          child: _ThreeStats(
            values: <_StatValue>[
              _StatValue('${periodSeries?.median ?? '—'}', 'Median index'),
              _StatValue('${periodSeries?.minimum ?? '—'}', 'Minimum'),
              _StatValue('${periodSeries?.maximum ?? '—'}', 'Maximum'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RecentValuesCard(
          title: 'Recent captured values',
          values:
              periodSeries?.samples.reversed.take(7).toList() ??
              const <TimedValue>[],
          unit: 'index',
        ),
        const SizedBox(height: 18),
        _Disclosure(
          isStress
              ? 'The protocol exposes this as a stress index, but its formula and thresholds are unverified. LibreRing does not call it relaxed, normal, or high.'
              : 'The protocol exposes this as an HRV index, but its unit and calculation are unverified. LibreRing does not label it milliseconds or use it for Recovery.',
        ),
      ],
    );
  }
}

class SportRecordScreen extends ConsumerWidget {
  const SportRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider).value ?? const <JournalEntry>[];
    final sports = entries
        .where((value) => value.kind == JournalEntryKind.swim)
        .toList(growable: false);
    final minutes = sports.fold<int>(
      0,
      (sum, value) => sum + (value.durationMinutes ?? 0),
    );
    return _AnalyticsScreen(
      key: const Key('screen-sport-record'),
      activePath: '/trends',
      children: <Widget>[
        const _AnalyticsTopBar(
          title: 'Sport record',
          fallbackPath: '/movement',
        ),
        const SizedBox(height: 26),
        const _Eyebrow('Manual context · local only'),
        const SizedBox(height: 8),
        _Display(
          sports.isEmpty ? 'No activities yet' : '${sports.length} activities',
        ),
        const SizedBox(height: 12),
        Text(
          sports.isEmpty
              ? 'Add an activity when the ring cannot identify the context.'
              : '${_minutes(minutes)} recorded manually. These entries never alter ring measurements.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        if (sports.isEmpty)
          const _EmptyCard('Your first manual sport record will appear here.')
        else
          _HeroMetricCard(
            title: 'Recent activities',
            child: Column(
              children: sports
                  .map(
                    (entry) => _EvidenceRow(
                      icon: Icons.pool_outlined,
                      title: entry.title,
                      value: _minutes(entry.durationMinutes ?? 0),
                      detail:
                          '${DateFormat('d MMM · HH:mm').format(entry.occurredAtUtc.toLocal())} · ${entry.effort ?? 'Manual'}',
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        const SizedBox(height: 18),
        LibreRingPrimaryButton(
          label: 'Add a swim',
          icon: Icons.add,
          onPressed: () => context.go('/journal/swim'),
        ),
      ],
    );
  }
}

class CapabilitiesScreen extends ConsumerWidget {
  const CapabilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(isDemoModeProvider)
        ? null
        : ref.watch(ringDataProvider).value;
    return _AnalyticsScreen(
      key: const Key('screen-capabilities'),
      activePath: '/you',
      children: <Widget>[
        const _AnalyticsTopBar(
          title: 'Ring capabilities',
          fallbackPath: '/you/ring',
        ),
        const SizedBox(height: 26),
        const _Eyebrow('Read-only safety boundary'),
        const SizedBox(height: 8),
        const _Display('What works now'),
        const SizedBox(height: 12),
        Text(
          'A capability only appears as available when the R12 protocol and this firmware have been verified. Device identifiers stay transient.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        _CapabilityGroup(
          title: 'Available locally',
          values: <_CapabilityValue>[
            _CapabilityValue(
              'Battery',
              dataset?.batteryLevel == null
                  ? 'No recent value'
                  : '${dataset!.batteryLevel}% at last sync',
            ),
            _CapabilityValue(
              'Activity history',
              '${dataset?.activity.length ?? 0} decoded buckets',
            ),
            _CapabilityValue(
              'Pulse history',
              '${dataset?.heartRate.length ?? 0} measured samples',
            ),
            _CapabilityValue(
              'Sleep and stages',
              '${dataset?.sleep.length ?? 0} firmware sessions',
            ),
            _CapabilityValue(
              'Oxygen history',
              '${dataset?.oxygen.length ?? 0} hourly ranges',
            ),
            _CapabilityValue(
              'Firmware indexes',
              '${dataset?.vendorIndexes.length ?? 0} opaque values',
            ),
            const _CapabilityValue('Device time', 'Time synchronisation only'),
          ],
        ),
        const SizedBox(height: 14),
        const _CapabilityGroup(
          title: 'Not yet available',
          available: false,
          values: <_CapabilityValue>[
            _CapabilityValue(
              'Gesture and display controls',
              'Write protocol not enabled',
            ),
            _CapabilityValue(
              'Find ring and camera shutter',
              'Command path not safely validated',
            ),
            _CapabilityValue(
              'Monitoring schedules',
              'Read/write preference semantics incomplete',
            ),
            _CapabilityValue(
              'Live pulse or oxygen',
              'Stable user-facing flow not validated',
            ),
            _CapabilityValue('Apple Health', 'HealthKit integration not built'),
            _CapabilityValue(
              'Firmware update',
              'No signed update path is available',
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _Disclosure(
          'Unavailable does not mean the ring has no capability. It means LibreRing will not expose a control until the exact behavior is understood and reversible.',
        ),
      ],
    );
  }
}

class _AnalyticsScreen extends StatelessWidget {
  const _AnalyticsScreen({
    required this.children,
    required this.activePath,
    super.key,
  });

  final List<Widget> children;
  final String activePath;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ),
    bottomNavigationBar: _AnalyticsBottomNav(activePath: activePath),
  );
}

class _AnalyticsBottomNav extends StatelessWidget {
  const _AnalyticsBottomNav({required this.activePath});

  final String activePath;

  @override
  Widget build(BuildContext context) {
    const items = <(String, IconData, String)>[
      ('/today', Icons.home_outlined, 'Today'),
      ('/trends', Icons.trending_up, 'Trends'),
      ('/you', Icons.person_outline, 'You'),
    ];
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 14),
      child: Center(
        heightFactor: 1,
        child: Container(
          width: 226,
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: LibreRingTokens.foreground,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: items
                .map((item) {
                  final selected = item.$1 == activePath;
                  return Expanded(
                    child: Semantics(
                      label: item.$3,
                      selected: selected,
                      button: true,
                      child: IconButton(
                        onPressed: () => context.go(item.$1),
                        color: selected
                            ? Colors.white
                            : const Color(0xFFC5C2BC),
                        style: IconButton.styleFrom(
                          backgroundColor: selected
                              ? const Color(0xFF42423E)
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(item.$2, size: 20),
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

class _AnalyticsTopBar extends StatelessWidget {
  const _AnalyticsTopBar({
    required this.title,
    required this.fallbackPath,
    this.trailing,
  });

  final String title;
  final String fallbackPath;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: <Widget>[
        IconButton(
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(fallbackPath),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        Expanded(
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(width: 48, child: trailing),
      ],
    ),
  );
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<int>(
    key: const Key('analytics-range-selector'),
    showSelectedIcon: false,
    segments: const <ButtonSegment<int>>[
      ButtonSegment(value: 1, label: Text('Day')),
      ButtonSegment(value: 7, label: Text('Week')),
      ButtonSegment(value: 30, label: Text('Month')),
    ],
    selected: <int>{selected},
    onSelectionChanged: (value) => onChanged(value.first),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
      color: LibreRingTokens.muted,
    ),
  );
}

class _Display extends StatelessWidget {
  const _Display(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      value,
      maxLines: 1,
      style: const TextStyle(
        fontSize: 58,
        height: .94,
        fontWeight: FontWeight.w200,
        letterSpacing: -3.2,
      ),
    ),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 22),
        child,
      ],
    ),
  );
}

class _StatValue {
  const _StatValue(this.value, this.label);
  final String value;
  final String label;
}

class _ThreeStats extends StatelessWidget {
  const _ThreeStats({required this.values});

  final List<_StatValue> values;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List<Widget>.generate(values.length, (index) {
      final item = values[index];
      return Expanded(
        child: Container(
          padding: EdgeInsets.only(
            left: index == 0 ? 0 : 12,
            right: index == values.length - 1 ? 0 : 12,
          ),
          decoration: index == values.length - 1
              ? null
              : const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: LibreRingTokens.border),
                  ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: LibreRingTokens.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

class _MetricTimelineCard extends StatelessWidget {
  const _MetricTimelineCard({
    required this.title,
    required this.value,
    required this.note,
    required this.values,
    required this.color,
  });
  final String title;
  final String value;
  final String note;
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) => _HeroMetricCard(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w200,
            letterSpacing: -1.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          note,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 22),
        _BarChart(values: values, color: color),
      ],
    ),
  );
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 620),
    curve: LibreRingTokens.curve,
    tween: Tween<double>(begin: 0, end: 1),
    builder: (context, progress, child) => SizedBox(
      height: 132,
      width: double.infinity,
      child: CustomPaint(painter: _BarChartPainter(values, color, progress)),
    ),
  );
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(this.values, this.color, this.progress);
  final List<double> values;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = LibreRingTokens.border;
    for (final y in <double>[.25, .55, .85]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        grid,
      );
    }
    if (values.isEmpty) return;
    final maximum = math.max(1.0, values.reduce(math.max));
    final slot = size.width / values.length;
    final paint = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final height = (size.height * .78 * values[i] / maximum) * progress;
      final width = math.max(2.0, math.min(9.0, slot * .48));
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          slot * i + (slot - width) / 2,
          size.height * .88 - height,
          width,
          height,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.progress != progress ||
      oldDelegate.color != color;
}

class _TimedPlotValue {
  const _TimedPlotValue(this.at, this.value);
  final DateTime at;
  final double value;
}

class _TimedLineChart extends StatelessWidget {
  const _TimedLineChart({required this.values, this.accent = false});
  final List<_TimedPlotValue> values;
  final bool accent;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 680),
    curve: LibreRingTokens.curve,
    tween: Tween<double>(begin: 0, end: 1),
    builder: (context, progress, child) => SizedBox(
      height: 190,
      width: double.infinity,
      child: CustomPaint(painter: _TimedLinePainter(values, progress, accent)),
    ),
  );
}

class _TimedLinePainter extends CustomPainter {
  _TimedLinePainter(this.values, this.progress, this.accent);
  final List<_TimedPlotValue> values;
  final double progress;
  final bool accent;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = LibreRingTokens.border;
    for (final y in <double>[.2, .5, .8]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        grid,
      );
    }
    if (values.isEmpty) return;
    final sorted = values.toList(growable: false)
      ..sort((a, b) => a.at.compareTo(b.at));
    final min = sorted.map((value) => value.value).reduce(math.min);
    final max = sorted.map((value) => value.value).reduce(math.max);
    final range = math.max(1.0, max - min);
    final first = sorted.first.at.millisecondsSinceEpoch;
    final last = sorted.last.at.millisecondsSinceEpoch;
    final timeRange = math.max(1, last - first);
    final path = Path();
    for (var index = 0; index < sorted.length; index++) {
      final value = sorted[index];
      final x = sorted.length == 1
          ? size.width / 2
          : size.width * (value.at.millisecondsSinceEpoch - first) / timeRange;
      if (x > size.width * progress) break;
      final y = size.height * (.82 - ((value.value - min) / range) * .64);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final color = accent ? LibreRingTokens.accent : LibreRingTokens.foreground;
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final value in sorted) {
      final x = sorted.length == 1
          ? size.width / 2
          : size.width * (value.at.millisecondsSinceEpoch - first) / timeRange;
      if (x > size.width * progress) break;
      final y = size.height * (.82 - ((value.value - min) / range) * .64);
      canvas.drawCircle(
        Offset(x, y),
        2.8,
        Paint()..color = LibreRingTokens.accent,
      );
    }
  }

  @override
  bool shouldRepaint(_TimedLinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent;
}

class _OxygenBandChart extends StatelessWidget {
  const _OxygenBandChart({required this.ranges});
  final List<RingOxygenRange> ranges;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 620),
    curve: LibreRingTokens.curve,
    tween: Tween<double>(begin: 0, end: 1),
    builder: (context, progress, child) => SizedBox.expand(
      child: CustomPaint(painter: _OxygenBandPainter(ranges, progress)),
    ),
  );
}

class _OxygenBandPainter extends CustomPainter {
  _OxygenBandPainter(this.ranges, this.progress);
  final List<RingOxygenRange> ranges;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = LibreRingTokens.border;
    for (final y in <double>[.2, .5, .8]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        grid,
      );
    }
    if (ranges.isEmpty) return;
    final width = size.width / ranges.length;
    final paint = Paint()
      ..color = LibreRingTokens.accent
      ..strokeWidth = math.min(8, width * .55)
      ..strokeCap = StrokeCap.round;
    double yFor(int value) =>
        size.height * (.88 - ((value.clamp(80, 100) - 80) / 20) * .72);
    for (var index = 0; index < ranges.length; index++) {
      if ((index + 1) / ranges.length > progress) break;
      final value = ranges[index];
      final x = width * index + width / 2;
      canvas.drawLine(
        Offset(x, yFor(value.minimumPercent)),
        Offset(x, yFor(value.maximumPercent)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OxygenBandPainter oldDelegate) =>
      oldDelegate.ranges != ranges || oldDelegate.progress != progress;
}

class _SleepRibbon extends StatelessWidget {
  const _SleepRibbon(this.stages);
  final List<RingSleepStageSpan> stages;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('No stage runs retained')),
      );
    }
    return SizedBox(
      height: 108,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: stages
            .map((span) {
              final level = switch (span.stage) {
                RingSleepStage.awake => 1.0,
                RingSleepStage.rem => .82,
                RingSleepStage.light => .62,
                RingSleepStage.deep => .38,
              };
              return Expanded(
                flex: math.max(1, span.durationMinutes),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: level,
                    widthFactor: .94,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _stageColor(span.stage),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    this.stage,
    this.label,
    required this.minutes,
    required this.percent,
    this.color,
  });
  final RingSleepStage? stage;
  final String? label;
  final int minutes;
  final int percent;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label ?? _stageName(stage!),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${_minutes(minutes)} · $percent%',
              style: const TextStyle(
                fontSize: 10.5,
                color: LibreRingTokens.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: (percent / 100).clamp(0, 1),
            color: color ?? _stageColor(stage!),
            backgroundColor: LibreRingTokens.soft,
          ),
        ),
      ],
    ),
  );
}

class _RecentSleepCard extends StatelessWidget {
  const _RecentSleepCard({required this.sessions});
  final List<SleepAnalytics> sessions;

  @override
  Widget build(BuildContext context) => _HeroMetricCard(
    title: 'Recent sleep sessions',
    child: Column(
      children: sessions
          .map(
            (value) => _EvidenceRow(
              icon: Icons.bedtime_outlined,
              title: DateFormat('EEE, d MMM')
                  .format(value.session.endedAtUtc.toLocal()),
              value: _minutes(value.intervalMinutes),
              detail:
                  '${value.recordedStageMinutes} stage minutes · firmware estimate',
            ),
          )
          .toList(growable: false),
    ),
  );
}

class _RecentValuesCard extends StatelessWidget {
  const _RecentValuesCard({
    required this.title,
    required this.values,
    required this.unit,
  });
  final String title;
  final List<TimedValue> values;
  final String unit;

  @override
  Widget build(BuildContext context) => _HeroMetricCard(
    title: title,
    child: values.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No captured values')),
          )
        : Column(
            children: values
                .map(
                  (value) => _EvidenceRow(
                    icon: Icons.circle,
                    title: '${value.value} $unit',
                    value: _clock(value.at),
                    detail: DateFormat('EEE, d MMM').format(value.at.toLocal()),
                  ),
                )
                .toList(growable: false),
          ),
  );
}

class _RangeListCard extends StatelessWidget {
  const _RangeListCard({required this.ranges});
  final List<RingOxygenRange> ranges;

  @override
  Widget build(BuildContext context) => _HeroMetricCard(
    title: 'Recent hourly ranges',
    child: ranges.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No captured ranges')),
          )
        : Column(
            children: ranges
                .map(
                  (value) => _EvidenceRow(
                    icon: Icons.water_drop_outlined,
                    title: '${value.minimumPercent}–${value.maximumPercent}%',
                    value: _clock(value.hourStartedAtUtc),
                    detail: 'Minimum–maximum · ring history',
                  ),
                )
                .toList(growable: false),
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
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 66),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: LibreRingTokens.border)),
    ),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 18, color: LibreRingTokens.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: LibreRingTokens.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 11, color: LibreRingTokens.muted),
        ),
      ],
    ),
  );
}

class _CapabilityValue {
  const _CapabilityValue(this.label, this.detail);
  final String label;
  final String detail;
}

class _CapabilityGroup extends StatelessWidget {
  const _CapabilityGroup({
    required this.title,
    required this.values,
    this.available = true,
  });
  final String title;
  final List<_CapabilityValue> values;
  final bool available;

  @override
  Widget build(BuildContext context) => _HeroMetricCard(
    title: title,
    child: Column(
      children: values
          .map(
            (value) => _EvidenceRow(
              icon: available ? Icons.check_circle_outline : Icons.lock_outline,
              title: value.label,
              value: available ? 'Available' : 'Unavailable',
              detail: value.detail,
            ),
          )
          .toList(growable: false),
    ),
  );
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(LibreRingTokens.cardRadius),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LibreRingTokens.foreground,
        borderRadius: BorderRadius.circular(LibreRingTokens.cardRadius),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 26, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFFCBC8C1),
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: action,
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Disclosure extends StatelessWidget {
  const _Disclosure(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 14),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: LibreRingTokens.accent, width: 2)),
    ),
    child: Text(value, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => LibreRingCard(
    child: SizedBox(
      height: 180,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.hourglass_empty,
            size: 28,
            color: LibreRingTokens.muted,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _AxisLabels extends StatelessWidget {
  const _AxisLabels({required this.left, required this.right});
  final String left;
  final String right;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Text(
        left,
        style: const TextStyle(fontSize: 9, color: LibreRingTokens.muted),
      ),
      Text(
        right,
        style: const TextStyle(fontSize: 9, color: LibreRingTokens.muted),
      ),
    ],
  );
}

Color _stageColor(RingSleepStage stage) => switch (stage) {
  RingSleepStage.awake => const Color(0xFFF0C989),
  RingSleepStage.rem => const Color(0xFFD5B7A8),
  RingSleepStage.light => const Color(0xFFB77E69),
  RingSleepStage.deep => LibreRingTokens.accent,
};

String _stageName(RingSleepStage stage) => switch (stage) {
  RingSleepStage.awake => 'Awake',
  RingSleepStage.rem => 'REM',
  RingSleepStage.light => 'Light',
  RingSleepStage.deep => 'Deep',
};

String _minutes(int value) {
  final hours = value ~/ 60;
  final minutes = value.remainder(60);
  if (hours == 0) return '$minutes min';
  return '$hours h ${minutes.toString().padLeft(2, '0')} min';
}

String _clock(DateTime value) => DateFormat('HH:mm').format(value.toLocal());

String _distance(int meters) =>
    meters < 1000 ? '$meters m' : '${(meters / 1000).toStringAsFixed(2)} km';
