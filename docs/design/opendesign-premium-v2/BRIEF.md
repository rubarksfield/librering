# LibreRing Premium V2 — OpenDesign Commission

## Outcome

Create a complete, production-minded redesign of every current LibreRing route. The result must feel materially calmer, clearer, more intuitive, more tactile, and more premium than the current app while remaining recognisably LibreRing.

This is not a cosmetic reskin and not a concept-board exercise. Deliver a coherent interactive mobile product prototype with a complete design system, navigation model, motion language, state model, accessibility behavior, and implementation handoff.

## Canonical inputs

Treat the following as the source of truth, in this order:

1. Product behavior, routes, claims, and safety boundaries in the current Flutter source:
   - `apps/mobile/lib/app.dart`
   - `apps/mobile/lib/src/screens.dart`
   - `apps/mobile/lib/src/analytics_screens.dart`
   - `apps/mobile/lib/src/ring_analytics.dart`
2. All 26 deterministic current-state captures in:
   - `docs/design/opendesign-premium-v2/current-screens/`
   - Four contact sheets are beside this brief for quick audit.
3. The approved LibreRing visual foundation:
   - `docs/design/approved-reference-led/DESIGN.md`
   - `docs/design/approved-reference-led/design-contract.md`
4. The Q Ring feature-coverage and claim-boundary map:
   - `docs/product/qring-feature-map.md`

The captures are the **before state**, not a layout template. Preserve their functionality and honest states, then redesign the experience from first principles.

## Complete screen inventory

Design all 26 routes, with no placeholders, duplicated shells, lorem ipsum, or “coming soon” shortcuts:

1. Welcome — `/welcome`
2. Privacy promise — `/privacy`
3. Pairing scan — `/pairing/scan`
4. Ring found — `/pairing/found`
5. Today — `/today`
6. All signals — `/metrics`
7. Activity — `/movement`
8. Sleep — `/sleep`
9. Heart — `/heart`
10. Oxygen — `/oxygen`
11. Firmware HRV index — `/signals/hrv-index`
12. Firmware stress index — `/signals/stress-index`
13. Recovery unavailable — `/recovery`
14. Sport record — `/sport`
15. Sleep evidence — `/sleep/evidence`
16. No-result state — `/no-result`
17. Trends — `/trends`
18. Journal — `/journal`
19. Check-in — `/journal/check-in`
20. Add swim — `/journal/swim`
21. You — `/you`
22. Ring device — `/you/ring`
23. Ring capabilities — `/you/ring/capabilities`
24. Data hub — `/you/data`
25. About — `/you/about`
26. Cycle privacy — `/privacy/cycle`

Canonical viewport is 390 × 844 points. The prototype must also remain coherent at 320 px width and at large text sizes.

## Experience direction

LibreRing should feel like a piece of beautifully edited health publishing married to a precise instrument: warm, quiet, tactile, trustworthy, and never clinical or generic.

Keep and evolve:

- Warm paper, mineral, titanium, ink, and restrained coral as a recognisable LibreRing palette.
- Editorial typography with oversized, light, slightly compressed-feeling data numerals and confident grotesk text.
- Spacious composition, strong pacing, clear hierarchy, and one unmistakable primary action per screen.
- Flat, refined material surfaces rather than “cards everywhere.” Use sectional composition and open canvas wherever a container adds no meaning.
- Coral only for measured data, selection, urgency, or the one key moment—not as decorative confetti.
- A distinctive ring motif that becomes a useful progress/sync/navigation device, not a logo pasted onto every screen.

Avoid:

- Generic wellness gradients, glassmorphism, glow, heavy shadows, dashboard grids, nested cards, neon, stock photography, and interchangeable SaaS styling.
- Dense walls of equal-weight information.
- Reproducing Q Ring, Oura, Apple Health, or the supplied reference literally.
- Decorative animation that delays reading or obscures state.

## Information architecture and flow

Make the app feel simpler even though it is feature-complete:

- Tell a concise daily story before exposing raw signal detail.
- Use progressive disclosure for evidence, provenance, capability explanations, historical ranges, and privacy mechanics.
- Keep the primary navigation stable, thumb-reachable, and immediately legible.
- Make Today, Trends, Journal, and You feel like a deliberate four-part system. Metric details should feel like focused reading modes, not new app silos.
- Pairing and routine sync must never feel like the same flow. Routine refresh should be calm, in-place, non-blocking, and should preserve already synced data.
- Back behavior, date/range switching, metric selection, and drill-down must be consistent everywhere.
- Empty, unavailable, locked, stale, loading, syncing, success, partial-data, and failure states must look intentional and explain the next safe action.
- Prefer glanceable summaries; let the user ask for evidence instead of forcing evidence into every overview.

## Charts and data interaction

