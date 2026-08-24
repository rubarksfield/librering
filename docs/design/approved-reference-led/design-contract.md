# LibreRing Reference Design Contract

## Goal and target

- **Artifact:** responsive, browser-viewable mobile product prototype with a 12-screen gallery and focused 390×844 clickable phone mode.
- **Audience:** inferred—health-conscious ring wearers who value plain evidence, privacy, and honest capability boundaries.
- **Primary job:** move from private ring setup into a calm daily reading, then reveal evidence, trends, manual activity context, and consent controls only when relevant.

## Evidence

| Evidence | Confidence | Use |
| --- | --- | --- |
| User-supplied Dribbble URL | provided, not visually inspected | Sole named visual reference; page access was unavailable, so no unseen detail is claimed. |
| User-described reference qualities | provided | Neutral grotesk type, narrow light numerals, generous whitespace, flat warm-grey cards, coral data graphics, compact navigation. |
| LibreRing product contract in the brief | provided | Evidence-first language, confidence/provenance, consent, unsupported-metric honesty, and no diagnostic claims. |
| 390×844 focused phone size and 12 required screens | provided | Canonical viewport and screen inventory. |
| Primary bottom navigation across post-setup screens | inferred | Supplies a quiet, obvious journey without explanatory rails. |

## Reference boundaries

| Keep | Change | Do not copy |
| --- | --- | --- |
| Type-scale contrast; open composition; flat card material; coral visualizations; compact nav; quiet hierarchy. | Product identity, all copy, exact proportions, art, datasets, icons, charts, navigation labels, and screen sequence become LibreRing-specific. | Literal screenshots, ring renders, logos, proprietary UI, exact layouts, claims, pricing, or prompt wording. |

## Frozen design stance

LibreRing will use a calm editorial mobile system on warm paper, with light compressed-feeling numerals as the memorable visual move. Every screen isolates one task. Flat mineral cards support content without shadows; coral appears only as measurable data or selected state. The interface remains sparse but product-complete, placing evidence and consent on dedicated details rather than turning the daily view into a dashboard.

## Risks and explicit unknowns

- The remote reference image was not available for direct visual inspection; fidelity is grounded only in the qualities explicitly supplied by the user.
- Demonstration values are plausible sample data, not medical facts or promises.
- Browser support for installed Helvetica Neue varies; the local fallback chain preserves neutral grotesk character without network fonts.

## Quality gate

- [x] Twelve unique required screens are present and independently targetable.
- [x] Lead stats and 2×2 metrics are separate screens.
- [x] Onboarding is ring-art dominant with minimal copy and one primary action.
- [x] No unsupported or diagnostic measurement is presented as a result.
- [x] Focused journey is fully clickable; all targets are at least 44×44 px.
- [x] Body copy clears 4.5:1; focus and reduced-motion states are present.
- [x] No gradients, blur, glow, heavy shadow, nested cards, or explanatory rail.
- [x] Source contains reusable tokens/components and concise design notes.
