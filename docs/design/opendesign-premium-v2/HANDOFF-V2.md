# LibreRing Premium V2 — Flutter implementation handoff

## 1. Handoff status

`librering-premium-v2.html` is the interaction and visual source for the Premium V2 redesign. It is a browser prototype, not authorization to enable new R12 commands, create a health score, change the local storage contract, or ship production Flutter without the existing product gates.

The canonical product behavior remains in:

- `apps/mobile/lib/app.dart`
- `apps/mobile/lib/src/screens.dart`
- `apps/mobile/lib/src/analytics_screens.dart`
- `apps/mobile/lib/src/ring_analytics.dart`

Implement V2 inside the current Flutter/Riverpod/GoRouter/design-system stack. Do not migrate frameworks or replace the verified repository, decoder, pairing, journal, export, or privacy controllers.

## 2. Route mapping

| Route | Current Flutter screen | V2 composition | Required states |
| --- | --- | --- | --- |
| `/welcome` | `WelcomeScreen` | Product art, promise, setup action, secondary Skip | Default |
| `/privacy` | `PrivacyPromiseScreen` | Local boundary art, storage/export promise, continue | Default |
| `/pairing/scan` | `RingScanScreen` | Pairing status motif, exact-candidate list, scan action | Idle, searching, multiple exact/unconfirmed, unavailable, recoverable failure |
| `/pairing/found` | `RingFoundScreen` | Verified device result, history sync, partial/complete receipt | Connected, syncing, complete, partial, recoverable failure |
| `/today` | `TodayScreen` | Daily story, quiet refresh, glance facts, source-aware signal list | Loading, empty, error, populated, syncing, complete, partial, stale |
| `/metrics` | `MetricsScreen` | Vertical decoded-signal ledger | Loading, empty, error, populated, partial, large text |
| `/movement` | `ActivityLabScreen` | Display value, day/week/month activity instrument, firmware estimates, manual separation | Loading, empty, populated, partial/gaps, range switch, scrub |
| `/sleep` | `SleepLabScreen` | Recorded interval, firmware stage instrument, continuity facts, evidence link | Loading, empty, error, populated, partial stages, scrub |
| `/heart` | `HeartLabScreen` | Latest spot sample, day/week/month instrument, sample summary | Loading, empty, error, populated, partial/gaps, range switch, scrub |
| `/oxygen` | `OxygenLabScreen` | Captured min–max headline, range bars, coverage facts | Loading, empty/no-reading, populated, partial/gaps, range switch, scrub |
| `/signals/hrv-index` | `VendorSignalScreen(firmwareHrv)` | Unitless display, opaque-field timeline, observed values | Loading, empty, populated, partial/gaps, range switch, scrub |
| `/signals/stress-index` | `VendorSignalScreen(stress)` | Unitless display, opaque-field timeline, observed values | Loading, empty, populated, partial/gaps, range switch, scrub |
| `/recovery` | `RecoveryScreen` | Protected evidence boundary and useful separate inputs | Unavailable/locked only |
| `/sport` | `SportRecordScreen` | Manual-only empty or history state and Add swim | Loading, empty, error, populated |
| `/sleep/evidence` | `EvidenceScreen` | Source chronology with primary, supporting, partial, unavailable entries | Empty, populated, partial |
| `/no-result` | `NoResultScreen` | Stable live no-reading explanation and stored-history path | Honest no-result |
| `/trends` | `TrendsScreen` | 7/30/90-day range, signal selector, one morphing instrument, manual-context link | Loading, empty, error, populated, partial/gaps, range and metric switching, scrub |
| `/journal` | `JournalScreen` | Check-in/swim actions and recent manual context | Loading, empty, error, populated |
| `/journal/check-in` | `CheckInScreen` | Optional tags/note with local-only save | Untouched, dirty valid, submitted-pending, saved, storage failure |
| `/journal/swim` | `SwimEntryScreen` | Duration/environment/effort form | Untouched, invalid on blur/submit, dirty valid, submitted-pending, saved, storage failure |
| `/you` | `YouScreen` | Ring, Journal, Data, Cycle privacy, About rows | Default, missing ring-history metadata |
| `/you/ring` | `RingDeviceScreen` | Device motif, last-sync facts, capabilities, quiet refresh | Connected, syncing, partial, stale, recoverable failure |
| `/you/ring/capabilities` | `CapabilitiesScreen` | Available, partial, and locked capability ledger | Mixed status, missing latest values, large text |
| `/you/data` | `DataHubScreen` | Record inventory, export, separate destructive actions | Loading, empty, error, populated, export pending, export ready, delete confirmation/result |
| `/you/about` | `AboutScreen` | Product scope, health model, licence, consumer-device disclaimer | Default |
| `/privacy/cycle` | `CyclePrivacyScreen` | Separate-consent toggles and local ring-data boundary | Enabled, disabled dependency, locked, loading, failure, saved |

