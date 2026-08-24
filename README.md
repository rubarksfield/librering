# LibreRing V1 — design and scoring review

Status: **`DESIGN_AND_SCORING_APPROVED`**

Visual direction: **approved for V1 on 2026-08-24**  
Scoring model: **approved for V1 on 2026-08-24**

LibreRing V1 has an approved product-design and scientific-model foundation for
the COLMI R12. Production Flutter implementation is authorised after the frozen
V1 sources are verified.

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
not silently alter the frozen V1 implementation contract.
