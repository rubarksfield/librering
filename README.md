# LibreRing V1

Status: **`IMPLEMENTATION` — Phase 5 production foundation complete**

Visual direction: **approved for V1 on 2026-08-24**  
Scoring model: **approved for V1 on 2026-08-24**

LibreRing V1 has an approved and separately committed product-design and
scientific-model foundation for the COLMI R12. The first production Flutter
vertical slice implements the twelve priority screens, deterministic demo mode,
local privacy/journal state, and English/pt-PT locale plumbing.

## Run the mobile foundation

Flutter 3.47.1 is installed at `/Users/zoerichardson/develop/flutter`.

```sh
cd apps/mobile
/Users/zoerichardson/develop/flutter/bin/flutter run \
  --dart-define=LIBRERING_DEMO=true
```

Omit the flag to verify the fail-closed production state. It never substitutes
demo health values when a real repository is unavailable.

```sh
/Users/zoerichardson/develop/flutter/bin/flutter analyze
/Users/zoerichardson/develop/flutter/bin/flutter test
/Users/zoerichardson/develop/flutter/bin/flutter build ios --simulator --debug \
  --dart-define=LIBRERING_DEMO=true
```

The verified native render is archived at
`docs/testing/screenshots/ios-welcome.png`.

## Review the interactive prototype

```sh
python3 -m http.server 4173 --directory prototype
```

Open <http://localhost:4173/> and complete the eight numbered journeys. The
prototype is dependency-free, uses fictional demo data, and includes light/dark,
large-text, missing-data, swim, device-conflict, export, Cycle Context, pregnancy,
and separate-deletion states.

See:

- [Approved reference-led visual direction](docs/design/approved-reference-led/README.md)
- [Approved 12-screen visual prototype](docs/design/approved-reference-led/prototype.html)
- [Prototype instructions](prototype/README.md)
- [Prototype review](docs/design/prototype-review.md)
- [Research synthesis](docs/design/research.md)
- [R12 evidence boundary](docs/protocol/colmi-r12-evidence.md)
- [Approved scoring model](docs/science/scoring-model-v1.md)
- [Model evaluation](docs/science/model-evaluation.md)
- [Progress and limitations](docs/PROGRESS.md)
- [Production architecture](docs/architecture/system-overview.md)

## Reproduce the scoring research

```sh
python3 research/scoring/run_research.py
python3 -m unittest discover research/scoring/tests -v
```

The fixed seed generates 2,970 fictional daily records across 33 scenarios and
six fictional profiles. Passing deterministic tests establish specified
behavior, not hardware, medical, demographic, or clinical validity.

## Approval gate

The user supplied an unmistakable equivalent approval on 2026-08-24. The V1
design and scoring sources are frozen, and production implementation is now
authorised. The canonical approval phrase remains:

```text
APPROVE DESIGN AND SCORING V1
```

Future design or scoring changes require an explicit versioned revision and must
not silently alter the frozen V1 implementation contract. BLE, persistent data,
health bridges, and scoring execution remain later-phase work.