## 3. Reusable primitives

### Navigation and shell

- `PremiumAppScreen`: safe area, scroll region, dynamic-type behavior, bottom-navigation reservation, and persistent live regions.
- `PremiumAppBar`: leading/back, centered route label, trailing status/action, 44-point targets.
- `PremiumBottomNav`: four stable destinations with icon and label.
- `RouteTransitionPage`: shared-axis detail transition and reduced-motion replacement.

### Typography and content

- `EditorialHeading`: condensed display stack, balanced wrap, Dynamic Type-safe line height.
- `DisplayMeasurement`: tabular data value with separate unit semantics.
- `PageMeta`: source/date/status metadata.
- `DailyStory`: provenance label, headline, explanation, evidence action.
- `SectionHeading`: title and optional right-aligned source/range metadata.

### Data and status

- `SignalLedgerRow`: value, label, source limitation, destination.
- `EvidenceTimeline`: ordered primary/supporting/partial/unavailable source entries.
- `StatusStrip`: semantic icon, plain title, cause/preservation sentence, live-region priority.
- `CapabilityStatus`: Available, Partial, or Locked with non-color shape and text.
- `EmptyState`: icon, job-specific headline, explanation, one safe action.
- `FailureState`: known cause, preserved data, recovery, retry count/age, support escalation.
- `SkeletonState`: layout-matched, bounded by a 15-second notice and 60-second stop.

### Ring and synchronization

- `RingStatusMotif`: quiet, searching, syncing, partial, failure, locked.
- `PairingProgress`: one-time pairing phases only.
- `RoutineSyncStatus`: in-place refresh phases, committed dataset preservation, stale/partial family labels.
- `SyncReceipt`: record families committed, stale/missing families, local persistence readback, transient-identifier disposal.

### Charts

- `InstrumentSurface`: plotting field, axis labels, scrub output, accessible description.
- `GapAwareLineSeries`: nullable points; never maps null to zero.
- `GapAwareBarSeries`: nullable activity buckets/days.
- `OxygenRangeSeries`: minimum–maximum range per captured hour.
- `FirmwareStageTimeline`: stage-duration runs with unclassified intervals.
- `ChartScrubber`: nearest captured point/range, timestamp, value/range, provenance, keyboard actions, rate-limited selection haptic.
- `RangeSelector`: day/week/month for signal details; 7/30/90 days for Trends.
- `TrendMetricSelector`: Sleep, Pulse, Movement, Oxygen; one conceptual chart surface.

### Forms, privacy, and destructive actions

- `ManualContextForm`: persistent labels/helpers, blur validation, pending lock, error preservation.
- `PrivacyToggleRow`: enabled, disabled, locked, loading, failure, saved.
- `ConfirmationSheet`: focus trap, explicit scope, cancel-first focus order.
- `LocalStatusToast`: fixed position, pause on focus/hover, polite live region.

## 4. State and data contracts

### Loading

- Preserve route chrome and the expected content geometry.
- Start a 15-second long-running notice.
- At 60 seconds, stop progress animation and show error/retry/cancel.
- Never replace the entire application shell for a section-level load.

### Empty

- Distinguish first use, no retained record, and no stable live reading.
- Include a plain explanation and one safe next action.
- Do not collapse an error into empty.

### Error

- Name the failed subsystem when known: Bluetooth, local history, journal store, export, or privacy persistence.
- State what was preserved.
- First retry is immediate; subsequent retries back off 2 and 4 seconds.
- After three failures, show support guidance and a copyable local error ID.
- Preserve form input and previous toggle values.

