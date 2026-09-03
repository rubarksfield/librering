# Contributing to LibreRing

Thank you for helping build a calmer, more honest smart-ring companion.
Contributions can be code, tests, documentation, accessibility review, protocol
evidence, or carefully described device behaviour.

## Before you begin

1. Read the [R12 evidence boundary](docs/protocol/colmi-r12-evidence.md).
2. Search existing issues and open or claim one before doing substantial work.
3. Keep unsupported data unavailable. Never turn a missing value into zero and
   never rename an opaque firmware index as a validated health metric.
4. Never commit raw BLE captures, health records, location data, stable device
   identifiers, signing material, or credentials.
5. Use only hardware you own or have explicit permission to test.

## Local setup

```sh
git clone https://github.com/rubarksfield/librering.git
cd librering/apps/mobile
flutter pub get
flutter run --dart-define=LIBRERING_DEMO=true
```

Demo mode uses deterministic fictional data. Production mode must fail closed
when ring data is missing or unsupported.

## Make a focused change

- Create a branch from `main`.
- Keep protocol facts, decoding, domain meaning, and UI interpretation separate.
- Add or update the nearest tests.
- Update a golden image only after visually reviewing the complete rendered
  screen; do not approve a bulk change by checksum alone.
- Add evidence and limitations when extending hardware support.

## Required checks

```sh
cd apps/mobile
flutter analyze
flutter test

cd ../../research/scoring
python3 run_research.py
python3 -m unittest discover tests -v
```

If your change is platform-specific, also build or test that platform and state
the exact device, OS, ring model, and firmware in the pull request—without a
stable identifier or personal reading.

## Pull requests

Explain:

- what changed and why;
- which data source or evidence supports it;
- how missing and unsupported states behave;
- which commands and devices were used for verification;
- any remaining risk or untested edge case.

Small, reviewable pull requests are preferred. By contributing, you agree that
your contribution is licensed under Apache-2.0.
