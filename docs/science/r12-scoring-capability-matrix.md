# R12 scoring capability matrix

Reviewed: 2026-08-26. Hardware status: read-only protocol structure was captured
from one owned R12 running `RT11CR_1.00.09_260424`. `Available` means the named
firmware exposed the field; it does not mean physiological accuracy is
validated.

| Metric | Available on R12 | Protocol command | Sampling frequency | History | Raw or processed | Unit | Semantic definition | Known range / missing | Firmware dependency | Independent validation | Confidence / scoring decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Battery | Yes | `0x03` | on request | no | firmware status | % | reported charge | physical response in 0–100 range | high | none needed for physiology | Medium; display only |
| Live pulse | Transport only | `0x69`/`0x6A` family | live session | no | firmware processed PPG | bpm-like byte | instantaneous pulse estimate | physical run returned warm-up zeros only | high | no R12 study | Low; no live value accepted yet |
| Pulse history | Yes | `0x15` | firmware-reported interval | yes | firmware processed PPG | bpm-like byte | interval pulse estimate | zero/`0xFF` structurally verified as missing | high | no R12 study | Medium; protocol input available, scoring still provisional |
| Overnight resting pulse | Derived | pulse history | derived nightly | derived | app-derived | bpm | robust low/resting region during reliable sleep | no score if inadequate coverage | high | no R12 study | Low–Medium; provisional Recovery input |
| Time of nightly pulse minimum | Possibly derived | pulse history | interval resolution | derived | app-derived | local time | time of lowest accepted nightly pulse bin | ties/gaps/timezone unresolved | high | none | Low; exclude v0.1 |
| “HRV” firmware value | Byte stream verified | `0x39` | firmware-reported interval | yes | opaque firmware estimate | unknown | unknown; no R–R series or method | zero/`0xFF` missing; 1-byte ceiling | high | none | Very low; exclude from score/export as HRV |
| R–R intervals | No evidence | unknown | unknown | unknown | unsupported | ms | beat-to-beat intervals | unavailable | unknown | none | Unsupported |
| SpO₂ live | Transport only | live command family | on demand/session | limited | firmware processed PPG | %-like | oxygen-saturation estimate | physical run returned warm-up zeros only | high | no R12 oximetry study | Very low; no live value accepted yet |
| SpO₂ history | Yes | `0xBC`, type `0x2A` | hourly min/max summary | yes | firmware summary | %-like | supplied hourly min/max pair | 49-byte days, zeros, range and CRC verified | high | none | Low; exclude from v0.1 scores |
| Sleep interval | Yes | `0xBC`, type `0x27` | per session | multi-day | firmware inferred | local timestamps | firmware start/end session | four bounded physical records decoded; timezone changes untested | high | no R12 PSG study | Low–Medium; protocol input available, scientific gate remains |
| Sleep stages | Yes | `0xBC`, type `0x27` | duration runs | multi-day | firmware inferred | stage + minutes | awake/light/deep/REM-like categories | only known codes in physical capture; overruns fail closed | high | no R12 PSG study | Very low; descriptive only, zero score weight |
| Naps | Unknown | sleep history | unknown | unknown | firmware inferred | session | secondary sleep period | unknown cutoff/merge behaviour | high | none | Unknown; exclude |
| Steps | Yes | `0x43` | 15-minute history bins | yes | firmware motion estimate | steps | proprietary step count | date, quarter-hour slot, paging and no-data structurally verified | high | no R12 study | Medium; Movement input with source label |
| Inactive time/breaks | Not directly | activity bins, if recoverable | unknown | limited | app-derived | minutes/count | gaps in movement, not necessarily sitting | raw motion unavailable | high | none | Low; optional/provisional |
| Distance | Yes | activity history | daily/bin | yes | firmware estimate | likely metres | proprietary step-to-distance estimate | semantics need capture | high | none | Low; display only |
| Calories | Yes | activity history | daily/bin | yes | firmware estimate | likely kcal | proprietary expenditure estimate | demographic/config assumptions unknown | high | none | Very low; exclude |
| Raw accelerometer | No known path | unknown | unknown | no | unsupported | unknown | raw axes | unavailable | unknown | none | Unsupported |
| Workout record | No reliable evidence | unknown | unknown | unknown | unsupported | event | structured activity | no stable record format found | unknown | none | Unsupported; manual/imported only |
| Swimming session | No | none | none | no | unsupported | event | swim type/duration/laps | not distinguishable | n/a | none | Unsupported; manual/imported only |
| Underwater HR/laps/strokes | No | none | none | no | unsupported | various | swim physiology/performance | 1ATM does not establish capability | n/a | none | Unsupported |
| Skin temperature | No R12 support | temperature exists on R09 path | n/a | no | unsupported on R12 | °C | finger skin temperature | R09 must not be generalized | model-specific | none | Unsupported on R12 |
| Respiratory rate | No evidence | none | none | no | unsupported | breaths/min | breathing frequency | unavailable | n/a | none | Unsupported |
| Stress index | Byte stream verified | `0x37` | firmware-reported interval | yes | opaque firmware estimate | unknown byte | proprietary index, not emotion | zero/`0xFF` missing; thresholds vendor-specific | high | none | Very low; display only as vendor estimate, not v0.1 |
| Wear detection | Indirect/uncertain | sleep/activity gaps | unknown | limited | firmware/app inferred | state | ring contact/wear continuity | no quality channel verified | high | none | Low; contributes only to confidence after QA |
| Device display | Yes | display preferences | on setting | n/a | device feature | n/a | ring display configuration | R12 coordinator-specific | high | n/a | High; device settings only |

## Gate decisions

- Sleep v0.1 now has a physically verified packet-decoding path, but timezone,
  no-wear, completeness, and scientific acceptance must pass before a real score.
- Recovery v0.1 is provisional with reconstructed pulse and Sleep. The firmware
  “HRV”, stress, SpO₂, and unsupported temperature are excluded.
- Movement v0.1 uses steps plus manual/imported structured activity. It does not
  use calories, distance, or infer swimming.
- Cycle Context on R12 is calendar/symptom logging only. There is no basis for a
  physiology-derived fertile window, ovulation, or pregnancy inference.

Protocol details and sources are in
[`docs/protocol/colmi-r12-evidence.md`](../protocol/colmi-r12-evidence.md).
