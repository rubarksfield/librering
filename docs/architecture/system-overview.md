# Production architecture

Status: Phase 5 foundation, 2026-08-24.

```text
apps/mobile
  ├── ring_core              immutable cross-layer records
  ├── ring_demo              deterministic demo records only
  └── ring_design_system     frozen V1 tokens and visual primitives

future acquisition/storage/scoring packages
  └── ring_core              never import app or design packages

ring_colmi_qring
  ├── ring_ble               transport, driver, sync contracts
  └── ring_core              advertisements and capabilities
```

`apps/mobile` owns routing, feature composition, localization, and presentation
state. `ring_design_system` owns visual tokens and reusable primitives but never
health meaning. `ring_demo` can only create records marked `DataOrigin.demo`.
When `LIBRERING_DEMO` is absent, no demo snapshot enters the provider graph and
health screens render an honest unavailable state.

## Phase boundary

Phase 5 contains no BLE scan, device driver, database, HealthKit, Health Connect,
score calculation, export, deletion, network, analytics, or background service.
The pairing route is interactive only in labelled demo mode. This prevents UI
progress from being confused with physical COLMI R12 compatibility.

Phase 6 adds pure-Dart BLE/QRing boundaries and synthetic framing tests. It does
not yet link a platform plugin or emit an R12 command payload.

## Platform targets

- iOS deployment target 16.0; simulator build verified with Xcode 26.6.
- Android minimum SDK 28; native build awaits an installed Android SDK and user
  acceptance of its licences.
- Portrait-first canonical layout 390×844, with scrolling and scaling for text.
- Supported locales: English and Portuguese (Portugal).

## State and navigation

`go_router` owns twelve stable paths. Riverpod owns the demo-data boundary,
cycle privacy settings, and manual swim entry. Route widgets receive immutable
domain records rather than packets, database rows, or formula internals.

## Safety properties

- Demo and real data cannot mix through a fallback branch.
- Manual swim provenance remains separate from ring measurements.
- Cycle entries remain optional, local, and excluded from recovery scoring.
- Unsupported evidence resolves to no-result instead of estimation.
- Reduced motion removes route translation and transition duration.
