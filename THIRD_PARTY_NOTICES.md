# Third-party notices

Status: Phase 6 BLE adapter, reviewed 2026-08-26.

LibreRing original code is licensed under Apache-2.0. The repository does not
copy or vendor source code or visual assets from the protocol/design references
below. Repository inspection informed facts, architecture, and risk notes only.

| Reference | Revision reviewed | Licence observed | Use in LibreRing |
| --- | --- | --- | --- |
| SneakyZippy/Colmi_Rxx_flutter_companion | `0e4249b626aee16390757aa37dc86492de845ec0` | MIT | Facts only; no copied code |
| robinojw/openring | `c406e2bb6e5a9c429c73b7593d8baaa92579f0b1` | MIT | Facts and architecture comparison only |
| saksham2001/PulseLoopiOS | `439ca81293ce858db1db26243a553d60d59d70ee` | CC BY 4.0 | Concepts only; no copied software or assets |
| foureight84/PulseLoopAndroid | `86153533e0c9b4ba4ca1a51b1c4fc522237fddf3` | No licence found | Inspection only; all rights presumed reserved |
| Freeyourgadget/Gadgetbridge (Codeberg) | `9d872b136fb8670856dba0f78c9486a25c39b5e6` | AGPL-3.0-or-later | Protocol facts only; no copied code |
| d4xika/Ringularity | `234b94530661c64f24c2f41e3e2b5555d9acdc3b` | No licence found | Product comparison only |
| tahnok/colmi_r02_client | `19e70aa502749b87d57e3dba0156dfd67ddc0d4a` | MIT | Protocol corroboration only |
| atc1441/ATC_RF03_Ring | `7b2e78e0e9f42b7cec95dd1e733670f533089bbb` | GPL-3.0 | Hardware facts only; no firmware/code/assets |
| Penpot | 2.17.1 | MPL-2.0 and component licences | External local design tool; not distributed here |

The Phase 5 Flutter application links these package dependencies through the
standard Dart package resolver:

| Package | Version | Licence |
| --- | --- | --- |
| Flutter / `flutter_localizations` | 3.47.1 SDK | BSD-3-Clause |
| `flutter_riverpod` | 3.4.2 | MIT |
| `go_router` | 18.0.0 | BSD-3-Clause |
| `intl` | 0.20.3 | BSD-3-Clause |
| `path_provider` | 2.1.6 | BSD-3-Clause |
| `flutter_reactive_ble`, `reactive_ble_mobile`, `reactive_ble_platform_interface` | official 5.6.0 source pinned at `6b81c85e7681e222080263992b0ab8f2bc6a6404` | BSD-3-Clause |
| Swift Protobuf | 1.38.1, revision `55d7a1cc5666b85c13464aea1c4b4a90feccb4c8` | Apache-2.0 |

Full transitive notices are generated into Flutter build artifacts. The scoring
sandbox uses only Python's standard library. Penpot runtime images, state,
credentials, and backups are gitignored and are not distributed.
