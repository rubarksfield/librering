# Notebook route map

The master brief suggested eight notebooks. To avoid hidden execution state,
their concerns are represented by deterministic modules and outputs:

| Suggested exploration | Reproducible artifact |
| --- | --- |
| Oura model research | `docs/science/oura-model-reconstruction.md` |
| Baseline methods | `src/librering_scoring/baselines.py`, tests |
| Sleep model | `models.py`, `outputs/sleep_sensitivity.csv` |
| Recovery model | `models.py`, `outputs/recovery_sensitivity.csv` |
| Movement model | `models.py`, `outputs/movement_sensitivity.csv` |
| Cycle Context | `models.py`, cycle tests/model card |
| Sensitivity | `run_research.py`, CSV and SVG outputs |
| Scenario validation | synthetic JSONL and `scenario_results.csv` |

If notebooks are added later, they must import these functions and may not become
the only source of a formula or result.

