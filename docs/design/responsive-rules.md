# Approved V1 responsive rules

- Canonical review size is 390×844 with 24 px horizontal content insets.
- At 320–389 px, preserve 24 px where possible, reduce only display type, and
  keep 48 dp targets. Never horizontally scroll a product screen.
- At 390–599 px, use the canonical single-column composition.
- At 600–839 px, constrain content to 520 px and keep one dominant reading.
- At 840 px and above, allow a supporting evidence column only on detail screens;
  onboarding and lead screens remain visually singular.
- Safe-area insets wrap top bars, primary actions, and floating navigation.
- Text scaling to 200% may stack controls/cards and move actions below the fold;
  it must not clip, overlap, or hide meaning.
- Orientation is portrait-first. Landscape phones use a centred scrollable
  content column; no separate landscape design is required for V1.
- Charts downsample visibly and preserve gaps; they never smooth missing data.
