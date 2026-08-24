# Model evaluation v0.1

Run: 2026-08-23, seed 1729, 33 scenarios, six fictional profiles, 2,970 days.
This is a synthetic face/safety evaluation, not scientific validation.

## Summary

| Dimension | Evidence | Verdict |
| --- | --- | --- |
| Construct validity | narrow questions and literature-informed contributors; no labelled outcomes | Not established |
| Face validity | required scenarios reviewed; explanations/actions inspected | Provisional pass |
| Test-retest stability | deterministic functions and fixed seed | Pass for software determinism only |
| Responsiveness | 300-min night changes Sleep 99.0→31.6 in baseline sensitivity | Pass for intended short-night response |
| Calibration | no R12 reference cohort or ground truth | Not run |
| Monotonicity | duration, pulse deviation, inactivity, and load test curves sampled | Pass within specified regions |
| Missing-data sensitivity | low sleep coverage gives no score; missing pulse/HRV lowers confidence | Pass |
| Outlier sensitivity | geometric bottleneck and clamps prevent compensation; extreme values can still produce large moves | Provisional; needs real distributions |
| Weight sensitivity | one-at-a-time input outputs generated; weights not yet grid-searched | Partial |
| Contributor dependence | correlated Sleep/Recovery paths documented; stages excluded | Partial; needs cohort analysis |
| Demographic fairness | no demographic attributes or outcome cohort | Not evaluated |
| Chronotype fairness | late personal midpoint profile avoids population-clock penalty | Synthetic pass only |
| Shift-work suitability | rotating-shift profile correctly exposes regularity uncertainty | Partial; score still risks schedule judgement |
| Cycle-phase fairness | luteal context avoids disease priming and temperature is excluded | Policy pass; no physiological validation |
| Pregnancy suitability | declared pregnancy returns trends/no number without relevant baseline | Safety pass; no clinical validation |
| Device/firmware drift | Recalibrating state reduces confidence and preserves prior baseline concept | Synthetic pass |
| User comprehension | copy and hierarchy reviewed internally; no participant study | Not evaluated with users |

## Volatility

Across valid consecutive synthetic scores, median absolute daily change was 1.5
Sleep points, 2.4 Recovery points, and 2.6 Movement points. The 90th percentiles
were 6.0, 6.8, and 6.9. Large maximum changes (49.4 Sleep, 70.6 Recovery, 42.4
Movement) occur around deliberately severe disruptions or changing availability;
the UI must explain these transitions and never interpolate across no-result days.

Stable good-sleep days remain high with small ordinary noise. One poor night
meaningfully lowers the daily Sleep result without mutating the personal baseline;
the longer-term trend is a separate robust window. Several poor nights remain
visible across consecutive daily results.

## Required assertions

All are automated and green:

- one poor night lowers Sleep meaningfully;
- one poor night does not rewrite the baseline;
- short nights reduce daily Sleep progressively;
- missing HRV reduces Recovery confidence rather than receiving a poor value;
- a hard workout may lower Recovery without an unhealthy label;
- an illness rest day receives no poor Movement score;
- luteal context avoids illness language;
- declared pregnancy avoids a pre-pregnancy numeric judgement;
- incomplete sleep fails closed;
- a manual swim receives structured-activity credit without underwater steps.

## Known failures and risks

The lower-mobility profile still encounters a fixed 150-minute structured-activity
guardrail and inactivity proxy that may be inequitable. It is retained to expose,
not resolve, this risk. Before beta, add ability/context-sensitive goal modes and
evaluate with disabled users and clinicians without encoding low expectations.

Recovery's symmetric pulse penalty is deliberately conservative but may punish
benign fitness-related decreases or medication effects. The inexpensive ring may
not support a valid resting-pulse reconstruction at all. R12 physical capture,
ECG/PPG comparison, repeatability, artefact analysis, and explicit no-score rates
are release blockers.

No score has demonstrated prediction of energy, soreness, performance, illness,
or any health outcome. Comparable output to a commercial wearable would not count
as validation.

## Reproducible artifacts

- `research/scoring/outputs/scenario_results.csv`
- `research/scoring/outputs/scenario_summaries.csv`
- `research/scoring/outputs/*_sensitivity.csv`
- `research/scoring/outputs/*_sensitivity.svg`
- `research/scoring/outputs/manifest.json`
- `research/scoring/synthetic_data/scenarios.jsonl`
