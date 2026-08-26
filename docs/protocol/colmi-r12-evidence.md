# COLMI R12 protocol evidence

Status: read-only transport and history structure verified on an owned R12 running
`RT11CR_1.00.09_260424`; physiological accuracy remains unvalidated. Reviewed
2026-08-26.

## Confidence vocabulary

- **Confirmed for model identity:** an R12-specific source names the behaviour.
- **Corroborated family behaviour:** two or more Yawell-family implementations agree.
- **Physically verified:** a consented exchange from the owned R12 and named
  firmware passed framing, checksum/CRC, and bounded-parser checks.
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
| Command service | `6E40FFF0-B5A3-F393-E0A9-E50E24DCCA9E` | Physically verified on named R12 firmware |
| Write characteristic | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | Physically verified |
| Notify characteristic | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | Physically verified |
| Big-data service | `DE5BF728-D711-4E47-AF26-65E3012A5DC7` | Physically verified |
| Big-data notify/write | service-suffixed `...729` / `...72A` | Physically verified |

Do not fall back to the first writable or notifiable characteristic. Require the
expected service set and a positive identity/capability probe; otherwise fail
closed with an unsupported-firmware message.

## Observed command families

The inspected implementations agree materially on battery (`0x03`), pulse
history (`0x15`), auto-pulse configuration (`0x16`), activity/steps (`0x43`),
live measurements (`0x69`/`0x6A`), stress history (`0x37`), the firmware stream
called HRV (`0x39`), and big data (`0xBC`). Sleep history is big-data type
`0x27`; SpO₂ history is type `0x2A`. The named R12 firmware answered every one
of these bounded read-only requests. Time synchronisation was the only setting
write. No reset, goal, schedule, display, find-device, power, or other setting
write was issued.

## Owned-device capture result

The single approved suite captured eight requested activity days, eight pulse
days, seven stress days, seven firmware-HRV days, all returned sleep and oxygen
history, and both live channels. Every 16-byte history packet passed its family
checksum. Both big-data envelopes matched their declared lengths and MODBUS
CRC; the sleep payload contained four bounded day records and only the known
stage codes, while oxygen contained three complete 49-byte day records.

The live pulse and oxygen sessions returned 30 and 40 valid warm-up packets,
respectively, with the expected reading type, zero device error, and no nonzero
measurement. Their result is **no reading**, not timeout and not proof of a
valid live physiological value. Six configuration reads completed; the display
preference read timed out and remains unavailable on this firmware.

The raw capture was local-only and was not added to the repository. The
committed physical fixture contains structural counts and validation results
only; identifiers, physiological values, and timestamps are omitted. Decoder
tests use fully synthetic command and big-data packets.

## Semantic cautions

- Pulse history: paging, sampling interval, date echo, and zero/`0xFF` missing
  values are now structurally verified. BPM accuracy is not.
- “HRV”: a half-hour byte is labelled milliseconds by implementations without
  R–R intervals, calculation method, signal-quality field, or ECG reference.
  Treat as opaque firmware index; do not score or export as RMSSD/SDNN.
- Sleep: session start/end and firmware stage-duration pairs are structurally
  verified. They are not EEG and their wake/light/deep/REM accuracy is
  unvalidated.
- SpO₂: hourly min/max firmware summaries are structurally verified in big data.
  Do not present them as medical oximetry or use them in a recovery score
  without validation.
- Stress: a 1–99 firmware value appears at half-hour intervals. It is an opaque
  vendor index, not emotional state or clinical stress.
- Temperature: current R12 coordinator does not support it. R09 temperature
  support must not be generalized to R12.
- Activity: steps and vendor distance/calories exist; calories and distance are
  firmware estimates. Raw accelerometer samples are not exposed by known paths.
- Swimming: 1ATM is not evidence of swimming-session detection, underwater BLE,
  stroke count, lap count, or heart-rate accuracy. Use manual/imported logging.

## Remaining acceptance work

The read-only protocol gate is complete for the captured firmware. Production
acceptance still needs duplicate-sync/idempotency, timezone and daylight-saving
changes, app contention, low-battery behavior, and a future-firmware regression
device. No factory reset is required for the read-only gate. Physiological
validation requires external reference devices or studies and cannot be inferred
from packet correctness.

## Sources

- [COLMI R12 product page](https://www.colmi.com/colmi-r12-smart-ring/)
- [COLMI 2025 catalogue](https://file.globalso.com/file_manage/1417/20251030/colmi-catalog-2025.pdf)
- [Gadgetbridge R12 coordinator](https://codeberg.org/Freeyourgadget/Gadgetbridge/src/commit/9d872b136fb8670856dba0f78c9486a25c39b5e6/app/src/main/java/nodomain/freeyourgadget/gadgetbridge/devices/yawell/ring/ColmiR12Coordinator.java)
- [Gadgetbridge Yawell ring support](https://codeberg.org/Freeyourgadget/Gadgetbridge/src/commit/9d872b136fb8670856dba0f78c9486a25c39b5e6/app/src/main/java/nodomain/freeyourgadget/gadgetbridge/service/devices/yawell/ring/YawellRingDeviceSupport.java)
- [Gadgetbridge packet handler](https://codeberg.org/Freeyourgadget/Gadgetbridge/src/commit/9d872b136fb8670856dba0f78c9486a25c39b5e6/app/src/main/java/nodomain/freeyourgadget/gadgetbridge/devices/yawell/ring/YawellRingPacketHandler.java)
- [openring protocol notes](https://github.com/robinojw/openring/tree/c406e2bb6e5a9c429c73b7593d8baaa92579f0b1)
- [COLMI client](https://github.com/tahnok/colmi_r02_client/tree/19e70aa502749b87d57e3dba0156dfd67ddc0d4a)