### Partial

- Model partial state by record family, not as a generic boolean.
- A successful family may update only after local commit/readback.
- A failed family keeps the previous committed value labelled stale, or remains a gap if no prior value exists.
- Copy must name updated and unchanged families.

### Stale

- Keep the prior value visible with last-sync age and source.
- Stale is not unavailable; unavailable is not zero.
- A stale reading never receives fresh styling or language.

### Locked

- Explain the missing verification, reversibility, or integration gate.
- A locked control remains in the capability ledger so the boundary is visible.
- Locked controls do not trigger haptics, writes, command payloads, or fake progress.

## 5. Analytics binding

Continue to use `RingAnalytics` and nullable domain records. V2 chart adapters must preserve source meaning:

- `ActivityDay.hourly[].hasRecord == false` → gap, not zero activity.
- `SampleSeries.samples` → measured spot samples; day/week/month summaries must retain sample count.
- `OxygenSeries.ranges` → minimum and maximum only.
- `DailyValue.value == null` → visible missing day.
- `SleepAnalytics.session` and `stageMinutes` → firmware interval and stage estimates.
- `SleepAnalytics.unclassifiedMinutes` → visible unclassified interval.
- `vendorIndexFor` and `vendorHistory` → unitless original values only.

The existing `mean` or `median` helpers may summarize captured samples when clearly labelled as a summary of those samples. They must not be relabelled as resting pulse, baseline, clinical average, stress state, or HRV milliseconds.

## 6. Accessibility implementation

- Keep a single logical heading hierarchy per route.
- Use semantic buttons, switches, form controls, lists, and navigation.
- Minimum target is 44 × 44 points on iOS; Android parity requires 48 dp if that target is added later.
- Expose chart summaries as one accessible graphic plus an adjustable scrub control; do not expose every decorative path.
- Scrub accessibility value includes time/date, value or range, and source.
- Status starts with a persistent live-region container. Errors are assertive only at the affected scope.
- On failed form submission, focus the first invalid field.
- On user-triggered successful load, move focus to the loaded heading only when the old surface was fully replaced.
- Respect Dynamic Type through 200% without fixed-height text containers.
- Respect iOS Reduce Motion and web reduced motion according to `MOTION-V2.md`.
- Preserve a visible non-color selected state and a 3:1 focus indicator.

## 7. Implementation sequence

1. Add V2 color/type/spacing/motion tokens to `ring_design_system` without deleting V1 tokens.
2. Build the V2 shell, app bar, four-destination navigation, focus behavior, and Dynamic Type tests.
3. Add status, empty, error, skeleton, confirmation, and toast primitives with semantic tests.
4. Implement nullable chart adapters and scrub accessibility before restyling individual charts.
5. Migrate Today and All signals as the primary vertical slice; bind real provider states and routine refresh receipts.
6. Migrate Activity, Sleep, Heart, Oxygen, firmware HRV, and firmware stress details.
7. Migrate Recovery, Sleep evidence, No-result, and Trends.
8. Promote Journal to primary navigation and migrate Check-in, Add swim, and Sport record without changing repository separation.
9. Migrate You, Ring device, Capabilities, Data hub, About, and Cycle privacy.
10. Migrate Welcome, Privacy, Pairing scan, and Ring found after the routine-sync distinction is protected in tests.
11. Run golden tests at 390 × 844, 320-point compact width, 200% text, reduced motion, and both English and pt-PT.
12. Run physical-iPhone pairing/sync QA with the owned exact-model R12; verify local persistence readback and no identifier/raw-packet retention.

## 8. Test requirements

### Navigation and flow

- Every route deep-links through `GoRouter` and has a deterministic back destination.
- Four primary destinations preserve their navigation selection across child routes.
- Pairing is never entered by routine refresh.
- Existing local data remains visible throughout routine refresh.

### Data truth

- Null activity buckets, samples, ranges, and days render gaps.
- Oxygen tests reject any average label or scalar-only chart.
- Vendor-index tests reject `ms`, relaxed, normal, medium, high, readiness, and Recovery usage.
- Sleep tests always include firmware-estimate language.
- Manual sport/check-in writes never change ring-domain records or chart series.
- Recovery always renders unavailable in production data mode.

