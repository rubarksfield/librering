# Sleep timeline inspection

## Behaviour

- Tap or drag horizontally anywhere in the sleep chart to inspect a moment.
- Touch and hold, then slide down for later times or up for earlier times.
  The first clear movement locks the axis for that hold, preventing diagonal
  movement from unexpectedly switching between horizontal and vertical control.
- A quick vertical swipe still scrolls the page, even when it starts on the chart.
- The cursor and readout stay visible after release. The readout shows the
  inspected local time, estimated stage, interval start/end and duration.
- Gaps remain `Unclassified` with `No stage recorded`; inspection never snaps
  across a gap to an adjacent recorded stage. Stage intervals are start-inclusive
  and end-exclusive. Dragging beyond the chart clamps to the sleep window.
- Screen-reader increase/decrease actions traverse chronological intervals,
  including gaps. Empty stage histories do not offer inspection gestures.
- Changing the selected session or stage data clears inspection. Equivalent
  rebuilt data retains it. Sleep calculations, stored records and BLE are unchanged.

## Verification scope

The focused widget tests in `apps/mobile/test/sleep_scrubbing_test.dart` exercise
gestures inside the real `/sleep` page, including scrolling, interval boundaries,
missing data, accessibility, date changes and 320×568 layout at 200% text size.
Visual baselines cover the sleep page and selected-state readout.

Results on 2026-09-05 (run from `apps/mobile`):

- `flutter test test/sleep_scrubbing_test.dart --no-pub`: 16 passed.
- `flutter test --no-pub --reporter compact`: all 219 mobile tests passed.
- `flutter analyze --no-pub`: no issues.
- Formatting and `git diff --check`: clean.
- Both the default sleep-page and selected-interval golden images were visually
  reviewed; no clipping or overlap found.

Files changed for this feature: `apps/mobile/lib/src/analytics_screens.dart`,
the focused test above, `apps/mobile/test/goldens/analytics_sleep.png`,
`apps/mobile/test/goldens/sleep_scrubbing.png`, and this verification note.
Existing HRV-education and sync-feedback changes were preserved.

This is local implementation and automated/rendered verification, not physical
iPhone gesture testing or a phone/GitHub deployment.
