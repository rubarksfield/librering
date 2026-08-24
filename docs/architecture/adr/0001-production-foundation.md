# ADR 0001: Phase 5 production foundation

Date: 2026-08-24

Status: accepted

## Context

The user approved the frozen V1 design and scoring model. Production work must
implement that contract without prematurely introducing BLE, persistence,
health-platform, or scoring behavior.

## Decision

Use a Flutter workspace with a thin app and three initial local packages:
`ring_core`, `ring_demo`, and `ring_design_system`. Use Riverpod for explicit
state/dependency overrides and `go_router` for stable deep links. Keep demo mode
off by default and enable it only with `LIBRERING_DEMO=true`.

The visual system uses system Helvetica Neue on Apple platforms with Arial and
sans-serif fallbacks, project-authored canvas art, Material icons, and no remote
font/image dependency.

## Consequences

- UI, locale, accessibility, navigation, and state behavior can be verified now.
- Production mode remains sparse until a real repository exists.
- BLE, storage, and scoring packages can depend on `ring_core` without importing
  the UI or demo package.
- Android compilation remains externally blocked until its SDK/licence gate is
  satisfied; this does not weaken Flutter or iOS verification.
