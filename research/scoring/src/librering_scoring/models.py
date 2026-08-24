"""LibreRing v0.1 research formulas. All functions are deterministic."""

from __future__ import annotations

from math import exp, log
from typing import Any

CALCULATION_VERSION = "0.1.0-research"


def clamp(value: float, low: float = 0.0, high: float = 100.0) -> float:
    return max(low, min(high, value))


def weighted_geometric(contributors: dict[str, tuple[float, float]]) -> float:
    """Bottleneck-aware combination; scores are 0..100, weights are positive."""
    total_weight = sum(weight for _, weight in contributors.values())
    if total_weight <= 0:
        raise ValueError("at least one positive contributor weight is required")
    value = sum(weight * log(max(1.0, score) / 100.0) for score, weight in contributors.values())
    return clamp(100.0 * exp(value / total_weight))


def confidence_label(value: float) -> str:
    if value >= 0.80:
        return "High"
    if value >= 0.60:
        return "Moderate"
    return "Low"


def _result(score: float | None, confidence: float, contributors: dict[str, float],
            missing: list[str], status: str, summary: str, action: str,
            limitations: list[str], baseline_state: str) -> dict[str, Any]:
    return {
        "score": None if score is None else round(score, 1),
        "status": status,
        "confidence": confidence_label(confidence),
        "confidence_value": round(confidence, 3),
        "contributors": {key: round(value, 1) for key, value in contributors.items()},
        "positive_contributors": [key for key, value in contributors.items() if value >= 80],
        "negative_contributors": [key for key, value in contributors.items() if value < 60],
        "missing_contributors": missing,
        "data_completeness": round(1 - len(missing) / max(1, len(contributors) + len(missing)), 3),
        "baseline_maturity": baseline_state,
        "calculation_version": CALCULATION_VERSION,
        "plain_language_summary": summary,
        "reasonable_action": action,
        "limitations": limitations,
    }


def _circular_hour_distance(a: float, b: float) -> float:
    raw = abs(a - b) % 24
    return min(raw, 24 - raw)


def sleep_result(day: dict[str, Any]) -> dict[str, Any]:
    """Answer whether sleep was sufficient, continuous, and appropriately timed."""
    coverage = float(day.get("sleep_coverage", 0.0))
    baseline_state = day.get("baseline_state", "No baseline")
    if not day.get("reliable_sleep_interval", False) or coverage < 0.60:
        return _result(
            None, coverage * 0.45, {}, ["reliable sleep interval"], "No result",
            "There is not enough reliable ring wear to evaluate this sleep period.",
            "Check fit and battery tonight; no score is better than a guess.",
            ["Firmware sleep stages are descriptive only."], baseline_state,
        )

    total = float(day["total_sleep_min"])
    time_in_bed = max(total, float(day.get("time_in_bed_min", total)))
    awake = max(0.0, float(day.get("awake_after_onset_min", time_in_bed - total)))
    midpoint = float(day["sleep_midpoint_hour"])
    baseline_midpoint = float(day.get("baseline_midpoint_hour", midpoint))
    variability = max(0.0, float(day.get("midpoint_variability_min", 30.0)))

    if total < 420:
        duration = clamp(100 - (420 - total) * 0.70)
    elif total <= 540:
        duration = 100.0
    else:
        duration = clamp(100 - (total - 540) * 0.22)

    efficiency = total / time_in_bed
    efficiency_score = clamp((efficiency - 0.70) / 0.20 * 100)
    interruption_score = clamp(100 - max(0, awake - 20) * 1.15)
    continuity = 0.65 * efficiency_score + 0.35 * interruption_score
    timing = clamp(100 - _circular_hour_distance(midpoint, baseline_midpoint) * 22)
    regularity = clamp(100 - max(0, variability - 20) * 0.85)

    values = {
        "duration": duration,
        "continuity": continuity,
        "personal timing": timing,
        "regularity": regularity,
    }
    weighted = weighted_geometric({
        "duration": (duration, 0.45),
        "continuity": (continuity, 0.30),
        "timing": (timing, 0.15),
        "regularity": (regularity, 0.10),
    })
    if weighted >= 85:
        status = "Supportive"
    elif weighted >= 70:
        status = "Steady"
    elif weighted >= 55:
        status = "Limited"
    else:
        status = "Disrupted"

    maturity_factor = float(day.get("baseline_maturity_factor", 0.5))
    confidence = clamp(100 * (0.45 * coverage + 0.25 * maturity_factor
                              + 0.20 * float(day.get("timestamp_reliability", 0.7))
                              + 0.10 * 0.85), 0, 100) / 100
    low = min(values, key=values.get)
    summary = f"Sleep looks {status.lower()}; {low} was the main constraint."
    action = "Protect a sufficient sleep window tonight." if duration < 70 else "Keep the routine that is working."
    return _result(
        weighted, confidence, values, ["validated sleep stages"], status, summary, action,
        ["Sleep stages are ring-firmware estimates and have zero score weight.",
         "This is a wellness interpretation, not a sleep-disorder assessment."],
        baseline_state,
    )


