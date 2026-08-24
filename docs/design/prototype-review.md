# Prototype review

Status: **PASS WITH DOCUMENTED LIMITATIONS — ready for user review.**

Visual status: **SUPERSEDED** by the approved reference-led artifact in
`approved-reference-led/`; the journeys, copy, scoring boundaries, and edge cases
in this prototype remain authoritative implementation inputs.

Artifact: `prototype/index.html` with `styles.css` and `app.js`. It is local,
dependency-free, keyboard operable, and contains fictional demo data only.

## Browser-playtest results

| Journey | Target and tap path | Result |
| --- | --- | --- |
| First use | welcome → privacy → Bluetooth rationale → scan → R12 capability check → resumable sync → calibration → Today; 7 taps | PASS |
| Morning | Today exposes conclusion and three domains; Sleep explanation in 1 tap, evidence in 1 further tap | PASS |
| Incomplete night | evidence → alternate states → no-result; 2 taps; gap is not scored | PASS |
| Swimming | Add context → form → review → saved; 3 taps; unsupported underwater metrics remain explicit | PASS |
| Trends | Trends → Sleep 30d → select gap; 2 taps; baseline corridor and 25/30 coverage visible | PASS |
| Device problem | issue → close QRing/retry → resume → verified success; 3 taps; 0 duplicates | PASS |
| Data ownership | Your data → export → preview → completion; 3 taps; exact scope, rows, format and checksum visible | PASS |
| Cycle Context | off → privacy → mode → calendar estimate → pregnancy trend → separate deletion; 5 focused taps | PASS |

All target strings were asserted from rendered browser state. The browser console
reported zero errors or warnings.

## Premium visual refinement

The review build uses a graphite device frame, cool neutral canvas, opaque flat
modules, project-authored SVG line icons, staged content reveals, chart drawing,
scan waves, progress fills, and restrained press/hover feedback. The implementation
is dependency-free CSS and JavaScript; it does not load or copy a reference asset.

The visual pass was rechecked in dark and light themes, large text, and the
390×844 breakpoint. A complete Cycle Context playthrough and complete export
playthrough still reached their final states. Direct browser assertions also
reached the required endpoint for every numbered journey. `prefers-reduced-motion`
removes chart, scan, reveal, sheet, toast, and navigation motion while retaining
the complete final state.

## Brand and flow refinement

The review build carries LibreRing's open-signal glyph, `LibreRing` wordmark, and
the line “Signals, made legible.” The selected direction now uses one native
system-grotesk stack for brand, conclusions, controls, measurements, and evidence;
no external font is loaded.

The welcome and Daily Signal screens now lead with one legible conclusion. A
compact journey meter replaces bottom navigation inside focused tasks, while
direction-aware transitions distinguish forward, back, jump, and settled states.
All motion still resolves immediately under `prefers-reduced-motion`.

The refinement was rechecked across all 36 numbered routes and all eight complete
click journeys. Dark, light, large-text, and 390×844 states remained operable;
every route exposed either destination navigation or exact journey progress, and
the browser console remained free of errors and warnings.

## Structured smart-ring reference refinement

The 2026-08-24 selected-reference pass replaces the earlier hybrid with a light
neutral dashboard, a centred period switch, oversized nightly duration, coral
square heatmap, flat grey two-by-two metric cards, compact labels, and restrained
chart marks. Detail and onboarding cards use the same low-shadow construction.
Sleep 64, Recovery 72, Movement 38 min, confidence, provenance, and limitations
remain LibreRing-authored and evidence-bound.

Motion is bounded and non-semantic: heat cells and bars rise once, chart paths
draw once, and route/navigation changes settle briefly. `prefers-reduced-motion`
shows every final state immediately. No external image, font, animation, or
reference asset is loaded; Biosora branding, ring imagery, and unsupported
metrics remain excluded.

The earlier mood-style clustered forms, colour washes, and editorial serif were
removed from the rendered build. Fresh verification results are recorded in
`docs/PROGRESS.md`.

## Heuristic findings and fixes

- The first implementation gave segmented controls 42px height; the shared token
  was increased to 48px before final review.
- Three light-theme signal colours and the faint-text token missed 4.5:1 against
  the mineral canvas; darker light-theme values now pass.
- Card accessible names intentionally include the subtitle so provenance and
  limitations survive non-visual navigation.
- The 390×844 layout keeps the three-destination navigation visible and puts
  additional content in the internal screen scroll rather than clipping it.
- A deliberate prototype-only toast intercepts share/delete/check-in actions;
  review clicks cannot export, share or delete real data.
- Compact status badges are the only pill-shaped content containers; cards,
  controls, sheets, and navigation retain distinct radii and hierarchy.

## Limitations

This is a structured internal playtest, not external usability evidence. Physical
R12 behavior, assistive-technology labs, platform share sheets, real deletion, and
production performance remain untested and outside this gate.
