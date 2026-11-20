# Dataset

Place the ELWVB file `wafer_site_data.csv` in this folder before running the project.

Expected dataset:
- 40,000 wafer sites
- 200 x 200 spatial grid
- 13 columns described in the ELWVB documentation

Expected columns:
`x, y, r, cd, thickness, hotspot, hotspot_mask, E_true, p_defect,
failure, p_mle, p50_mc, p95_mc`

The model-training scripts deliberately exclude target variables and pre-computed
prediction outputs from the predictor set to reduce leakage.

The supplied project currently includes the Monte Carlo 95th-percentile wafer map
as `outputs/mc_p95_map.png`; the raw CSV was not included in the uploaded files.
