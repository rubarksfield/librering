# Today: gentle daily guidance

Implemented 2026-09-05. Local, deterministic wellbeing suggestions, not a recovery score, medical assessment or exercise prescription. Reference screenshots are not evidence of a supported measurement.

## What the user sees

One optional suggestion near the top of Today, a visible reason, an action and an offline “Why this?” explanation. Existing sage styling is retained. Historical dates never receive present-tense suggestions. Active sync and unavailable preferences do not generate new guidance. Demo guidance is labelled and never reads the real journal.

Priority:

1. Today's explicit **Illness** check-in: take the pressure off activity goals.
2. Today's explicit **Stress** or **Low energy** check-in: offer a comfortable pause. These two optional tags are now available in the existing check-in form, with canonical stored values and Portuguese labels. Free-text notes are not analysed.
3. Sufficient recorded sleep ending today below the current saved target: consider time to wind down before the next sleep, not a diagnosis of poor sleep.
4. Recent recorded steps: acknowledge the goal if reached, otherwise offer an optional comfortable walk. A manual Exercise or swim entry suppresses a below-goal walk nudge; a non-step activity is not inactivity.
5. Without sufficient context: a neutral check-in invitation, not a fabricated assessment.

## Conservative eligibility rules

Rules live in `apps/mobile/lib/src/daily_guidance.dart`. Thresholds are product guardrails, not scientifically validated clinical or exercise-readiness cut-offs.

- Today only, using the local calendar; future-dated check-ins and readings are not evidence.
- Failed or pending journal reads cannot silently permit an exercise recommendation.
- Steps: complete activity transfer, sync and latest actual activity record each at most two hours old; 12:00–19:59 local time. A below-goal nudge needs positive recorded steps across at least three distinct hours. Valid quarter-hour R12 records remain separate. Duplicate timestamps or negative steps invalidate the comparison.
- A complete transfer is **not** proof of complete wear time. Copy always describes recorded steps, never how sedentary or inactive the person has been. Fresh battery-only syncs cannot substitute for fresh activity records.
- Sleep: complete sleep transfer synced today, completed valid sessions ending today, fully classified bounded stages, at least one session of three hours, no overlapping session windows. Sum all qualifying sleep ending today, including naps. At least 60 minutes below the saved target and positive recorded sleep, after 08:00. Never call it “last night”: it could be daytime sleep. Missing/conflicting stages and nap-only records do not justify the suggestion.
- Explicit manual context takes priority even when ring data is stale. Delete the relevant journal entry to remove that context; it also expires at the next local day.

## Deliberately excluded

- Running readiness, training intensity, diagnosis, “your body needs recovery”, or a claim that the user has had a stressful day based on ring data.
- Firmware HRV/stress indexes, pulse/oxygen thresholds, unverified calorie estimates, invented energy or recovery scores.
- Reading sentiment from notes, cloud AI, account creation, uploads, automatic exercise logging or notifications.

An activity CTA opens existing history; it does not start tracking. The pause guide does not record a completed exercise. Suggestions do not change personal goals. How the person feels, their circumstances and clinical advice take priority.

## General wording sources

Checked 2026-09-05; none validates personalised R12 recommendations:

- [NHS: Walking for health](https://www.nhs.uk/live-well/exercise/walking-for-health/) — gradual, accessible walking. The app does not impose a pace or distance.
- [NHS: Breathing exercises for stress](https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/breathing-exercises-for-stress/) — a comfortable position and gentle, unforced breathing. The app offers no breath holds, performance target or treatment claim.
- [NHS Every Mind Matters: Sleep guidance](https://www.nhs.uk/every-mind-matters/mental-wellbeing-tips/how-to-fall-asleep-faster-and-sleep-better/) — a calm wind-down before sleep. The app does not infer training safety from sleep duration.

## Verification scope

Rules have unit coverage; card tests cover copy, routes, explanation, Portuguese, accessibility and large text; Today tests cover goals, persistence, unavailable stores, history and demo isolation. Golden images verify actual rendered layout. This is local application verification, not clinical validation or a physical-phone deployment test.

Verified on 2026-09-05:

- `flutter test --no-pub --reporter expanded`: **310 passed**, including 38 guidance rule tests, 41 card tests and 9 Today integration tests.
- `flutter analyze --no-pub`: **no issues found**.
- `git diff --check`: **clean**.
- Rendered Today, demo Today and isolated walk/pause cards visually inspected. English and Portuguese cards reflow at 320px and 200% text; explanation sheets respect reduced motion. Existing iOS edge-swipe navigation remains covered.
- Three existing test assumptions were corrected without relaxing their intent: navigation tests now scroll to the below-fold targets before tapping; the imperial-distance assertion matches a numeric miles value rather than the substring in “mind”.
- Independent source review identified and corrected “Update check-in”, which had opened a create-only form. The illness suggestion now opens **View journal**, where existing context can be reviewed or deleted.

## Changed files for this feature

- `apps/mobile/lib/src/daily_guidance.dart`: deterministic eligibility and priority rules.
- `apps/mobile/lib/src/ui/daily_guidance_card.dart`: sage-aligned presentation, EN/PT copy, actions and evidence explanation.
- `apps/mobile/lib/src/dashboard_screens.dart`: Today placement and provider-state guards.
- `apps/mobile/lib/src/screens.dart`: optional Stress and Low energy check-in tags and translations.
- New `daily_guidance_test.dart`, `daily_guidance_card_test.dart` and `daily_guidance_today_test.dart`; targeted updates in `app_routes_test.dart` and `dashboard_refinement_test.dart`.
- New walk/pause goldens and updated `today.png` / `analytics_today.png`.

No changes to ring acquisition, stored measurements, scoring, subscriptions, notifications, or platform permissions in this feature. No phone installation or GitHub push performed.
