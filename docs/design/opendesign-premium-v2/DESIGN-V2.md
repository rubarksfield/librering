# LibreRing Premium V2 — Product and visual system

## 1. Product stance

LibreRing is edited health publishing joined to a precise local instrument. It tells one concise daily story, makes source and limitations available on demand, and treats an unavailable result as an intentional product state rather than an error to disguise.

The V2 prototype is a complete, independent redesign of all 26 Flutter routes. It preserves product behavior and safety boundaries while changing the information hierarchy, navigation model, chart language, interaction states, and component architecture.

## 2. Before / after design diagnosis

| Before | After | Why |
| --- | --- | --- |
| Three-destination bottom navigation with Journal nested under You | Four stable destinations: Today, Trends, Journal, You | Manual context is a first-class daily behavior and remains thumb-reachable without becoming part of measured data. |
| Many equal mineral cards with similar weight | Open editorial sections, rule-based ledgers, and a material plate only where containment has meaning | The screen reads as a story first and an instrument second, not a dashboard grid. |
| Metric overviews emphasize large values before provenance | Each value is immediately paired with measured, firmware estimate, manual, opaque, unavailable, partial, or stale language | The user can understand both the result and its evidence status in one glance. |
| Chart-library-like lines inside repeated cards | One instrument surface with filled encoding, visible gaps, precise scrub output, and an accessible text description | Exploration becomes useful and missing data cannot be mistaken for zero. |
| Sync mainly appears as a spinner or toast | One ring-motif state language for searching, connecting, receiving, complete, partial, stale, and failure | Status feels causally connected without recreating pairing during routine refresh. |
| Pairing and routine refresh share too much ceremony | Pairing uses a single one-time spatial sequence; refresh stays in place and preserves the visible local reading | Routine use remains calm and non-blocking. |
| Recovery is a large unavailable headline with supporting data inside a card | Recovery is a protected evidence boundary followed by an open ledger of what remains useful | The state feels resolved and trustworthy rather than empty or broken. |
| State QA is implicit and scattered | Route-specific review states live in the external prototype shell | Every state is independently inspectable without adding designer controls to the product UI. |

## 3. Foundations

### Color tokens

The six approved LibreRing tokens remain verbatim:

```css
:root {
  --bg: oklch(0.9585 0.0098 87.47);
  --surface: oklch(0.9132 0.0058 84.57);
  --fg: oklch(0.2034 0.0058 106.91);
  --muted: oklch(0.4958 0.0112 93.69);
  --border: oklch(0.8518 0.0101 87.48);
  --accent: oklch(0.5973 0.1511 33.88);
}
```

Derived colors remain in the same warm neutral and coral families. `--paper` lifts editable and elevated surfaces slightly above the canvas. `--ink-soft` supports secondary body copy while retaining body-text contrast. `--accent-soft` supplies chart area fill. Semantic danger and success colors are reserved for explicit status and always paired with text and shape.

Coral is used for measured or captured data, the ring sensor/status point, and rare urgency. It is not used for decorative headings, generic links, or primary buttons.

### Typography

- Display and data: `"Avenir Next Condensed", "Helvetica Neue", "Neue Haas Grotesk Text Pro", "Nimbus Sans Narrow", sans-serif`.
- Body and UI: `"Avenir Next", "Helvetica Neue", "Nimbus Sans", sans-serif`.
- Metadata: `"SFMono-Regular", "SF Mono", "IBM Plex Mono", monospace`.
- Display values use weight 300, tabular figures, `-0.055em` tracking, and a line height below 0.9.
- Product headlines use weight 400, `-0.028em` tracking, balanced wrapping, and 36–50 px at canonical scale.
- Body copy uses 12–14 px in the 390-point prototype with 1.55–1.58 leading; large-text mode increases the internal type scale to 1.28.
- Small uppercase metadata uses at least `0.08em` tracking.
- No content paragraph exceeds approximately 65 characters per line.

### Spatial system

- Canonical product frame: 390 × 844 points.
- Compact QA frame: 320 × 844 points.
- Product inset: 22 points canonical, 17 points compact.
- Spacing sequence: 4, 8, 12, 18, 22, 30, 44, 68.
- Bottom navigation safe zone: 114 points.
- Minimum target: 44 × 44 points.
- Flat instrument radius: 18 points.
- Primary control radius: 15 points.
- Navigation radius: 21 points outer, 15 points selected item.

## 4. Information architecture

### Stable destinations

1. **Today** — one daily story, a glanceable measured summary, and focused signal reading modes.
2. **Trends** — the same signals over time, with missing days preserved and manual context adjacent rather than merged.
3. **Journal** — optional user-entered context, visibly manual, locally stored, and separately deletable.
4. **You** — ring status, capabilities, files, privacy, and product boundaries.

