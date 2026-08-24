# Independent derivation record

Version: 0.1, 2026-08-23.

## Starting question

The models answer three narrow questions:

1. Sleep — was this sleep sufficient, continuous, and appropriately timed for
   this person?
2. Recovery — do available overnight/recent signals look normal for this person,
   or might more recovery be useful?
3. Movement — was movement sustainable and reasonably balanced, including
   legitimate rest and activities the ring cannot see?

There is no fourth “health” total.

## Combination method

Arithmetic, geometric, harmonic, rule-based, and probabilistic approaches were
considered. V0.1 uses a weighted geometric mean for present contributors because
it is explainable and prevents one high contributor from fully hiding a weak
critical contributor. Values are clamped to 1 before `log`, preserving a finite
0–100 output. Missing critical inputs fail closed; optional inputs are omitted and
reduce confidence. This avoids treating absence as poor physiology.

A pure minimum was rejected as too volatile. Arithmetic averaging was rejected
as too compensatory. A Bayesian status model was deferred because R12 reference
data and outcome calibration do not exist. Rule-only output remains the preferred
fallback for protected rest, pregnancy without a relevant baseline, and no wear.

## Baselines

Rolling median is the centre for pulse, sleep duration/midpoint, and steps.
Median absolute deviation describes spread. Winsorised mean is available for
stable load summaries. The chosen maturity states are No baseline (0–2 valid
days), Learning (3–13), Provisional (14–27), Established (28+), and Recalibrating
after firmware/device changes. Production must version and preserve each baseline.

Chronotype/shift-work suitability is handled by comparing timing to personal
midpoint first; population timing remains education, not a blunt penalty. Phase-
conditioned baselines require enough complete cycles and are not in R12 v0.1.

## Model decisions

### Sleep

Duration (45%) and continuity (30%) dominate because the R12's sleep stages have
no validation. Personal timing (15%) and regularity (10%) add circadian/behavioural
context. Stages are descriptive with zero weight. A reliable interval and at
least 60% coverage are critical.

### Recovery

Sleep support (40%), robust overnight pulse deviation (30%), recent load balance
(20%), and optional check-in (10%) form the R12 profile. A validated external HRV
series may enter at 15%; absence is not a negative contributor. The R12 firmware
HRV/stress bytes, SpO₂, temperature, and respiratory rate are excluded. Pregnancy
without a pregnancy-specific baseline produces trends, not a number.

### Movement

General movement (40%), inactive time (25%), structured activity (20%), and load
balance (15%) reward consistency without maximalism. Calories are excluded.
Manual/imported swims protect against underwater step absence. Logged illness
plus rest yields `Rest protected`, not a poor score.

### Cycle Context

R12 Cycle Context is strictly opt-in calendar and symptom context. It does not
infer phase, ovulation, fertility, pregnancy, perimenopause, or menopause from
R12 physiology. Fertile-window work is a separately gated research concept.

## Safety and comprehension

- Score and confidence are separate.
- Labels avoid diagnosis and never claim how the user feels.
- A disagreement between sensors and check-in is shown, not silently reconciled.
- Low confidence is never represented as a low score.
- Every result carries calculation version, missing contributors, and limitations.
- Normal UI uses High/Moderate/Low confidence; technical detail exposes 0–1.

## Simulation influence

The 33-scenario, 2,970-day run caused two concrete changes: luteal copy stopped
mentioning disease even in a negation, and manual/imported swimming now floors
general-movement evidence rather than treating unavailable underwater steps as
inactivity. Declared pregnancy was changed from a number-plus-warning to a
trend-only result without a pregnancy-specific baseline.

## Patent review flag

Oura patent families concerning readiness, cycle morphology, pregnancy, and HRV
variability were reviewed only as historical/legal landscape. The v0.1 curves,
weights, names, and rules were independently authored. Counsel should review
claims before production, especially if future validated temperature or HRV
features expand the model.
