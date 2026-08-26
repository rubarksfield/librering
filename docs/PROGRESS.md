# LibreRing progress

Last updated: 2026-08-26

## Current status

`IMPLEMENTATION`

- Visual direction: **approved for V1 on 2026-08-24**
- Scoring model: **approved for V1 on 2026-08-24**
- Design/scoring freeze: **complete in commit `04563fe`**
- Phase 5 production foundation: **complete and verified**
- Phase 6 decoded local sync: **physically accepted on the owned R12**
- Product preview 1.1.0 (5): **implemented, QA-verified, and installed on the owned iPhone**

## Completed

- Read the complete 4,316-line master prompt and locked production Flutter work.
- Verified Penpot 2.17.1 from the official current release, pinned every runtime
  image by digest, and started the local-only stack.
- Created a local profile; verified HTTP, PostgreSQL, Valkey, and MCP initialization.
- Configured the supported same-origin MCP stream and read its tool overview.
- Created backup/start/restore helpers; restored a database/assets backup into
  scratch targets and verified profile/assets counts and hashes.
- Audited eight ring/open-source references at pinned revisions and current
  Gadgetbridge on Codeberg; wrote the clean-room and licence boundary.
- Completed market, QRing, Oura, patent, scientific, and R12 capability research.
- Derived original Sleep, Recovery, Movement, and no-score Cycle Context models.
- Generated 2,970 synthetic days across 33 scenarios and six fictional profiles.
- Passed all 13 scoring/baseline behaviour tests and generated sensitivity SVG/CSV.
- Defined three-destination IA, complete user flows, content hierarchy, three
  materially different visual directions, and reviewable design tokens.
- Created the authenticated Penpot team `LibreRing`, project `LibreRing V1`, and
  file `LibreRing — Product & Scientific Model V1` after verifying the local stack.
- Switched the first-gate visual source of truth to a dependency-free interactive
  web prototype when Penpot 2.17.1 and its bundled 2.17.0 MCP plugin proved
  unreliable for unattended automation; this followed the user's explicit
  no-input alternative-design instruction.
- Built and browser-playtested all eight journeys, alternate/no-result states,
  dark/light themes, large text, and the 390×844 mobile breakpoint.
- Refined the prototype with a premium original material system, dimensional
  device frame, project-authored SVG icons, and reduced-motion-safe animation.
- Studied Oura's supplied 2024 app-refresh article and film subtitles/storyboards,
  then translated only high-level hierarchy principles into an original LibreRing
  identity, editorial/interface type pairing, conclusion-first screens, exact
  journey progress, and direction-aware reduced-motion-safe flow.
- Studied the supplied Dribbble concepts, then followed the user's final selection
  of the Nixtio smart-ring shot as the rigid reference for fonts and cards. The
  rendered build now uses one system grotesk, oversized tabular numerals, flat
  grey modules, a two-by-two metric grid, coral data marks, and bounded chart
  drawing; the mood-style hybrid and its source CSS were removed.
- Completed prototype, simplicity, accessibility, and originality reviews.
- Completed a separate Open Design pass and received user approval to proceed
  with its sparse reference-led direction. Archived its self-contained 12-screen
  prototype, design system, brand specification, decision contract, and
  implementation handoff under `docs/design/approved-reference-led/`.
- Designated the Open Design artifact as the V1 visual source of truth while
  retaining `prototype/` as the 36-route functional, content, scoring, and
  edge-case reference until every journey is mapped during implementation.
- Received unmistakable approval of both V1 design and scoring after explicitly
  stating that scoring approval remained outstanding.
- Frozen the approved design exports, tokens, specifications, scoring V1, and
  model cards as a separate root commit (`04563fe`).
- Installed and verified Flutter 3.47.1 / Dart 3.13.1 without enabling analytics.
- Created `apps/mobile`, `ring_core`, `ring_demo`, and `ring_design_system` with
  one-way dependency boundaries and no BLE/storage/health/scoring implementation.
- Implemented all twelve approved routes with the exact warm-paper, Helvetica,
  flat-card, oversized-number, coral-mark, and original vector-art direction.
- Added an explicit `LIBRERING_DEMO` boundary: production mode fails closed and
  never substitutes bundled health values.
- Added English and pt-PT copy, reduced-motion-aware route transitions, semantic
  summaries, 48 dp controls, contrast assertions, and scroll-safe layouts.
