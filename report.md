# Spatial Defect Prediction, DOE and Statistical Process Control for Semiconductor Wafer Manufacturing Using ELWVB

## 1. Executive Summary

This project develops a data-driven semiconductor wafer defect and yield analysis
framework using the Energy-Landscape Wafer Variation Benchmark (ELWVB). ELWVB is a
synthetic benchmark representing 40,000 sites on a 200 x 200 wafer grid. It contains
spatial coordinates, process-related variables such as critical dimension (CD) and
film thickness, an energy-landscape variable, ground-truth defect probability, and
binary failure outcomes.

The engineering objective is to identify spatial and process-variable patterns
associated with wafer failure and to evaluate machine-learning models for site-level
failure prediction.

**Important:** ELWVB is synthetic. The results from this project should be presented
as benchmark/simulation findings rather than real fab production measurements.

## 2. Dataset and Variables

The main dataset is `wafer_site_data.csv`.

Primary variables:
- x, y: normalized wafer coordinates
- r: normalized radial distance
- cd: critical-dimension variation
- thickness: film-thickness variation
- hotspot / hotspot_mask: defect-prone-region information
- E_true: underlying energy-landscape value
- p_defect: ground-truth defect probability
- failure: simulated binary failure
- p_mle: MLE probability estimate
- p50_mc: Monte Carlo median probability
- p95_mc: Monte Carlo 95th-percentile probability

For predictive modeling, the project uses x, y, r, cd, thickness, hotspot and
hotspot_mask. `failure` is the response variable. Ground-truth and pre-computed
prediction columns are excluded from the main model to reduce information leakage.

## 3. Problem Statement

Semiconductor wafer manufacturing requires control of spatial and process variation.
A uniform average defect rate can hide localized high-risk regions. The project
therefore asks:

1. Where are defects concentrated across the wafer?
2. How are CD and film-thickness variation associated with defect probability?
3. Does hotspot membership correspond to higher failure risk?
4. Can site-level failure be predicted from process/spatial variables?
5. Which variables contribute most strongly to predictive performance?
6. How reliable are the predicted probabilities for risk-based monitoring?

## 4. Methodology

### 4.1 Spatial exploratory analysis
Generate wafer maps for:
- ground-truth defect probability
- binary failure
- CD
- film thickness

The supplied `mc_p95_map.png` is also retained as a Monte Carlo uncertainty
visualization.

### 4.2 Statistical analysis
Calculate:
- overall failure rate
- mean ground-truth defect probability
- failure rate by radial region
- failure rate by hotspot status
- Spearman correlations among spatial/process variables and targets

### 4.3 Machine learning
Compare:
- Logistic Regression
- Random Forest
- Gradient Boosting

Evaluation metrics:
- ROC-AUC
- PR-AUC
- accuracy
- precision
- recall
- F1
- Brier score

### 4.4 Model interpretation
Use permutation importance to identify variables that materially affect ROC-AUC.

### 4.5 Probability calibration
Group model probabilities into bins and compare predicted probability with
observed failure frequency.

## 5. Engineering Interpretation Framework

### Spatial variation
The wafer map should be interpreted as a spatial process-monitoring tool.
Localized regions with elevated defect probability or failure frequency indicate
potential process nonuniformity or an underlying hotspot mechanism.

### Critical dimension
CD is treated as a key process-related variable because dimensional variation can
affect pattern quality. The analysis should determine whether CD variation is
statistically associated with failure risk in this benchmark.

### Film thickness
Film thickness is another process-related variable. Spatially structured thickness
variation can indicate nonuniform processing and should be compared with defect
probability and failure.

### Hotspot regions
If hotspot_mask shows a materially higher failure rate than non-hotspot sites, the
hotspot variable provides an engineering screening mechanism for high-risk regions.

## 6. DOE and Statistical Process Control

The researcher implemented the DOE and SPC analysis in MATLAB. The analysis was
designed around the variables actually available in ELWVB rather than introducing
unavailable fab settings.

### 6.1 DOE design

Because the benchmark does not contain controlled scanner settings such as
exposure dose and focus, CD variation and film-thickness variation were selected
as the two engineering factors.

Each factor was divided into three levels using the empirical one-third and
two-thirds quantiles:

| Factor | Level 1 | Level 2 | Level 3 |
|---|---|---|---|
| CD variation | Low | Medium | High |
| Thickness variation | Low | Medium | High |

This produced a 3 × 3 factorial structure. The analysis evaluated mean failure
rate and mean defect probability in each factor combination.

The MATLAB analysis generated:
- factorial cell means;
- main-effect plots;
- CD × thickness interaction plot;
- descriptive two-factor ANOVA;
- logistic regression including the interaction term;
- response-surface visualization; and
- the lowest predicted-risk combination within the DOE grid.

The factorial analysis is interpreted as **retrospective/model-based engineering
analysis** because the original ELWVB observations were not generated through
randomized treatment assignment. Consequently, the analysis identifies
associations and process regions rather than proving causal effects.

### 6.2 DOE response

The interaction term is particularly important. If the interaction is large,
the effect associated with CD variation depends on the thickness-variation
condition. Such a result would indicate that process variables should not be
optimized independently.

