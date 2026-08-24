# LibreRing first-stage build plan

Status: `DESIGN_AND_SCORING_APPROVED`

Visual direction and scoring are approved for V1. The required freeze artifacts
are being completed before production code begins.

The user supplied an unmistakably equivalent approval of both design and scoring
on 2026-08-24.

## Gates

| Gate | State | Evidence required |
| --- | --- | --- |
| Design infrastructure | Complete | Pinned local Penpot/recovery proof plus dependency-free web-prototype fallback |
| Repository audit | Complete | Source and dependency audits, notices, licence decision |
| Market research | Complete | Dated source-backed synthesis, competitor matrix, QRing audit |
| Scientific research | Complete for review | Evidence ledger, conflicts, R12 capability matrix, independent derivation |
| Product definition | Complete | Jobs, principles, information architecture, content hierarchy, flows |
| Design exploration | Complete | Three materially distinct, original visual directions |
| Prototyping | Complete | Eight interactive web journeys, alternate states, light/dark/large-text coverage |
| Visual direction decision | Accepted | Approved Open Design artifact archived under `docs/design/approved-reference-led/` |
| User review | Approved | Visual and scoring approval recorded on 2026-08-24 |
| Design and scoring freeze | In progress | Exports, tokens, specifications, mapping, and scoring V1 |
| Production implementation | Unlocked after freeze | Begin Phase 5 only after freeze verification |

## Verification strategy

- Design infrastructure: Penpot container health, HTTP readiness, account/project/file creation and recovery rehearsal; web prototype syntax, runtime, responsive, interaction and accessibility checks.
- Research: primary/official sources first; dates, versions, populations, limitations and conflicts recorded.
- Scoring: deterministic environment, unit tests, scenario assertions, sensitivity/volatility outputs and model cards.
- Prototype: all eight journeys, five-second and three-tap tests, heuristic/accessibility/originality reviews, no unsupported metrics.
- Freeze gate: verify and commit approved V1 design/model artifacts separately
  before creating production code.

## Current gate

Complete and verify the V1 design/scoring freeze, commit it separately, then begin
Phase 5: Flutter workspace, design system, deterministic demo mode, approved
navigation/screens, and tests.
