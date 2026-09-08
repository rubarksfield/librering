# Saved-reading refresh and tactile feedback

Implemented and locally checked on 2026-09-07. No phone installation, GitHub
push, live measurement or raw-data capture was performed in this change.

Subsequent phone delivery on 2026-09-08 is recorded in
[release 1.3.2](release-1.3.2.md).

## Behavior

- Pull down on Today, Vitals, Trends, activity, sleep, pulse, oxygen, firmware
  signal detail and the day timeline to reload **saved phone data only**.
  The gesture also works on short/empty reading pages. Demo pages do not read
  real storage or contact a ring.
- The Today Sync button still explicitly starts the Bluetooth history sync.
  A successful save publishes readings automatically, including to a previously
  visited Vitals tab. A second pull is not required.
- Local refresh is serialized with saves/deletions. Existing readings remain
  visible during reload and on failure; EN/PT result messages distinguish refresh
  from Sync. Retry can recover an initial transient storage-read failure.
- A reproduced cached-clock bug could hide samples newer than the app's last
  one-minute clock tick. Successful merge/refresh now advances that clock before
  publishing the data. This proves a bounded display-delay fix, **not** the cause
  of every missing reading reported from the physical phone.
- Explicit historical dates remain selected. Changed chart data clears stale
  sample inspection; unchanged data retains it. Trends tracks the selected
  calendar day, rather than a relative array index across midnight.
- Restrained native haptics cover navigation, calendar/range/filter selection,
  explanation sheets, explicit sync, refresh results, and form save/delete
  results. Disabled/repeated controls and passive data changes remain quiet.
  Chart ticks are deduplicated and limited to one per 100 ms; sleep ticks mark
  stage/gap boundaries, not every movement. Haptic platform failures cannot
  prevent the user's action. Persistence feedback follows the actual save result.
- Live pulse is not falsely advertised as production-supported. The heart-rate
  page explains the difference between saved samples and live acquisition.
  See [live pulse acceptance](live-pulse-acceptance-2026-09-07.md) for the missing
  worn-ring evidence and stop/cancel validation.

## Main files

- `apps/mobile/lib/src/app_state.dart`: serialized local refresh and clock fix.
- `apps/mobile/lib/src/ui/refresh_readings.dart`: local-only UI callback/results.
- `apps/mobile/lib/src/dashboard_screens.dart`, `analytics_screens.dart`,
  `product_system_screens.dart`: pull gestures, chart-selection integrity,
  tactile interactions and live-pulse help.
- `apps/mobile/lib/src/ui/app_chrome.dart`, `ui/ring_status_help.dart`,
  `screens.dart`: shared interaction feedback, refresh/sync education and
  journal-form result feedback.
- `packages/ring_design_system/lib/src/haptics.dart`, `components.dart`:
  semantic effects, throttled chart ticks and shared button behavior; mobile
  `ui/haptics.dart` re-exports the same policy.
- `packages/ring_colmi_qring/lib/src/driver.dart`: live capability metadata
  agrees with the existing production gate; no new BLE commands.

## Verification

Run from the relevant package directory:

- Mobile: `flutter test --no-pub --reporter expanded` — 427 tests passed.
- Mobile: `flutter analyze --no-pub` — no issues.
- R12 driver: `dart test --reporter expanded` — 33 tests passed;
  `dart analyze` — no issues.
- Design system: `flutter test --no-pub --reporter expanded` — 4 tests passed.
- iOS: `flutter build ios --release --no-codesign --no-pub
  --dart-define=LIBRERING_DEMO=false --dart-define=LIBRERING_CAPTURE=false`
  — release app built. This is an **unsigned local compilation check**, not
  installation or physical-device acceptance.
- Changed Dart files pass the formatter check; `git diff --check` is clean.

Focused coverage includes local repository concurrency, initial-read recovery,
failing-before-fix clock regressions, actual pull gestures on ten routes,
automatic post-sync UI updates, historical-date preservation, haptic channel
effects/throttling, pending/failed saves, demo isolation, localized explanations,
sleep scrubbing and live-driver zero-write rejection. Dedicated iOS-platform
tests exercise pull gestures on Today, Vitals and Heart, including an empty
page; nine chart regressions cover same-count replacements and midnight refresh.

## Remaining physical checks

The reported phone sync was not reproduced with real ring data this turn.
The tactile feel and new refresh gesture still need a phone pass after delivery.
Live pulse needs a separate, approved, bounded worn-ring test; successful
synthetic fixtures or Bluetooth connection alone do not satisfy it.
