# Changelog

Notable changes to LibreRing. Version numbers refer to app/source milestones,
not App Store or TestFlight releases. Earlier milestones below link to the
commits and QA records that establish them; they are not retroactive GitHub
release tags.

## [1.3.2](https://github.com/rubarksfield/librering/releases/tag/v1.3.2) — 2026-09-08

App version **1.3.2+13**. Development preview / source release; no public IPA,
App Store, Play Store or TestFlight distribution.

### Added

- Pull-to-refresh saved phone readings on Today, Vitals, Trends, Activity,
  Sleep, Pulse, Oxygen, firmware HRV/stress details and the day timeline.
  Short and empty pages support the gesture too. It does not contact the ring;
  **Sync** remains the explicit Bluetooth history action.
- Restrained native haptics for navigation, chart and date selection,
  explanation sheets, explicit sync and actual refresh/save/delete outcomes.
  Chart ticks are throttled and deduplicated; sleep ticks follow stage and gap
  boundaries. Disabled controls and passive updates remain quiet.
- In-app live-pulse help distinguishing saved samples, Bluetooth connection
  and on-demand measurement.
- A current-version screenshot gallery and screen tour using deterministic
  fictional fixtures on the production UI path.

### Fixed

- Newly saved readings no longer wait for the app's next one-minute clock tick
  to become visible. Successful sync updates Today and an already visited Vitals
  tab without an extra pull. The bounded delay was reproduced in tests; this is
  not a claim that every physical-ring missing-data report is resolved.
- Local refresh is serialized with writes and deletions. Existing readings stay
  visible during reload and after failure; a retry can recover an initial
  transient read failure. Result messages are available in English/Portuguese.
- Refresh preserves a selected historical day. Changed chart data clears stale
  sample selection; unchanged data keeps it. Trends tracks a calendar date
  rather than a shifting array position across midnight.
- Haptic platform errors cannot prevent an action, and persistence success
  feedback follows the actual save rather than the initial button press.

### Capability boundary

Live pulse and oxygen are reported as **unavailable in production**, matching
the existing measurement gate. Owned-ring tests produced warm-up responses but
no usable readings; safe completion/stop/cancel still needs physical validation.
History remains supported. No new BLE commands or production live-measurement
feature were introduced.

### Verification and delivery

- Mobile release preflight: **427 tests passed**, analyzer clean.
- R12 driver: **33 tests passed**, analyzer clean; production live rejection
  verifies zero BLE writes. Design system: **4 tests passed**.
- Production-mode iOS release build and signing verification passed. Installed
  in place on an owned iPhone; inventory confirmed **1.3.2 (13)**. After unlock,
  process launch and a follow-up running-process check succeeded.
- Hardware sync regression, tactile feel and full real-device accessibility are
  not established by build/install evidence alone. Live measurement remains
  separately gated.

Evidence: [release delivery](docs/testing/release-1.3.2.md),
[refresh/haptics QA](docs/testing/refresh-haptics-2026-09-07.md),
[live-pulse acceptance](docs/testing/live-pulse-acceptance-2026-09-07.md).

## 1.3.1 — 2026-09-05

App version **1.3.1+12**.
[Source milestone](https://github.com/rubarksfield/librering/commit/716509f6084ab111afbea418ceb23de377ae8e48).

- Added visible sync stages, elapsed time, stalled/partial/error states and
  recovery help; separated last-reported ring battery from sync progress.
- Unified sleep around the green palette and added continuous stage inspection,
  including hold/vertical scrubbing and accessible adjustments.
- Added bounded daily suggestions with **Why this?** explanations and manual
  context. Opaque firmware HRV/stress indexes do not drive health advice.
- Put HRV, stress and energy education beside the readings. Unverified energy
  is labelled **Ring energy value**, not confirmed active calories; values were
  not silently recalculated or assigned invented units.
- Clarified local data, accounts and costs, and added safe introduction replay
  without resetting pairing, history or preferences.
- Verified **349 mobile tests** and **31 R12 protocol tests**, clean analyzers,
  signed iOS release and in-place installation. Initial launch verification was
  blocked by the phone being locked.

Evidence: [1.3.1 delivery](docs/testing/release-1.3.1.md),
[in-app explanations](docs/testing/in-app-explanations-2026-09-05.md).

## 1.3.0 — 2026-09-05

App version **1.3.0+11**.
[Source milestone](https://github.com/rubarksfield/librering/commit/184eaa4).

- Refined Today, Vitals and Trends around supported ring history, with retained
  tab position, historical browsing and inspectable 7/30/90-day comparisons.
- Improved chart axes, missing-data handling, sleep-session integrity,
  accessibility and reduced-motion behaviour.
- Persisted name, units and personal goals locally; improved journal saving,
  failure recovery, export ordering and explicit damaged-file recovery.
- Removed automatic nearby-device scans on launch/resume: discovery alone does
  not prove ownership of a ring.
- Verified **165 mobile tests** and **47 reusable-package tests**, iOS simulator
  and Android debug builds; subsequently installed development-signed iOS
  **1.3.0 (11)**. Physical-device UX/BLE acceptance remained separate.

Evidence: [refinement and delivery record](docs/testing/refinement-2026-09-05.md).

## 1.2.0 — 2026-09-03

App version **1.2.0+10** in the published source milestone—not a claim about
earlier device build numbers.
[Source milestone](https://github.com/rubarksfield/librering/commit/290c06906b71dade17774f0c9f2115ed4ca7a7f5).

- Published the project showcase, branded iOS/Android app icons and expanded
  product screens, including profile, timeline and manual activity flows.
- Added contribution/security guidance, issue and pull-request templates, a
  roadmap, and GitHub Actions checks.
- Published an initial screenshot gallery and tour. Those earlier showcase
  assets are superseded on the front page by the versioned 1.3.2 captures.

This historical entry is based on the source commit and its package version;
it does not imply a GitHub release tag or public binary existed at the time.