The response-surface analysis provides an engineering visualization of the
predicted failure-risk landscape and identifies the factor combination associated
with the lowest modeled risk.

### 6.3 SPC methodology

The researcher established subgroup-based SPC using five observations per
subgroup. The following charts were generated:

1. **X-bar chart for CD** — monitors shifts in average critical dimension.
2. **R chart for CD** — monitors within-subgroup CD variation.
3. **p-chart for failure** — monitors the proportion of failed wafer sites.
4. **X-bar chart for thickness** — monitors shifts in average film thickness.
5. **R chart for thickness** — monitors within-subgroup thickness variation.

For the X-bar/R charts, standard subgroup-size-five constants were used. For the
p-chart, subgroup-specific binomial control limits were calculated.

### 6.4 Process capability

The researcher calculated Cp and Cpk for CD using within-subgroup variation:

$$
C_p = \frac{USL-LSL}{6\sigma_{within}}
$$

$$
C_{pk} =
\min\left(
\frac{USL-\mu}{3\sigma_{within}},
\frac{\mu-LSL}{3\sigma_{within}}
\right)
$$

The specification limits in the MATLAB script are explicitly configurable.
Because the supplied benchmark does not provide a real manufacturing CD
specification, the default limits are based on the observed dataset range and
must not be described as an actual semiconductor product specification.

### 6.5 SPC interpretation

An out-of-control point is treated as an indication for investigation rather
than automatic proof of a process fault. The proposed engineering response is:

**SPC signal → verify measurement → examine spatial/process variables → identify
root cause → corrective action → confirm stability**

The SPC results should therefore be discussed together with the wafer maps,
DOE results and defect-probability analysis.

## 7. Results

After placing `wafer_site_data.csv` in the `data/` directory, the MATLAB and Python
analyses can be executed. The actual numerical results should be populated from
the generated files; no numerical DOE/SPC result is invented here because the
uploaded material does not contain the raw CSV.

### 7.1 Overall wafer performance

| Metric | Result |
|---|---:|
| Number of wafer sites | [MATLAB output] |
| Overall failure rate | [MATLAB output] |
| Mean ground-truth defect probability | [MATLAB output] |
| Lowest predicted DOE risk | [MATLAB output] |
| CD Cp | [MATLAB output] |
| CD Cpk | [MATLAB output] |
| Number of CD X-bar signals | [MATLAB output] |
| Number of failure p-chart signals | [MATLAB output] |

### 7.2 Required figures

The final report should include:
- `true_p_defect_map_recreated.png`
- `failure_map_recreated.png`
- `cd_map.png`
- `thickness_map.png`
- `mc_p95_map.png`
- `DOE_main_effects_failure.png`
- `DOE_interaction_failure.png`
- `DOE_response_surface.png`
- `SPC_Xbar_CD.png`
- `SPC_R_CD.png`
- `SPC_p_chart_failure.png`
- `SPC_Xbar_Thickness.png`
- `SPC_R_Thickness.png`

### 7.3 Interpretation

The researcher will compare the spatial defect distribution with the DOE
response surface and SPC signals. Regions showing elevated defect probability
should be investigated alongside CD, thickness and hotspot information.

A process factor should only be recommended for corrective action when the
statistical evidence and engineering interpretation are consistent. This avoids
treating a statistical association as a proven physical cause.

## 7. Benchmark Context

The published ELWVB description reports 40,000 sites and benchmark AUC values of
approximately 0.5841 for its MLE model and 0.5842 for a logistic-regression
benchmark. These values should be treated as reference benchmark figures rather
than as results produced by this project.

## 8. Process-Engineering Recommendations

Recommendations should be tied to the observed results. Suitable actions include:

1. Prioritize wafer regions with consistently elevated predicted defect probability.
2. Investigate CD and thickness nonuniformity where these variables show strong
   association with failure.
3. Use hotspot maps as an early-warning layer for targeted inspection.
4. Prefer probability-based monitoring over a single binary pass/fail threshold when
   the model is adequately calibrated.
5. Re-run the analysis after process changes to check whether hotspot size,
   probability, and failure rate decrease.

## 9. Limitations

- ELWVB is synthetic and does not represent real production-fab measurements.
- Spatial dependence means a random train/test split can be optimistic; a stronger
  future version should use spatial holdout validation.
- The benchmark's failure outcomes are stochastic, so model metrics can vary with
  the train/test split.
- No real-time process history is available, so this is a spatial defect/yield
  prediction study rather than a true run-to-run control system.

## 10. Future Extension

The next version should add:
- spatial block cross-validation
- XGBoost/LightGBM comparison
- Gaussian-process or spatial statistical modeling
- CNN-based wafer-map classification
- SHAP explanations
- defect-cost-sensitive decision thresholds
- process capability analysis when repeated time/lot measurements are available
- a Streamlit dashboard for process-engineer use

## 11. Conclusion

The project demonstrates a complete semiconductor data-analysis workflow from wafer
mapping and statistical analysis to predictive modeling and engineering
interpretation. Its strongest portfolio value is the connection between spatial
manufacturing variation and actionable yield monitoring rather than treating the
dataset as a generic machine-learning classification problem.
