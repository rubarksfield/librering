# LibreRing 1.3.2 (13) delivery and release verification

Date: 2026-09-08.

## Included

- Local-only pull-to-refresh across reading pages; Bluetooth sync stays explicit.
- Immediate publication of newly saved readings with the cached-clock delay fixed.
- Stable chart/date inspection when refreshed data changes or midnight passes.
- Restrained navigation, selection, chart, refresh and persistence-result haptics.
- Honest live-pulse help and capability metadata; no unverified live measurement.

See [implementation and QA](refresh-haptics-2026-09-07.md) and
[live-pulse acceptance](live-pulse-acceptance-2026-09-07.md).

## Artifact and installation

- Version changed in `apps/mobile/pubspec.yaml` from `1.3.1+12` to `1.3.2+13`.
- `flutter build ios --release --no-pub
  --dart-define=LIBRERING_DEMO=false --dart-define=LIBRERING_CAPTURE=false`
  succeeded with development signing.
- `codesign --verify --deep --strict` passed. Artifact metadata confirmed
  `org.librering.libreringMobile`, version 1.3.2, build 13.
- Installed in place on the paired iPhone with `xcrun devicectl device install
  app`. No uninstall or data-deletion operation was performed.
- A fresh, bundle-filtered device inventory confirmed **LibreRing 1.3.2 (13)**.
- Initial launch check was refused by iOS with `FBSOpenApplicationErrorDomain`
  `Locked`. The phone had relocked during the build; the user was asked to
  unlock it again. This is not proof of an app crash or successful launch.
- After the user unlocked again, `xcrun devicectl device process launch`
  succeeded and reported the app launched. No Flutter debugger was attached.
- A follow-up process inventory confirmed the executable at this installation's
  exact app-container path remained running after launch.

## Release preflight

- Fresh `flutter analyze --no-pub`: no issues.
- Fresh full mobile suite: **427 tests passed**.
- `git diff --check`: clean. Pending changes were independently reviewed
  against the refresh/haptics scope; no unrelated changes found.

## Scope

The phone installation is development-signed, not App Store/TestFlight
distribution. Real-ring sync, haptic feel, home-screen tapping and live
measurement are not claimed verified by the build/install evidence alone.

## GitHub source-release preparation

The subsequent publishing request covers the same `1.3.2+13` app code, current
README media, [changelog](../../CHANGELOG.md), and
[release notes](../releases/v1.3.2.md). It does not distribute the personally
signed iOS app or a public Android install package.

- Re-ran `flutter analyze --no-pub` and the complete mobile test suite:
  no issues and **427 passing tests**.
- Re-ran R12 package analysis/tests: no issues and **33 passing tests**.
- Re-ran design-system analysis/tests: no issues and **4 passing tests**.
- Public showcase renders use fictional fixtures and simulated sync status,
  never phone health exports, device identifiers, or raw Bluetooth captures.
- Source/version, public claims, and changes were independently reviewed before
  publication. Remote CI and the final tag/release metadata are separate checks,
  available on GitHub; the local checks above do not imply a remote CI result.