- Added local-only swim journal and cycle privacy state with separate provenance.
- Generated and visually inspected four 390×844 Helvetica golden baselines.
- Built, installed, launched, and visually inspected the demo app on an iPhone
  17 Pro simulator. The archived screenshot hash is
  `a83c306d442d7391b9a90208fb3142d83975b6bbada4eb93dc239d35d2e2bece`.
- Added protocol-independent BLE/driver contracts, bounded sync lifecycle and
  retry/deduplication primitives, and a scripted transport covering slow and
  failed connections, interruption, reconnect, and fixture-backed notifications.
- Added exact R12 advertisement matching, inclusive QRing candidate discovery,
  strict service validation, 16-byte checksum framing, bounded duplicate-safe
  big-data assembly, and fail-closed command gates.
- Installed Google-signed Android Studio Quail 3 Patch 1 and its arm64 JDK,
  Android SDK/platform/build/command-line tools, and verified a real debug APK.
- Added the audited Flutter BLE adapter and production pairing flow with bounded
  inclusive scanning, exact `COLMI R12_*` acceptance, connection/service
  discovery, permission copy, QRing-conflict recovery, and no raw-packet
  retention. Service validation subscribes for notifications but sends no
  protocol health or settings command.
- Pinned the official upstream `flutter_reactive_ble` 5.6.0 source at merged
  commit `6b81c85e7681e222080263992b0ab8f2bc6a6404` after the published 5.5.0
  Android package failed against its own modern AndroidX dependency graph.
- Confirmed the user's iPhone 15 Pro Max on iOS 26.5.2 is physically connected
  and visible to Flutter and Xcode.
- Completed one consented, local-only owned-R12 capture covering firmware,
  battery, time sync, GATT profile, six readable configuration families, eight
  activity and pulse days, seven stress and firmware-HRV days, all returned
  sleep and oxygen history, and both bounded live sessions.
- Verified every command-history checksum and both big-data MODBUS CRCs; decoded
  55 activity buckets, 79 pulse samples, 146 stress-index samples, 75 opaque
  firmware-HRV samples, four sleep records, and 30 oxygen hourly ranges without
  retaining physiological values in repository fixtures.
- Added deterministic, fail-closed decoders backed by fully synthetic fixtures
  and an anonymised physical-structure manifest. Live warm-up-only streams are
  now classified as `noReading`, not timeout.
- Added an exact-firmware production sync that reads battery, bounded activity,
  pulse, sleep, hourly oxygen, and opaque vendor-index history. Necessary time
  synchronisation is its only setting write; unknown firmware and all live or
  unrelated settings remain fail-closed.
- Added a versioned Application Support repository with atomic writes,
  deterministic upsert, 400-day retention, corrupt-schema failure, local
  deletion, and no BLE identifier/raw-packet input path.
- Replaced production placeholders with stored ring steps, measured pulse,
  firmware-derived sleep and oxygen-range views. Recovery remains unavailable;
  firmware HRV/stress are retained only as opaque evidence and are not displayed
  as validated metrics.
- Added repository, duplicate/no-data/corruption/privacy/deletion, real-data UI,
  and production sync widget tests.
- Separated returning-user refresh from first-run pairing: a stored-data launch
  opens Today, and its sync control performs a bounded in-place scan/connect/sync
  without routing through onboarding or persisting a BLE identifier.
- Restored the proven 12-second discovery window for routine refresh, added one
  automatic retry after best-effort stale-link release, and separated
  no-advertisement, unconfirmed-family and multiple-R12 failure messages.
- Added a transient iOS CoreBluetooth fallback for an R12 that is already
  connected and therefore not advertising. It is deduplicated with scan results
  and does not persist the system peripheral identifier.
- Replaced the dense production dashboard with the approved three-destination
  Today / Trends / You shell and transparent Sleep, Recovery, Movement, Heart,
  and Oxygen drill-downs. Recovery remains intentionally unavailable.
- Added 7/30/90-day multi-domain history with missing-day gaps, source labels,
  sample counts, and no zero-filling or invented baseline interpretation.
- Added an atomic local Journal with manual swims, tag/note check-ins, separate
  deletion, and portable JSON/CSV export with a SHA-256 manifest. Device
  identifiers and raw BLE packets are excluded from export.
- Added quiet, bounded stale-history refresh on Today launch and foreground
  resume while preserving manual refresh and the no-pairing returning-user flow.
- Expanded the route, journey, compact-phone, large-text, deletion, export, and
  golden suites; fixed an expanding confidence badge and navigation overlay
  found during rendered visual review.
