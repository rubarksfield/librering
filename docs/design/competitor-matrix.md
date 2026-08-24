# Competitor matrix

Reviewed: 2026-08-23. This is a source-backed desk audit of current public
materials, not direct usability testing of every signed-in app build.

| Product | Opening model | Strength worth learning from | Density / limitation | LibreRing implication |
| --- | --- | --- | --- | --- |
| Oura | Three intent-led views: timely Today, detailed Vitals, long-term My Health | strong narrative compression, progressive disclosure, baselines, tags, and mature trends | broad feature accumulation; formulas partly opaque; membership/account; several unsupported R12 concepts | keep LibreRing's distinct Today / Trends / You structure, but make Glance → Explain → Inspect and daily-to-long-term flow more legible |
| RingConn | broad wellness summaries, sleep/activity/stress | reports, notes, device locating, accessible ring framing | many summary surfaces; cloud/family sharing are different trust model | local reports and find-ring without account/share defaults |
| Ultrahuman | Sleep Index, Dynamic Recovery, Movement, PowerPlugs | active recommendations and modular specialised views | biomarkers, plugins, AI, longevity and medical-adjacent concepts overload | no plugin marketplace or AI on daily surface |
| Samsung Health + Galaxy Ring | Energy Score inside health super-app | polished overview and cross-device continuity | account/Galaxy/cloud; super-app modules; one total score can conceal causes | no account; no all-domain score; visible contributors |
| Whoop | Sleep, Recovery, Strain | memorable triad, journal impacts, personal HRV | intense athlete framing, 0–100/colour judgement, membership | calmer labels; hard workouts are context, not unhealthy |
| Apple Health/Vitals | metric records plus compact Vitals typical range | provenance, typical range, multi-signal outlier gate, accessibility | fragmented across Health/Fitness/Watch; supported hardware varies | typical-range language and source records in one ring-focused shell |
| Garmin Connect | training/readiness/body-battery ecosystem | deep training context and long-term load | dense, watch/sport-first, many overlapping readiness concepts | only one load view and one action per day |
| Fitbit | Today metrics and readiness/sleep summaries | approachable cards and broad platform integrations | premium segmentation and dashboard breadth | glanceable cards without paywall or unrelated modules |
| Amazfit/Zepp | readiness plus health/device ecosystem | low-cost hardware experience and device control | metric volume and opaque composites | device controls separate; unsupported numbers absent |
| QRing | many health/device modules around low-cost ring | inexpensive direct pairing and broad raw access | weak hierarchy, translation, sync/history reliability and trust explanations | sync truth first; smaller vocabulary; confidence/provenance |
| Gadgetbridge | device dashboards and power-user controls | local-first, no account, broad device support and export ethos | technical density and device-driven navigation | preserve local control behind a consumer-first Today surface |
| openring/PulseLoop | developer-oriented protocol/domain demos | capability declarations, fixtures, stable IDs, source layers | experimental semantics can still look authoritative | show capability maturity and semantic certainty explicitly |

## Five differentiators

1. No account or cloud is needed for core use.
2. A result and its confidence are separate.
3. Measured, firmware-estimated, app-derived, imported, and user-entered records
   are visibly different.
4. Cheap-hardware limitations are explained at the point of use.
5. Formulas and calculation versions are inspectable and reproducible.

Sources and review limitations are in [`research-sources.md`](research-sources.md).

## 2026-08-24 Oura interface refresh

The supplied October 2024 launch article and 96-second product film were reviewed
as interaction and storytelling references, not templates. Transferable lessons:

- organise breadth by user intent rather than one tab per metric;
- surface one timely conclusion before deeper measures;
- make the route from daily context to detailed evidence to long-term pattern
  visible;
- use typography, negative space, and motion to teach hierarchy rather than add
  decorative density.

Excluded source-specific elements include the Oura mark, score rings/gauges,
Today / Vitals / My Health labels, exact blue-green screens, tree iconography,
stacked contributor treatment, automatic activity claims, fertility-window
presentation, screenshots, motion sequences, and copy.
