# Questions answered in the app

## Scope and outcome

The user's explanations now belong to the native interface, not only the
conversation. This is an education and presentation change, not new ring
measurement validation. The existing calm sage design is retained.

| Question | Where the answer lives |
| --- | --- |
| What is HRV, and why does it matter? | Today/Vitals → HRV index: visible definition, usefulness and limits; “What is HRV?” opens the longer guide. |
| What does the stress number mean? How is it calculated? | Today/Vitals → Stress index: explanation beside the number, plus a guide covering unknown firmware formula, no verified thresholds, and latest vs period median. |
| Can the active-calorie figure be right? | Vitals and Activity now say “Ring energy value” with unverified units. Activity includes “Can I trust the calorie figure?”; values remain unchanged. Timeline and older presentation models use the same uncertainty boundary. |
| Is 8% the battery? Is it current? | Today: separate “Ring battery 8%” / “Last reported · not live” action. The guide distinguishes ring charge from phone battery, progress, runtime and freshness. |
| Is syncing processing or broken? | Today: “About sync” explains real stages, elapsed time, stalled/partial/failed results and safe next steps. Existing live progress and troubleshooting remain intact. |
| What are the account/subscription words for? | You: concrete local-data summary and “Accounts, costs and your data”. Explains the current absence of accounts/billing/paid tiers without promising future pricing. |
| Where did the welcome introduction go? | You → “Revisit the introduction”. Explains returning-user startup and safely replays the original artwork/privacy story without pairing or resetting data. |

The existing green sleep palette, visible touch-scrubbing instruction and
daily guidance “Why this?” explanation are preserved.

## Implementation files

- `apps/mobile/lib/src/ui/hrv_education.dart`
- `apps/mobile/lib/src/ui/stress_education.dart`
- `apps/mobile/lib/src/ui/calorie_education.dart`
- `apps/mobile/lib/src/ui/ring_status_help.dart`
- `apps/mobile/lib/src/dashboard_screens.dart`
- `apps/mobile/lib/src/analytics_screens.dart`
- `apps/mobile/lib/src/screens.dart`
- `apps/mobile/lib/src/product_system_screens.dart`
- `apps/mobile/lib/src/ring_data_view.dart`
- `apps/mobile/lib/src/ring_product_view.dart`
- `apps/mobile/lib/src/ui/app_chrome.dart`

New explanations are English/Portuguese, scrollable, and respect reduced
motion. Today and shared section headers stack at larger text sizes instead
of squeezing labels beside actions. Action-tile semantics now expose their
tap callback, including introduction replay.

Battery freshness is deliberately conservative: repository merges can retain
the old battery and charging status when a subsequent sync returns neither.
No battery-specific reading timestamp is stored. Capabilities and Ring settings
therefore no longer imply every sync refreshed that information.

## Verification

- `flutter analyze --no-pub`: no issues.
- `flutter build ios --release --no-codesign --no-pub`: passed; unsigned
  `build/ios/iphoneos/Runner.app` built (24.5 MB). This is compile evidence,
  not an installed or signed phone release.
- `flutter test --no-pub --reporter expanded`: **349 passed**, including 39
  new tests this turn (19 metric, 11 battery/sync help, 9 You/replay).
- Existing HRV tests continue to pass; stress-copy expectation updated.
- EN/PT open/dismiss paths, 320×568 at 2× text, 48-point labelled actions,
  reduced motion, no-data and sample modes verified.
- Replay leaves ring history, journal and preferences untouched; normal
  first-time setup still reaches pairing.
- Energy values/chart points and stress sample-median aggregation remain
  unchanged; missing readings are not replaced with zero.
- Current golden renders inspected for Today, syncing, stalled sync, Vitals,
  day timeline, capabilities, HRV, stress, energy guide/summary and You.
  Expected references updated selectively; original welcome unchanged.
- `git diff --check`: clean. Independent review findings on battery freshness
  and misleading active-energy wording were corrected.

See [metric evidence and sources](../science/metric-explanations.md) and
[HRV background](../science/hrv-education.md).

## Boundaries

No new BLE commands, calculations, storage schema, export format, billing,
cloud service or recovery algorithm in this turn. Existing unrelated work
was preserved. No GitHub push or physical-phone installation was performed.
Automated semantics checks are not a full real-device VoiceOver/BLE review.
