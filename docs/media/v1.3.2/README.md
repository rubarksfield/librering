# LibreRing 1.3.2 screenshot provenance

These PNGs are captures of the actual Flutter app widgets, not generated designs,
browser mockups, or photographs of a connected device. All health values are
fictional examples. No personal health records, device identifiers, accounts,
or real Bluetooth sessions were used.

## Reproduce

On macOS, from `apps/mobile`, using the repository's Flutter SDK version:

```sh
TZ=Europe/Lisbon flutter test --no-pub tool/capture_release_test.dart --update-goldens --reporter expanded
```

Omit `--update-goldens` to compare a fresh render with these files. The capture
tool is intentionally outside `test/`, so it is not part of normal test discovery.
It loads macOS Helvetica Neue and the installed Flutter MaterialIcons font.
The logical viewport is 390×844 on Flutter's iOS target platform; the PNG render
is 780×1688 (2×). There is no fabricated iOS status bar or device frame.
Captured with Flutter 3.47.1 (framework `6655482ec0`) and Dart 3.13.1.
Font/Flutter/macOS changes can affect pixel comparison. All 14 captures passed
a second, non-updating pixel comparison after generation; all images were also
visually inspected.

## Data and state

- Fixed app time: 8 September 2026, 10:20, Europe/Lisbon.
- Data: the unmodified `exampleRingHistory(now)` fixture from
  `apps/mobile/lib/src/presentation_data.dart`, including its fictional source
  and `DataOrigin.demo` markers. The fixture covers 14 calendar days with gaps.
- `demoMode` is false so production navigation, refresh, education, and guidance
  code runs. This does **not** turn the fictional fixture into physical-ring
  evidence. In particular, the real guidance evaluator conservatively shows its
  check-in suggestion rather than treating demo-origin records as verified data.
- All repositories are in-memory, read-only capture doubles. The journal is
  empty and preferences use the app defaults. No Bluetooth client is created.
- No fake readiness, recovery, stress categories, calibrated HRV, or calorie
  scores were added. Actual app capability warnings remain visible.

| Files | Captured state |
| --- | --- |
| `today`, `vitals`, `sleep`, `heart`, `activity`, `oxygen`, `hrv-index`, `stress-index`, `trends` | Actual matching production routes with the fictional history above |
| `welcome` | Actual `/welcome` route and onboarding artwork |
| `hrv-explained`, `stress-explained` | Actual explanation sheets, opened through their in-app buttons |
| `refresh` | Actual Vitals pull-to-refresh success snackbar after one repository reread; no sync or data write |
| `syncing` | Actual `RefinedTodayScreen` and sync status widget, with an explicitly simulated state: reading activity, 12 seconds elapsed, 2 of 8 days checked; not a recorded BLE session |

Each name in the table has a `.png` extension. Public use should retain a nearby
caption identifying the readings as synthetic examples. These images demonstrate
implemented UI, not medical validity, hardware accuracy, or a completed physical
device acceptance test.

## Screen tour

`librering-tour.mp4` is a silent 25.58-second sequence of these eight captures:
Today, Vitals, Sleep, Heart, Trends, HRV explanation, simulated Sync, and Refresh.
The only motion is a 0.35-second crossfade between screenshots; it is not a
recording of app interaction, animation performance, or a physical ring session.
The MP4 is H.264, 390×844, 24 fps. `librering-tour.gif` is the smaller, looping
README preview. Its nearby caption identifies the fictional data.

Rebuild from the repository root with FFmpeg installed:

```sh
bash apps/mobile/tool/build_release_tour.sh
```

The script reads only the eight named PNGs and replaces these two versioned
media outputs. It does not read a phone, health export, or Bluetooth log.
