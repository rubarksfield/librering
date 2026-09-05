# LibreRing 1.3.1 (12) delivery

Date: 2026-09-05.

## Included

- Real sync stages, elapsed time, stalled/partial/error feedback and recovery help.
- Green sleep palette and continuous timeline inspection, including hold/vertical
  scrubbing and accessible adjustments.
- Bounded daily suggestions with a visible explanation and manual context;
  opaque firmware indexes do not drive health advice.
- Contextual HRV, stress and energy explanations; unverified energy units are
  no longer presented as confirmed active calories.
- Separate last-reported battery status and sync help.
- Clear account/data wording and safe introduction replay.

## Preflight

- Mobile analysis: clean.
- Mobile tests: 349 passed.
- R12 protocol package analysis: clean; 31 tests passed.
- Sleep-scrubbing tests: 17 passed again after replacing a personal absolute
  font path with runtime-relative Flutter font discovery for portable CI.
- Public-change review found no credentials, raw BLE captures, private device
  dumps or health exports in pending changes. New golden screenshots use
  synthetic test fixtures.
- Diff whitespace checks: clean.

## Physical-device artifact

Built with `flutter build ios --release --no-pub
--dart-define=LIBRERING_DEMO=false --dart-define=LIBRERING_CAPTURE=false`.
Automatic development signing succeeded and `codesign --verify --deep --strict`
passed. Artifact metadata confirmed version 1.3.1, build 12.

Installed as an in-place update using the existing bundle identifier. No
uninstall or data-deletion operation was performed. A fresh device app inventory
confirmed LibreRing 1.3.1 (12).

The initial launch verification was refused by iOS because the phone was locked.
That is a device-state limitation, not a successful runtime test or an observed
app crash. This development-signed release is not an App Store/TestFlight release;
complete real-device UX, VoiceOver and physical-ring QA remain separate.

See [in-app explanation verification](in-app-explanations-2026-09-05.md),
[sync feedback](sync-feedback-2026-09-05.md) and
[sleep interactions](sleep-scrubbing-2026-09-05.md).
