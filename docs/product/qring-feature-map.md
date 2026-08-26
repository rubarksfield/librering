# Q Ring reference feature map

The 28 Q Ring screenshots supplied for this build are used as an
information-architecture reference, not as evidence that every displayed
metric is scientifically valid or available through the decoded R12 protocol.

## Implemented from supported local records

- Today overview for activity, sleep, pulse, oxygen, and local data coverage.
- Hourly steps, firmware distance, and firmware calorie timelines.
- Day, week, and month activity views.
- Sleep interval, firmware stage ribbon, stage composition, awake runs,
  longest uninterrupted recorded sleep run, recent sessions, and pulse/oxygen
  records that fall inside the interval.
- Pulse daily timeline, observed mean/minimum/maximum, recent measurements,
  and day/week/month history.
- Oxygen minimum-maximum range map, captured bounds, coverage, recent ranges,
  and day/week/month history.
- Unitless firmware HRV and stress index timelines, observed statistics, and
  recent captured values with explicit unvalidated semantics.
- Manual sport history that remains separate from ring measurements.
- Ring battery, firmware, record counts, and an explicit capability matrix.

## Intentionally changed from Q Ring

- LibreRing does not display activity, sleep, recovery, stress, or health
  scores unless their required inputs and calculation are independently
  validated.
- Oxygen remains an hourly minimum-maximum range; no exact average is invented.
- Firmware HRV is not labelled in milliseconds and firmware stress is not
  classified as relaxed, normal, medium, or high.
- Missing hours and days are shown as gaps rather than zero health values.
- Manual activity does not change ring steps, calories, sleep, or vital data.
- The visual system remains the approved warm, quiet LibreRing language rather
  than copying Q Ring's dark cards, photography, or crown-score gauges.

## Visible but locked until verified

- Monitoring schedule writes, gesture controls, display controls, find-ring,
  camera shutter, time-format changes, ring games, and firmware updates.
- Stable live pulse, live oxygen, or live vendor-index measurement flows.
- Apple Health export and background Bluetooth sync.

## Still to build

- Persisted dashboard card ordering and appearance preferences.
- Validated activity-session detection beyond manual sport context.

The only ring-setting write currently allowed is the already approved device
time synchronisation path.
