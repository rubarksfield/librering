# LibreRing mobile

LibreRing mobile 1.3.0 (11) provides refined Today / Vitals / Trends / You views,
interactive supported-signal histories, personal goals and units, a daily
timeline, manual Journal, local JSON/CSV export, and explicit deletion/recovery.
Sync is user-triggered; opening or resuming the app does not scan nearby rings.
Real and demo health records remain strictly separate.

```sh
flutter run \
  --dart-define=LIBRERING_DEMO=true
```

Without the flag, production uses the versioned Application Support repository
and verified R12 driver. Unsupported data and scores fail closed. The UI targets
iOS 16+ and Android API 28+.

For installation on a physical iPhone, use a signed release or profile build.
Debug Flutter builds cannot be launched independently from the Home Screen.

```sh
flutter build ios --release \
  --dart-define=LIBRERING_DEMO=false \
  --dart-define=LIBRERING_CAPTURE=false
```

See the [refinement QA record](../../docs/testing/refinement-2026-09-05.md)
for verification and remaining physical-ring checks.

Verification:

```sh
flutter analyze
flutter test
flutter build ios --simulator --debug \
  --dart-define=LIBRERING_DEMO=true
```
