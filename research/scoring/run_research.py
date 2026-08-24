#!/usr/bin/env python3
"""Generate deterministic synthetic data, results, sensitivity, and SVG charts."""

from __future__ import annotations

import csv
import json
import random
import sys
from copy import deepcopy
from datetime import date, timedelta
from pathlib import Path
from statistics import median

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "src"))

from librering_scoring.baselines import maturity  # noqa: E402
from librering_scoring.models import movement_result, recovery_result, sleep_result  # noqa: E402

SEED = 1729
SCENARIOS = [
    "consistent_good_sleep", "chronic_short_sleep", "one_short_night", "several_short_nights",
    "long_fragmented_sleep", "late_consistent_sleep", "shift_worker", "jet_lag",
    "high_overnight_heart_rate", "low_hrv", "improving_hrv", "temperature_elevation",
    "missing_temperature", "missing_heart_rate", "partial_sleep", "no_ring_wear",
    "hard_workout", "swimming_day", "strength_day", "excessive_load", "extended_inactivity",
    "illness", "alcohol", "late_meal", "normal_cycle", "irregular_cycle",
    "hormonal_contraception", "follicular_phase", "luteal_phase", "user_declared_pregnancy",
    "perimenopause_symptoms", "low_baseline_maturity", "new_device_firmware_change",
]
PROFILES = (
    "typical_schedule", "late_chronotype", "rotating_shift", "endurance_training",
    "lower_mobility_pattern", "cycle_context",
)


def base_day(index: int, rng: random.Random, profile: str = "typical_schedule") -> dict:
    state, factor = maturity(index + 1)
    day = {
        "profile": profile,
        "date": str(date(2026, 1, 1) + timedelta(days=index)),
        "reliable_sleep_interval": True,
        "sleep_coverage": round(rng.uniform(0.91, 0.99), 3),
        "total_sleep_min": round(rng.gauss(455, 15), 1),
        "time_in_bed_min": round(rng.gauss(500, 18), 1),
        "awake_after_onset_min": round(max(10, rng.gauss(30, 6)), 1),
        "sleep_midpoint_hour": round(rng.gauss(3.25, 0.18), 3),
        "baseline_midpoint_hour": 3.25,
        "midpoint_variability_min": round(max(10, rng.gauss(25, 5)), 1),
        "timestamp_reliability": 0.85,
        "baseline_state": state,
        "baseline_maturity_factor": round(factor, 3),
        "overnight_rhr_bpm": round(rng.gauss(58, 1.5), 1),
        "rhr_baseline_bpm": 58,
        "recent_load_ratio": round(rng.gauss(1.0, 0.07), 3),
        "subjective_energy": 4,
        "validated_hrv_semantics": False,
        "hrv_deviation_z": None,
        "steps": int(rng.gauss(7600, 800)),
        "step_baseline": 7500,
        "inactive_hours": round(rng.gauss(8.7, 0.6), 2),
        "structured_minutes_7d": round(rng.gauss(165, 20), 1),
        "activity_coverage": 0.94,
        "workout_source": "ring",
        "workout_type": "walking",
        "context": None,
        "rest_day": False,
        "synthetic": True,
    }
    if profile == "late_chronotype":
        day["sleep_midpoint_hour"] = round(rng.gauss(5.5, 0.18), 3)
        day["baseline_midpoint_hour"] = 5.5
    elif profile == "rotating_shift":
        day["sleep_midpoint_hour"] = 12.5
        day["baseline_midpoint_hour"] = 12.5
        day["midpoint_variability_min"] = 110
    elif profile == "endurance_training":
        day["overnight_rhr_bpm"] = round(rng.gauss(50, 1.2), 1)
        day["rhr_baseline_bpm"] = 50
        day["steps"], day["step_baseline"] = int(rng.gauss(11000, 900)), 10800
        day["structured_minutes_7d"] = round(rng.gauss(310, 25), 1)
    elif profile == "lower_mobility_pattern":
        day["steps"], day["step_baseline"] = int(rng.gauss(3600, 450)), 3500
        day["structured_minutes_7d"] = round(rng.gauss(90, 15), 1)
        day["inactive_hours"] = round(rng.gauss(10.5, 0.6), 2)
    elif profile == "cycle_context":
        day["context"] = "follicular"
    return day