- Ran Appium MCP 1.92.6 through XCUITest/WebDriverAgent 16.8.0 on an iPhone 17
  Pro simulator. The native accessibility-tree journey passed from onboarding
  through Today, Trends, manual save, You, Data/export, and deletion Cancel.
  A final Quick check-in pass also verified native tag/note entry, local-save
  readback, outside-tap keyboard dismissal, and Journal's selected You state.
- Built the signed production iOS release and production-mode Android debug APK,
  installed `1.1.0 (5)` over the local network, and confirmed the installed
  version/build through CoreDevice readback.

## In progress

- Unlock and foreground-QA the already-installed LibreRing 1.1.0 (5), then
  confirm quiet stale refresh against the owned R12.

## Blocked

- No active physical-capture blocker. Physiological accuracy and score validity
  still require independent reference evidence; packet correctness cannot clear
  those scientific gates.

## Decisions

- Apache-2.0 for original repository materials; no third-party code/assets copied.
- Current Gadgetbridge confirms an R12-specific Yawell driver but not physiological
  validity. R12 firmware HRV/stress and stages are excluded from score math.
- R12 temperature, respiration, raw acceleration, R–R intervals, and automatic
  swim detection are unsupported.
- Navigation is Today / Trends / You; Log is a labelled Today action.
- Structured Health Dashboard is selected over Quiet Ledger and Daily Brief.
- The approved reference-led Open Design artifact supersedes the earlier
  prototype's visual treatment; it does not supersede its functional journeys.
- Pregnancy without an appropriate baseline is trend-only; illness rest is
  protected; manual/imported swimming is not interpreted as inactivity.

## Verification log