### State coverage

- Snapshot/golden coverage for all states listed in the route table.
- Loading 15-second and 60-second thresholds use fake time.
- Partial-family commit behavior uses repository readback.
- Form validation runs on blur/submit and preserves input after failure.
- Toggle failure restores the previous persisted value.
- Retry escalation stops after three failed attempts and exposes an error ID.

### Accessibility and layout

- Semantics order matches visual order.
- Every target meets 44 points.
- All controls have accessible names, roles, values, and states.
- Charts have useful non-visual descriptions and adjustable scrub values.
- No clipping or horizontal overflow at 320 points and 200% text.
- Reduced motion removes translation, scale, and orbit while preserving state.

## 9. Explicit prohibitions

Do not infer, calculate, label, enable, or write any of the following:

- activity, recovery, sleep, readiness, resilience, cardiovascular-age, stress, or general health scores;
- diagnostic meaning, medical-grade accuracy, clinical thresholds, or treatment advice;
- firmware HRV milliseconds, RMSSD, SDNN, or validated HRV semantics;
- relaxed, normal, medium, high, or similar stress-index classifications;
- oxygen averages or exact values when the source is a minimum–maximum range;
- zero values from missing hours, missing days, failed reads, or unavailable history;
- automatic sport detection or conversion of manual sport into measured ring activity;
- raw-motion/acceleration evidence not exposed by the verified protocol;
- stable live pulse, oxygen, or vendor-index measurement flows;
- monitoring-schedule writes;
- gesture or display controls;
- find-ring or camera-shutter commands;
- time-format changes;
- ring game;
- firmware update;
- Apple Health export;
- background Bluetooth sync;
- persistent device identifiers;
- raw BLE packets in health storage or export.

The only allowed device-setting write remains necessary device time synchronisation through the existing verified path.

## 10. Privacy and deletion boundaries

- Ring history, manual context, cycle context, and exported files remain separately inspectable and separately deletable.
- Deleting local ring history does not change the physical ring.
- Deleting manual context does not change ring measurements or prior exported files.
- Cycle context requires its own keep-local, trend-context, and per-export consent behavior.
- Disabling a sensitive context view must not be reported as deletion unless repository readback proves deletion.
- An animation, cleared field, dismissed sheet, or toast is not delivery or persistence proof.

## 11. Route self-review

Each route was reviewed in the browser prototype against five gates: five-second comprehension, next-action clarity, authored visual hierarchy, useful/reduced motion, and truth/accessibility.

