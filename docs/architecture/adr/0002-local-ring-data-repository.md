# ADR 0002: Local R12 history repository

Date: 2026-08-26

Status: accepted

## Context

The owned-device capture verified read-only history structure on firmware
`RT11CR_1.00.09_260424`. Production sync needs durable, duplicate-safe storage
before decoded records can enter the UI. Raw BLE packets and stable device
identifiers must not enter that store.

## Decision

Store a versioned JSON document under the operating system's Application Support
directory, located with `path_provider` 2.1.6. The repository accepts only
decoded `ring_core` records, writes a same-directory temporary file with flush
before atomic rename, and rejects corrupt or unknown-schema data without
overwriting it.

Deterministic keys upsert activity, pulse, vendor-index and oxygen timestamps;
sleep sessions upsert by start time so a later firmware revision replaces the
same session. No-data responses preserve older records. Records older than 400
days are removed during merge. Source provenance includes only driver ID and
firmware version, never BLE ID or advertised name. Deletion removes the exact
local document and its temporary file; it sends no command to the ring.

Production sync is enabled only for the physically verified firmware. It reads
battery and bounded retained history, with the already-authorised clock
synchronisation as its only setting write. Unknown firmware, corrupt storage,
live measurement and all other settings fail closed.

The presence of valid stored data, rather than a stored BLE identity, marks a
returning user. Returning launches open Today, where routine refresh performs a
new bounded scan and requires exactly one R12 before connecting. On iOS, the
same discovery pass also queries CoreBluetooth for a currently connected
peripheral exposing the QRing command service, because it may not advertise.
That transient system identifier is deduplicated with scan results and is never
persisted. No result or multiple exact matches stop safely; first-run pairing
remains a separate setup journey.

## Consequences

- Repeated syncs are idempotent and survive app relaunch.
- The data remains inside the app sandbox with no account, cloud, analytics or
  background transfer.
- JSON is sufficient for the R12's bounded record volume and makes deletion and
  deterministic inspection straightforward; a database dependency is avoided.
- The store is not application-level encrypted. It relies on platform sandbox
  and device protection; stronger platform-backed protection requires a later
  privacy review and migration.
- Export is not implemented by this decision. A future export must require a
  separate confirmation and preserve the same provenance/identifier boundary.
