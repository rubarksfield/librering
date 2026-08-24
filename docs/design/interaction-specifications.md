# Approved V1 interaction specifications

## Navigation

- Primary destinations are Today, Metrics, Trends, and Privacy for the approved
  visual artifact. Production may expose Journal as a contextual action without
  adding a fifth persistent destination.
- Back returns to the immediate source; it never discards entered data silently.
- A destination restores its last meaningful scroll/date state.
- Deep links use the routes in `screen-specifications.md`.

## Motion

- Route/state transitions: 180–320 ms, `cubic-bezier(0.2, 0, 0, 1)` equivalent.
- Animate transform and opacity only; do not animate decoration.
- Charts and numbers may enter once when the underlying period changes.
- Reduced motion removes translation, scale, staged reveals, and chart drawing.

## Critical flows

1. Welcome → privacy → scan → found → Today.
2. Today → Metrics → Sleep → Evidence → no-result → supported Trend.
3. Trend → Add swim → Save locally → Privacy.
4. Cycle privacy changes require explicit control and never share data by toggling.

## Feedback and recovery

- Every asynchronous state has idle, progress, partial, complete, failed, and
  cancelled semantics.
- Save actions confirm scope and provenance. Destructive actions require a
  second confirmation and describe whether recovery is possible.
- BLE, health permission, and database errors use domain-specific recovery; raw
  exception text is available only in diagnostics.
