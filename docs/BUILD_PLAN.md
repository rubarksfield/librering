# LibreRing first-stage build plan

Status: `IMPLEMENTATION`

Visual direction and scoring are approved and frozen for V1. Phase 5 production
foundation work is implemented and verified; Phase 6 protocol work is next.

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
| Design and scoring freeze | Complete | Commit `04563fe`; exports, tokens, specifications, mapping, and scoring V1 |
| Phase 5 production foundation | Complete | Flutter workspace, approved twelve routes, demo boundary, locale/state plumbing, tests, iOS simulator build |
| Android build environment | Machine gap | Android SDK must be installed and its licences accepted by the user |
| Phase 6 protocol implementation | In progress | Pure-Dart driver/transport contracts, fail-closed QRing framing and synthetic fixtures complete; physical commands gated |

## Verification strategy

- Design infrastructure: Penpot container health, HTTP readiness, account/project/file creation and recovery rehearsal; web prototype syntax, runtime, responsive, interaction and accessibility checks.
- Research: primary/official sources first; dates, versions, populations, limitations and conflicts recorded.
- Scoring: deterministic environment, unit tests, scenario assertions, sensitivity/volatility outputs and model cards.
- Prototype: all eight journeys, five-second and three-tap tests, heuristic/accessibility/originality reviews, no unsupported metrics.
- Freeze gate: verify and commit approved V1 design/model artifacts separately
  before creating production code.

## Current gate

Phase 5 is complete. Phase 6 has a verified fail-closed protocol foundation;
platform BLE wiring and command enablement require the Android/tooling and
physical COLMI R12 fixture gates. Do not add database/scoring/health behavior yet.
