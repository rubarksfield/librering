# LibreRing Premium V2 — Motion and tactile system

## 1. Principle

Motion earns its place only when it explains navigation, state, causality, or device status. LibreRing does not animate to imply scientific certainty, premium value, or progress that has not occurred.

The system uses one crisp, front-loaded curve for opacity and color, plus one restrained overshoot curve for press and toggle position. Content is always present before chart reveal motion begins. Every transition is interruptible by a new route, range, metric, or state choice.

## 2. Tokens

```css
:root {
  --ease-out: cubic-bezier(.2, 0, 0, 1);
  --ease-spring: cubic-bezier(.2, 1.28, .42, 1);
}
```

| Token | Duration | Curve | Use |
| --- | ---: | --- | --- |
| `press` | 120 ms | `--ease-spring` | Button, chip, row, and navigation press feedback |
| `state-fast` | 150 ms | `--ease-out` | Color, border, selected-state, and hover confirmation |
| `toggle` | 160 ms | `--ease-spring` | Switch thumb position |
| `toast-enter` | 180 ms | `--ease-out` | Non-urgent local confirmation |
| `scroll-reveal` | 220 ms | `--ease-out` | Evidence items entering the visible reading area |
| `route-enter` | 230 ms | `--ease-out` | Shared-axis overview/detail navigation |
| `chart-reveal` | 260 ms | `--ease-out` | Filled chart and bar reveal after content exists |
| `privacy-save` | 420 ms maximum | `--ease-out` | Demonstration of a local toggle write, with final state authoritative |
| `ring-orbit` | 920 ms × 4 maximum | `--ease-out` | Bounded searching or receiving status |

No routine UI transition exceeds 260 ms. The longer ring orbit is a bounded progress/status animation, not a control transition.

## 3. Route transitions

### Overview to detail

- Incoming detail begins 10 points to the right at zero opacity.
- It reaches its final position and opacity in 230 ms.
- The new screen is interactive immediately; the transition confirms navigation rather than delaying it.
- Back navigation uses the same spatial axis in the opposite conceptual direction in native implementation.
- A second navigation interrupts and replaces the active transition without waiting for completion.

### Primary-destination changes

Today, Trends, Journal, and You use a short cross-fade with no large lateral travel in native implementation. The web prototype uses the same 10-point shared-axis entry for consistency, but does not animate keyboard-only host route changes beyond the product surface.

### Reduced-motion equivalent

The destination replaces the source immediately. Focus and route labels establish the new state; no translate or scale runs.

## 4. Press and selection behavior

### Buttons and rows

- Pointer press: scale to 0.975 in 120 ms.
- Release: return to 1 with the same restrained spring curve.
- The ink foreground/background pair remains contrast-safe throughout.
- Keyboard activation has no transform animation; focus and resulting state provide confirmation.

### Bottom navigation

- Press scale: 0.95 in 120 ms.
- Selection fill and text/icon color change in 150 ms.
- Selected icon and label remain visible statically when motion is removed.

### Segmented controls and chips

- Selection commits immediately.
- Fill, border, and text pair change in 150 ms.
- Press scale is 0.975 for pointer feedback only.
- Range change then triggers one chart morph/reveal; the control does not wait for the chart.

### Toggle

- The preference write begins on activation; the previous value remains authoritative until success.
- The thumb uses a 160 ms restrained overshoot after success.
- Loading may move the thumb toward the midpoint twice, then stops.
- Failure restores the previous value and reveals a persistent inline error.

## 5. Chart behavior

### First reveal

- Data is rendered and accessible before animation begins.
- Filled areas and bars scale from 86% height to full height over 260 ms.
- Points fade in over 180 ms.
- A small group may stagger by 25 ms in the Flutter implementation; long lists do not stagger.
- No number count-up is used.

### Day / week / month morph

- The selected segment changes immediately.
- Existing points interpolate to new positions where the conceptual sample persists.
- Added points fade in; removed points fade out.
- Gaps never interpolate through zero.
- Native duration: 240 ms with the standard curve.
- A new range selection retargets from the current visual state rather than restarting from the old range.

### Scrubbing

- Pointer/touch position selects the nearest captured point or range.
- The selected mark switches from paper fill to coral fill with an ink outline in 150 ms.
- Timestamp, value/range, and provenance update immediately in a persistent output row.
- One light selection haptic fires when crossing to a different point, never continuously while remaining on the same point.
- Left and Right Arrow keys move through captured points without motion dependency.

### Reduced-motion equivalent

The new chart appears immediately with the same filled encoding. Scrubbing changes the selected mark and output text without moving surrounding content.

## 6. Pairing progression

Pairing may feel ceremonial once because it establishes trust and a physical relationship.

