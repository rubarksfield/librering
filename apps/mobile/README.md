# LibreRing mobile

LibreRing mobile 1.1.0 (5) implements the approved Today / Trends / You shell,
domain details, 7/30/90-day history, manual Journal, local JSON/CSV export,
separate deletion, and foreground stale-data refresh. Real and demo health
records remain strictly separate.

```sh
/Users/zoerichardson/develop/flutter/bin/flutter run \
  --dart-define=LIBRERING_DEMO=true
```

Without the flag, production uses the versioned Application Support repository
and verified R12 driver. Unsupported data and scores fail closed. The UI targets
iOS 16+ and Android API 28+.

Verification:

```sh
/Users/zoerichardson/develop/flutter/bin/flutter analyze
/Users/zoerichardson/develop/flutter/bin/flutter test
/Users/zoerichardson/develop/flutter/bin/flutter build ios --simulator --debug \
  --dart-define=LIBRERING_DEMO=true
```
