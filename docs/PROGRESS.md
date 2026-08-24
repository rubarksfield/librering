# LibreRing progress

Last updated: 2026-08-24

## Current status

`IMPLEMENTATION`

- Visual direction: **approved for V1 on 2026-08-24**
- Scoring model: **approved for V1 on 2026-08-24**
- Design/scoring freeze: **complete in commit `04563fe`**
- Phase 5 production foundation: **complete and verified**

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

## In progress

- Phase 6 platform BLE adapter and physical command-fixture acquisition.

## Blocked

- Android native compilation is machine-blocked before Gradle because no Android
  SDK is installed. Licence acceptance is a user-controlled external gate.
- Physical COLMI R12 behavior remains unverified because no owned device or
  packet capture is available.

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

## Known limitations

- No owned physical COLMI R12, firmware capture, PSG, ECG, oximetry, or outcome-
  labelled cohort was available. Hardware accuracy and score validity are unproven.
- QRing findings are a desk/app-store audit, not direct task testing in its app.
- Competitor detail can change; sources are dated and should be refreshed for release.
- Synthetic checks establish deterministic face/safety behaviour, not calibration,
  demographic fairness, medical validity, or user comprehension.
- Phase 5 is a production-code foundation, not a complete device application.
  Platform BLE, device commands, database, health bridges, scoring execution,
  export, and deletion are not implemented yet.
- Low-battery and partial-history transport fixtures are intentionally pending:
  no proven R12 battery response or history end/partial sentinel is available,
  so the test layer does not invent either packet shape.
- The prototype is interaction-complete but not a usability study with external
  participants or a screen-reader/device-lab certification.
- Penpot remains a verified local auxiliary environment, not the first-gate visual
  source of truth; its bundled MCP plugin reported a 2.17.0/2.17.1 version mismatch.
- The approved visual artifact covers 12 priority screens. The separate 36-route
  functional prototype has not been destructively replaced or visually remapped.

## Next concrete action

Wire the audited platform BLE adapter only after the Android/licence gate, then
capture consented physical R12 fixtures before enabling any command payload.