Pairing is a one-time setup flow outside the primary navigation. Signal details are reading modes entered from Today or All signals. They return consistently to their source overview. Sleep evidence and the no-result explanation form a progressive-disclosure chain. Device, capability, data, about, and cycle privacy routes form a consistent You hierarchy.

### Back behavior

- Welcome → Privacy → Pairing scan → Ring found is linear.
- Today opens All signals and focused signal details.
- All signal details return to All signals except Recovery, which returns to Today.
- Sleep evidence returns to Sleep; No-result returns to evidence.
- Trends and Journal remain independently reachable through primary navigation.
- Check-in and Add swim return to Journal.
- Ring, capabilities, data, about, and cycle privacy return through You.
- Browser history and Escape work in the web review shell; product back controls use explicit route destinations.

## 5. Component system

### App bar

Three logical columns preserve optical balance: leading navigation or wordmark, a small centered route label, and a trailing status or action. Icon targets remain 44 points even when the visible icon is 20 points.

### Bottom navigation

The navigation is an opaque ink island with four equal targets. Selection uses a second ink value plus icon and text; it never relies on color alone. Labels remain visible at every size.

### Daily story

The story is an open section bounded by two rules. It contains a provenance label, one editorial headline, one plain explanation, and a tertiary evidence action. It replaces the dense hero card while preserving the same daily job.

### Metric ledger

All signals uses a vertical ledger rather than a 2 × 2 dashboard. Each entry aligns:

- one large value or honest dash;
- the signal name and source limitation;
- a consistent drill-down affordance.

The ledger survives large text by allowing rows to grow vertically.

### Instrument

Charts use one flat mineral plate because the chart needs a bounded plotting field. Every instrument includes:

- filled data encoding;
- a visible neutral gap mark where applicable;
- precise point or range exploration on pointer press/move and arrow keys;
- timestamp, value/range, and provenance in a persistent output line;
- a full VoiceOver-readable chart description;
- a static, useful reading with motion disabled.

### Status strip

Status uses an icon, label, explanatory sentence, and semantic live-region role. Error, success, partial, stale, and locked states never depend on color alone.

### Ring motif

The ring is an original, flat CSS construction. Its small coral sensor point is the only decorative brand signal. An outer orbit becomes functional:

- solid moving orbit: searching or syncing;
- dashed stationary orbit: partial result;
- broken semantic-color orbit: recoverable failure;
- squared sensor: locked capability.

The motif appears prominently only in onboarding, pairing, no-result, and device status.

### Forms

Forms use persistent labels and helper text. Validation occurs on blur or submit, never on the first keystroke. Invalid input keeps the entered value, adds an inline message, sets `aria-invalid`, and moves focus to the field on failed submission. Submitted-pending disables the primary action against duplicate writes.

### Toggles

Toggle rows render enabled, disabled, locked, loading, and recoverable-failure conditions. The 48 × 28 visual switch sits inside a 54 × 44 target. Dependent controls disable when keep-local is not available. A successful change produces a polite local-only status; a failed change retains the previous setting.

### Confirmation sheet and toast

Destructive actions use an alert dialog sheet with explicit scope and Cancel/Delete actions. Toasts use one fixed location, persist for 4.8 seconds, receive `role="status"`, and can receive keyboard focus. No toast is treated as provider or storage readback proof in production.

## 6. Screen-by-screen rationale

