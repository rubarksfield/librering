# LibreRing refinement — 5 September 2026

## Purpose

Improve the complete everyday R12 experience without treating unsupported
signals as features. Preserve the established warm, local-first identity while
making readings, navigation, historical inspection, and failure recovery feel
coherent. This is a local development refinement, not a claim of clinical
validation or an App Store release.

## Implemented

- Today: sleep summary, steps, pulse, oxygen range, distance, personal movement
  goal, calendar browsing, pull to refresh, and clear stale/error/loading states.
- Vitals: scan-friendly supported-signal grid, historical day selection, source
  explanations behind disclosure, and explicitly unvalidated firmware indexes.
- Trends: interactive chronological daily points, real gaps, recorded zeroes,
  7/30/90-day ranges, recorded-day averages, previous-period comparisons, and
  selected-day drill-through.
- Details: native back navigation, bounded calendars/periods, proportional
  time axes, touch/keyboard/accessibility selection, sleep-stage exploration,
  and multiple retained sessions.
- You: quieter profile and settings, persistent name/units/personal goals,
  honest last-reported battery and connection status, and readily reachable
  export/deletion controls.
- Journal: single-submit saves, retry with the draft intact, correct per-form
  saved status, and guarded deletion with failures surfaced.
- Reliability: serialized storage writes, export waits for outstanding writes,
  unavailable is not zero, future records are excluded, and sleep-stage bounds,
  overlaps, conflicts, and unclassified intervals are handled explicitly.
- Recovery: unreadable local files can be removed only after an explicit,
  irreversible-deletion warning. Cancelling retains identical bytes; successful
  removal unblocks subsequent durable sync/journal saves.
- Preferences: minute-precise sleep targets survive reopening and editing an
  unrelated field. Demo settings explicitly disclose their session-only scope.
- Accessibility: scalable layouts, real semantic navigation actions, labelled
  chart values, minimum touch targets, contrast checks, and reduced-motion-aware
  transitions. No animated interpolation of measured health values.

## Intentional limits

No fabricated readiness/recovery, temperature, blood pressure, VO2 max,
emotional stress, clinical HRV, or ring GPS. Cycle switches that did not enforce
real functionality were removed. Live sensor transport is not promoted as a
validated measurement feature. Demo records remain explicitly fictional and
separate from the production store.

Calendar presentation handles 23/25-hour local days, but existing ring packet
decoders do not retain historical timezone/travel provenance. Reconstructing
ambiguous historical wall-clock packets remains protocol work, not a UI fix.

Sync is deliberately user-triggered. Automatic nearby-device scans on launch
or resume were removed: the current app does not persist a verified ring binding,
so discovering one nearby R12 is not proof that it is the user's own ring.

## Main changed areas

- `apps/mobile/lib/src/dashboard_screens.dart`: Today, Vitals and Trends.
- `apps/mobile/lib/src/ui/app_chrome.dart` and `apps/mobile/lib/app.dart`:
  shared layout, persistent root tabs, native navigation and accessibility.
- `apps/mobile/lib/src/analytics_screens.dart`, `ring_analytics.dart`,
  `ring_data_view.dart`, and `ring_product_view.dart`: supported-history detail,
  interval calculations and honest presentation.
- `apps/mobile/lib/src/product_system_screens.dart`, `screens.dart`,
  `app_state.dart`, `storage/preferences_repository.dart`, and `main.dart`:
  timeline, settings, forms, local storage, sync and recovery.
- `packages/ring_design_system/lib/src/`: palette, type, controls and theme.
- Mobile/package tests, 22 golden renders, README and roadmap.

The Fable Loop inspect–fix–verify workflow was used for the audit and regression
passes. The web-only Taste skill was not applied to native Flutter; the existing
LibreRing brand and native mobile interaction conventions guided the refinement.

## Verification

Final command results are recorded below. All data in golden renders and the
simulator walkthrough is deterministic or explicitly fictional, not personal
health records.

| Check | Result |
| --- | --- |
| Mobile `flutter analyze` | Clean |
| Mobile `flutter test --reporter expanded` | 165 tests pass, including 22 golden screen checks and the iOS back-gesture regression |
| Five reusable packages: `flutter analyze` and `flutter test` | Clean; 47 tests pass |
| Scoring sandbox `python3 -m unittest discover tests -v` | 13 tests pass; synthetic research only |
| `dart format --output=none --set-exit-if-changed` | Clean |
| `git diff --check` | Clean |
| `flutter build ios --release --no-codesign` | Pass; production data mode, unsigned artifact |
| `flutter build ios --simulator --dart-define=LIBRERING_DEMO=true` | Pass; installed and launched on iPhone 17 Pro simulator, iOS 26.5 |
| `flutter build apk --debug` | Pass; production data mode |

Native simulator walkthrough confirmed Today → previous day → Vitals retains
the selected day; sleep-stage taps update their description; trend metric/range
selection and selected-day drill-through work; returning preserves the chart
selection; and profile name/units survive leaving and reopening the form within
the demo session. Durable preferences across fresh launches are covered by
repository/controller tests. Direct text injection through the Simulator tool
was unavailable; the native onscreen keyboard successfully entered the test
name. Simulator mouse-drag did not establish edge-swipe behavior, so a dedicated
iOS-targeted widget gesture regression separately verifies that navigation path.

Physical R12 sync, full VoiceOver on a real phone, background behavior, battery
impact, Android hardware/visual QA and historical travel/timezone provenance
remain unverified. English is the primary refined interface; complete Portuguese
translation remains outstanding. The Android build reports existing Java native
access/SDK-tooling version warnings, but succeeds. No dependency versions were
changed to silence warnings.

At the end of this refinement pass, no GitHub push or installation on the user's
phone had been performed. Phone delivery is a separate step requiring signing
and a profile/release build; a debug simulator build is not Home Screen launch
proof. A development-signed phone build is not an App Store distribution release.

## Phone delivery — version 1.3.0 (11)

The subsequent delivery request was built with `flutter build ios --release`
and explicit `LIBRERING_DEMO=false` / `LIBRERING_CAPTURE=false` definitions.
Development signing and `codesign --verify --deep --strict` passed. Installation
updated the existing app without uninstalling it or invoking any data-deletion
operation. Device inventory readback confirmed version 1.3.0, build 11.

The first launch attempt was refused because the phone was locked; this is not
an app-crash or debug-mode result. A complete on-device UX/BLE session remains
separate from successful installation. Release analysis was clean and all 165
mobile tests passed again before publication.
