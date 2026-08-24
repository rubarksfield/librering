# Approved V1 screen specifications

Canonical phone: 390×844, portrait first, 24 px content inset. The first twelve
screens define the approved visual system; the existing 36-route prototype
remains the content and edge-case source for implementation expansion.

| Route | Screen | Dominant job | Required content/state |
| --- | --- | --- | --- |
| `/welcome` | Welcome | Understand the product | Original ring art, privacy promise, demo and connect paths |
| `/privacy` | Privacy promise | Understand local-first defaults | On-device statement, explicit sharing boundary |
| `/pairing/scan` | Ring scan | Start local scan | Permission rationale, QRing conflict help, scanning/error states |
| `/pairing/found` | Ring found | Confirm device | Alias/model, battery, signal, capability identification |
| `/today` | Daily lead | Read one conclusion | One lead result, explanation, confidence, large heatmap only |
| `/metrics` | Four metrics | Scan supported signals | Separate 2×2 grid; provenance and limitations on every card |
| `/sleep` | Sleep detail | Understand last night | Duration, continuity, coverage, confidence, evidence link |
| `/sleep/evidence` | Evidence | Inspect derivation | Inputs, coverage, provenance, correction, formula version |
| `/no-result` | No result | Understand a capability/data limit | Unsupported or insufficient reason and safe next path |
| `/trends` | Trend detail | Read supported change | Range control, gaps, baseline, semantic chart summary |
| `/journal/swim` | Swim entry | Add manual context | Duration, pool/open water, effort, separate provenance |
| `/privacy/cycle` | Cycle privacy | Control sensitive data | Strict opt-in, local storage, separate context/export/delete controls |

Production expansion must also cover the approved pairing, recovery, movement,
device, export/delete, Cycle Context, error, partial, calibration, dark theme,
large-text, and health-permission states documented in `prototype/` and the state
matrix. Unsupported capabilities remain hidden or resolve to an honest no-result.
