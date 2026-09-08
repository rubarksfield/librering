# Live pulse: evidence and acceptance boundary

Reviewed 2026-09-07. No device operation was performed for this review.

## Current evidence

The owned COLMI R12 running `RT11CR_1.00.09_260424` returned 30 valid live
pulse warm-up packets, with matching type and no device error, but **zero
nonzero readings**. Oxygen returned 40 warm-up packets and zero readings.
That proves transport, not a successful live physiological measurement.

See the [physical protocol review](../protocol/colmi-r12-evidence.md) and
`packages/ring_colmi_qring/test/fixtures/r12-approved-suite-physical-structure-rt11cr-1.00.09.json`.
Synthetic pulse/oxygen responses in driver tests are not physical evidence.

`startLiveMeasurement` remains deliberately disabled. Capability discovery
now reports live pulse and oxygen as unavailable **in production**, consistent
with that API. This is not a claim that the ring lacks the hardware: the
diagnostic transport is retained. Recorded pulse/oxygen history and BLE
connection status remain separate supported concepts.

## Missing pulse-only acceptance conditions

Before enabling a production live-pulse feature:

1. Confirm the exact owned R12 model/firmware and an explicitly approved,
   bounded worn-ring pulse-only session. Do not run the full suite: it also
   captures unrelated history/configuration, writes the clock, and starts
   oxygen measurement.
2. Use only the already documented pulse start/stop commands. Verify frame
   length/checksum, matching pulse type, device status and a nonzero value.
   Warm-up, malformed, wrong-type, error and missing responses must never be
   presented as heart-rate measurements. A nonzero byte alone does not prove
   valid BPM semantics or accuracy.
3. Observe a completed measurement on the physical ring and corroborate the
   meaning of the returned value against an appropriate simultaneous pulse
   reference. Record the observed limitations; this is not clinical validation.
4. Physically verify the completion/stop lifecycle, including explicit cancel,
   leaving the measurement screen, app backgrounding and disconnect. A successful
   GATT stop write alone does not prove the sensor stopped. Stop failure or
   unknown completion must remain explicit.
5. Verify bounded warm-up/no-reading and error states, no automatic restart or
   overlap with history sync, and no replay of stale samples as live. Record
   session freshness and retain no raw physiological data or device identifiers
   in repository fixtures/logs; use structural evidence only.

No new diagnostic implementation, packet exploration, physical measurement or
production live feature was added in this change. Live oxygen requires its own
acceptance evidence and is not unlocked by pulse acceptance.

## Automated verification

- Driver capability tests assert live pulse/oxygen are unavailable while
  supported history remains available.
- Both connected and disconnected calls to both live measurement types fail
  with the existing evidence-gate exception and perform zero BLE writes.
- Existing diagnostic-suite tests remain intact: a production gate does not
  remove the already bounded diagnostic transport.
