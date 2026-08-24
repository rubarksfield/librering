# COLMI QRing protocol implementation record

Status: Phase 6 foundation; no physical R12 validation.

Driver version: `colmi-qring-v1`

Reviewed: 2026-08-24

## Transport profile

| Role | UUID | Implementation confidence |
| --- | --- | --- |
| Command service | `6E40FFF0-B5A3-F393-E0A9-E50E24DCCA9E` | family-corroborated |
| Command write | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | family-corroborated |
| Command notify | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | family-corroborated |
| Big-data service | `DE5BF728-D711-4E47-AF26-65E3012A5DC7` | family-corroborated |
| Big-data notify | `DE5BF729-D711-4E47-AF26-65E3012A5DC7` | family-corroborated |
| Big-data write | `DE5BF72A-D711-4E47-AF26-65E3012A5DC7` | family-corroborated |

Advertisement matching is exact for `COLMI R12_*`. Discovery remains inclusive
when the command service is advertised, but an inclusive candidate never becomes
an R12 match without identity evidence. Service discovery requires the expected
write/notify properties and never falls back to the first available channel.

## Framing

The command channel accepts only 16-byte frames. Byte 15 must equal the low byte
of the sum of bytes 0–14. Invalid size, byte range, or checksum fails closed.
The committed `checksum-command-03-synthetic.hex` fixture proves framing only;
it is generated, is not an R12 capture, and does not prove a valid battery request.

Big-data fragments are assembled only after a decoder supplies an explicit
sequence and final flag. Assembly rejects gaps, ignores already-accepted
duplicates, stops after completion, and has a 64 KiB default bound. The byte
positions that encode sequence/finality remain firmware-capture work.

## Command ledger

No request below is emitted by current production code. A command becomes
enabled only after a consented physical fixture records request, response,
firmware, units, no-data sentinel, edge cases, and expected observable.

| Family | ID/type | Current request/response | Unit/meaning | Confidence | Tested R12/firmware | Fixture | Edge cases / provenance |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Battery | `0x03` | disabled; payload unknown | battery/charging candidate | family-corroborated | none | checksum-only synthetic | no-data and charging encoding unknown; ring-origin when verified |
| Pulse history | `0x15` | disabled; ranges/sequencing unknown | BPM-like byte | family-corroborated | none | pending | timestamps/sentinels unknown; ring-origin |
| Auto pulse | `0x16` | disabled | interval setting candidate | family-corroborated | none | pending | bounds/ack unknown; device-setting provenance |
| Activity | `0x43` | disabled | steps plus vendor estimates | family-corroborated | none | pending | distance/calorie semantics unvalidated; ring-origin |
| Live readings | `0x69` / `0x6A` | disabled | pulse/oxygen candidate | family-corroborated | none | pending | start/stop/status unknown; ring-origin |
| Big data | `0xBC` | disabled | history envelope | family-corroborated | none | pending | sequence/end/partial/reset unknown; ring-origin |
| Sleep big data | `0x27` | disabled | firmware sleep/session candidates | family-corroborated | none | pending | stages not EEG; completeness unknown; ring-origin |
| Oxygen big data | `0x2A` | disabled | firmware oxygen summaries | family-corroborated | none | pending | not medical oximetry; ring-origin |
| Firmware HRV index | `0x39` | disabled | opaque half-hour byte | semantic unknown | none | pending | never export/score as RMSSD or SDNN; ring-origin |

## Recovery and dual-protocol behavior

Connection timeout is 12 seconds at the driver boundary. Unsupported services
trigger disconnect and a typed error. Retry policy is bounded and injected;
there is no permanent reconnect loop. Notification subscriptions are cancelled
on disconnect, and raw packets are not retained by default.

SmartHealth/YCBT identification is not implemented. An ambiguous device must
remain a visible candidate and prompt a vendor-app choice in a later UI version.
The wrong choice must be recoverable and non-destructive. Repeated disconnects
should surface the approved “Close QRing and try again” guidance.
