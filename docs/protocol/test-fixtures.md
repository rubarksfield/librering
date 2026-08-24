# Protocol fixture policy

Fixtures are either `synthetic` or `physical-capture` and the filename/record
must say which. A physical capture additionally records device ID alias, hardware
size, firmware, phone/OS, timezone, command, response, expected observable,
checksum, missing-data behavior, and consent scope.

Synthetic fixtures may test framing, bounds, duplicates, ordering, timeouts, and
error handling. They may not establish a command payload, unit, capability,
physiological meaning, or device compatibility.

The scripted BLE transport currently covers slow and failed connections,
interruption, reconnect, and caller-supplied notifications. Low-battery and
partial-history cases remain pending until a physical capture establishes their
response payloads and sentinels; synthetic framing must not stand in for those
semantics.

Raw captures are sensitive diagnostic data. Redact stable identifiers and never
commit health values or packets without explicit consent and a retention decision.
