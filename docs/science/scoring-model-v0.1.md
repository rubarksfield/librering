# LibreRing scoring model v0.1

Status: provisional research model for user review; not production or clinically
validated. Calculation version: `0.1.0-research`.

## Shared formula

For present contributors (c_i\) in 0–100 with weights (w_i\):

```text
score = 100 × exp( Σ(w_i × ln(max(1, c_i) / 100)) / Σw_i )
```

This weighted geometric form is bottleneck-aware. Critical missing data returns
no result. Optional data is omitted without a negative value and reduces
confidence. Values are rounded only for display.

## Contributor specification

| Model / contributor | Input and unit | Target / personal baseline / guardrail | Curve and weight | Confidence and missing behaviour | Meaning / evidence / R12 |
| --- | --- | --- | --- | --- | --- |
| Sleep duration | inferred total sleep, min | 420–540 min; personal history contextualises | below 420: `100−0.70×deficit`; 420–540: 100; above 540: `100−0.22×excess`; 45% | no interval or <60% coverage: no Sleep result | sufficiency; strong population guidance, medium R12 interval certainty |
| Sleep continuity | total/time-in-bed and awake-after-onset | efficiency ≥90%; interruption allowance 20 min | 65% efficiency curve + 35% interruption curve; model weight 30% | missing interval: no result | continuity, not stage quality; medium evidence/R12 certainty |
| Personal timing | sleep midpoint, hours | own robust midpoint | `100−22×circular-hour-distance`; 15% | immature baseline lowers confidence | alignment with personal pattern; moderate evidence, timestamps unverified |
| Regularity | midpoint variability, min | own pattern; 20-min neutral zone | `100−0.85×max(0, variability−20)`; 10% | fewer valid nights lowers confidence | schedule stability; moderate/high evidence |
| Recovery sleep support | Sleep v0.1 | current result | direct contributor; 40% | missing allowed only if adequate pulse remains; confidence falls | last-night support, avoids reusing stages |
| Overnight pulse deviation | robust nightly pulse vs personal median, bpm | personal normal; symmetric research curve | `100−9×absolute bpm deviation`; 30% | absent: omitted and confidence −0.18 | physiological change, not diagnosis; R12 provisional |
| Recent load balance | 7-day load / 28-day personal load | 1.0 | `100−72×abs(ratio−1)`; 20% | history missing makes Recovery provisional | under/over-load context; imported/manual sources labelled |
| Optional check-in | energy 1–5 | user response | linear 1→0, 5→100; 10% | absent: omitted; does not override sensors | subjective context, not ground truth |
| Validated HRV (optional) | z deviation of known RMSSD/SDNN | metric-specific personal baseline | `100−25×abs(z)`; 15% when present | absent lowers confidence only | not available from R12 firmware byte; external validated source only |
| General movement | steps / personal median | sustainable 1.0–1.8×; no 10k rule | up to baseline 25→100; plateau; extreme-load taper; 40% | poor coverage lowers confidence | firmware estimate; swim/manual exception |
| Inactive time | hours/day | ≤8 hours is neutral research region | 100 then −15/hour; 25% | not direct on R12; provisional | breaks/sedentary proxy, not posture |
| Structured activity | 7-day min manual/imported/ring | personal plan with WHO 150 min education | `35 + 65×min(minutes/150,1)`; 20% | source always shown | includes strength/swimming; not step-derived |
| Movement load balance | recent/personal load | 1.0 | `100−70×abs(ratio−1)`; 15% | insufficient history lowers confidence | prevents maximum-is-best behaviour |

Firmware sleep stages, firmware “HRV”, stress, calories, distance, SpO₂,
temperature, respiratory rate, and swimming inference have zero weight.

## Confidence

Confidence is a 0–1 weighted completeness/quality value displayed as Low (<0.60),
Moderate (0.60–0.79), or High (≥0.80). Sleep uses coverage, timestamp reliability,
baseline maturity, and semantic certainty. Recovery adds availability of pulse and
validated HRV; its R12 profile is normally Moderate at best. Movement uses activity
coverage, baseline maturity, and workout provenance. Confidence never changes a
score into a better or worse physiological value.

## Missing and protected states

| Condition | Behaviour |
| --- | --- |
| Unreliable/under-60% sleep interval | no Sleep result |
| Missing R12 “HRV” | no score penalty; disclose exclusion |
| Sleep plus pulse both missing | no Recovery result |
| Declared pregnancy without pregnancy baseline | trend only; no Recovery number |
| Logged illness and rest day | `Rest protected`; no Movement number |
| Manual/imported swim | counts structured activity; underwater step absence is not inactivity |
| Firmware/device change | baseline `Recalibrating`; confidence reduced; prior baseline retained |
| Display interpolation | labelled display-only and never enters score |

## Labels

Sleep: Supportive / Steady / Limited / Disrupted. Recovery: Normal range / Some
recovery may help / More recovery may help / Trend only / No result. Movement:
Sustainable / Building / Light / Rest protected. These are wellness descriptions,
not medical categories.

## Evaluation snapshot

The deterministic run contains 33 scenarios × 90 fictional days. All 13 unit and
behaviour tests pass. Baseline sensitivity shows a 300-minute night lowers Sleep
from 99.0 to 31.6; removing reliable coverage yields no score. Missing pulse raises
neither alarm nor penalty and drops Recovery confidence from 0.748 to 0.568.
Extreme inactivity and load are visible; manual swimming retains structured
activity credit. Median daily changes in stable scenarios are small, while a
single short night is deliberately responsive.

This establishes face behaviour, monotonicity for core curves, missing-data
safety, and deterministic reproduction—not construct validity, calibration, or
demographic fairness. No physical R12 or outcome-labelled cohort was available.

Run:

```bash
python3 research/scoring/run_research.py
python3 -m unittest discover research/scoring/tests -v
```

See [`research/scoring/outputs/manifest.json`](../../research/scoring/outputs/manifest.json)
and the model cards for intended use, bias, and validation limits.
