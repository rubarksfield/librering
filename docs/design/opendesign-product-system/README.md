# Open Design product-system handoff

This folder freezes the Open Design artifact used for the current Flutter implementation.

- Open Design project: `librering-reference-led-mobile-ui`
- Artifact: `librering-product-system.html`
- Retrieved: 2026-08-28
- SHA-256: `4414dac3d35390d02967035abc46c298c4abb33e657176e9a848f81d842e9147`

## Implementation contract

The Flutter app follows the artifact's four-part hierarchy: Today, Vitals, Trends, and You. It also carries forward the timeline, activity confirmation, manual sport logging, profile, device history, and capability-bound vital states.

The HTML contains illustrative health values and concept scores. They are visual/product examples, not production measurements. Production Flutter screens continue to use stored local ring records and preserve these boundaries:

- unavailable is not zero;
- manual and confirmed-suggestion context stays separate from ring-recorded data;
- sport type is never inferred automatically;
- firmware HRV and stress fields remain experimental and unvalidated;
- oxygen samples do not become a validated result automatically;
- temperature is unsupported by the connected R12;
- recovery/readiness concepts are not presented as measured production scores.

The frozen artifact is retained for visual diffing and future design-to-code audits. Open Design remains the editable design workspace; this copy is the reviewed source snapshot for this implementation pass.
