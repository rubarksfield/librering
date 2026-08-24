# LibreRing V1 interactive prototype

This is the functional, content, scoring, and edge-case reference for the first
approval gate. It is a self-contained, dependency-free HTML/CSS/JavaScript
prototype: no account, network connection, build step, package installation, or
production Flutter code is required.

The selected V1 visual source is the approved Open Design artifact at
`../docs/design/approved-reference-led/prototype.html`. This 36-route prototype
must remain available until every journey and state has been mapped to that
visual system.

## Run

From the repository root:

```sh
python3 -m http.server 4173 --directory prototype
```

Open `http://localhost:4173/`.

## Recommended review

Use the numbered rail to play all eight journeys:

1. Pair a ring.
2. Read the morning.
3. Inspect evidence and alternate/no-result states.
4. Log a swim.
5. Check a 30-day trend and select a gap.
6. Resolve a QRing connection conflict and resume without duplicates.
7. Preview and save a local export.
8. Review Cycle Context privacy, pregnancy trend-only behavior, and separate deletion.

The rail also switches light/dark themes and standard/large text. Arrow keys move
through the current journey. The premium material and motion layer is built with
local CSS and project-authored SVG icons; reduced-motion preferences remove all
decorative animation. All displayed values are fictional demo data.

The LibreRing brand uses an open-signal glyph, the line “Signals, made legible,”
and one native system-grotesk family. Focused flows show an exact step meter
instead of destination navigation, and directional transitions make forward,
back, and cross-journey movement legible without changing the information
architecture or scoring boundaries.

The selected direction is `Structured Health Dashboard`: a light neutral canvas,
oversized tabular health numerals, flat grey modular cards, compact labels, coral
heat cells, and restrained chart drawing. It follows the supplied smart-ring
reference's type and card grammar while retaining LibreRing's own copy, fictional
data, evidence/confidence/provenance labels, and safety boundaries. Light is the
default review theme and dark remains available from the rail.

## Scope boundary

This artifact is for design/scoring review. It does not connect to a ring, write
an export, invoke a system share sheet, delete data, or initialize production
Flutter. Production remains locked until the exact approval phrase in the main
handoff is supplied.
