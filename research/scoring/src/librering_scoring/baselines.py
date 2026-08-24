"""Robust baseline helpers used by the research models."""

from __future__ import annotations

from statistics import median


def mad(values: list[float]) -> float | None:
    """Return median absolute deviation, or None for no observations."""
    if not values:
        return None
    centre = median(values)
    return median(abs(value - centre) for value in values)


def winsorised_mean(values: list[float], proportion: float = 0.1) -> float | None:
    """Return a deterministic two-sided winsorised mean."""
    if not values:
        return None
    ordered = sorted(values)
    count = int(len(ordered) * proportion)
    if count:
        low, high = ordered[count], ordered[-count - 1]
        ordered = [min(high, max(low, value)) for value in ordered]
    return sum(ordered) / len(ordered)


def maturity(valid_days: int, firmware_changed: bool = False) -> tuple[str, float]:
    """Return a user-facing baseline state and a 0..1 maturity factor."""
    if firmware_changed:
        return "Recalibrating", min(0.55, valid_days / 42)
    if valid_days < 3:
        return "No baseline", 0.20
    if valid_days < 14:
        return "Learning", 0.35 + valid_days / 70
    if valid_days < 28:
        return "Provisional", 0.55 + (valid_days - 14) / 70
    return "Established", min(1.0, 0.75 + (valid_days - 28) / 120)

