# Golden-test contract

Four priority screens are captured at the approved 390×844 viewport: Welcome,
Today, Metrics, and Cycle privacy. They live under
`apps/mobile/test/goldens/`.

Goldens run on macOS because the approved design uses the system Helvetica Neue
collection. The test loads that font explicitly, locates Flutter's own Material
Icons font from the active SDK, and skips on non-macOS hosts rather than creating
false cross-platform diffs.

```sh
cd apps/mobile
/Users/zoerichardson/develop/flutter/bin/flutter test \
  test/golden_screens_test.dart
```

Use `--update-goldens` only after comparing the rendered change with the frozen
design source and recording the design decision.