| Phase | Visual behavior | Copy responsibility | Haptic recommendation |
| --- | --- | --- | --- |
| Idle | Quiet ring; no orbit | Bluetooth starts only after Scan | None |
| Searching | Outer orbit rotates; four iterations maximum | Identifiers stay transient; no health/settings command | None |
| Multiple found | Orbit stops and becomes dashed | User must choose the exact owned R12 | Selection haptic on exact candidate |
| Verifying | One short orbit cycle | Service profile only; no health/settings command | None |
| Connected | Orbit disappears; ring sensor remains | Exact service profile verified | One medium success haptic |
| Receiving history | Orbit runs, bounded | Existing local data remains readable | None |
| Complete | Orbit stops; explicit stored-record result | Recovery still unavailable | One light success haptic |
| Partial | Dashed static orbit | Name committed families and stale/missing families | One warning haptic |
| Failure | Broken static semantic-color orbit | Explain preservation and retry | One warning haptic |

Pairing timers are cancellable on route change. No pairing progress is described as complete until local persistence succeeds in production.

## 7. Routine refresh state machine

Routine refresh stays in Today or Ring device and never replays onboarding.

```text
idle
  -> searching
  -> connecting
  -> receiving
  -> complete

searching | connecting | receiving
  -> partial
  -> stale-preserved
  -> recoverable-failure
```

### State behavior

- **Idle:** existing reading is fully visible.
- **Searching:** small sync action and ring-status copy update; data remains visible.
- **Connecting:** no measured value changes.
- **Receiving:** decoded families may stage privately, but the visible committed dataset remains stable.
- **Complete:** committed readback replaces changed families and a fixed-position status confirms local refresh.
- **Partial:** successful families update; failed families retain prior values with a stale or missing label.
- **Stale-preserved:** prior history remains visible with age and source.
- **Recoverable failure:** prior history remains visible; first retry is immediate.

### Retry discipline

1. First user retry fires immediately.
2. Second and third attempts use 2-second and 4-second backoff.
3. After three failures, the product replaces Retry with support guidance and a copyable local error ID.
4. The surface shows last-attempt age after the first retry.
5. No spinner or orbit runs beyond 60 seconds. A 15-second notice explains that the operation is taking longer than expected; after 60 seconds, animation stops and recovery actions replace progress.

## 8. Long evidence screens

Evidence entries may fade from 20% to full opacity while translating 8 points upward over 220 ms when they first enter the scroll viewport. The observer runs against the phone scroll area, unregisters each item after its first reveal, and is cancelled with the route.

The effect gives source chronology a light rhythm. It does not modify scroll position, apply parallax, or delay reading. Under reduced motion, all entries render statically at full opacity.

## 9. Sheets and toast

### Destructive confirmation sheet

- Native iOS implementation: bottom sheet enters over 240 ms with an iOS-standard interruptible spring.
- Dismissal completes in 180 ms.
- The background does not scale or blur.
- Focus moves to Cancel and remains trapped until Cancel, Delete, or Escape.
- Destructive completion uses a warning haptic only after verified local deletion.

### Toast

- Enters 8 points upward plus opacity in 180 ms.
- Uses one fixed position above bottom navigation.
- Remains visible for 4.8 seconds.
- Pauses while hovered or focused in production.
- Never serves as sole proof of a data write; the destination state must reflect the committed result.

## 10. Haptic map

| Event | iOS recommendation | Constraint |
| --- | --- | --- |
| Standard button activation | `UIImpactFeedbackGenerator(style: .light)` | Pointer/touch only; not keyboard or VoiceOver double-action duplication |
| Exact ring selected | Selection feedback | Once per actual selection change |
| Pairing verified | Medium impact + success notification | Only after verified service profile |
| Sync completed | Light success notification | Only after local persistence readback |
| Partial sync | Warning notification | Once; do not repeat for every missing family |
| Chart point changed | Selection feedback | Only when index changes, rate-limited |
| Privacy toggle saved | Selection feedback | After persistence succeeds |
| Form saved locally | Light success notification | After journal readback |
| Destructive deletion | Warning notification | After deletion readback, never on confirmation tap |
| Locked control | None | Static explanation is sufficient |

Haptics must respect the device and app-level haptic preference.

## 11. Interruption and performance rules

- Route change clears pending timers, observers, sync demonstration steps, and transient toasts.
- A new range or metric selection retargets from the current state.
- Transforms and opacity are the only properties used for spatial motion.
- Color and border transitions use explicit properties; `transition: all` is prohibited.
- The ring orbit has a fixed iteration count and never loops indefinitely.
- No continuous scroll listener is used; evidence reveal uses `IntersectionObserver`.
- No backdrop blur, parallax, layout-property animation, or autoplay decoration appears.
- Native implementation should profile pairing, chart scrub, and long evidence scrolling on a physical iPhone and maintain 60 fps.

## 12. Reduced-motion contract

When iOS Reduce Motion, web `prefers-reduced-motion`, or the prototype override is active:

- route translation is removed;
- chart height/point reveals are removed;
- ring orbit stops and status copy plus static shape carries the state;
- evidence scroll reveals are skipped;
- toast translation is removed while opacity/state remain;
- toggle position may change without overshoot;
- focus, selected state, source labels, values, and errors remain unchanged;
- no information is lost and no action takes longer.
