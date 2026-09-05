# HRV education in LibreRing

Reviewed 2026-09-05. General education, not an R12 validation claim.

## Product behaviour

The HRV detail page explains the abbreviation beside the number and offers a
“What is HRV?” guide. The guide is available offline, including when no ring
data exists and in Day, Week and Month views. English and European Portuguese
copy use the existing information sheet; larger text can scroll and reduced
motion disables the sheet animation.

The first paragraph of the guide identifies the displayed value as an unverified
R12 firmware index. Nothing changes the decoder, recorded values, chart
aggregations, scoring or exports. General HRV interpretations must not be
applied to this index. No normal ranges, milliseconds or recovery classifications
are added to the readings.

## Sources and boundaries

- [Cleveland Clinic: Heart Rate Variability](https://my.clevelandclinic.org/health/symptoms/21773-heart-rate-variability-hrv)
  supports the definition, distinction from pulse rate, nervous-system context
  and ECG measurement. Reviewed article dated 2021-09-01.
- [Harvard Health: What is heart rate variability?](https://www.health.harvard.edu/heart-health/what-is-heart-rate-variability)
  supports the link to autonomic regulation, changing demands, sleep and stress,
  and cautions about consumer measurement accuracy. Article dated 2021-02-01.
- [Oura Member Care: Heart Rate Variability](https://support.ouraring.com/hc/en-us/articles/360025441974-Heart-Rate-Variability)
  explains personal baselines, recovery context and measurement conditions.
  Its measurement and validation claims apply to Oura, not COLMI.
- [Oura: 8 Myths About HRV, Debunked](https://ouraring.com/blog/myths-about-hrv/)
  explains why higher is not always better and methods/conditions matter.
- [R12 protocol evidence](../protocol/colmi-r12-evidence.md) and
  [capability matrix](r12-scoring-capability-matrix.md) establish the local
  device boundary: the app receives an opaque index without verified units,
  beat-to-beat intervals or a known HRV formula.

Do not infer a diagnosis, emotional state or training recommendation from an
isolated reading. Any future validated HRV source requires explicit provenance,
the calculation method and units before using general baseline guidance.
