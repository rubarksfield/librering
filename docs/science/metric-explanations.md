# Metric explanations in the interface

Reviewed 2026-09-05. These are product explanations, not new algorithms or
validation of the COLMI R12.

## Stress index

The detail page places a plain-language summary beside the number and an
offline “What does this number mean?” guide before the chart. The summary
explains that this is neither a stress percentage nor a measure of feelings.
The guide answers the user's example of 49 without inventing a formula,
thresholds or a physiological interpretation.

- The formula executes in firmware; the received index does not provide its
  inputs, weighting, scale validation, or a reproducible algorithm.
- Day is the latest sample on the selected date, not a live reading.
- Week/Month headline is the median of captured samples in the period,
  rounded to an integer. The chart is one median per recorded day. These
  aggregations are not interchangeable when days have unequal sample counts.
- Missing samples are not zero stress. No data remains empty.
- Values do not drive health labels, recovery scores, or daily advice.

Evidence: [R12 capability matrix](r12-scoring-capability-matrix.md),
[physical protocol review](../protocol/colmi-r12-evidence.md), and current
`RingAnalytics.vendorPeriod`, `vendorHistory`, and `_median` implementation.
Byte decoding is not physiological validation.

## Energy / calorie figure

The Activity detail now calls the field “Ring energy value” rather than
“Active energy”, preserves the numeric totals and chart points unchanged,
and explicitly labels its units as unverified. The openable guide is next
to the summary, and is also available without activity records.

The protocol evidence says only that the R12 exposes an energy field;
the unit is likely kcal, not confirmed, and the firmware's demographic and
configuration assumptions are unknown. Nothing here rescales the number or
claims to repair its accuracy. It is not used for food allowances, targets,
personal exercise intensity, recovery scoring, or daily advice.

General definitions were checked against primary sources on 2026-09-05:

- [NHS: Understanding calories](https://www.nhs.uk/live-well/healthy-weight/managing-your-weight/understanding-calories/):
  food/drink energy and kcal terminology. No dietary targets were copied into
  the app.
- [Apple HealthKit: activeEnergyBurned](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/activeenergyburned):
  activity energy excludes resting energy.
- [Apple HealthKit: basalEnergyBurned](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/basalenergyburned):
  resting energy supports basic bodily functions.

These sources explain energy terminology; they do not validate R12 data or
imply Apple Health integration.

## HRV

The existing [HRV guide](hrv-education.md) is retained. The detail page now
also explains why people track reliable HRV trends, while explicitly saying
the ring's unverified index cannot support those conclusions. The same guide
can be reused through `showHrvEducation` without duplicating copy.

## Verification

- `metric_education_test.dart`: real screen entry/exit in English and
  Portuguese, no-data states in all date ranges, actual sample vs daily
  median distinction, unchanged energy points/totals, unit and label
  boundaries, 48-point accessible help actions, 320-point screens at 2x
  text, and reduced-motion sheets.
- Updated HRV/stress screen golden references and new stress, energy-guide,
  and activity-summary golden references are inspected after rendering.
- No protocol, storage, source data, aggregation, export, or BLE changes are
  part of these explanations.

Physical-device review is still separate from widget/golden verification.