| Route | V2 product decision |
| --- | --- |
| `/welcome` | Product-art-led entry with one promise and one setup action. Skip remains secondary. |
| `/privacy` | Privacy appears before Bluetooth and names local storage plus explicit export choice. |
| `/pairing/scan` | Scan is user-initiated; searching, multiple-ring, unavailable, and failure states preserve identifier and command boundaries. |
| `/pairing/found` | Verification and history sync are separate. Partial sync explains exactly what committed and what stayed stale. |
| `/today` | Leads with an edited daily story, then three glanceable facts and a source-aware signal list. Routine refresh stays in place. |
| `/metrics` | Replaces the equal-card grid with a source-aware ledger that includes unavailable Recovery. |
| `/movement` | Separates ring steps, firmware distance/energy, missing periods, and manual sport context. |
| `/sleep` | Treats interval and stage runs as firmware estimates, with evidence one step away and no score. |
| `/heart` | Uses latest spot sample as the headline and labels computed summary statistics as sample summaries, not continuous monitoring. |
| `/oxygen` | Uses min–max range bars, never an average, with captured hours and gaps visible. |
| `/signals/hrv-index` | Keeps the value unitless and exposes original firmware naming without milliseconds. |
| `/signals/stress-index` | Keeps the value unitless and avoids relaxed, normal, or high classifications. |
| `/recovery` | Makes unavailability feel intentional and useful by listing available inputs that remain excluded from scoring. |
| `/sport` | First-use empty state explains why manual activity exists and what it cannot change. |
| `/sleep/evidence` | A chronological evidence line distinguishes primary, supporting, partial, and unavailable sources. |
| `/no-result` | Explains the difference between a failed stable live reading and retained hourly history; no value is filled. |
| `/trends` | One chart morphs across range and metric selection. Missing days remain gaps; manual context is adjacent only. |
| `/journal` | Gives manual context its own destination while repeating the separation rule in plain language. |
| `/journal/check-in` | Optional tags and note remain locally stored and visibly manual. |
| `/journal/swim` | Duration, environment, and effort form a complete manual record with bounded validation. |
| `/you` | Groups the ring, manual context, data exit, sensitive privacy, and product evidence model. |
| `/you/ring` | Presents last-sync device facts and a quiet refresh flow; transient identifiers remain explicit. |
| `/you/ring/capabilities` | Lists available, partial, and locked capabilities in one readable safety ledger. |
| `/you/data` | Separates export, manual deletion, ring-history deletion, and identifier exclusion. |
| `/you/about` | States the open-source wellness scope and medical-device boundary without marketing exaggeration. |
| `/privacy/cycle` | Uses a separate consent boundary, dependent controls, per-export confirmation language, and explicit non-sharing copy. |

## 7. Responsive behavior

- Internal layout uses container queries rather than viewport assumptions.
- At 320 points, insets reduce to 17 points; headings, data values, metric-ledger columns, and ring art scale independently.
- No product element uses a fixed width wider than its container.
- The phone content scrolls vertically; the bottom navigation stays fixed and never covers the last actionable item because the scroll region reserves 114 points.
- Gallery devices scale visually on narrow host canvases without changing their internal layout resolution.
- Focus mode calculates a non-upscaling fit from both available width and height.

## 8. Accessibility decisions

- One logical main region per phone screen and one descriptive heading.
- Native buttons, inputs, selects, textareas, and switches are used before ARIA substitutes.
- Every control is keyboard reachable in DOM reading order.
- Focus uses a 3-pixel ink outline with 3-pixel offset.
- All targets are at least 44 × 44 points.
- Body and secondary copy use approved contrast-safe ink tokens; coral is not used for small text.
- Chart points can be explored from the chart with Left and Right Arrow keys.
- Chart descriptions and scrub output communicate time, value/range, gap, and source without color or animation.
- Status changes use persistent live regions. Errors use `role="alert"`; non-urgent confirmations use `role="status"`.
- Large-text mode uses a 1.28 internal scale and lets rows, forms, and pages scroll rather than clipping.
- Reduced-motion mode removes transforms and collapses timings while preserving color, labels, and final state.
- Focus is trapped inside the focused-prototype shell and returns to the invoking control when closed.

## 9. State model

Data-bearing surfaces cover loading, empty, error, populated, and edge/partial states. The external review shell exposes only the states relevant to each route. Product UI never contains a designer-facing state switcher.

- Loading keeps route chrome and expected layout shape.
- Empty includes a headline, plain explanation, and safe next action.
- Error names what failed, what was preserved, and what the user can do.
- Partial names exactly which family updated and which family stayed stale or missing.
- Stale labels age without deleting the prior result.
- Locked explains the evidence or reversibility gate.
- Submitted-pending prevents duplicate form writes.

## 10. Claims and privacy guardrails

- No activity, recovery, sleep, readiness, resilience, cardiovascular-age, or general health score appears.
- Recovery remains unavailable until independently validated inputs and a transparent calculation exist.
- Firmware HRV and stress values remain unitless opaque indexes with unvalidated semantics.
- Sleep stage labels are firmware estimates and never described as EEG.
- Oxygen is displayed only as captured hourly minimum–maximum ranges; no average is calculated.
- Missing samples, hours, and days remain gaps, not zeros.
- Manual entries never modify or visually merge with ring measurements.
- Consumer measurements are never described as diagnostic or medical-grade.
- Device identifiers remain transient and excluded from health storage and export.
- Data is local-first; export and sensitive-context availability remain explicit choices.
- The only allowed device-setting write is necessary time synchronisation.
- Monitoring schedules, gesture/display control, find ring, camera shutter, time-format changes, ring game, firmware update, stable live vital flows, Apple Health export, and background Bluetooth sync remain locked.

## 11. Distinctive visual move

V2 uses one recurring relationship: a quiet circular ring status paired with unusually compressed editorial data numerals. The ring is not repeated as decoration; it appears only when the physical device or a missing-device reading is causally relevant. This gives LibreRing a recognizable identity while the majority of every screen remains paper, ink, rules, and readable evidence.