def apply_scenario(day: dict, scenario: str, index: int) -> None:
    last = index == 89
    recent = index >= 85
    if scenario == "chronic_short_sleep":
        day["total_sleep_min"], day["time_in_bed_min"] = 330, 380
    elif scenario == "one_short_night" and last:
        day["total_sleep_min"], day["time_in_bed_min"] = 300, 350
    elif scenario == "several_short_nights" and recent:
        day["total_sleep_min"], day["time_in_bed_min"] = 360 - (index - 85) * 12, 410
    elif scenario == "long_fragmented_sleep":
        day["total_sleep_min"], day["time_in_bed_min"], day["awake_after_onset_min"] = 500, 660, 150
    elif scenario == "late_consistent_sleep":
        day["sleep_midpoint_hour"], day["baseline_midpoint_hour"], day["midpoint_variability_min"] = 6.0, 6.0, 15
    elif scenario == "shift_worker":
        day["sleep_midpoint_hour"], day["baseline_midpoint_hour"] = (13.0, 13.0) if index % 4 else (3.0, 13.0)
        day["midpoint_variability_min"] = 150
    elif scenario == "jet_lag" and recent:
        day["sleep_midpoint_hour"] = 8.0 - (index - 85) * 0.6
    elif scenario == "high_overnight_heart_rate" and recent:
        day["overnight_rhr_bpm"] = 68
    elif scenario == "low_hrv":
        day["hrv_deviation_z"] = -2.0
    elif scenario == "improving_hrv":
        day["hrv_deviation_z"] = -1.5 + index / 45
    elif scenario == "temperature_elevation":
        day["temperature_deviation_c"] = 0.8
    elif scenario == "missing_temperature":
        day["temperature_deviation_c"] = None
    elif scenario == "missing_heart_rate" and recent:
        day["overnight_rhr_bpm"] = None
    elif scenario == "partial_sleep" and last:
        day["sleep_coverage"], day["reliable_sleep_interval"] = 0.55, False
    elif scenario == "no_ring_wear" and last:
        day["sleep_coverage"], day["reliable_sleep_interval"], day["activity_coverage"] = 0, False, 0
        day["overnight_rhr_bpm"], day["steps"] = None, 0
    elif scenario == "hard_workout" and last:
        day["recent_load_ratio"], day["structured_minutes_7d"] = 1.55, 260
    elif scenario == "swimming_day" and last:
        day["workout_type"], day["workout_source"], day["structured_minutes_7d"] = "swimming", "manual", 220
        day["steps"] = 3200
    elif scenario == "strength_day" and last:
        day["workout_type"], day["workout_source"], day["structured_minutes_7d"] = "strength", "manual", 220
    elif scenario == "excessive_load" and recent:
        day["recent_load_ratio"], day["structured_minutes_7d"] = 2.1, 480
    elif scenario == "extended_inactivity":
        day["inactive_hours"], day["steps"] = 14, 2800
    elif scenario == "illness" and recent:
        day["context"], day["rest_day"], day["steps"] = "illness", True, 1100
        day["overnight_rhr_bpm"] = 65
    elif scenario == "alcohol" and last:
        day["context"], day["overnight_rhr_bpm"], day["awake_after_onset_min"] = "alcohol", 66, 80
    elif scenario == "late_meal" and last:
        day["context"], day["overnight_rhr_bpm"] = "late meal", 64
    elif scenario in {"normal_cycle", "follicular_phase"}:
        day["context"] = "follicular"
    elif scenario == "irregular_cycle":
        day["context"] = "cycle unknown"
    elif scenario == "hormonal_contraception":
        day["context"] = "hormonal contraception"
    elif scenario == "luteal_phase" and recent:
        day["context"], day["overnight_rhr_bpm"] = "luteal", 62
        day["temperature_deviation_c"] = 0.5
    elif scenario == "user_declared_pregnancy":
        day["context"], day["overnight_rhr_bpm"] = "pregnancy", 65
    elif scenario == "perimenopause_symptoms":
        day["context"] = "perimenopause symptoms"
    elif scenario == "low_baseline_maturity":
        state, factor = maturity(min(index + 1, 8))
        day["baseline_state"], day["baseline_maturity_factor"] = state, factor
    elif scenario == "new_device_firmware_change" and recent:
        state, factor = maturity(index - 84, firmware_changed=True)
        day["baseline_state"], day["baseline_maturity_factor"] = state, factor


def score_day(day: dict) -> dict:
    sleep = sleep_result(day)
    recovery = recovery_result(day, sleep)
    movement = movement_result(day)
    return {"sleep": sleep, "recovery": recovery, "movement": movement}


