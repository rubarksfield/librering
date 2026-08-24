# QRing audit

Reviewed: 2026-08-23. Evidence is limited to the current public app-store listing,
vendor/manual imagery, current reviews, and protocol behaviour; there was no
direct logged-in QRing session or owned R12. Findings from reviews are anecdotal,
not measured prevalence.

## Task audit

| Task | Evidence-backed friction | Category | Replacement-app control |
| --- | --- | --- | --- |
| Pair ring | repeated reports of disconnect/rebind loops; Bluetooth state is not a clear recovery journey | Bluetooth + interface | explicit phases, last success, bounded retry, diagnostics, no blind rebind |
| Understand sleep | high sleep scores despite poor subjective sleep and missing final hours appear in reviews | firmware/data + score explanation | score only with reliable interval; show coverage; stage estimates zero-weight |
| Know recovery | opaque stress/HRV-like numbers can look medical without semantic definitions | firmware + copy | omit opaque inputs; call Recovery provisional; state what is missing |
| See battery | reviews report no low-battery warning and multi-day data gaps | device + notification UX | persistent battery/last sync; local warning; explain resulting missing night |
| Record swim | vendor 1ATM claim can be mistaken for swim tracking; no stable swim-record evidence | hardware + copy | manual/imported swim; no underwater metrics claim |
| See improvement | users report history disappearing/reappearing after repeated sync | sync/data integrity | idempotent local sync, last complete day, gap marker, no silent replacement |
| Export/control | reviews mention incomplete Health/workout transfer and image-oriented export | integration + interface | CSV/JSON export, provenance, preview, health-platform write summary |

## Interface and copy problems

Public screenshots/listings present step, sleep, heart rate, exercise and other
health-style modules with similar visual authority. That makes an opaque stress
index or firmware stage look as reliable as battery. Dense metric equality is the
central hierarchy failure. Generic wellness labels also fail to say measured vs
estimated, current vs stale, or why a result changed.

LibreRing will use one primary conclusion, a confidence line, three domain rows,
and an explicit source chip. Technical names appear only in Inspect. Error copy
will say what is known, what was preserved, and the next safe action.

## Problems an app can improve

- pairing/sync state visibility and safe retries;
- local history integrity, idempotency, and gap display;
- information hierarchy and translation;
- provenance, confidence, missing-data explanations;
- accessible charts and meaningful trend questions;
- data export/deletion and local-first defaults;
- separating device controls from health interpretation.

## Problems an app cannot solve

- PPG/accelerometer quality, fit, motion artefact, or sensor placement;
- firmware sleep/stage/SpO₂/stress/HRV validity;
- absent temperature, respiration, R–R, raw acceleration, or swim detection;
- underwater radio limits or 1ATM constraints;
- timestamp/firmware behaviour not exposed by the device;
- coexistence conflicts when another app owns the BLE connection.

## Review signal

As of review, Google Play showed 2.6/5 from roughly 2.68K reviews and 500K+
downloads; Apple's US listing showed 2.8/5 from 352 ratings. Current reviews are
mixed—some users find pairing and basic data satisfactory—but recurring negative
themes include missing/reappearing history, disconnects, absent battery warnings,
incomplete Health/workout export, and distrust of sleep/stress/step accuracy.

These are product hypotheses for validation, not proof that every user or version
has the same issue.

## Sources

- [QRing on Google Play](https://play.google.com/store/apps/details?id=com.app.cq.ring&hl=en)
- [QRing on the US App Store](https://apps.apple.com/us/app/qring/id6473672621)
- [COLMI R12 product page](https://www.colmi.com/colmi-r12-smart-ring/)
- [Current R12 protocol evidence](../protocol/colmi-r12-evidence.md)
