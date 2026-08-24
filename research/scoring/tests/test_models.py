import sys
import unittest
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from librering_scoring.models import movement_result, recovery_result, sleep_result


def normal_day():
    return {
        "reliable_sleep_interval": True, "sleep_coverage": 0.96,
        "total_sleep_min": 465, "time_in_bed_min": 505, "awake_after_onset_min": 30,
        "sleep_midpoint_hour": 3.3, "baseline_midpoint_hour": 3.2,
        "midpoint_variability_min": 25, "timestamp_reliability": 0.9,
        "baseline_state": "Established", "baseline_maturity_factor": 0.9,
        "overnight_rhr_bpm": 58, "rhr_baseline_bpm": 58, "recent_load_ratio": 1.0,
        "subjective_energy": 4, "validated_hrv_semantics": False, "hrv_deviation_z": None,
        "steps": 7600, "step_baseline": 7500, "inactive_hours": 8.5,
        "structured_minutes_7d": 170, "activity_coverage": 0.95,
        "workout_source": "ring", "workout_type": "walking", "context": None,
        "rest_day": False,
    }


class ModelBehaviourTests(unittest.TestCase):
    def test_one_poor_night_lowers_sleep_meaningfully(self):
        normal = normal_day()
        poor = deepcopy(normal)
        poor.update(total_sleep_min=300, time_in_bed_min=350)
        self.assertGreater(sleep_result(normal)["score"] - sleep_result(poor)["score"], 25)

    def test_one_poor_night_does_not_rewrite_baseline(self):
        day = normal_day()
        original_midpoint = day["baseline_midpoint_hour"]
        poor = deepcopy(day)
        poor["total_sleep_min"] = 300
        sleep_result(poor)
        self.assertEqual(day["baseline_midpoint_hour"], original_midpoint)

    def test_several_short_nights_progressively_lower_balance_proxy(self):
        scores = []
        for minutes in (420, 390, 360, 330):
            day = normal_day()
            day["total_sleep_min"] = minutes
            day["time_in_bed_min"] = max(430, minutes + 40)
            scores.append(sleep_result(day)["score"])
        self.assertEqual(scores, sorted(scores, reverse=True))

    def test_missing_hrv_reduces_confidence_not_score(self):
        day = normal_day()
        missing_sleep = sleep_result(day)
        missing = recovery_result(day, missing_sleep)
        validated = deepcopy(day)
        validated["validated_hrv_semantics"] = True
        validated["hrv_deviation_z"] = 0.0
        with_hrv = recovery_result(validated, sleep_result(validated))
        self.assertGreater(with_hrv["confidence_value"], missing["confidence_value"])
        self.assertGreaterEqual(missing["score"], 70)

    def test_hard_workout_can_lower_recovery_without_unhealthy_label(self):
        day = normal_day()
        base = recovery_result(day, sleep_result(day))
        day["recent_load_ratio"] = 1.6
        hard = recovery_result(day, sleep_result(day))
        self.assertLess(hard["score"], base["score"])
        self.assertNotIn("unhealthy", hard["plain_language_summary"].lower())

    def test_illness_rest_does_not_damage_movement(self):
        day = normal_day()
        day.update(context="illness", rest_day=True, steps=200)
        result = movement_result(day)
        self.assertIsNone(result["score"])
        self.assertEqual(result["status"], "Rest protected")

    def test_luteal_change_does_not_trigger_illness_language(self):
        day = normal_day()
        day.update(context="luteal", overnight_rhr_bpm=63, temperature_deviation_c=0.6)
        result = recovery_result(day, sleep_result(day))
        self.assertIn("luteal", result["plain_language_summary"])
        self.assertNotIn("illness", result["plain_language_summary"])

    def test_pregnancy_does_not_use_prepregnancy_judgement(self):
        day = normal_day()
        day.update(context="pregnancy", overnight_rhr_bpm=67)
        result = recovery_result(day, sleep_result(day))
        self.assertEqual(result["status"], "Trend only")
        self.assertIsNone(result["score"])
        self.assertIn("without comparing", result["plain_language_summary"])

    def test_incomplete_sleep_fails_closed(self):
        day = normal_day()
        day.update(reliable_sleep_interval=False, sleep_coverage=0.4)
        self.assertIsNone(sleep_result(day)["score"])

    def test_swim_counts_without_ring_steps(self):
        day = normal_day()
        day.update(workout_type="swimming", workout_source="manual", steps=1000,
                   structured_minutes_7d=240)
        result = movement_result(day)
        self.assertIn("swim", result["plain_language_summary"].lower())
        self.assertGreaterEqual(result["contributors"]["general movement"], 80)
        self.assertGreater(result["contributors"]["structured activity"], 90)


if __name__ == "__main__":
    unittest.main()