| Date | Check | Result |
| --- | --- | --- |
| 2026-08-23 | Docker / Compose | Docker 29.4.3; Compose 5.1.4 |
| 2026-08-23 | Penpot release/compose | Stable 2.17.1; official compose; digest-pinned local copy |
| 2026-08-23 | Local services | frontend HTTP 200; database/cache healthy; MCP protocol 2025-06-18 initialized |
| 2026-08-23 | Backup restore rehearsal | passed: profile restored, assets hash/count verified |
| 2026-08-23 | `python3 research/scoring/run_research.py` | 2,970 deterministic synthetic records; seed 1729 |
| 2026-08-23 | `python3 -m unittest discover research/scoring/tests -v` | 13/13 passed |
| 2026-08-23 | `node --check prototype/app.js` | passed |
| 2026-08-23 | Browser playtest | 8/8 journeys reached their required target states |
| 2026-08-23 | Responsive/theme review | dark, light, large text, and 390×844 rendered without blocked controls |
| 2026-08-23 | Premium visual regression | 9 journey entry/final assertions passed; Cycle Context 5-step and export 3-step playthroughs passed |
| 2026-08-23 | Browser console | 0 errors or warnings |
| 2026-08-23 | Accessibility runtime audit | no duplicate IDs, unnamed controls, or sub-44px phone controls on audited screens |
| 2026-08-23 | Token contrast calculation | normal text pairs ≥4.5:1 after light-token correction |
| 2026-08-24 | Oura source review | official article, complete English subtitles, and 11 public storyboard sheets reviewed; Gemini watch-video analysis unavailable after two HTTP 503 responses, so no Gemini-derived claims used |
| 2026-08-24 | Brand route regression | 36/36 numbered routes rendered with navigation or exact journey progress; 0 undefined states |
| 2026-08-24 | Brand interaction regression | 8/8 complete click journeys reached their required target states |
| 2026-08-24 | Brand responsive review | dark, light, large text, and 390×844 passed; browser console 0 errors or warnings |
| 2026-08-24 | Dribbble reference review | rendered shot media and creator descriptions inspected; transferable composition/motion principles separated from excluded brand, artwork, layout, and physiological claims |
| 2026-08-24 | Superseded hybrid route regression | 36/36 routes rendered with navigation or exact progress; zero undefined states |
| 2026-08-24 | Superseded hybrid interaction regression | 8/8 complete click journeys reached their required target states; browser diagnostic log empty |
| 2026-08-24 | Superseded hybrid theme review | warm light, dark, large text, 390×844 phone frame, and domain-detail transition passed |
| 2026-08-24 | Structured-dashboard route regression | 36/36 routes rendered with navigation or exact progress; zero undefined states |
| 2026-08-24 | Structured-dashboard interaction regression | 8/8 complete click journeys reached their required target states |
| 2026-08-24 | Structured-dashboard visual review | light, dark, large text, 390×844 phone frame, onboarding, Stats, and Sleep detail passed |
| 2026-08-24 | Structured-dashboard accessibility runtime audit | 36/36 routes: no duplicate IDs, unnamed controls, or sub-44px CSS touch targets |
| 2026-08-24 | Structured-dashboard contrast calculation | 16/16 normal-text token pairs ≥4.5:1 |
| 2026-08-24 | Final syntax/model/dependency checks | JS syntax passed; scoring 13/13; HTTP 200; CSS braces balanced; zero external network references |
| 2026-08-24 | Approved Open Design visual artifact | 12/12 screens reachable; heading/target structure passed; unique IDs passed; JS/CSS checks passed; no external assets or banned effects; tested body contrast ≥4.72:1 |
| 2026-08-24 | Approved visual interaction review | Sleep → Evidence → no-result → Trend → Swim → Privacy passed; swim save and consent toggle passed; navigation centring and heatmap clearance visually confirmed |
| 2026-08-24 | Frozen design/scoring commit | `04563fe chore: freeze approved V1 design and scoring` |
| 2026-08-24 | Flutter static analysis | no issues across app and local packages |
| 2026-08-24 | Production route/flow tests | 12/12 routes; evidence-to-privacy flow; production fail-closed; pt-PT copy passed |
| 2026-08-24 | Production 200% text test | Welcome, Today, Metrics, Sleep, Evidence, and Cycle privacy rendered without overflow |
| 2026-08-24 | Design-system/domain/demo tests | 3/3 + 1/1 + 1/1 passed; token, contrast, target, and provenance assertions |
| 2026-08-24 | Golden regression | 4/4 generated with system Helvetica Neue and rechecked at 390×844 |
| 2026-08-24 | iOS simulator build | Xcode build passed; Runner.app installed/launched on iPhone 17 Pro simulator |
| 2026-08-24 | Android debug build | correctly stopped: Android SDK unavailable on this Mac |
| 2026-08-24 | Phase 6 protocol foundation | 12/12 BLE/sync tests + 11/11 QRing/framing tests + 2/2 capability tests passed; slow/failure/interruption/reconnect/unexpected-firmware cases covered |
| 2026-08-25 | Android toolchain | Android Studio Quail 3 Patch 1; arm64 JDK; SDK Platform 36/37, Build-Tools 36, Platform-Tools 37.0.1, and command-line tools 23 installed |
| 2026-08-25 | Android debug APK | `flutter build apk --debug --dart-define=LIBRERING_DEMO=true` passed; 159 MB; SHA-256 `7f21f8ce898a3c5285f039f0fa93f2335a4ec923771fa8e7cdc96abf4511ce1a` |
| 2026-08-26 | Platform BLE adapter | static analysis passed; 13/13 mobile tests including bounded adapter mapping, explicit multi-ring selection and production no-command pairing flow passed |
| 2026-08-26 | Production BLE builds | unsigned physical-iOS debug build passed; production-mode Android debug APK passed with API 28 minimum and SDK 37 compile target |
| 2026-08-26 | Physical iPhone preflight | Flutter and Xcode detect iPhone 15 Pro Max, iOS 26.5.2; install stopped because Developer Mode is disabled |
| 2026-08-26 | Owned-R12 read-only suite | firmware/battery/time/GATT/config plus full supported history families captured in one run; command checksums and big-data length/CRC passed; live HR/SpO₂ returned valid warm-up packets with no reading |
| 2026-08-26 | R12 decoder verification | 25/25 package tests passed; deterministic synthetic history/big-data fixtures and anonymised physical structural evidence only |
| 2026-08-26 | Gate 2 package/app verification | core 3/3, BLE 12/12, QRing 27/27, demo 1/1, design system 3/3 and mobile 24/24 passed; all analyzers clean |
| 2026-08-26 | Local repository safety | repeated merge, no-data preservation, 400-day retention, corrupt-store fail-closed, identifier-field absence and confirmed deletion passed |
| 2026-08-26 | Production platform builds | signed iOS release and Android debug APK `1.0.0+2` passed; APK SHA-256 `8f25819247194d418857a9dbdfdbc9c2176ad59f75806760170b4dfe5fbaa1ee` |
| 2026-08-26 | Local-network iPhone delivery | release installed over CoreDevice local-network transport; installed-app readback confirmed version `1.0.0`, build `2`; launch unavailable while phone was not foreground-launchable |
| 2026-08-26 | Returning-user sync UX | stored-data launch and in-place Today refresh tests passed; approved demo golden remained pixel-identical; mobile suite 27/27 passed |
| 2026-08-26 | Returning-user UX delivery | signed iOS release and Android debug APK `1.0.0+3` built; APK SHA-256 `969408daf43df1d2a4fb8afa5da280b56bcd02d7c53a049d597a18d74bb77775`; local-network installed-app readback confirmed build `3` |
| 2026-08-26 | Physical sync persistence/idempotency | user-observed initial and repeated syncs both completed with 409 stored records; relaunch preserved the local dataset |
| 2026-08-26 | Refresh discovery regression | targeted 9/9 and full mobile 29/29 tests passed; static analysis clean; connected-device fallback, shared 12-second scan, two bounded no-result scans and multi-ring refusal passed |
| 2026-08-26 | Resilient refresh delivery | signed iOS release and Android debug APK `1.0.0+4` built; APK SHA-256 `aa59fb3c7e61dd0cf9ecca42766358ff9e2b69b51f595b4971719d76cd256da2`; local-network installed-app readback confirmed build `4` |
| 2026-08-26 | Product preview 1.1 application suite | 44/44 mobile tests passed after route, product-journey, export/delete, compact-phone, check-in, and parent-navigation expansion; analyzer clean |
| 2026-08-26 | Product preview golden regression | 8/8 390×844 Helvetica baselines generated and visually inspected |
| 2026-08-26 | Native Appium MCP QA | iPhone 17 Pro simulator / iOS 26.5; XCUITest journey and accessibility readbacks passed with Appium MCP 1.92.6 and WDA 16.8.0 |
| 2026-08-26 | Product preview simulator build | LibreRing `1.1.0 (5)` built, installed, launched, and visually inspected on iPhone 17 Pro simulator |
| 2026-08-26 | Product preview package regression | core 3/3, BLE 12/12, QRing 27/27, demo 1/1, design system 3/3, scoring 13/13 and mobile 44/44 passed; all analyzers clean |
| 2026-08-26 | Product preview native builds | signed production iOS release and production-mode Android debug APK `1.1.0+5` passed; APK SHA-256 `13402cfc8a62e12781ddf216545be8acf3be449d610475427f95c67eb7f62004` |
| 2026-08-26 | Product preview iPhone delivery | local-network install passed; installed-app readback confirmed `1.1.0 (5)`; automatic launch was correctly reported unavailable because the phone was locked |