def recovery_result(day: dict[str, Any], sleep: dict[str, Any]) -> dict[str, Any]:
    """Evaluate normal-vs-changed signals without claiming how the person feels."""
    baseline_state = day.get("baseline_state", "No baseline")
    rhr = day.get("overnight_rhr_bpm")
    rhr_baseline = day.get("rhr_baseline_bpm")
    if sleep.get("score") is None and (rhr is None or rhr_baseline is None):
        return _result(
            None, 0.20, {}, ["sleep result", "overnight resting pulse"], "No result",
            "Overnight evidence is too incomplete for a Recovery result.",
            "Use how you feel and try for a complete night of wear.",
            ["R12 HRV and temperature are unavailable for scoring."], baseline_state,
        )

    contributors: dict[str, float] = {}
    weighted: dict[str, tuple[float, float]] = {}
    missing: list[str] = []
    if sleep.get("score") is not None:
        contributors["sleep support"] = float(sleep["score"])
        weighted["sleep"] = (contributors["sleep support"], 0.40)
    else:
        missing.append("sleep support")

    if rhr is not None and rhr_baseline is not None:
        deviation = float(rhr) - float(rhr_baseline)
        contributors["overnight pulse deviation"] = clamp(100 - abs(deviation) * 9)
        weighted["rhr"] = (contributors["overnight pulse deviation"], 0.30)
    else:
        missing.append("overnight pulse deviation")

    load_ratio = max(0.0, float(day.get("recent_load_ratio", 1.0)))
    contributors["recent load balance"] = clamp(100 - abs(load_ratio - 1.0) * 72)
    weighted["load"] = (contributors["recent load balance"], 0.20)

    energy = day.get("subjective_energy")
    if energy is not None:
        contributors["optional check-in"] = clamp((float(energy) - 1) / 4 * 100)
        weighted["checkin"] = (contributors["optional check-in"], 0.10)
    else:
        missing.append("optional check-in")

    hrv_valid = bool(day.get("validated_hrv_semantics", False)) and day.get("hrv_deviation_z") is not None
    if hrv_valid:
        hrv_score = clamp(100 - abs(float(day["hrv_deviation_z"])) * 25)
        contributors["validated HRV deviation"] = hrv_score
        weighted["hrv"] = (hrv_score, 0.15)
    else:
        missing.append("validated HRV")

    score = weighted_geometric(weighted)
    if score >= 82:
        status = "Normal range"
    elif score >= 65:
        status = "Some recovery may help"
    else:
        status = "More recovery may help"

    confidence = (0.24 + 0.20 * float(day.get("sleep_coverage", 0.0))
                  + (0.18 if rhr is not None else 0.0)
                  + (0.15 if hrv_valid else 0.0)
                  + 0.13 * float(day.get("baseline_maturity_factor", 0.5)))
    context = day.get("context")
    if context == "luteal":
        summary = "Signals differ from usual; a logged luteal phase is relevant physiological context."
    elif context == "pregnancy":
        summary = "Pregnancy mode shows trends without comparing this day to a pre-pregnancy norm."
        status = "Trend only"
        score = None
    elif context == "illness":
        summary = "You logged illness; the app will prioritise rest and avoid performance judgement."
    elif load_ratio > 1.35:
        summary = "Recent load was above your usual range; that can temporarily lower Recovery."
    else:
        low = min(contributors, key=contributors.get)
        summary = f"Available signals are {status.lower()}; {low} changed most."

    action = ("Use the trend as context and follow clinical guidance for any concern."
              if score is None else
              "Choose an easier day if that matches how you feel."
              if score < 82 else "Your usual plan looks reasonable if you feel well.")
    return _result(
        score, min(1.0, confidence), contributors, missing, status, summary, action,
        ["The R12 firmware HRV byte and stress index are excluded.",
         "Temperature and respiratory rate are unsupported on R12.",
         "Recovery is not a diagnosis or a statement of subjective feeling."],
        baseline_state,
    )


