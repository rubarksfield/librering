# Ring sync feedback

## Problem and change

The production R12 sync reads retained history in sequential requests (up to
eight days for activity and pulse). The interface previously reduced all of
that work, local persistence, and Bluetooth teardown to a small spinner.
Today also lacked a persistent first-sync error when there was no dataset.

The sync now exposes actual discovery, connection, metadata, battery, activity,
pulse, sleep, oxygen, firmware-index, processing, local-saving, and connection-
closing stages. Day counters describe requests checked, including empty or
unsuccessful requests; they are not counts of imported records or percentages.

Today, device setup, the ring page, and sync help share persistent native feedback.
Completion, partial reads, and failures stay distinct. Empty successful reads do
not invent health data. No complete result is shown while storage or teardown is
still pending. Demo mode does not pretend to perform a physical sync.

## Slow-operation behavior

- Elapsed time advances independently of protocol progress.
- After 30 seconds with no new stage or completed day request, the status changes
  to a visible warning with the time since progress and recovery instructions.
- A genuine progress event clears the warning. Passing time never increments day
  counters or claims a confirmed failure.
- Reduce Motion uses a static status icon. Stage announcements exclude the
  per-second timer to avoid repeated screen-reader interruptions.
- Late callbacks cannot replace saving, terminal, or a newer attempt's progress.

## Safety boundary

This is an observability/UX change, not a change to ring commands, response
timeouts, firmware acceptance, decoding, or stored health data. The existing
concurrency lock remains held until the actual operation and disconnect settle.

Some platform calls (including BLE writes and disconnect) can outlive the existing
response timers. An outer Dart Future timeout would not cancel those operations.
This patch deliberately does not unlock and start a second sync on top of them.
If a platform call never settles, the user gets a persistent no-progress warning
and instructions to close/reopen the app, not an endless ordinary spinner or a
false assertion that cancellation succeeded. Automatic cancellation/recovery
needs separately tested transport cancellation and physical-ring acceptance.

## Verification scope

Regression coverage exercises gated discovery/read/save/disconnect futures,
real stage/day progress, the 30-second warning and recovery, complete/partial/
empty outcomes, retries, disposal, stale callbacks, narrow screens, large type,
reduced motion, and native screen rendering. Protocol tests retain firmware and
unsupported-channel gates. Physical BLE timing and VoiceOver on the user's
iPhone require a device session; synthetic tests are not physical acceptance.

## Verified results

| Check | Result |
| --- | --- |
| Mobile `flutter analyze --no-pub` | No issues |
| Mobile `flutter test --no-pub` | 193 tests passed, including 24 golden screens |
| R12 package `dart analyze` / `dart test` | No issues / 31 tests passed |
| iOS `flutter build ios --release --no-codesign --no-pub --dart-define=LIBRERING_DEMO=false --dart-define=LIBRERING_CAPTURE=false` | Release build passed; unsigned, not a phone installation |
| Visual review | Today active/stalled status and revised Sync button inspected from rendered goldens |
| `git diff --check` | Clean |

The two older pairing tests now assert the persistent complete/empty result
instead of the removed transient toast and technical record-summary copy. Their
connection, sync, disconnect, and stored-dataset assertions remain intact.

Files involved: `apps/mobile/lib/src/app_state.dart`, `sync_progress.dart`,
`ble/r12_pairing_client.dart`, `ui/sync_status_card.dart`, the Today/device/setup/
support screen integrations, and `packages/ring_colmi_qring/lib/src/driver.dart`.
Tests include `sync_progress_controller_test.dart`, `sync_status_card_test.dart`,
`physical_pairing_flow_test.dart`, and the driver's existing test suite.

Changes remain local until a separate signed-device update/publication is approved.
