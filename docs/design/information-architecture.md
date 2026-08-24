# Information architecture

## Chosen structure

```text
Today / Trends / You
```

Logging is a labelled `Log` action on Today, not a primary destination. Device
status is a compact header control and appears fully under You → Ring. This keeps
the stable navigation to three destinations while putting swim logging within two
taps and battery within one.

```text
Today
├── Daily Signal
├── Sleep → Explain → Inspect
├── Recovery → Explain → Inspect
├── Movement → Explain → Inspect
├── Log → Swim / workout / check-in / note / period or symptom (if opted in)
├── Ring status → sync / battery / diagnostics
└── relevant issue → recovery flow

Trends
├── Sleep / Recovery / Movement
├── 7 days / 30 days / 6 months
├── Pattern detail → evidence / confidence / provenance
└── journal overlays (explicit, never causal by default)

You
├── Ring → status / sync / unpair / developer mode
├── Data → export / health platforms / delete
├── Privacy → local storage / notifications
├── Cycle Context → opt-in / modes / separate delete
├── Accessibility → text / contrast / motion
└── About → model versions / open-source notices
```

## Cross-cutting depth

- **Glance:** one conclusion and three domain summaries.
- **Explain:** contributors, comparison, confidence, one action.
- **Inspect:** charts, exact values, provenance, formula version, gaps, export.

No screen makes the user choose a depth before seeing the answer. Back navigation
returns to the same day/range.

## Search and history

V1 does not need global search. Trends handles time questions; Log history appears
as an accessible chronological list under the relevant domain and export. This
avoids an empty “History” container that duplicates every domain.

## Conditional domains

Cycle Context is absent from Today and Log until opted in. Developer Mode is
absent until enabled under About. Health-platform settings appear only on a
supported OS. Unsupported R12 capabilities do not produce disabled menu clutter.
