# Cycle Context model card

- **purpose:** Provide private, optional context for cycle, symptoms, pregnancy,
  postpartum, perimenopause, and menopause without creating a health score.
- **intended_use:** Local calendar/symptom journalling and contextual trend
  explanations chosen explicitly by the user.
- **not_intended_use:** Contraception, fertility status, ovulation confirmation,
  pregnancy detection, diagnosis, or automatic inference from sex/age.
- **inputs:** user-entered bleeding/symptoms/intentions; optional imported,
  validated evidence in future separately reviewed modules.
- **input_provenance:** user-entered in R12 V1. R12 physiology is not used.
- **data_requirements:** none to use LibreRing; feature is off by default. Calendar
  estimates require user logs and are labelled calendar estimates.
- **calibration:** none. No physiology-derived prediction ships in V1.
- **baseline_method:** none for R12 V1. Future phase-conditioned baselines need
  complete cycles, validation, and preserved versions.
- **contributor_formulas:** no composite formula and no Reproductive Health score.
- **weights:** not applicable.
- **missing_data:** phase remains Unknown. Never fill missing period, temperature,
  pregnancy, or symptom data by inference.
- **confidence:** explicit labels: user logged, calendar estimate, physiology-
  supported (future only), retrospectively detected (future only), or unknown.
- **output:** logs, calendar context, trends, provenance, separate deletion, and
  educational limitations. Pregnancy is user-declared and Recovery is trend-only
  without an appropriate baseline.
- **labels:** Logged, Calendar estimate, Unknown, Research concept only / Not
  validated / Not contraception for any future fertile-window mockup.
- **known_limitations:** R12 has no temperature/respiration and no validated HRV;
  irregular cycles, hormones, shift work, illness, pregnancy, postpartum, and
  perimenopause confound calendar assumptions.
- **validation:** policy assertions for luteal copy and declared pregnancy; no
  fertility or clinical validation.
- **bias_risks:** gendered language, fertility assumptions, pregnancy loss,
  irregular cycles, hormones, cultural privacy needs, coercive access, and
  regional medical-device rules.
- **version:** `1.0.0`.
- **change_history:** 2026-08-23 initial no-score, local-only architecture;
  2026-08-24 approved unchanged for V1 implementation.
