# Approved V1 design-to-code map

| Approved source | Production target | Ownership boundary |
| --- | --- | --- |
| `design/tokens/tokens.json` | `packages/ring_design_system/lib/src/tokens.dart` | colours, spacing, radius, type, motion |
| Wordmark/ring SVG grammar | `LibreRingWordmark`, `LibreRingArtwork` | design system only |
| Flat cards/buttons/fields | `LibreRingCard`, `LibreRingPrimaryButton`, `LibreRingField` | design system only |
| Heatmap/trend/continuity charts | app-owned chart widgets | semantic records in; no scoring inside widget |
| Welcome/privacy/pairing | mobile feature routes | driver/repository through interfaces |
| Today/Metrics | mobile feature routes | immutable summary view models |
| Sleep/Evidence/No result | mobile feature routes | scoring/evidence records, never packets |
| Trend/Swim | mobile feature routes | query/journal interfaces |
| Cycle privacy | mobile feature route | separate sensitive-data repository |
| Prototype motion | `LibreRingMotion` + platform reduced-motion | no semantic dependence on animation |

Package dependency direction:

```text
apps/mobile → ring_design_system + feature/domain interfaces
ring_design_system → Flutter only
ring_ble / ring_colmi_qring → ring_core
ring_data / ring_scoring / ring_insights → ring_core
ring_health_bridge → validated ring_core records
```

The production implementation may deviate for platform constraints only when the
change is recorded in a design-QA comparison and preserves hierarchy, semantics,
accessibility, and safety.
