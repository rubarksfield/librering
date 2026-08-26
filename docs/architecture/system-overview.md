# Production architecture

Status: Phase 6 local sync implementation, 2026-08-26.

```text
apps/mobile
  ├── ring_core              immutable cross-layer records
  ├── ring_demo              deterministic demo records only
  ├── ring_design_system     frozen V1 tokens and visual primitives
  └── local repository       versioned decoded history in Application Support

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

Phase 6 adds pure-Dart BLE/QRing boundaries, synthetic framing tests, a Flutter
platform adapter, and a versioned local decoded-history repository. The
production pairing flow accepts only exact `COLMI R12_*` identities. Sync is
enabled only for the physically verified firmware, stores no raw packets or BLE
identifier, and preserves idempotency across relaunch. Local deletion is
available with confirmation. HealthKit, Health Connect, scoring, export,
networking, analytics, accounts and background sync remain absent.

## Platform targets

- iOS deployment target 16.0; simulator build verified with Xcode 26.6.
- Android minimum SDK 28; native build awaits an installed Android SDK and user
  acceptance of its licences.
- Portrait-first canonical layout 390×844, with scrolling and scaling for text.
- Supported locales: English and Portuguese (Portugal).

## State and navigation

`go_router` owns twelve stable paths. Riverpod owns the demo-data boundary,
decoded local repository state, pairing/sync state, cycle privacy settings, and
manual swim entry. Route widgets receive immutable domain records rather than
packets, storage rows, or formula internals.

First-run users enter the consent/pairing journey. A valid local dataset routes
returning launches directly to Today; its refresh control performs a bounded
scan/connect/sync in place and never turns routine refresh back into onboarding.

## Safety properties

- Demo and real data cannot mix through a fallback branch.
- Stable BLE identifiers and raw packets cannot enter the repository API.
- Corrupt or unknown-schema local data fails closed without overwrite.
- Recovery remains unavailable; opaque firmware HRV/stress indexes are not
  displayed or scored.
- Manual swim provenance remains separate from ring measurements.
- Cycle entries remain optional, local, and excluded from recovery scoring.
- Unsupported evidence resolves to no-result instead of estimation.
- Reduced motion removes route translation and transition duration.
