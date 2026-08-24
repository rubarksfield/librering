# Structured Health Dashboard design system specification

The approved Open Design contract in `approved-reference-led/DESIGN.md` and its
self-contained `approved-reference-led/prototype.html` are the V1 visual source
of truth. The dependency-free web prototype in `prototype/` remains the richer
functional, content, scoring, and edge-case reference. This text record is kept
for component naming and future Flutter mapping where the approved contract is
silent; conflicting visual tokens in this older record are superseded.

## Core tokens

| Semantic token | Dark | Light |
| --- | --- | --- |
| `color.background.canvas` | `#190D0B` | `#F2F2F0` |
| `color.background.surface` | `#2A1A16` | `#E3E3E3` |
| `color.background.raised` | `#35211C` | `#FAFAF8` |
| `color.text.primary` | `#F5F1ED` | `#150907` |
| `color.text.secondary` | `#C5B8B1` | `#665B56` |
| `color.signal.sleep` | `#FF9279` | `#9C3C2D` |
| `color.signal.recovery` | `#72C89B` | `#24714E` |
| `color.signal.movement` | `#EFBD75` | `#89551B` |
| `color.signal.heart` | `#D78477` | `#A3483C` |
| `color.signal.oxygen` | `#69B7C9` | `#226A7C` |
| `color.state.warning` | `#D0AD5B` | `#7B5B0B` |
| `color.state.error` | `#F07575` | `#B72828` |
| `color.border.subtle` | `#49322B` | `#D4D3D0` |

Contrast targets are ≥4.5:1 for normal text and ≥3:1 for large text/non-text UI.
Colour is always paired with label, shape, or line style.

Spacing: `space.050=4`, `100=8`, `150=12`, `200=16`, `300=24`, `400=32`,
`600=48`. Radius: `control=14`, `card=16`, `field=18`, `sheet=24`; pill shapes
are reserved for compact status badges. Touch target minimum 44×44 iOS / 48×48
Android.

Typography uses one platform grotesk stack (`-apple-system`, `Helvetica Neue`,
Arial fallback) across brand, conclusions, controls, measurements, and evidence.
Lead health numerals use a 76px neutral-weight face with tabular figures and tight
tracking; card metrics use 41px. Titles are 24/30, body is 17/24, labels are
14/20, and technical metadata is 13/18. All text supports 200% scaling without
clipping. No all-caps paragraphs or editorial serif remains in the selected
direction.

Motion uses a restrained hierarchy: controls 220–300 ms, material transitions
520 ms, content reveals 660 ms, signal traces 900 ms, and chart drawing 1,250 ms.
Primary easing is `cubic-bezier(0.16, 1, 0.3, 1)`; press feedback uses a bounded
spring curve. Ambient light, trace drawing, chart drawing, scan waves, and staged
reveals are decorative. Reduced motion changes all of them into immediate state
swaps, and no essential meaning exists only during motion.

Confidence: High solid line + label; Moderate dashed segment + label; Low dotted
segment + explicit sentence. Provenance: Ring estimate, App-derived, Imported,
You logged. Never reduce primary text opacity to convey uncertainty.

The selected Daily surface is `StructuredDashboard`. A centred period selector
and oversized factual measure lead into a compact coral sleep-history heatmap,
one plain-language conclusion, and a two-by-two grid of flat metric modules. Each
module keeps the same order: title and delta, labelled confidence or provenance,
large result, then a compact chart. The heatmap and charts draw once; they never
replace the adjacent text or imply unsupported precision.

## Material direction

The premium layer translates the selected smart-ring reference into LibreRing's
own product content: a graphite review device, light neutral canvas, low-shadow
grey modules, restrained system typography, and one coral chart accent. It uses
no reference assets, ring imagery, branding, or unsupported physiological
measures. Opaque surfaces and readable foreground text are mandatory.

The brand glyph consists of three incomplete evidence arcs plus a source node.
Its open right edge represents inspectability and export rather than goal
completion. The lockup reads `LibreRing` in the same interface face used
throughout; the supporting line is “Signals, made legible.”

The app screen uses depth only to clarify hierarchy: navigation floats above
scrolling content, selected states receive one luminous edge, and cards lift by at
most three pixels on pointer hover. Buttons and navigation use project-authored
SVG line icons with hidden decorative markup and explicit accessible names.

Non-navigation journeys use a fixed, labelled progress surface with an exact step
count and continuous gradient track. Forward, back, cross-journey, and settled
states have distinct bounded transitions so motion reinforces direction. Reduced
motion reveals the same final states immediately.

## Component families

`AppShell`, `TopHeader`, `PrimaryNavigation`, `RingStatus`, `DailyConclusion`,
`DomainSummary`, `MetricSummary`, `ExplanationRow`, `BaselineComparison`,
`TrendChart`, `SleepTimeline`, `WorkoutSummary`, `SwimSummary`,
`ConfidenceIndicator`, `ProvenanceBadge`, `DataQualityMessage`, `EmptyState`,
`LoadingState`, `SyncProgress`, `PermissionRequest`, `ErrorRecovery`,
`JournalEntry`, `SettingsRow`, `ModalSheet`, `ConfirmDialog`, `Button`,
`ChartTooltip`, `DateRangeSelector`, `CalibrationState`, `CycleContextCard`, and
`ReproductivePrivacyPrompt`.

Variants are named by semantic state (`normal`, `warning`, `noResult`, `selected`,
`disabled`, `largeText`) and theme (`dark`, `light`), not colour or position.
Layouts use Auto Layout/flex concepts and responsive constraints. Component names
are deliberately suitable for future Flutter widget names after approval.
