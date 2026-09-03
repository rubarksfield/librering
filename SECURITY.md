# Security policy

## Supported version

LibreRing is currently a development preview. Security fixes target the latest
commit on `main`.

## Report a vulnerability

Please use GitHub's private vulnerability-reporting flow for this repository.
If that flow is unavailable, contact
[`@rubarksfield`](https://github.com/rubarksfield) privately before sharing
details. Do not open a public issue for a vulnerability.

Include the affected revision, platform, impact, and minimal reproduction. Do
not attach personal health data, location, raw BLE captures, stable Bluetooth
identifiers, signing files, tokens, or credentials.

## Project boundary

LibreRing reads health-adjacent data from nearby hardware and stores decoded
records locally. Treat changes involving BLE discovery, exports, deletion,
platform permissions, or persistence as security-sensitive. Unknown firmware
and malformed packets must fail closed.
