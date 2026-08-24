# Visual direction exploration

All three directions use original layouts and the same truthful fictional data.
Each is represented across Daily, Sleep, Recovery, 7-day trend, Pairing, Swim,
data-quality, and Cycle Context. They differ structurally—not only by colour.

## A — Quiet Ledger

- **Composition:** editorial vertical ledger; large conclusion, thin rules,
  domain rows rather than floating cards.
- **Density:** lowest; one chart or table per screen.
- **Type:** strong sentence-case hierarchy, tabular figures as annotations.
- **Charts:** restrained line with confidence gaps and labelled turning points.
- **Colour/surface:** warm mineral canvas, ink text, indigo/jade/amber marks;
  almost no elevation.
- **Navigation:** text-forward bottom bar.
- **Character:** reflective, trustworthy, human.
- **State handling:** missing data becomes a full-width note in document flow.

Five-second clarity is strongest and cross-platform implementation is simple.
Risk: could feel more like an excellent report than a responsive instrument.

## B — Structured Health Dashboard (selected; user confirmed 2026-08-24)

- **Composition:** a centred period switch and oversized nightly measure lead to
  a coral history heatmap, one conclusion, and a two-by-two status grid.
- **Density:** medium; Glance is sparse, Explain uses structured rows.
- **Type:** one neutral system grotesk; very large tabular numerals, compact plain
  labels, and small-but-accessible provenance text.
- **Charts:** baseline corridor plus a solid personal trace; breaks are explicit
  gaps, never smoothed away.
- **Colour/surface:** near-black/brown in dark and cool neutral grey in light;
  flat low-shadow cards; coral carries history and chart marks.
- **Navigation:** three stable destinations in a grounded rail/bar.
- **Character:** calm scientific instrument without clinical coldness.
- **State handling:** confidence changes trace texture and copy, never opacity of
  essential text or colour alone.
- **Brand language:** open-signal arc glyph; single system-grotesk family;
  “Signals, made legible.”
- **Flow language:** directional Glance → Explain → Inspect transitions and an
  exact progress surface for bounded tasks.
- **Motion language:** heat cells, bars, and paths draw once; navigation and
  route changes settle with short bounded movement. Motion is decorative and
  removed without information loss.

This is the user-selected direction because its type and card hierarchy stay
closest to the supplied smart-ring reference while LibreRing's evidence,
confidence, provenance, and missing-data rules remain explicit.

The frozen visual source is the Open Design artifact at
`approved-reference-led/prototype.html`, governed by
`approved-reference-led/DESIGN.md`. The separate `prototype/` implementation is
retained as the functional and scoring reference, not the final visual source.

## C — Daily Brief

- **Composition:** morning brief with a two-column lead on wide screens and
  stacked answer/action cards on mobile; contextual timeline below.
- **Density:** highest, but sections are strongly titled by question.
- **Type:** compact news-brief hierarchy with explanatory deck text.
- **Charts:** small multiples for yesterday/7d/30d, sparklines with source labels.
- **Colour/surface:** cool fog background, charcoal panels, domain colour only in
  chart strokes; sharper corners and hairline borders.
- **Navigation:** segmented top-level title plus bottom labels.
- **Character:** analytical and efficient.
- **State handling:** an evidence column makes uncertainty excellent on tablets,
  but risks scroll/density on phones and large text.

## Evaluation (1 weak – 5 strong)

| Criterion | Quiet Ledger | Structured Dashboard | Daily Brief |
| --- | ---: | ---: | ---: |
| Five-second comprehension | 5 | 5 | 3 |
| Premium quality | 4 | 5 | 4 |
| Originality | 4 | 5 | 4 |
| Accessibility | 5 | 4 | 3 |
| Data honesty/missing states | 4 | 5 | 5 |
| Cross-platform practicality | 5 | 4 | 3 |
| Open-source maintainability | 5 | 4 | 3 |
| Difference from Oura/QRing | 5 | 5 | 4 |

Structured Health Dashboard is selected. Quiet Ledger is preserved as the low-density
alternative and should influence reports/exports. Daily Brief is preserved for a
future tablet/desktop technical view, not the primary mobile shell.
