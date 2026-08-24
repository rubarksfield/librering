# Approved V1 accessibility annotations

- Use semantic headings and route names on every screen.
- Minimum targets are 44 pt on iOS and 48 dp on Android.
- Normal text contrast is at least 4.5:1; large text/non-text UI at least 3:1.
- Charts expose metric, period, range, trend direction, completeness, and selected
  value as text. Gaps are described, not silently interpolated.
- Confidence and provenance use labels plus shape/line treatment, never colour alone.
- Toggles announce label, value, consequence, and whether an additional
  confirmation is required.
- Dynamic type supports 200%; text remains selectable where copying helps.
- Focus order follows visual reading order. Modal focus is trapped and restored.
- Reduced motion removes translation, scale, staged reveal, and chart drawing.
- Haptics are optional and disableable. No critical result relies on haptics.
- Dates, times, durations, units, and decimal separators are localised for English
  and Portuguese (Portugal).
- Decorative ring/chart geometry is excluded from semantics; equivalent text
  remains adjacent or in an explicit semantic label.
