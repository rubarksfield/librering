# LibreRing mobile

The Phase 5 Flutter application implements the twelve approved routes and keeps
real and demo health records strictly separate.

```sh
/Users/zoerichardson/develop/flutter/bin/flutter run \
  --dart-define=LIBRERING_DEMO=true
```

Without the flag, production health surfaces fail closed until a real repository
is implemented. The UI targets iOS 16+ and Android API 28+.

Verification:

```sh
/Users/zoerichardson/develop/flutter/bin/flutter analyze
/Users/zoerichardson/develop/flutter/bin/flutter test
/Users/zoerichardson/develop/flutter/bin/flutter build ios --simulator --debug \
  --dart-define=LIBRERING_DEMO=true
```
