# Market and UX research synthesis

Desk audit reviewed 2026-08-23. It used current official product/help material,
app-store listings, current open-source repositories, and peer-reviewed evidence.
No proprietary app binary was downloaded and no screenshot is committed.

## What people open the app to learn

The recurring first questions are simple: did I sleep enough, does today look
normal for me, have I moved in a sustainable way, is the ring synced/charged, and
what changed over time? Premium products answer these with a small number of daily
summaries, then expose contributors and raw trends. QRing's store feedback shows
that inexpensive hardware users also need a more basic promise: can I trust that
last night's data arrived and will it still be there tomorrow?

The first five seconds should therefore show:

1. one plain Daily Signal sentence;
2. Sleep, Recovery, and Movement as separate results with confidence;
3. sync recency and battery without opening device settings;
4. any data limitation before advice.

One tap deeper should answer why. Raw interval pulse, firmware stages, provenance,
and technical coverage belong at Inspect level—not on the opening surface.

## Market patterns

- Oura's contributor hierarchy is learnable, but many scores, health areas, hubs,
  and new features create accumulated surface area.
- Apple Vitals is unusually direct: a typical range, a small set of overnight
  signals, and multi-signal outlier context. Apple Training Load's 7-vs-28-day
  comparison is also legible.
- Whoop's Sleep/Recovery/Strain triad is strong, but colour/number intensity and
  athlete language can turn normal variation into performance judgement.
- RingConn foregrounds broad summaries, stress, reports, and device finding;
  family sharing and cloud protection are different privacy choices from LibreRing.
- Ultrahuman has actionable Sleep/Recovery/Movement ideas but its PowerPlugs,
  biomarkers, longevity, metabolic, AI, and medical-adjacent layers demonstrate
  how a product can become conceptually dense.
- Samsung puts a single Energy Score above broad Health modules, but an account,
  Galaxy phone, cloud, and multi-device handoff are the opposite of no-account
  local simplicity.
- Garmin, Fitbit, Zepp, and Samsung are health super-apps: comprehensive but often
  make a ring user navigate nutrition, coaching, challenges, watch features, or
  device ecosystems unrelated to tonight's data.
- Gadgetbridge is exemplary about local control and device breadth, but its power-
  user information architecture is not a calm consumer daily experience.

## Hardware truth changes the UX

The R12 has vendor claims for pulse, SpO₂, sleep, sport, and steps, and current
open-source support can parse additional firmware streams. None supplies R12
reference-standard validation. Temperature, respiratory rate, raw accelerometer,
R–R intervals, and automatic swim identification are unsupported. Consequently:

- Recovery is deliberately provisional and excludes opaque “HRV” and stress;
- sleep stages are labelled firmware estimates and carry zero score weight;
- swimming is manual/imported and never inferred from waterproofing;
- SpO₂ is an estimate in Inspect, not medical reassurance;
- missing data reduces confidence or produces no result instead of a bad score.

## Swimmer needs

Before: know whether the ring can be worn, but distinguish 1ATM/IP68 from a
validated swim feature. During: the R12 cannot deliver underwater BLE, laps,
strokes, distance, or validated heart rate. After: log/import type, duration,
effort, and optional notes; count it as structured activity; show ring data gaps
honestly; never call the day inactive because steps were unavailable.

## Simplicity decisions

- Three primary destinations: Today, Trends, You. Logging is a clearly labelled
  action from Today, not a permanent destination.
- Device status is a persistent compact control, not a primary tab.
- One Daily Signal sentence, not an unexplained fourth score.
- Three depths: Glance, Explain, Inspect.
- Every estimate carries provenance close to the value.
- Technical and contributor needs are met through Inspect, export, and diagnostics,
  not by making the daily surface a developer console.
- Cycle Context is separately opted in, hidden by default, and separately deleted.

## Excluded from V1 proposal

Fertile window, ovulation/pregnancy inference, general health score, AI coach,
cloud account, social feed, calorie targets, automatic swimming, stage-based sleep
advice, stress diagnosis, blood pressure/glucose, ECG, maps, and subscription
upsells. Research concepts do not become hidden roadmap promises.

## Product implication

LibreRing should feel like a truthful instrument panel, not a cheaper imitation
of a premium ring. Reliability state and uncertainty are first-class product
content. Calmness comes from hierarchy and selective disclosure, not from hiding
data provenance.
