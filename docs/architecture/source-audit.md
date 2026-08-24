# Source and licence audit

Reviewed: 2026-08-23. This is an engineering audit, not legal advice.

## Decision

Keep LibreRing's original work under Apache-2.0. Import no code, icons, layouts,
screenshots, firmware, APKs, or documentation prose from the surveyed projects.
Use published behaviour and independently corroborated protocol observations as
facts, with attribution. A future implementation must use a clean-room protocol
record and original tests/fixtures captured from an owned R12.

## Repository findings

### COLMI Flutter companion

The MIT-licensed Flutter project explicitly targets R12/Yawell-family rings and
contains a useful command map. It also has broad device-name matching, arbitrary
characteristic fallbacks, Android bonding despite no-bond evidence elsewhere,
and source comments that label step, sleep, SpO₂, and HRV interpretations as
guesses or pattern-derived. Its cloud API conflicts with LibreRing's local-first
mission. It is a lead, not an implementation base.

### openring

The MIT-licensed TypeScript project has the strongest separation of protocol
core and transport, fixture tests, explicit no-data sentinels, and a useful
stable/experimental boundary. Battery, interval pulse history, step history,
and live pulse/SpO₂ have materially stronger support than sleep, SpO₂ history,
or the firmware's `0x39` “HRV” series. Calling that byte value `hrvMs` is not
clinical validation; LibreRing treats its semantics and unit as unknown.

### PulseLoop iOS and Android

PulseLoop demonstrates capability-declared drivers, stable record IDs,
plausibility guards, source provenance, and the useful rule that real data wins
over demo data. iOS is CC BY 4.0, an awkward software licence; Android contains
no discoverable licence. Neither codebase will be copied. Unsupported blood
pressure, glucose, fatigue, and “HRV ms” labels are specifically rejected.

### Gadgetbridge

The live Codeberg repository is AGPL-3.0-or-later. Its explicit R12 coordinator
matches `COLMI R12_*`, declares no Bluetooth bond, and routes the model through
the Yawell ring driver. Current handlers parse activity, heart-rate history,
SpO₂, stress, firmware sleep sessions/stages, and a half-hourly byte stream named
HRV. Only R09 overrides temperature support; R12 does not. These are valuable
facts, but AGPL source will not enter the Apache codebase and field semantics
still require physical-device and reference-standard validation.

### Ringularity

No licence was found. The app requires account/cloud services and includes
location/maps. Its ring-style dashboards and opaque 35/25/20/20 sleep formula
are neither compatible with the product mission nor scientifically adequate.

### Other references

- `tahnok/colmi_r02_client` (MIT) corroborates the 16-byte checksum packet and
  `6E40FFF0` service family with good fixture/property tests, but not R12 identity.
- `ATC_RF03_Ring` (GPL-3.0) supplies factual hardware notes for RF03 hardware and
  includes firmware dumps, patched binaries, and vendor archives. None are used
  or redistributed.
- QRing app-store material is used only for UX and reliability research. No app
  binary was downloaded, decompiled, or executed.

## Clean-room boundary

1. Record facts and uncertainty in `docs/protocol/colmi-r12-evidence.md`.
2. Capture new fixtures only from an owned, consented R12 and record firmware,
   time zone, command, raw bytes, expected meaning, and checksum.
3. Have production implementation authored from the protocol record, not from
   third-party source.
4. Add origin/provenance headers to fixtures.
5. Run legal review before implementing claims close to surveyed patents or
   before changing distribution terms.

## Sources

- [COLMI Flutter companion](https://github.com/SneakyZippy/Colmi_Rxx_flutter_companion/tree/0e4249b626aee16390757aa37dc86492de845ec0)
- [openring](https://github.com/robinojw/openring/tree/c406e2bb6e5a9c429c73b7593d8baaa92579f0b1)
- [PulseLoop iOS](https://github.com/saksham2001/PulseLoopiOS/tree/439ca81293ce858db1db26243a553d60d59d70ee)
- [PulseLoop Android](https://github.com/foureight84/PulseLoopAndroid/tree/86153533e0c9b4ba4ca1a51b1c4fc522237fddf3)
- [Gadgetbridge on Codeberg](https://codeberg.org/Freeyourgadget/Gadgetbridge/src/commit/9d872b136fb8670856dba0f78c9486a25c39b5e6)
- [Ringularity](https://github.com/d4xika/Ringularity/tree/234b94530661c64f24c2f41e3e2b5555d9acdc3b)
- [COLMI client](https://github.com/tahnok/colmi_r02_client/tree/19e70aa502749b87d57e3dba0156dfd67ddc0d4a)
- [ATC RF03 Ring](https://github.com/atc1441/ATC_RF03_Ring/tree/7b2e78e0e9f42b7cec95dd1e733670f533089bbb)
