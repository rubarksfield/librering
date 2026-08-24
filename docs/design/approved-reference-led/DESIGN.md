# LibreRing Reference-Led Mobile Design System

## 1. Visual Theme & Atmosphere

LibreRing is calm, editorial health software: an open warm-paper canvas, quiet black type, flat mineral-grey cards, and one restrained coral signal. The interface should feel precise and humane rather than clinical or decorative. Whitespace is a functional material that isolates one decision or reading at a time.

## 2. Color

Bind these tokens directly. Derived colors must use `oklch()` and preserve the same hue family.

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

- Neutrals occupy at least 88% of each screen.
- Coral is a data fill or a single state cue, never a decorative wash.
- Use ink for body copy. Muted ink is tuned to clear 4.5:1 on both paper and card.
- No gradients, glows, glass layers, or large dark fields inside the product screens.

## 3. Typography

- Display and numeric stack: `"Helvetica Neue", "Neue Haas Grotesk Text Pro", "Nimbus Sans Narrow", sans-serif`.
- Body/UI stack: `"Helvetica Neue", "Nimbus Sans", sans-serif`.
- Mono/meta stack: `"SFMono-Regular", "SF Mono", "IBM Plex Mono", monospace`.
- Use light weights (200–300) for 56–92 px numerals, tabular figures, and tight negative tracking.
- Use 400 for reading and 550–600 for controls/headings. Avoid 700+.
- Keep UI labels 11–13 px with `0.06em`–`0.09em` tracking when uppercase.

## 4. Spacing & Grid

- Canonical screen: 390×844 px; safe content inset 24 px; top inset 24–34 px.
- Base spacing unit: 4 px. Primary intervals: 8, 12, 16, 24, 32, 48, 64.
- Reserve 92 px at the bottom of primary product screens for the floating navigation and safe area.
- Touch targets are at least 44×44 px. Cards use 18–24 px internal padding.

## 5. Layout & Composition

- One dominant reading or decision per screen.
- Onboarding is product-art led: original ring artwork occupies roughly 55–65% of the canvas.
- The stats lead contains one readiness/recovery number and one large square coral heatmap only.
- The four health metrics live on a separate 2×2 grid screen.
- Detail screens use a quiet top bar, one decisive chart or record, and short supporting evidence below.
- Compact floating navigation is centered and detached from the bottom edge without blur.

## 6. Components

- Cards: flat `--surface`, 14–18 px radius, no drop shadow, optional single 1 px separator.
- Primary button: ink fill, white label, 14 px radius, minimum 52 px height.
- Secondary controls: text or quiet surface buttons; never compete with the primary action.
- Data graphics: solid coral cells/bars/lines with ink or neutral context marks.
- Toggles: native buttons with a clear on/off state, 48×28 px visual track inside a 44 px target.
- Ring artwork: original SVG/CSS geometry with matte metal shading created from flat layered shapes, not gradients.

## 7. Motion & Interaction

- Use 180–320 ms transitions with `cubic-bezier(0.2, 0, 0, 1)`.
- Animate screen/state reorientation, number/chart entrance, button press, and nav selection only.
- Use transforms and opacity; do not animate decoration.
- Under `prefers-reduced-motion: reduce`, remove translation/scale and retain only short opacity/color feedback.
- Every focusable element receives a visible 2 px focus ring and 2 px offset.

## 8. Voice & Brand

LibreRing speaks plainly and never diagnoses. Copy distinguishes measured data, derived insight, user-entered context, unavailable data, and unsupported capabilities. An honest no-result is a valid success state. Evidence, confidence, provenance, and consent appear where decisions need them—not as persistent explanation panels.

## 9. Anti-patterns

- No desktop review rail, notes rail, explanation sidebar, or presenter controls inside the phone UI.
- No dense dashboard overview, nested cards, dashboard soup, or four metrics beneath the lead heatmap.
- No glassmorphism, background blur, gradients, glow, heavy shadow, decorative blob, or hero choreography.
- No copied Dribbble layouts, marks, assets, claims, or wording.
- No unsupported oxygen, QT, breathing, diagnostic, or inferred sensor values.
- No repeated primary action in one viewport and no coral text below large-text contrast thresholds.
