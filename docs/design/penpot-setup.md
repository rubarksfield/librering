# Penpot setup

Reviewed and verified: 2026-08-23

## Environment

- Penpot: `2.17.1` (current stable release at review time)
- Docker Engine: `29.4.3`
- Docker Compose: `5.1.4`
- Local URL: <http://localhost:9001>
- Exposure: loopback/local machine only; no tunnel or public proxy
- Telemetry: disabled
- Compose project: `librering-penpot`
- Runtime and credentials: gitignored `.tools/penpot/`

The official Compose definition was retrieved from the pinned `2.17.1` tag and its SHA-256 was `79330b4445d6c6dba6918d222d342a365710ba90b6bb8a8eae3d333155b0cf5e` before the local security amendments. All service images are pinned by digest in the local Compose file.

## Start and stop

Docker Desktop must be running. The wrapper uses a task-local Docker client configuration because the machine's global Docker Desktop credential helper blocked anonymous public-image pulls during setup.

```bash
.tools/penpot/penpot-compose.sh up -d
.tools/penpot/penpot-compose.sh ps
.tools/penpot/penpot-compose.sh down
```

`down` preserves the named Postgres and asset volumes. Do not add `--volumes` unless intentionally deleting all local Penpot data.

## Local account

The local-only profile is `LibreRing Local`. Login details are stored with mode `0600` in:

```text
.tools/penpot/.local-credentials
```

This file is gitignored. Do not copy its contents into commits, screenshots, issue reports or chat messages.

## Authenticated project state

Team: `LibreRing`

Project: `LibreRing V1`

Design file: `LibreRing — Product & Scientific Model V1`

The authenticated team, project and file were created successfully. The first-gate
visual source of truth then moved to `prototype/` under the user's explicit
instruction to choose a no-input alternative if Penpot was too difficult.

The planned native page topology is retained below as a future migration map,
not a claim that those pages exist in the current Penpot file:

Required pages:

```text
00 — Read Me
01 — Research Synthesis
02 — Scientific Model
03 — Jobs and Principles
04 — Information Architecture
05 — User Flows
06 — Visual Directions
07 — Foundations
08 — Components
09 — Prototype — Primary Flow
10 — Prototype — Alternate States
11 — Scoring Scenario Explorer
12 — Light Mode
13 — Dark Mode
14 — Accessibility
15 — Handoff
16 — Archive
```

## MCP

Penpot 2.17.1 includes the official MCP service in the self-hosted Compose stack. The frontend exposes it through same-origin routes:

- Streamable HTTP: `http://localhost:9001/mcp/stream`
- Legacy SSE: `http://localhost:9001/mcp/sse`
- Plugin WebSocket: `ws://localhost:9001/mcp/ws`

The older standalone-package example in the master prompt is not used because the current stable self-hosted distribution bundles the matching MCP service. A plain GET to the stream route returns HTTP `406`, confirming that the route is live and requires an MCP-compatible request.

The Penpot user session and intended design file must be open for design-context
operations. Transport/tool discovery was verified, but a context read plus
reversible edit was not claimed: Penpot 2.17.1 reported that the bundled plugin
targets 2.17.0, and the connection was not reliable enough for unattended work.

## Backup and restore

Create a logical database plus asset-volume backup:

```bash
.tools/penpot/backup.sh
```

The command prints the new timestamped backup directory. It includes:

- `penpot-postgres.dump`
- `penpot-assets.tar.gz`
- `SHA256SUMS`

Rehearse restoration into a scratch database and scratch Docker volume without overwriting the live environment:

```bash
.tools/penpot/verify-restore.sh /absolute/path/to/backup-directory
```

For a real disaster restore, stop the frontend/backend/exporter, restore the database dump and asset archive into the named live volumes, then restart and verify through the UI. Real live-volume replacement is intentionally not automated because it is destructive.

## Export

If native Penpot work resumes, use its dashboard export for portable `.penpot`
backups. The review artifact itself is already portable because `prototype/` has
no dependency or remote asset.

## Known limitations

- The profile, team, project and design file exist; the planned 17-page topology
  and presentation-mode links were intentionally not built after the source-of-
  truth switch.
- MCP transport is reachable, but context-aware design operations are unproven due
  to the bundled plugin's 2.17.0/2.17.1 version mismatch.
- No public exposure or multi-user scaling is configured.
