# Dependency audit

Reviewed: 2026-08-26.

## Current repository

The approved production foundation uses Flutter 3.47.1 and Dart 3.13.1. The
scoring sandbox remains Python-standard-library only and is not imported by the
mobile application.

| Direct dependency | Resolved version | Licence | Purpose / removal path |
| --- | --- | --- | --- |
| Flutter SDK | 3.47.1 stable | BSD-3-Clause | Mobile UI/runtime; platform foundation |
| `flutter_riverpod` | 3.4.2 | MIT | Explicit local state and dependency boundaries; replace with inherited state if removed |
| `go_router` | 18.0.0 | BSD-3-Clause | Deep-linkable 22-route map; replace with Router API if removed |
| `intl` | 0.20.3 | BSD-3-Clause | Locale support required by Flutter localizations; SDK-aligned |
| `flutter_localizations` | SDK | BSD-3-Clause | English and pt-PT platform localization delegates |
| `path_provider` | 2.1.6 | BSD-3-Clause | Resolves the sandboxed Application Support directory; replace with direct platform channels if removed |
| `crypto` | 3.0.7 | BSD-3-Clause | SHA-256 export integrity manifest only; not application-level encryption |
| `share_plus` | 13.3.0 | BSD-3-Clause | Invokes the platform share sheet for user-created JSON/CSV exports; remove to leave exports in Files only |

Local path packages are original Apache-2.0 project code:

- `ring_core` — immutable records, with no Flutter/BLE/scoring dependency.
- `ring_demo` — deterministic records whose provenance is always `demo`.
- `ring_design_system` — frozen tokens, theme, components, and original vector art.

The mobile lockfile SHA-256 is
`679dde6ddc9ce781d9673298862321f6fbbf43ac970bbdb31d5b986f991d0263`.
The local repository now uses `dart:io`, and `path_provider` uses the standard
platform channel to locate Application Support. It adds no health/network
permission, analytics or runtime networking. BLE remains the only feature with
radio permissions.

## Local design tooling

Penpot 2.17.1 runs outside the distributed project from digest-pinned images.
Runtime configuration, database, object storage, credentials, and backups live
under gitignored `.tools/penpot/`. A compose-file licence inventory is still
required before anyone redistributes those images; LibreRing does not do so.

## Later-phase decision record

BLE and local-directory discovery are approved as recorded below. No health,
chart, analytics, crash-reporting, authentication or database package is
approved yet. The audited `crypto` package is approved only for the portable
export checksum and is not used to claim encryption. Evaluate the minimum
later-phase set against these gates:

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

### Audited BLE adapter candidate

`flutter_reactive_ble` 5.5.0 was the published candidate audited on 2026-08-24
and is BSD-3-Clause. Its Android subpackage hard-codes compile SDK 33, which is
incompatible with its current AndroidX graph. The mobile adapter therefore pins
the official upstream 5.6.0 source at merged commit
`6b81c85e7681e222080263992b0ab8f2bc6a6404`; that change updates the plugin for
Flutter 3.47, built-in Kotlin, AGP 9 and Android SDK 37. The federated mobile and
platform-interface packages are pinned to the same commit to keep the graph
coherent. `pubspec.lock` records the resolved revisions. The adapter supports
scan, connect, service discovery, writes and notifications while `ring_ble`
remains pure Dart and protocol commands remain fail-closed.

### Audited local-storage dependency

`path_provider` 2.1.6 is maintained by the Flutter team and licensed
BSD-3-Clause. It resolves the platform Application Support directory but does
not read or write health data itself. LibreRing owns the versioned JSON format,
atomic write, 400-day retention, deterministic upsert and exact deletion
semantics. SQLite and application-level crypto were not added. The platform
sandbox is the current protection boundary; see ADR 0002 for the limitation.

## Rejected first-stage dependencies

- No third-party scoring/math packages: the formulas need to be readable.
- No hosted analytics, AI, crash-reporting, authentication, or database SDK.
- No copied protocol library until clean-room evidence and licensing are settled.
- No proprietary app APK or reverse-engineering bundle in the repository.

## Verification

`python3 -m unittest discover research/scoring/tests -v` is the dependency-free
research entry point. `flutter analyze`, the package tests, the application
tests, and the iOS simulator build verify the current dependency graph. Repeat
this audit before every new platform package and before the first distributable
build; no automated CVE database was available in this phase.
