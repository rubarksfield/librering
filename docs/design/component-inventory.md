# Approved V1 component inventory

Every component uses tokens from `design/tokens/tokens.json`. Components render
domain values but do not perform BLE, persistence, or scoring work.

| Design component | Flutter component | Required states |
| --- | --- | --- |
| Phone surface | `LibreRingScaffold` | light, dark-ready, large text, reduced motion |
| Wordmark | `LibreRingWordmark` | standard, compact, semantic label |
| Primary action | `LibreRingPrimaryButton` | enabled, pressed, focused, disabled, loading |
| Quiet action | `LibreRingTextButton` | enabled, focused, disabled |
| Top bar | `LibreRingTopBar` | root, back, status, action |
| Floating navigation | `LibreRingNavigationBar` | Today, Metrics, Trends, Privacy |
| Flat card | `LibreRingCard` | normal, selected, warning, disabled |
| Lead metric | `LeadMetric` | measured, app-derived, no-result, calibrating |
| Metric card | `MetricCard` | measured, firmware-estimated, app-derived, user-entered, imported |
| Confidence label | `ConfidenceLabel` | high, moderate, low, insufficient, calibrating |
| Provenance label | `ProvenanceLabel` | ring, firmware, app, user, imported, unknown |
| Heatmap | `SignalHeatmap` | data, gaps, selected cell, reduced motion |
| Trend chart | `SignalTrendChart` | data, gaps, baseline, selected point, text alternative |
| Sleep continuity | `SleepContinuityChart` | complete, partial, no-result |
| Data row | `EvidenceRow` | primary, supporting, missing, corrected |
| Unsupported state | `NoResultPanel` | unsupported, insufficient, disrupted |
| Segmented control | `LibreRingSegmentedControl` | selected, unselected, focused, disabled |
| Form field | `LibreRingField` | normal, focused, invalid, disabled |
| Privacy switch | `LibreRingPrivacySwitch` | on, off, focused, disabled |
| Ring illustration | `LibreRingArtwork` | welcome, scan, found, unsupported |

Charts expose a semantic summary and never encode essential meaning by colour
alone. All interactive components meet 44 pt iOS and 48 dp Android targets.
