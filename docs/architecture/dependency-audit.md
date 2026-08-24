# Dependency audit

Reviewed: 2026-08-23.

## Current repository

There is no production application and therefore no production dependency
graph. This is intentional: the design-and-scoring approval gate remains locked.
The scoring sandbox uses Python 3 standard-library modules only. Its generated
CSV/JSON/SVG artifacts are reproducible and require no notebook runtime.

## Local design tooling

Penpot 2.17.1 runs outside the distributed project from digest-pinned images.
Runtime configuration, database, object storage, credentials, and backups live
under gitignored `.tools/penpot/`. A compose-file licence inventory is still
required before anyone redistributes those images; LibreRing does not do so.

## Future production decision record

No package is approved yet. After `APPROVE DESIGN AND SCORING V1`, evaluate the
minimum Flutter package set against these gates:

| Area | Required checks |
| --- | --- |
| BLE | active maintenance, iOS/Android permissions, MTU/notification control, no hidden analytics, licence compatibility |
| Storage | SQLite migrations, encryption story, deterministic export, deletion semantics, licence |
| Health platforms | current HealthKit/Health Connect APIs, provenance preservation, granular consent |
| Charts | accessible semantics, export support, rendering performance, licence |
| State/navigation | deep-linkability, testability, no unnecessary framework coupling |
| Crypto | platform-backed primitives only; never custom cryptography |

For each candidate record package name, exact version and hash, transitive
licences, known CVEs, update cadence, permissions, network behaviour, binary
size, alternatives, and removal plan. Prefer direct platform APIs where the
dependency saves little code.

## Rejected first-stage dependencies

- No third-party scoring/math packages: the formulas need to be readable.
- No hosted analytics, AI, crash-reporting, authentication, or database SDK.
- No copied protocol library until clean-room evidence and licensing are settled.
- No proprietary app APK or reverse-engineering bundle in the repository.

## Verification

`python3 -m unittest discover research/scoring/tests -v` is the dependency-free
verification entry point. A future production dependency audit must be repeated
after a lockfile exists and before the first distributable build.
