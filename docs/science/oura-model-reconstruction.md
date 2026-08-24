# Oura model reconstruction — conceptual only

Reviewed: 2026-08-23. “Reconstruction” here means a source-backed map of the
questions, signals, and time windows. It is not a copied or reverse-engineered
formula and cannot reproduce Oura numbers.

## Currently documented product behaviour

### Sleep

The current product exposes seven contributors: total sleep, efficiency,
restfulness, REM, deep, latency, and timing. Sleep inference uses motion and
physiological signals; Sleep evaluation judges sufficiency and quality after the
interval has been inferred. Product documentation allows some partial-night
outputs and acknowledges stillness/wake and movement/sleep confusion.

### Readiness

Nine documented contributors span last night, recent balance, and longer-term
normal: resting heart rate, HRV balance, body temperature, recovery index, Sleep,
Sleep Balance, Sleep Regularity, Previous Day Activity, and Activity Balance.
Documented windows differ by contributor: HRV compares roughly 14 days against
three months, while activity balance weighs roughly 14 days against two months.

### Activity

The six current contributors cover inactivity, hourly movement, target adherence,
training frequency, training volume, and easy/recovery days. The important design
lesson is that “more” is not always better: over-load and missing easy days can
reduce the result.

### Reproductive features

Cycle Insights combines explicit period logging with physiology. Hormonal
contraception changes available outputs. Fertile Window is a separately regulated
aid-to-conception feature with explicit warnings, contraindications, and bounded
performance. Pregnancy Insights is explicitly enabled and emphasises trends and
context. These are different products, not one “reproductive score.”

## Historical patent examples

Patents cover readiness, temperature-series cycle morphology, pregnancy
detection, and other wearable processing. They show possible mechanisms and
create a legal-review surface. They do not disclose current production truth,
confer permission, or supply clinical validation. LibreRing uses none of their
equations and deliberately rejects automatic pregnancy inference.

## Peer-reviewed evidence

- PSG remains the reference for sleep staging. Ring performance is useful but
  imperfect, with accuracy varying by stage, generation, cohort, and night.
- Duration/interval estimates are generally more defensible than stage minutes.
- Sleep duration, regularity, continuity, and timing are separable constructs.
- PPG pulse-rate variability is not automatically ECG HRV. The R12 provides no
  beat intervals or validated RMSSD method, so its “HRV” byte is unusable.
- Recovery has no single ground truth; triangulation with subjective energy,
  soreness, illness tags, performance, and stable physiological deviations is
  needed.

## Independent design implication

LibreRing keeps the good conceptual separation—last night, personal balance,
load, and explicit context—while changing all names, curves, weights, confidence,
and missing-data rules. It gives duration/continuity more authority than firmware
stages; makes R12 Recovery provisional; and uses no all-domain health score.

The claim-level record is in
[`oura-evidence-ledger.csv`](oura-evidence-ledger.csv) and unresolved differences
are in [`oura-source-conflicts.md`](oura-source-conflicts.md).
