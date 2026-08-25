# COLMI R12 physical-device checklist

Status: not run; an owned R12 is available but no physical phone/capture session
has been connected or consented yet.

Before capture, record the test phone/OS, ring size, advertised name, firmware,
charge state, QRing contention state, and whether redacted packets may remain
local-only or be committed as an anonymized fixture.

- Record ring hardware and firmware identifiers without exposing personal data.
- Capture permission, scan, connect, reconnect, timeout, and QRing-conflict states.
- Verify service/characteristic discovery against clean-room fixtures.
- Verify notification framing, checksums, ordering, retries, and cancellation.
- Test background/foreground and Bluetooth-off recovery on iOS and Android.
- Compare timestamps, battery, steps, pulse, and supported sleep records with raw
  captures; never infer unsupported oxygen, temperature, respiration, HRV, or swim.
- Run export/delete and app-removal checks with cycle data handled separately.
- Record screen-reader, 200% text, reduced motion, contrast, power, and performance.

Passing emulator or fixture tests is not a substitute for this checklist.