def write_jsonl(path: Path, rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def sensitivity_rows(domain: str, baseline: dict, changes: list[tuple[str, object]]) -> list[dict]:
    base_scores = score_day(baseline)
    base = base_scores[domain]["score"]
    rows = []
    for field, value in changes:
        changed = deepcopy(baseline)
        changed[field] = value
        result = score_day(changed)[domain]
        rows.append({"input": field, "value": value, "score": result["score"],
                     "delta": None if base is None or result["score"] is None else round(result["score"] - base, 1),
                     "confidence": result["confidence_value"]})
    return rows


def write_csv(path: Path, rows: list[dict]) -> None:
    fields = list(rows[0])
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def write_svg(path: Path, rows: list[dict], title: str) -> None:
    valid = [row for row in rows if row.get("delta") is not None]
    width, height = 900, 80 + len(valid) * 38
    bars = []
    for index, row in enumerate(valid):
        y = 62 + index * 38
        delta = float(row["delta"])
        x0 = 580
        x1 = x0 + delta * 8
        x = min(x0, x1)
        bar_width = max(2, abs(x1 - x0))
        colour = "#B8533E" if delta < 0 else "#397A68"
        bars.append(f'<text x="20" y="{y + 14}" font-size="14">{row["input"]}: {row["value"]}</text>')
        bars.append(f'<rect x="{x:.1f}" y="{y}" width="{bar_width:.1f}" height="18" fill="{colour}" rx="4"/>')
        bars.append(f'<text x="{x1 + (6 if delta >= 0 else -42):.1f}" y="{y + 14}" font-size="12">{delta:+.1f}</text>')
    content = "".join(bars)
    path.write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">'
        f'<rect width="100%" height="100%" fill="#F6F3EC"/><text x="20" y="32" font-size="21" font-family="sans-serif">{title}</text>'
        f'<line x1="580" y1="48" x2="580" y2="{height - 15}" stroke="#5F615D"/>{content}</svg>',
        encoding="utf-8",
    )


def main() -> None:
    rng = random.Random(SEED)
    synthetic_dir = ROOT / "synthetic_data"
    output_dir = ROOT / "outputs"
    synthetic_dir.mkdir(exist_ok=True)
    output_dir.mkdir(exist_ok=True)
    all_rows: list[dict] = []
    results: list[dict] = []
    for scenario_index, scenario in enumerate(SCENARIOS):
        profile = PROFILES[scenario_index % len(PROFILES)]
        for index in range(90):
            day = base_day(index, rng, profile)
            day["scenario"] = scenario
            apply_scenario(day, scenario, index)
            all_rows.append(day)
            scored = score_day(day)
            results.append({
                "scenario": scenario, "day": index + 1, "date": day["date"],
                "sleep_score": scored["sleep"]["score"], "sleep_confidence": scored["sleep"]["confidence_value"],
                "recovery_score": scored["recovery"]["score"], "recovery_confidence": scored["recovery"]["confidence_value"],
                "movement_score": scored["movement"]["score"], "movement_confidence": scored["movement"]["confidence_value"],
                "recovery_summary": scored["recovery"]["plain_language_summary"],
                "movement_status": scored["movement"]["status"],
            })
    write_jsonl(synthetic_dir / "scenarios.jsonl", all_rows)
    write_csv(output_dir / "scenario_results.csv", results)

    summaries = []
    for scenario in SCENARIOS:
        selected = [row for row in results if row["scenario"] == scenario]
        for domain in ("sleep", "recovery", "movement"):
            scores = [float(row[f"{domain}_score"]) for row in selected if row[f"{domain}_score"] is not None]
            daily_changes = [abs(b - a) for a, b in zip(scores, scores[1:])]
            summaries.append({
                "scenario": scenario, "domain": domain,
                "day_90_score": selected[-1][f"{domain}_score"],
                "median_score": round(median(scores), 1) if scores else None,
                "median_daily_absolute_change": round(median(daily_changes), 2) if daily_changes else None,
                "max_daily_absolute_change": round(max(daily_changes), 2) if daily_changes else None,
            })
    write_csv(output_dir / "scenario_summaries.csv", summaries)

    baseline = base_day(89, random.Random(SEED))
    suites = {
        "sleep": [("total_sleep_min", value) for value in (300, 360, 420, 480, 600)]
                 + [("sleep_coverage", value) for value in (0.5, 0.7, 0.95)],
        "recovery": [("overnight_rhr_bpm", value) for value in (52, 58, 64, 70)]
                    + [("recent_load_ratio", value) for value in (0.4, 1.0, 1.6, 2.2)]
                    + [("overnight_rhr_bpm", None)],
        "movement": [("steps", value) for value in (1000, 4000, 7500, 14000, 22000)]
                    + [("inactive_hours", value) for value in (6, 9, 12, 15)],
    }
    for domain, changes in suites.items():
        rows = sensitivity_rows(domain, baseline, changes)
        write_csv(output_dir / f"{domain}_sensitivity.csv", rows)
        write_svg(output_dir / f"{domain}_sensitivity.svg", rows, f"{domain.title()} v0.1 sensitivity from baseline")

    manifest = {
        "seed": SEED,
        "scenario_count": len(SCENARIOS),
        "days_per_scenario": 90,
        "records": len(all_rows),
        "profiles": list(PROFILES),
        "synthetic_only": True,
        "calculation_version": "0.1.0-research",
    }
    (output_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, sort_keys=True))


if __name__ == "__main__":
    main()
