# COLMI QRing protocol implementation record

Status: Phase 6 read-only capture and decoder gate physically verified on one
owned R12 firmware; production sync/storage remains fail-closed.

Driver version: `colmi-qring-v1`

Reviewed: 2026-08-26

## Transport profile

| Role | UUID | Implementation confidence |
| --- | --- | --- |
| Command service | `6E40FFF0-B5A3-F393-E0A9-E50E24DCCA9E` | physically verified |
| Command write | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | physically verified |
| Command notify | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | physically verified |
| Big-data service | `DE5BF728-D711-4E47-AF26-65E3012A5DC7` | physically verified |
| Big-data notify | `DE5BF729-D711-4E47-AF26-65E3012A5DC7` | physically verified |
| Big-data write | `DE5BF72A-D711-4E47-AF26-65E3012A5DC7` | physically verified |

Advertisement matching is exact for `COLMI R12_*`. Discovery remains inclusive
when the command service is advertised, but an inclusive candidate never becomes
an R12 match without identity evidence. Service discovery requires the expected
write/notify properties and never falls back to the first available channel.

## Framing

The command channel accepts only 16-byte frames. Byte 15 must equal the low byte
of the sum of bytes 0–14. Invalid size, byte range, or checksum fails closed.
The checksum fixture proves framing. A separate anonymised owned-device fixture
now proves the battery request/response on `RT11CR_1.00.09_260424` without a
device identifier.

Capture-side big data is bounded to 64 KiB and completed from the envelope's
declared little-endian payload length. Sleep and oxygen decoding then requires
an exact envelope length and a matching MODBUS CRC. Sleep records are bounded by
their declared record lengths; oxygen payloads must be complete 49-byte days.

## Command ledger

The requests below are enabled only in the explicit, consented capture path.
Normal production sync and live-measurement APIs remain fail-closed until the
decoded records have storage, provenance, deduplication, and UI integration.

| Family | ID/type | Current request/response | Unit/meaning | Confidence | Tested R12/firmware | Fixture | Edge cases / provenance |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Battery | `0x03` | capture enabled; decoded | battery percent/charging flag | physically verified | `RT11CR_1.00.09_260424` | anonymised physical | accuracy not independently calibrated |
| Pulse history | `0x15` | capture enabled; deterministic decoder | BPM-like byte on ring interval grid | physically verified structure | same | synthetic decoder + structural physical | zero/`0xFF` missing; physiological accuracy unknown |
| Auto pulse | `0x16` | read only in capture | enable flag and interval | physically verified read | same | structural physical | no setting write performed |
| Activity | `0x43` | capture enabled; deterministic decoder | 15-minute steps plus vendor estimates | physically verified structure | same | synthetic decoder + structural physical | distance/calorie accuracy unvalidated |
| Stress index | `0x37` | capture enabled; deterministic decoder | opaque vendor byte | physically verified structure; semantic unknown | same | synthetic decoder + structural physical | never treat as emotion or clinical stress |
| Live readings | `0x69` / `0x6A` | capture enabled and bounded | pulse/oxygen session | transport verified; no nonzero live reading | same | structural physical | valid warm-up packets classified `noReading` |
| Big data | `0xBC` | capture enabled; CRC/length validated | history envelope | physically verified | same | synthetic decoder + structural physical | 64 KiB bound; no partial record guessing |
| Sleep big data | `0x27` | capture enabled; deterministic decoder | firmware session/stage runs | physically verified structure | same | synthetic decoder + structural physical | stages not EEG; accuracy unknown |
| Oxygen big data | `0x2A` | capture enabled; deterministic decoder | hourly firmware min/max | physically verified structure | same | synthetic decoder + structural physical | not medical oximetry |
| Firmware HRV index | `0x39` | capture enabled; deterministic decoder | opaque half-hour byte | physically verified structure; semantic unknown | same | synthetic decoder + structural physical | never export/score as RMSSD or SDNN |

`0x05` display preference did not answer during the physical suite. It remains
unavailable rather than being interpreted as disabled. Device support, heart
rate schedule, goals, oxygen schedule, stress schedule, and firmware-HRV
schedule each returned one valid packet.

## Recovery and dual-protocol behavior

Connection timeout is 12 seconds at the driver boundary. Unsupported services
trigger disconnect and a typed error. Retry policy is bounded and injected;
there is no permanent reconnect loop. Notification subscriptions are cancelled
on disconnect, and raw packets are not retained by default.

SmartHealth/YCBT identification is not implemented. An ambiguous device must
remain a visible candidate and prompt a vendor-app choice in a later UI version.
The wrong choice must be recoverable and non-destructive. Repeated disconnects
should surface the approved “Close QRing and try again” guidance. The capture
path never retains device identifiers and overwrites one temporary local file;
committed fixtures contain only synthetic packets or anonymised structural
evidence.
