# Movement model card

- **purpose:** Reward sustainable general movement, movement breaks, structured
  activity, and reasonable load balance.
- **intended_use:** Personal daily/weekly wellness reflection including manual or
  imported swimming and strength work.
- **not_intended_use:** Energy-expenditure measurement, performance ranking,
  medical exercise prescription, or universal step-goal enforcement.
- **inputs:** steps, personal step pattern, inactive-time estimate, seven-day
  structured minutes, load ratio, activity coverage, workout type/source,
  explicit illness/rest context.
- **input_provenance:** R12 firmware steps; app-derived inactivity/load;
  ring/manual/imported workout records with visible source.
- **data_requirements:** enough day coverage for a numeric result; explicit
  manual/imported records may fill activities R12 cannot identify.
- **calibration:** no energy or health-outcome calibration. WHO guidance is an
  educational population guardrail, not a personal score truth.
- **baseline_method:** rolling median daily steps and robust 28-day activity load;
  versions reset to Recalibrating after device/firmware change.
- **contributor_formulas:** step ratio rises to personal baseline then plateaus and
  tapers only at extreme ratio; inactivity neutral through 8h then declines;
  structured minutes approach a 150-min weekly guardrail; load uses distance from
  1.0. Exact curves are in the scoring specification.
- **weights:** general movement 40%, inactive time 25%, structured activity 20%,
  load balance 15%.
- **missing_data:** lower coverage reduces confidence. Logged illness+rest yields
  Rest protected/no score. Manual/imported swim prevents unavailable underwater
  steps being interpreted as inactivity.
- **confidence:** activity coverage, baseline maturity, and workout provenance;
  categories Low/Moderate/High.
- **output:** score/status or protected state, confidence, contributors, source-
  aware explanation, action, limitations, version.
- **labels:** Sustainable, Building, Light, Rest protected.
- **known_limitations:** R12 steps are unvalidated; no raw motion/posture; inactive
  time is an imperfect proxy; no automatic swim/lap/stroke/underwater pulse;
  structured minutes may be manually misreported.
- **validation:** synthetic illness, swim, strength, excessive load, inactivity,
  and sensitivity tests. No outcome validation.
- **bias_risks:** mobility impairment, manual labour, wheelchair use, caring work,
  pregnancy, chronic illness, sport type, ring hand, and access to integrations.
- **version:** `1.0.0`.
- **change_history:** 2026-08-23 initial model; manual/imported swim protection
  added after scenario review; 2026-08-24 approved unchanged for V1 implementation.
