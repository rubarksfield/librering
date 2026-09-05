import 'package:ring_core/ring_core.dart';

import 'ring_analytics.dart';
import 'storage/journal_repository.dart';
import 'storage/preferences_repository.dart';

enum DailyGuidanceKind {
  checkIn,
  takeItEasy,
  pause,
  windDown,
  walk,
  goalReached,
}

/// An optional, descriptive next step, never a readiness or health assessment.
class DailyGuidance {
  const DailyGuidance({
    required this.kind,
    required this.stepGoal,
    required this.sleepTargetMinutes,
    this.recordedSteps,
    this.sleepMinutes,
  });

  final DailyGuidanceKind kind;
  final int stepGoal;
  final int sleepTargetMinutes;
  final int? recordedSteps;
  final int? sleepMinutes;
}

/// Conservative product rules, not clinical thresholds:
///
/// * Suggestions only describe today, and explicit check-ins take precedence.
/// * Activity needs a complete transfer, a sync and sample within two hours,
///   and three distinct recorded hours for a below-goal suggestion.
/// * Sleep needs fully classified, non-overlapping windows ending today, with
///   one window of at least three hours to avoid treating a nap as daily sleep.
/// * A one-hour difference from the saved sleep target is only a UX margin.
///
/// Missing hours never mean inactivity. No pulse, oxygen, firmware index,
/// calorie estimate, note sentiment, or invented recovery score is used.
DailyGuidance? evaluateDailyGuidance({
  required RingAnalytics analytics,
  required AppPreferences preferences,
  required List<JournalEntry>? journal,
  bool demo = false,
}) {
  final now = analytics.localNow;
  if (!RingCalendar.sameDay(analytics.selectedDay, now)) return null;

  DailyGuidance result(
    DailyGuidanceKind kind, {
    int? steps,
    int? sleepMinutes,
  }) => DailyGuidance(
    kind: kind,
    stepGoal: preferences.dailyStepGoal,
    sleepTargetMinutes: preferences.sleepTargetMinutes,
    recordedSteps: steps,
    sleepMinutes: sleepMinutes,
  );

  // Demo fixtures must never be personalised with the user's real journal.
  if (!demo && journal == null) return result(DailyGuidanceKind.checkIn);
  final entries = demo
      ? const <JournalEntry>[]
      : journal!
            .where(
              (entry) =>
                  !entry.occurredAtUtc.isAfter(now) &&
                  RingCalendar.sameDay(entry.occurredAtUtc, now),
            )
            .toList(growable: false);
  final tags = entries
      .where((entry) => entry.kind == JournalEntryKind.checkIn)
      .expand((entry) => entry.title.split(' · '))
      .toSet();
  if (tags.contains('Illness')) return result(DailyGuidanceKind.takeItEasy);
  if (tags.contains('Stress') || tags.contains('Low energy')) {
    return result(DailyGuidanceKind.pause);
  }

  // Invalid preferences are not a meaningful personal target.
  try {
    preferences.validate();
  } on FormatException {
    return result(DailyGuidanceKind.checkIn);
  }

  final dataset = analytics.dataset;
  final syncedAt = dataset.lastSyncedAtUtc;
  if (syncedAt.isAfter(now)) return result(DailyGuidanceKind.checkIn);

  if (now.hour >= 8 &&
      RingCalendar.sameDay(syncedAt, now) &&
      dataset.availability[RingDataKind.sleep] ==
          RingDataAvailability.complete &&
      _hasTrustworthySleep(analytics, demo: demo)) {
    final minutes = analytics.asleepMinutesFor(now);
    if (minutes != null &&
        minutes > 0 &&
        minutes <= preferences.sleepTargetMinutes - 60) {
      return result(DailyGuidanceKind.windDown, sleepMinutes: minutes);
    }
  }

  if (now.hour < 12 ||
      now.hour >= 20 ||
      now.difference(syncedAt) > const Duration(hours: 2) ||
      dataset.availability[RingDataKind.activity] !=
          RingDataAvailability.complete) {
    return result(DailyGuidanceKind.checkIn);
  }

  final activity = analytics.activityFor(now);
  if (activity.buckets.isEmpty) return result(DailyGuidanceKind.checkIn);
  final seenHours = <String>{};
  final seenRecords = <int>{};
  for (final bucket in activity.buckets) {
    // R12 activity is quarter-hourly. Same-hour samples are valid, but an exact
    // duplicate timestamp could inflate the total. Reject rather than guess
    // which duplicate wins. Values unrelated to steps deliberately play no role.
    if (!_allowedOrigin(bucket.origin, demo: demo) ||
        bucket.steps < 0 ||
        !seenRecords.add(bucket.startedAtUtc.microsecondsSinceEpoch)) {
      return result(DailyGuidanceKind.checkIn);
    }
    seenHours.add(RingCalendar.hourKey(bucket.startedAtUtc));
  }
  if (now.difference(activity.buckets.last.startedAtUtc) >
          const Duration(hours: 2) ||
      activity.steps <= 0) {
    return result(DailyGuidanceKind.checkIn);
  }
  if (activity.steps >= preferences.dailyStepGoal) {
    return result(DailyGuidanceKind.goalReached, steps: activity.steps);
  }
  final hasExercise =
      tags.contains('Exercise') ||
      entries.any((entry) => entry.kind == JournalEntryKind.swim);
  if (seenHours.length >= 3 && !hasExercise) {
    return result(DailyGuidanceKind.walk, steps: activity.steps);
  }
  return result(DailyGuidanceKind.checkIn);
}

bool _allowedOrigin(DataOrigin origin, {required bool demo}) =>
    origin == DataOrigin.ring || (demo && origin == DataOrigin.demo);

bool _hasTrustworthySleep(RingAnalytics analytics, {required bool demo}) {
  final sessions = analytics.sleepOn(analytics.localNow)
    ..sort((a, b) => a.session.startedAtUtc.compareTo(b.session.startedAtUtc));
  if (sessions.isEmpty ||
      !sessions.any((sleep) => sleep.intervalMinutes >= 180)) {
    return false;
  }
  DateTime? previousEnd;
  for (final sleep in sessions) {
    final session = sleep.session;
    final duration = session.endedAtUtc.difference(session.startedAtUtc);
    if (!_allowedOrigin(session.origin, demo: demo) ||
        duration <= Duration.zero ||
        duration != Duration(minutes: sleep.intervalMinutes) ||
        sleep.unclassifiedMinutes != 0 ||
        session.stages.isEmpty ||
        (previousEnd != null && session.startedAtUtc.isBefore(previousEnd))) {
      return false;
    }
    for (final span in session.stages) {
      if (span.durationMinutes <= 0 ||
          span.startedAtUtc.isBefore(session.startedAtUtc) ||
          span.startedAtUtc
              .add(Duration(minutes: span.durationMinutes))
              .isAfter(session.endedAtUtc)) {
        return false;
      }
    }
    previousEnd = session.endedAtUtc;
  }
  return true;
}
