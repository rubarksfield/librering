import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from librering_scoring.baselines import mad, maturity, winsorised_mean


class BaselineTests(unittest.TestCase):
    def test_mad_resists_outlier(self):
        self.assertEqual(mad([10, 10, 11, 11, 200]), 1)

    def test_winsorised_mean_limits_extreme_value(self):
        regular = winsorised_mean([10] * 9 + [1000], 0.1)
        self.assertEqual(regular, 10)

    def test_maturity_recalibrates_after_firmware_change(self):
        state, factor = maturity(40, firmware_changed=True)
        self.assertEqual(state, "Recalibrating")
        self.assertLessEqual(factor, 0.55)


if __name__ == "__main__":
    unittest.main()