def movement_result(day: dict[str, Any]) -> dict[str, Any]:
    """Reward sustainable movement, breaks, and structured activity—not maximum load."""
    baseline_state = day.get("baseline_state", "No baseline")
    if day.get("context") == "illness" and bool(day.get("rest_day", False)):
        return _result(
            None, 0.75, {}, [], "Rest protected",
            "A rest day during logged illness is not graded as poor Movement.",
            "Rest and resume gradually when it fits how you feel.",
            ["No movement score is issued for this protected day."], baseline_state,
        )

    steps = max(0.0, float(day.get("steps", 0)))
    step_baseline = max(1000.0, float(day.get("step_baseline", 7000)))
    step_ratio = steps / step_baseline
    if step_ratio <= 1:
        general = clamp(25 + step_ratio * 75)
    elif step_ratio <= 1.8:
        general = 100.0
    else:
        general = clamp(100 - (step_ratio - 1.8) * 28)
    if day.get("workout_type") == "swimming" and day.get("workout_source") in {"manual", "imported"}:
        # Underwater steps are not observable on this hardware profile. A known
        # swim prevents the general-movement contributor from treating absence
        # of ring steps as inactivity; it does not award maximal movement.
        general = max(general, 80.0)

    inactive_hours = max(0.0, float(day.get("inactive_hours", 10)))
    inactivity = 100.0 if inactive_hours <= 8 else clamp(100 - (inactive_hours - 8) * 15)
    weekly_minutes = max(0.0, float(day.get("structured_minutes_7d", 0)))
    training = clamp(35 + weekly_minutes / 150 * 65)
    load_ratio = max(0.0, float(day.get("recent_load_ratio", 1.0)))
    load = clamp(100 - abs(load_ratio - 1.0) * 70)

    contributors = {
        "general movement": general,
        "inactive time": inactivity,
        "structured activity": training,
        "load balance": load,
    }
    score = weighted_geometric({
        "movement": (general, 0.40),
        "inactivity": (inactivity, 0.25),
        "training": (training, 0.20),
        "load": (load, 0.15),
    })
    status = "Sustainable" if score >= 80 else "Building" if score >= 60 else "Light"
    confidence = (0.30 + 0.30 * float(day.get("activity_coverage", 0.8))
                  + 0.15 * float(day.get("baseline_maturity_factor", 0.5))
                  + (0.15 if day.get("workout_source") in {"manual", "imported", "ring"} else 0.05))
    if day.get("workout_type") == "swimming":
        summary = "The logged swim counts as structured activity; missing underwater ring data is not inactivity."
    elif load_ratio > 1.5:
        summary = "Movement was high, but load balance suggests an easier day may support sustainability."
    else:
        low = min(contributors, key=contributors.get)
        summary = f"Movement looks {status.lower()}; {low} has the most room."
    return _result(
        score, min(1.0, confidence), contributors, [], status, summary,
        "A short movement break is useful if practical." if inactivity < 70 else "Keep the pattern sustainable.",
        ["Steps are a firmware estimate.", "Calories are not used.",
         "Swimming needs a manual or imported record; R12 does not identify sessions."],
        baseline_state,
    )
