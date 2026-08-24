# Sleep model card

- **purpose:** Answer whether an inferred sleep period was sufficient,
  continuous, and appropriately timed for this person.
- **intended_use:** Daily wellness reflection for an adult who understands that
  R12 sleep is firmware-inferred.
- **not_intended_use:** Diagnosis, sleep-disorder screening, safety-critical
  alerting, treatment, or EEG-equivalent staging.
- **inputs:** total sleep, time in bed, awake-after-onset, sleep midpoint,
  midpoint variability, coverage, timestamp quality, baseline maturity.
- **input_provenance:** R12 firmware interval after protocol acceptance; timing
  and regularity app-derived. Firmware stages are display-only.
- **data_requirements:** reliable interval and ≥60% expected sleep-window
  coverage. Target: at least 14 valid nights for provisional personal timing.
- **calibration:** none to outcomes. Curves are v0.1 research choices tested only
  on synthetic data.
- **baseline_method:** rolling median midpoint and duration, MAD variability;
  states No baseline, Learning, Provisional, Established, Recalibrating.
- **contributor_formulas:** duration band/penalty; efficiency/interruption blend;
  circular distance from personal midpoint; variability penalty. Exact equations
  are in `scoring-model-v0.1.md` and executable source.
- **weights:** duration 45%, continuity 30%, personal timing 15%, regularity 10%.
- **missing_data:** critical interval/coverage failure returns no score. Optional
  stage data is never reweighted in.
- **confidence:** coverage 45%, baseline maturity 25%, timestamp reliability 20%,
  semantic certainty 10%; Low/Moderate/High display.
- **output:** score, label, separate confidence, contributor list, missing items,
  explanation, action, limitations, calculation version.
- **labels:** Supportive, Steady, Limited, Disrupted, No result.
- **known_limitations:** no R12 PSG validation; timezone/no-wear semantics pending;
  fixed v0.1 curves may not fit disability, shift work, older adults, adolescents,
  fragmented sleep, or atypical sleep need.
- **validation:** 2,970 synthetic daily records; unit tests for response,
  monotonicity, missing data, and baseline non-mutation. No construct or outcome
  validation.
- **bias_risks:** population duration guidance, employment/care schedules,
  chronotype, shift work, sleep disorders, medication, age, and ring fit.
- **version:** `0.1.0-research`.
- **change_history:** 2026-08-23 initial independent model; firmware stages given
  zero weight.