| # | Route | Comprehension and flow | Visual and motion | Truth and accessibility |
| ---: | --- | --- | --- | --- |
| 1 | `/welcome` | One promise and one primary setup action | Ring motif dominates without decoration | Secondary Skip remains keyboard reachable |
| 2 | `/privacy` | Local storage and export choice precede Bluetooth | Privacy disc reuses the ring geometry | No sharing is implied by continuing |
| 3 | `/pairing/scan` | User chooses when Bluetooth starts and which exact ring continues | Bounded orbit explains searching | Multiple, unavailable, and failure states name command/identifier limits |
| 4 | `/pairing/found` | Verification and history sync are distinct | Sync orbit stops for partial/failure | Partial copy names committed and stale families |
| 5 | `/today` | Daily meaning precedes metrics; refresh stays in place | Open story and quiet rule list replace dashboard soup | Stale, partial, loading, empty, and error preserve local data |
| 6 | `/metrics` | One ledger exposes every supported or unavailable signal | Large values align without equal cards | Sources and limitations accompany every value |
| 7 | `/movement` | Steps lead; firmware estimates and manual activity separate | Range change retains one chart surface | Gaps use neutral marks and scrub text |
| 8 | `/sleep` | Interval and firmware stages are immediately legible | Timeline is the single material plate | No score; firmware/EEG boundary is explicit |
| 9 | `/heart` | Latest spot sample and sample summary are distinct | Filled series supports range morph and scrub | Not continuous ECG; gaps are not interpolated |
| 10 | `/oxygen` | Min–max meaning is visible in headline and chart | Range bars encode shape rather than a scalar | No average; no-reading and missing ranges are separate |
| 11 | `/signals/hrv-index` | Original field is shown without pretending to interpret it | Same instrument language supports comparison | Unitless; not milliseconds or Recovery input |
| 12 | `/signals/stress-index` | Original field is shown without classification | Same instrument language supports comparison | No relaxed/normal/high labels |
| 13 | `/recovery` | Unavailability is resolved and useful | Open evidence ledger avoids a broken blank | Protected state cannot be mistaken for zero |
| 14 | `/sport` | Empty state explains the job and action | One focused empty composition | Manual source and separation are explicit |
| 15 | `/sleep/evidence` | Primary/supporting/unavailable sources read in order | Subtle one-time scroll rhythm supports chronology | Source types are text-labelled and remain static with reduced motion |
| 16 | `/no-result` | Explains no stable live reading versus stored history | Static partial ring makes the gap memorable | No invented value; safe path returns to captured history |
| 17 | `/trends` | Range and metric selection are adjacent to one chart | Chart morph replaces page swap | Missing days, source, and manual separation remain visible |
| 18 | `/journal` | Two manual jobs are first-class and obvious | Rule list keeps the screen light | Loading, empty, error, populated states preserve ring data |
| 19 | `/journal/check-in` | Optional tags/note and save scope are plain | Controls share one tactile language | Persistent labels, 44-point chips, pending lock, local source |
| 20 | `/journal/swim` | Duration, environment, effort, and save form one complete flow | Segmented effort is responsive but restrained | Blur/submit validation preserves input and ring separation |
| 21 | `/you` | Ring, context, files, privacy, and About form a clear hierarchy | Open rows avoid settings-card nesting | Every row has a full target and descriptive metadata |
| 22 | `/you/ring` | Last-sync facts and quiet refresh are distinct | Ring motif becomes a status instrument | Identifier is explicitly transient; failure preserves history |
| 23 | `/you/ring/capabilities` | Available, partial, and locked behavior is scannable | One continuous safety ledger | Status uses icon/shape/text, never color alone |
| 24 | `/you/data` | Export and each deletion scope are separated | Destructive confirmation uses a focused sheet | Identifiers/raw packets excluded; delete copy names what remains |
| 25 | `/you/about` | Product scope and non-medical boundary lead | Editorial text carries the screen | Consumer-device limitation is plain and readable |
| 26 | `/privacy/cycle` | Keep-local, context, export, and dependencies are explicit | Toggle feedback is brief and state-led | Loading, locked, failure, and per-export confirmation are covered |

Material issues found and addressed during the self-review:

- Journal was promoted from a nested You action to a stable primary destination.
- The equal-card signal dashboard was replaced with a source-aware ledger.
- Routine refresh was separated from pairing and made non-blocking.
- Charts gained filled encoding, visible gaps, scrub provenance, and keyboard exploration.
- Partial and stale states now name affected record families instead of using generic failure copy.
- Capability and privacy states gained non-color status cues and locked/loading/failure coverage.
- All 26 routes gained direct gallery and focused-mode reachability.

## 12. Prototype verification evidence

- All 26 source captures were inspected; every file is 390 × 844 pixels.
- Canonical route order matches the commission inventory exactly: 26/26.
- The route-state renderer generated 93 relevant variants with no wrong path, undefined/NaN content, missing/duplicate H1, duplicate primary action, or incorrect bottom-navigation count.
- Inline JavaScript passes `node --check`.
- The complete HTML passes Python `HTMLParser` without parser errors.
- Static anti-pattern review found no placeholders, unfinished markers, dead `href="#"` links, default-indigo accents, gradients, backdrop blur, `transition: all`, `scale(0)`, `scrollIntoView`, or removed focus outlines.
- Calculated WCAG contrast: ink/paper 15.92:1, muted/paper 5.41:1, ink/mineral 13.88:1, muted/mineral 4.72:1, paper/ink button text 17.06:1.
- `librering-prototype.html` remained byte-identical at SHA-256 `9a18c099637eaf934b73c2c2d096a628077d8f5a66009e03f0d72d57b180d195`.
- The single permitted OpenDesign image export returned without creating the requested image. No browser or second renderer was launched; collision/overflow review therefore used static structure, container-query, target-size, line-wrap, and state-render audits rather than a rendered screenshot.
