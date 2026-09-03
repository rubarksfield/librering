# Autonomous mobile UI QA

Reviewed: 2026-08-26.

## Decision

LibreRing uses two complementary release gates:

1. Deterministic Flutter widget, accessibility, compact-screen, journey, and
   golden-image tests are the repeatable merge gate.
2. Official Appium MCP drives the built iOS application through XCUITest for a
   native exploratory pass over the real accessibility tree.

This keeps release evidence reproducible without pretending that an LLM agent
is a deterministic test oracle. Appium MCP is invoked ephemerally for QA and is
not linked into or distributed with LibreRing.

## Candidate review

| Candidate | Observed fit | Decision |
| --- | --- | --- |
| [AppClaw](https://github.com/appclawhq/AppClaw) | Natural-language Appium loop; supports deterministic YAML as well as an LLM-driven mode. Agent mode adds a model/provider dependency. | Useful later for broad exploratory prompts; not the release gate. |
| [Arbigent](https://github.com/takahirom/arbigent) | Scenario decomposition over XCTest/Appium with a desktop workflow. Strong for reusable, goal-level scenario authoring. | Revisit when the scenario library and device matrix justify another harness. |
| [Appium MCP](https://github.com/appium/appium-mcp) | Official Appium project, embedded XCUITest/UiAutomator2 drivers, accessibility-first locators, screenshots, page source, gestures, and session lifecycle. | Selected for native exploratory QA. |
| [CogniSim](https://github.com/RevylAI/CogniSim) | Accessibility plus visual targeting is promising, but its public iOS-readiness statements are not yet consistent enough for this release gate. | Observe; do not make release claims from it. |

All four repositories were inspected from their upstream project pages. Their
code was not copied into LibreRing.

## Executed iOS pass

Environment:

- LibreRing `1.1.0 (5)`, debug simulator build with deterministic demo data.
- iPhone 17 Pro simulator, iOS 26.5.
- `appium-mcp` 1.92.6 under Apache-2.0.
- XCUITest with WebDriverAgent 16.8.0.

The native pass verified:

- app launch and first meaningful frame;
- all first-run controls discoverable by accessibility identifier;
- Welcome → privacy promise → deterministic pairing → Today;
- Today semantics for the score, explanation, trend action, and three-item
  navigation;
- Today → Trends → manual swim → save, including native readback of
  `Saved locally · Manual source`;
- Trends → You → Data and export;
- You → Journal → Quick check-in → tag/note → save, including keyboard-visible
  and outside-tap-dismissed readbacks and the correct selected You destination;
- native exposure of the separate ring/manual counts, no-identifier statement,
  export control, separate deletion controls, and Cycle Context boundary;
- deletion confirmation and Cancel preserving the manual entry;
- screenshots at Welcome, Today, Journal, and Check-in for human visual inspection.

The pass uses accessibility identifiers and iOS predicate queries before any
coordinate interaction. It does not use image-only targeting or grant an LLM
authority to interpret health data.

## Deterministic coverage

The Flutter suite remains authoritative for:

- every application route rendering;
- production/demo separation and absence of fictional production values;
- no Recovery result when evidence is insufficient;
- 7/30/90-day multi-domain trend rendering with explicit gaps;
- manual swim and check-in persistence;
- JSON/CSV export, SHA-256 manifest, identifier/raw-packet exclusion;
- separate journal and ring-history deletion;
- 320×568 at 130% text and priority routes at 200% text;
- 390×844 Helvetica golden-image regression.

## Reproduction

Build the deterministic simulator app:

```sh
cd apps/mobile
flutter build ios --simulator --debug \
  --dart-define=LIBRERING_DEMO=true
```

Start Appium MCP ephemerally with Node 22 or newer and select an already-created
iOS simulator. Keep the Appium MCP configuration outside the repository; it is
test infrastructure, not an application dependency. The exact session and WDA
ports are intentionally not committed because they are transient machine state.

## Remaining device QA

- Build 5 is installed on the owned iPhone; repeat the journey once the device is
  unlocked and confirm the quiet stale-data refresh against the owned R12.
- Run Android UI automation on a real supported Android phone; current Android
  evidence is compilation only.
- Add VoiceOver and TalkBack human audits. A complete accessibility tree is
  necessary evidence, but it is not equivalent to screen-reader usability.
- Add low-battery, time-zone/DST, app-contention, interrupted-history, and
  overnight sync scenarios when those physical states are available.
