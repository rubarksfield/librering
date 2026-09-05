# LibreRing roadmap

This roadmap is ordered by evidence and user safety, not by the number of
possible dashboard metrics.

## Now — harden the verified R12 path

- [x] Exact-family COLMI R12 discovery and service validation.
- [x] Duplicate-safe local sync for activity, pulse, sleep, oxygen, and opaque
  firmware indexes on `RT11CR_1.00.09_260424`.
- [x] Local journal, export, separate deletion, and no-demo-data production gate.
- [x] Refined Today, Vitals, Trends, and You; persistent root-tab state and native detail transitions.
- [x] Historical calendar browsing, interactive time-aligned charts, and 7/30/90-day comparisons.
- [x] Durable name, metric/imperial distance, and personal step/sleep targets.
- [x] Missing-versus-zero handling, future-record filtering, and overlap-safe sleep summaries.
- [x] Journal save/delete error recovery, duplicate-submit guards, and sync-safe deletion.
- [x] Physical iPhone release build, install, independent launch, and version
  readback for `1.2.0 (10)`.
- [ ] Complete foreground sync, relaunch, daylight-saving/timezone, low-battery,
  and competing-app tests with the owned R12.
- [ ] Run VoiceOver and larger accessibility-size passes on physical iPhone.
- [ ] Retain historical timezone/offset provenance in protocol decoding before claiming travel/DST reconstruction is solved.
- [ ] Complete translation of refined views beyond the existing first-run and settings coverage.
- [ ] Run the production path on a physical Android phone.

## Next — widen evidence carefully

- [ ] Collect anonymised structural fixtures from additional R12 firmware
  versions with explicit owner consent.
- [ ] Add a contributor-safe fixture validation tool that rejects identifiers,
  timestamps, and physiological values before commit.
- [ ] Improve background-sync behaviour within iOS and Android platform limits.
- [ ] Add an opt-in Apple Health / Health Connect proposal only after a privacy
  and provenance review.
- [ ] Package reproducible beta builds and release notes.

## Later — validated interpretation

- [ ] Compare pulse and oxygen output with reference devices before making any
  accuracy claim.
- [ ] Compare sleep sessions with an appropriate reference before assigning
  confidence to stage labels.
- [ ] Evaluate recovery/readiness models only with validated inputs and explicit
  missing-data behaviour.
- [ ] Consider other COLMI/QRing models as separate evidence targets—not as
  assumed R12-compatible devices.

## Explicitly out of scope today

- Invented temperature, blood pressure, respiration, VO₂ max, ECG, or raw
  accelerometer readings.
- Relabelling the firmware “HRV” byte as RMSSD/SDNN or the stress byte as a
  clinical/emotional state.
- Medical diagnosis, treatment advice, emergency monitoring, or hidden cloud
  upload.
