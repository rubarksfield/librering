# Oura source conflicts

Reviewed: 2026-08-23. The ledger preserves exact claims; this note explains why
they cannot be collapsed into one “Oura formula.”

## Current product vs historical patents

The current Readiness page documents nine contributor names and several windows,
but not weights or full normalisation. `US20180042540A1` is a historical patent
example with a 2015 priority date. It is evidence that readiness-style systems
were contemplated, not evidence of today's implementation. LibreRing does not
translate its equations or thresholds.

The same rule applies to menstrual-cycle and pregnancy patents. Current Cycle
Insights and the regulated Fertile Window 2.1 manual govern what the product says
now. A pending patent can broaden possible techniques but cannot establish
performance, intended use, or current UI behaviour.

## One baseline vs metric-specific baselines

Current general app guidance says broad baselines usually take two to four weeks.
The Readiness contributor page says averages can take up to two weeks to learn,
defines “long-term” generally as two months, and separately describes HRV Balance
as a 14-day comparison to three months. Pregnancy documentation cites 7–14 days
for an initial trend and 60–90 days for a shifted temperature baseline to settle.
These are not necessarily contradictions: they are metric- and context-specific.
LibreRing must show per-metric maturity, not a single learned/not-learned switch.

## Aggregate staging agreement vs individual accuracy

Oura currently reports 79% four-stage agreement with PSG. Peer-reviewed evidence
also shows generation-, population-, and stage-specific errors: the adolescent
study found systematic duration/stage bias, while multi-device healthy-adult work
reported good sleep/wake agreement but only moderate kappa. A 2025 meta-analysis
concludes duration is generally stronger than stage classification. Therefore:

- stage labels remain estimates, not EEG;
- agreement is not clinical diagnostic performance;
- study generation and population must travel with every claim;
- no Oura validation transfers to R12 firmware stages.

## Fertile-window presentation

The regulated manual is the controlling source: version 2.1+ is an aid to
conception, not contraception; it identifies contraindicated contexts and bounded
performance. Consumer help copy may simplify these warnings. LibreRing's concept
does not implement a fertile window on R12 because temperature is unavailable and
no validation dataset exists.

## Activity guidance vs personal scoring

Oura publishes concrete inactivity and training examples. WHO guidance supplies
population-level weekly guardrails. Neither justifies a universal daily target or
penalising illness, disability, pregnancy, a recovery day, or a swim whose motion
the ring misses. LibreRing uses personal pattern plus guardrails and keeps rest
protection explicit.

## Unresolved

- Current Oura contributor weights and complete curves are proprietary.
- Exact current stage-validation population and conflicts need the full paper,
  not only product help copy.
- Current treatment of simultaneous positive/negative Readiness contributors is
  not documented enough to reconstruct.
- It is unclear how much current pregnancy context changes scores versus only
  changing educational/trend presentation.

These gaps are reasons to derive an original model, not invitations to guess.