## Known limitations

- One owned physical COLMI R12 firmware is transport-compatible and its supported
  read-only history structures are decoded. PSG, ECG/reference pulse, oximetry,
  step-reference, and outcome-labelled validation have not been collected, so
  accuracy and score validity remain unproven.
- Flutter 3.47.1 still labels the Android licence status `unknown` because the
  new Android CLI deprecates `sdkmanager --licenses`; that command exits 0 and
  says the option is no longer needed. Gradle separately confirmed the Platform
  36 licence as accepted and the debug APK build passed.
- QRing findings are a desk/app-store audit, not direct task testing in its app.
- Competitor detail can change; sources are dated and should be refreshed for release.
- Synthetic checks establish deterministic face/safety behaviour, not calibration,
  demographic fairness, medical validity, or user comprehension.
- The production app syncs, displays, exports, journals, and separately deletes
  decoded local history. Health bridges, validated scoring execution, continuous
  background BLE, and application-level storage encryption are not implemented.
- Android runtime pairing has not been device-tested; only its manifest,
  production compilation and APK output are verified.
- Physical relaunch/resync persistence and duplicate safety passed with the
  owned ring. Low-battery, timezone-change, daylight-saving, app-contention, and
  partial-history transport cases remain pending. The current fixture establishes
  one ordinary battery response and the observed complete/no-data history shapes
  only. Build 5 is installed, but its physical foreground/R12 smoke pass remains
  pending because the phone was locked during unattended delivery.
- The prototype is interaction-complete but not a usability study with external
  participants or a screen-reader/device-lab certification.
- Penpot remains a verified local auxiliary environment, not the first-gate visual
  source of truth; its bundled MCP plugin reported a 2.17.0/2.17.1 version mismatch.
- The approved visual artifact covers 12 priority screens. The separate 36-route
  functional prototype has not been destructively replaced or visually remapped.

## Next concrete action

With QRing force-closed, unlock the iPhone, open the already-installed LibreRing
1.1.0 (5), and confirm the quiet stale-data refresh against the owned ring. Do
not forget or re-pair the ring unless later diagnostics establish that it is
necessary.
