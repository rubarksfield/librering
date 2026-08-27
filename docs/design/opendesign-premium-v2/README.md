# LibreRing Premium V2

Status: design complete; production Flutter implementation not yet applied.

This package is the route-complete OpenDesign redesign commissioned from the current LibreRing app on 2026-08-27. It preserves the approved LibreRing identity and product truth boundaries while replacing the current flat dashboard hierarchy with a calmer editorial system, instrument-like data views, four stable destinations, and a documented motion language.

## Open the prototype

Open `librering-premium-v2.html` in a modern browser. It contains:

- a gallery of all 26 production routes;
- a focused 390 × 844 phone mode;
- 320 px, large-text, and reduced-motion review modes;
- 93 route/state variants;
- interactive navigation, range controls, chart exploration, pairing and sync states, forms, privacy controls, feedback, and locked capability states.

## Package

- `librering-premium-v2.html` — self-contained interactive prototype.
- `DESIGN-V2.md` — design system, information architecture, route rationale, accessibility, and claims guardrails.
- `MOTION-V2.md` — motion tokens, state transitions, haptics, interruption rules, and reduced-motion equivalents.
- `HANDOFF-V2.md` — Flutter component mapping, state contracts, implementation order, and do-not-infer boundaries.
- `BRIEF.md` — the complete commission and acceptance criteria.
- `current-screens/` — deterministic 390 × 844 captures of all production routes before the redesign.
- `contact-sheet-*.png` — compact before-state audits.

## Verified

- 26 route definitions and 93 route/state variants.
- JavaScript syntax and HTML parsing.
- One semantic H1, no duplicate IDs, one primary action, and four navigation destinations where applicable.
- WCAG AA contrast for tested foreground/background pairs; lowest recorded ratio is 4.72:1.
- Keyboard/focus behavior, live announcements, pausable feedback, reduced motion, 320 px layout, and no horizontal overflow in the compact large-text check.
- Browser-rendered spot checks for the gallery, onboarding, Today, Sleep, Heart, ring capabilities, navigation, chart range switching, chart exploration, and console errors.
- No invented health scores, oxygen averages, firmware-index semantics, or unsupported ring capabilities.
- The approved V1 OpenDesign artifact remained unchanged.

## Boundary

This is an implementation-ready design artifact, not a claim that the Flutter app already uses V2. Implement the reusable primitives and route groups in the sequence in `HANDOFF-V2.md`, keeping the existing decoded-data and privacy contracts intact.