- Make timelines feel crafted and readable rather than like default chart-library output.
- Preserve gaps: unavailable is never rendered as zero.
- Show oxygen as captured minimum–maximum ranges, not invented averages or isolated exact values.
- Use scrub/press exploration with a precise timestamp, value/range, and provenance label.
- Range switching (day/week/month) should morph the same conceptual chart rather than replacing the whole page abruptly.
- Use restrained annotation, beautiful axes, meaningful comparison, and accessible non-color cues.
- Ensure every chart remains understandable with VoiceOver descriptions and without animation.

## Motion and tactile behavior

Create one coherent motion system and document exact timings, curves, distance, interruption behavior, and haptic recommendations.

Required motion moments:

- Shared-axis transitions between overview and metric detail.
- A subtle spring response for taps, segmented controls, selected dates, and expandable evidence.
- Staggered but fast chart reveals after content is present; never make the user wait for a decorative count-up.
- Chart morphs between day/week/month and graceful scrubbing feedback.
- A ring-motif sync state with clear searching, connecting, receiving, complete, partial, stale, and recoverable-failure variants.
- Pairing progression that feels ceremonial once, while routine refresh remains quiet.
- Scroll choreography that gives long evidence screens rhythm without hijacking scrolling.
- Deliberate button pressed, toggle, sheet, toast, and success states.
- Full `prefers-reduced-motion` behavior: cross-fade/state-change alternatives and no parallax or forced movement.

Aim for 60 fps and interruptible motion. Motion must clarify hierarchy, causality, spatial relationship, or status.

## Health truth and privacy boundaries

These are hard product constraints, not optional disclaimer copy:

- Do not invent activity, recovery, sleep, stress, readiness, resilience, cardiovascular age, or health scores.
- Do not imply diagnostic meaning or medical-grade accuracy.
- Firmware HRV and stress values are **unitless, opaque vendor indexes with unvalidated semantics**. Do not label HRV in milliseconds or classify the stress index as relaxed/normal/high.
- Sleep stages are firmware estimates, not EEG measurements.
- Oxygen is a captured hourly range. Do not compute or display an average that the source cannot support.
- Missing values are gaps and limited coverage, never zeros.
- Manual sport records are user context and must remain visibly separate from ring-measured activity.
- Recovery remains unavailable until validated inputs and a transparent calculation exist. Design that state as trustworthy and useful, not as a broken blank.
- Unsupported ring controls remain visibly locked: monitoring writes, gesture/display control, find ring, camera shutter, time-format changes, ring game, firmware update, stable live vital measurement, Apple Health export, and background Bluetooth sync.
- The only allowed ring-setting write is necessary device time synchronisation.
- Device identifiers must remain transient and redacted. Data is local-first, with provenance and consent legible at the moment they matter.

## Interaction and accessibility quality bar

- Follow Apple HIG-level conventions for navigation, safe areas, hit targets, sheets, focus, dynamic type, contrast, VoiceOver order, and motion accessibility without copying Apple’s visual styling.
- Minimum 44 × 44 point interactive targets.
- Body text must meet WCAG AA contrast and remain readable at 200% text size.
- Never rely on color alone for status or chart categories.
- Support keyboard navigation in the web prototype and make focus states visible but elegant.
- Include toggles in enabled, disabled, locked, loading, and failure conditions.

## Deliverables

Work inside the existing OpenDesign project `LibreRing — Reference-led Mobile UI`, but preserve the approved V1 artifact `librering-prototype.html` unchanged.

Create these new files:

- `librering-premium-v2.html` — a self-contained interactive prototype containing every route, a gallery overview, a focused 390 × 844 phone mode, keyboard navigation, functional controls, meaningful empty/failure states, reduced-motion mode, and large-text mode.
- `DESIGN-V2.md` — visual system, tokens, components, information architecture, screen-by-screen rationale, responsive behavior, accessibility decisions, and claims guardrails.
- `MOTION-V2.md` — motion principles, exact duration/easing/spring tokens, transition recipes, sync state machine, haptics, interruption rules, and reduced-motion equivalents.
- `HANDOFF-V2.md` — route/component mapping to the Flutter app, reusable primitives, state requirements, implementation sequence, and an explicit list of what must not be inferred or enabled.

Do not overwrite V1. Do not stop after a sample subset. The V2 prototype is complete only when all 26 routes are independently reachable and meaningfully designed.

## Self-review before delivery

Review and improve the result before declaring it done across these dimensions:

1. **Comprehension:** Can a new user understand the primary task and data state in under five seconds?
2. **Flow:** Is every next action obvious, reversible, and consistent across pairing, daily use, drill-down, journaling, and settings?
3. **Visual quality:** Does every screen feel authored, spacious, cohesive, and premium rather than component-generated?
4. **Motion quality:** Does motion explain state and causality, remain interruptible, and degrade elegantly with reduced motion?
5. **Truth and accessibility:** Are unsupported claims absent, gaps honest, privacy/provenance clear, and all key paths accessible?

Fix material issues found in that review. Return the completed prototype and written handoff, not merely recommendations.
