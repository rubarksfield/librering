# Ring compatibility: tested versus potential

Evidence checked 8 September 2026. This describes **direct Bluetooth support**,
not importing records that another app has placed in a phone's health store.

## Tested in LibreRing

**Only the maintainer's own COLMI R12 has been physically tested with LibreRing**,
running `RT11CR_1.00.09_260424`. This does not establish support for every R12
firmware revision or validate the physiological accuracy of its sensors.

The [R12 evidence record](protocol/colmi-r12-evidence.md) and
[README signal table](../README.md#what-the-r12-can-supply) describe the actual
boundaries. In particular, production live pulse/oxygen remain gated; an upstream
project supporting a feature does not mean LibreRing currently enables it.

## Other rings that could share the protocol

These are candidates for extending LibreRing, **not supported devices in the
current release**. “Should work” here can only mean that related protocol work
may be reusable after inspecting, adapting and testing the specific ring.

| Candidate model — QRing variant only | Upstream evidence, not LibreRing testing |
| --- | --- |
| COLMI R02, R06, R10 | Explicitly listed by the [Colmi R02 Python client](https://github.com/tahnok/colmi_r02_client/blob/19e70aa502749b87d57e3dba0156dfd67ddc0d4a/README.md#compatibility) |
| COLMI R03, R07 | [Gadgetbridge](https://gadgetbridge.org/gadgets/rings/yawell/) describes these as sharing R02 hardware |
| COLMI R09 | [Gadgetbridge](https://gadgetbridge.org/gadgets/rings/yawell/#device__colmi_r09) describes related R02 hardware with additional capabilities |
| Yawell R05 | [Gadgetbridge](https://gadgetbridge.org/gadgets/rings/yawell/#device__yawell_r05) relates it to COLMI R09 |
| Yawell R10 | [Gadgetbridge](https://gadgetbridge.org/gadgets/rings/yawell/#device__yawell_r10) relates it to COLMI R10 |
| Yawell R11 | [Gadgetbridge](https://gadgetbridge.org/gadgets/rings/yawell/#device__yawell_r11) relates it to COLMI R12 |

Those projects' support statements belong to those projects. We infer only that
these are sensible research targets. We have not tried them in LibreRing, and
the table does not promise a shared sensor set, history format, unit, feature
list or connection result. For example, R09-related features do not enable
temperature reporting in LibreRing.

## Why they do not work out of the box yet

The current app intentionally checks more than a generic Bluetooth service:

- [`profile.dart`](../packages/ring_colmi_qring/lib/src/profile.dart) recognises
  exact `COLMI R12_*` advertisements for the R12 path. Related service UUIDs can
  make a device a scan candidate, not a supported connection.
- [`r12_pairing_client.dart`](../apps/mobile/lib/src/ble/r12_pairing_client.dart)
  rejects non-R12 production connections.
- [`driver.dart`](../packages/ring_colmi_qring/lib/src/driver.dart) limits
  production history sync to the physically accepted firmware above and checks
  services/characteristics. Decoders and fixtures currently describe that R12.

Enabling another name or removing the firmware check is not sufficient evidence.
Each model needs a reviewed profile, packet/interval/unit validation and a
model-specific capability boundary. Unsupported data must remain unavailable.

## Names and rebrands are not guarantees

Gadgetbridge [warns about alternative hardware under R02/R03/R06 names](https://gadgetbridge.org/gadgets/rings/yawell/).
Check the actual companion app, firmware and hardware—not just the seller's
model title. QRing is a useful lead, but is not enough to promise compatibility.
Yawell R11 does not establish COLMI R11 support; Pro, revised and unbranded
variants also need separate evidence. Unlisted models are unknown, not implicitly
compatible or proven incompatible.

LibreRing currently has no direct drivers for Oura Ring, RingConn, Ultrahuman
Ring AIR or Samsung Galaxy Ring. Sharing a product category—or exchanging
records through a health platform—does not make their Bluetooth protocols
compatible with this driver.

## Help turn a candidate into tested support

Start with a [compatibility issue](https://github.com/rubarksfield/librering/issues/new)
before changing discovery or sending commands. Include only non-sensitive facts:

1. Exact brand/model, firmware revision and companion app name.
2. Phone OS and LibreRing version/commit.
3. A plain-language description of discovery/connection behaviour; it is fine
   to report that the current R12 gate correctly refuses the ring.
4. Whether you own the ring and are willing to help with a reviewed test plan.

Do **not** post Bluetooth addresses, serial numbers, full advertised-name
suffixes, account credentials, personal readings or raw BLE captures. Do not
bypass safety gates or flash firmware simply to test this list.

A support claim needs consenting hardware tests, sanitised structural fixtures,
decoder tests, capability/units review, and checked sync/reconnect/error behaviour.
Record results by exact model and firmware, including missing features. See
[contributing](../CONTRIBUTING.md) and the [fixture policy](protocol/test-fixtures.md).
