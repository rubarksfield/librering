# Recovery model card

- **purpose:** Show whether available overnight and recent signals appear normal
  for the person or whether more recovery may be useful.
- **intended_use:** Conservative daily wellness context with an R12 or labelled
  imported/manual records.
- **not_intended_use:** Diagnosis, illness detection, injury clearance, exercise
  prescription, pregnancy assessment, or a claim about how a person feels.
- **inputs:** Sleep result, reconstructed overnight resting pulse, recent load,
  optional energy check-in; optionally only a semantically validated HRV metric.
- **input_provenance:** R12 pulse history and Sleep; app-derived load; explicit
  check-in; imported HRV only when metric/method are known.
- **data_requirements:** Sleep or resting pulse must be available; for a normal
  numeric R12 result, reliable overnight pulse plus sleep is preferred. Declared
  pregnancy needs a pregnancy-specific baseline or remains trend-only.
- **calibration:** no recovery ground truth. V0.1 is uncalibrated research.
- **baseline_method:** rolling median and MAD for pulse; 7-day load relative to a
  robust 28-day personal history; baseline versions preserved.
- **contributor_formulas:** Sleep direct; pulse `100−9×|bpm deviation|`; load
  `100−72×|ratio−1|`; check-in linear; optional validated HRV
  `100−25×|robust z|`.
- **weights:** Sleep 40%, pulse 30%, load 20%, check-in 10%; validated HRV 15%
  only when present, with all weights normalized by the geometric combiner.
- **missing_data:** missing optional HRV lowers confidence but receives no poor
  value. Sleep and pulse both missing returns no result. Context can select a
  safer rule-only output.
- **confidence:** base evidence plus coverage, pulse availability, baseline
  maturity, and validated-HRV availability. R12 is generally Moderate at best.
- **output:** score or rule status, separate confidence, contributors,
  disagreement/context copy, reasonable action, limitations, version.
- **labels:** Normal range, Some recovery may help, More recovery may help, Trend
  only, No result.
- **known_limitations:** R12 HRV/stress/SpO₂ excluded; no R12 temperature or
  respiration; pulse reconstruction unvalidated; load and subjective truth are
  incomplete; symmetric pulse curve may over-penalise benign deviations.
- **validation:** synthetic scenario and sensitivity testing; assertions for
  missing HRV, hard workout, luteal context, pregnancy, illness, and no wear.
- **bias_risks:** fitness, medication, disability, autonomic differences, shift
  work, menstrual phase, pregnancy, illness, age, device fit, and unequal access
  to imported workouts.
- **version:** `0.1.0-research`.
- **change_history:** 2026-08-23 initial model; declared pregnancy changed to
  trend-only without a pregnancy-specific baseline after scenario review.
