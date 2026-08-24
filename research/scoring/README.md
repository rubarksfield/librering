# LibreRing scoring research sandbox

This is a deterministic research environment, not production implementation.
It contains independently derived, transparent Sleep, Recovery, and Movement
models plus a Cycle Context safety policy. It does not reproduce a commercial
wearable formula.

## Reproduce

From the repository root:

```bash
python3 research/scoring/run_research.py
python3 -m unittest discover research/scoring/tests -v
```

The first command recreates the 2,970 fictional daily records (33 scenarios ×
90 days) distributed across six fictional profiles (typical schedule, late
chronotype, rotating shift, endurance training, lower-mobility pattern, and Cycle
Context), machine-readable result files, sensitivity/volatility tables, and SVG
charts. Seed `1729` is fixed. Existing outputs are overwritten deterministically.

## Boundaries

- All records under `synthetic_data/` are fictional.
- The R12 firmware's “HRV” byte and sleep stages are excluded from formulas.
- R12 temperature and respiratory rate are unsupported.
- Confidence is calculated separately from a score.
- A missing critical interval returns no Sleep result; missing optional HRV does
  not receive a negative physiological score.
- Cycle Context is calendar/symptom context only in this hardware profile.
- The scripts use Python's standard library and have no hidden notebook state.

`notebooks/` contains a route map for optional exploration. Scripts and tests are
the canonical reproducible record.
