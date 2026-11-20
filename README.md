# ELWVB Semiconductor Wafer Defect Prediction Project

## Project title
**Spatial Defect Prediction and Yield Optimization in Semiconductor Wafer Manufacturing Using the Energy-Landscape Wafer Variation Benchmark (ELWVB)**

## Purpose
This is a portfolio-ready semiconductor process/data-engineering project using the
ELWVB synthetic wafer benchmark. The dataset represents 40,000 sites on a 200 x 200
wafer grid and provides spatial/process variables, ground-truth defect probability,
binary failure outcomes, and Monte Carlo/MLE probability estimates.

The project is designed to demonstrate:
1. Semiconductor manufacturing data understanding
2. Spatial wafer-map analysis
3. Statistical defect/yield analysis
4. Leakage-aware machine-learning modeling
5. Probability calibration and uncertainty analysis
6. Engineering interpretation of defect hotspots
7. Data-driven process monitoring and corrective-action recommendations

## Important distinction
ELWVB is a synthetic benchmark. Results produced by this project must be described
as simulation/benchmark results, not as measurements from a real semiconductor fab.

## Dataset
Place `wafer_site_data.csv` under `data/`.

The documentation describes 13 fields:
x, y, r, cd, thickness, hotspot, hotspot_mask, E_true, p_defect,
failure, p_mle, p50_mc, p95_mc.

For the predictive models, the default feature set is:
`x, y, r, cd, thickness, hotspot, hotspot_mask`

The following are excluded because they are targets or model outputs:
`p_defect, failure, E_true, p_mle, p50_mc, p95_mc`

## Run
```bash
pip install -r requirements.txt
python src/run_project.py
```

Outputs are written to `outputs/`.

## Main analyses
### A. Spatial EDA
- defect probability map
- failure/yield map
- CD and thickness spatial maps
- radial yield analysis
- hotspot comparison

### B. Statistical analysis
- Pearson/Spearman associations
- failure rates by hotspot status
- radial-region failure rates
- calibration of supplied probability estimates

### C. Machine learning
- Logistic Regression baseline
- Random Forest
- Gradient Boosting
- ROC-AUC, PR-AUC, accuracy, precision, recall, F1, Brier score
- confusion matrix
- feature importance

### D. Engineering interpretation
The project treats CD and film thickness as process-related variables and spatial
location as an important source of variation. The analysis asks where defects
concentrate, which process variables are associated with risk, and whether the
predicted probability is reliable enough to support yield monitoring.

## Portfolio framing
A strong final presentation should emphasize:
**process variation -> spatial defect risk -> statistical evidence -> prediction ->
engineering action**

## Suggested final CV bullet
Built a spatial semiconductor wafer defect-prediction framework using the 40,000-site
ELWVB benchmark, combining wafer-map analytics, statistical yield analysis, leakage-aware
machine learning, probability calibration, and feature-importance analysis to identify
defect-prone regions and process variables.

## Data attribution
The ELWVB documentation identifies the benchmark as the Energy-Landscape Wafer
Variation Benchmark and attributes the dataset to Naman Dixit / the corresponding
repository. Retain the dataset's stated license and attribution when redistributing
the data.


## MATLAB DOE + SPC

A dedicated MATLAB implementation is included under `matlab/`.

Run:

```matlab
ELWVB_DOE_SPC
```

It produces the 3x3 retrospective/model-based DOE, interaction analysis,
logistic response surface, X-bar/R charts, p-chart, Cp/Cpk and out-of-control
signal table.

The MATLAB module uses CD variation and thickness variation because these are
available in ELWVB. It does not claim that exposure dose/focus were measured in
the benchmark.
