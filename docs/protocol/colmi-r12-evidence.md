# COLMI R12 protocol evidence

Status: research evidence only; no physical R12 was available. Reviewed 2026-08-23.

## Confidence vocabulary

- **Confirmed for model identity:** an R12-specific source names the behaviour.
- **Corroborated family behaviour:** two or more Yawell-family implementations agree.
- **Unverified on owned hardware:** no recorded R12/firmware exchange exists here.
- **Semantic unknown:** bytes parse consistently but their physiological meaning
  or unit has no reference-standard validation.

## Model evidence

COLMI's current product page names RTL8762 ESF, Bluetooth 5.2, QRing, IP68 and
1ATM, and 15 mAh (sizes 7–9) or 18 mAh (sizes 10–13). Its catalogue lists sport,
heart rate, blood oxygen, sleep, pedometer, and camera functions. These are
vendor claims, not measurement validation.

Current Gadgetbridge has an R12-specific coordinator that matches
`^COLMI R12_.*`, uses no BLE bond, declares a display, and routes to its common
Yawell ring protocol. This supersedes the older GitHub mirror and is stronger
model evidence than R02/R06 compatibility claims.

## Transport and packet evidence

Family implementations agree on a fixed 16-byte command/notification channel,
with a checksum equal to the low byte of the sum of bytes 0–14. Big-data history
uses a second service and variable-length packets. The common identifiers are:

| Role | UUID / evidence | State |
| --- | --- | --- |
| Command service | `6E40FFF0-B5A3-F393-E0A9-E50E24DCCA9E` | Family-corroborated; R12 physical test pending |
| Write characteristic | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | Family-corroborated |
| Notify characteristic | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | Family-corroborated |
| Big-data service | `DE5BF728-D711-4E47-AF26-65E3012A5DC7` | Multiple implementations; R12 test pending |
| Big-data notify/write | service-suffixed `...729` / `...72A` | Multiple implementations; test pending |

Do not fall back to the first writable or notifiable characteristic. Require the
expected service set and a positive identity/capability probe; otherwise fail
closed with an unsupported-firmware message.

## Observed command families

The inspected implementations agree materially on battery (`0x03`), pulse
history (`0x15`), auto-pulse configuration (`0x16`), activity/steps (`0x43`),
live measurements (`0x69`/`0x6A`), and big data (`0xBC`). Sleep history is big
data type `0x27`; SpO₂ history is type `0x2A`; the history stream called HRV is
associated with `0x39`. Exact request payloads, ranges, sequencing, retry rules,
and end sentinels must be captured per R12 firmware before production.

## Semantic cautions

- Pulse history: a BPM-like byte is plausible and cross-implementation stable,
  but sample timestamps and missing sentinels still need device capture.
- “HRV”: a half-hour byte is labelled milliseconds by implementations without
  R–R intervals, calculation method, signal-quality field, or ECG reference.
  Treat as opaque firmware index; do not score or export as RMSSD/SDNN.
- Sleep: session start/end and firmware stage-duration pairs exist. They are not
  EEG and their wake/light/deep/REM semantics and accuracy are unvalidated.
- SpO₂: min/max hourly firmware summaries appear in big data. Do not present as
  medical oximetry or use in a recovery score without validation.
- Stress: a 1–99 firmware value appears at half-hour intervals. It is an opaque
  vendor index, not emotional state or clinical stress.
- Temperature: current R12 coordinator does not support it. R09 temperature
  support must not be generalized to R12.
- Activity: steps and vendor distance/calories exist; calories and distance are
  firmware estimates. Raw accelerometer samples are not exposed by known paths.
- Swimming: 1ATM is not evidence of swimming-session detection, underwater BLE,
  stroke count, lap count, or heart-rate accuracy. Use manual/imported logging.

## Required physical acceptance capture

Record ring hardware/size, advertised name, firmware, phone/OS, service list,
MTU, timezone, packet hex, checksum, retries, missing-data response, and expected
observable for: first pair, battery, clock set, seven days of steps, pulse
history, live pulse/SpO₂, full/partial/no-wear sleep, duplicate sync, timezone
change, firmware change, app contention, low battery, and factory reset.

## Sources

- [COLMI R12 product page](https://www.colmi.com/colmi-r12-smart-ring/)
- [COLMI 2025 catalogue](https://file.globalso.com/file_manage/1417/20251030/colmi-catalog-2025.pdf)
- [Gadgetbridge R12 coordinator](https://codeberg.org/Freeyourgadget/Gadgetbridge/src/commit/9d872b136fb8670856dba0f78c9486a25c39b5e6/app/src/main/java/nodomain/freeyourgadget/gadgetbridge/devices/yawell/ring/ColmiR12Coordinator.java)
- [Gadgetbridge Yawell ring support](https://codeberg.org/Freeyourgadget/Gadgetbridge/src/commit/9d872b136fb8670856dba0f78c9486a25c39b5e6/app/src/main/java/nodomain/freeyourgadget/gadgetbridge/service/devices/yawell/ring/YawellRingDeviceSupport.java)
- [Gadgetbridge packet handler](https://codeberg.org/Freeyourgadget/Gadgetbridge/src/commit/9d872b136fb8670856dba0f78c9486a25c39b5e6/app/src/main/java/nodomain/freeyourgadget/gadgetbridge/devices/yawell/ring/YawellRingPacketHandler.java)
- [openring protocol notes](https://github.com/robinojw/openring/tree/c406e2bb6e5a9c429c73b7593d8baaa92579f0b1)
- [COLMI client](https://github.com/tahnok/colmi_r02_client/tree/19e70aa502749b87d57e3dba0156dfd67ddc0d4a)
