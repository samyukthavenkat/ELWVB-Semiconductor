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

Applied the developed MATLAB-based analytical framework to the ELWVB wafer-site dataset. The analysis combined spatial wafer mapping, design of experiments (DOE), and statistical process control (SPC) to investigate the relationship between process variation and wafer-site failure.

### 7.1 Overall wafer performance

The dataset contains 40,000 wafer sites. The overall observed failure rate was 89.49%, which was consistent with the mean ground-truth defect probability of approximately 0.8949. This indicates that the benchmark represents a relatively high-risk operating condition, with a large proportion of wafer sites assigned a high probability of failure.

| Metric | Result |
|---|---:|
| Number of wafer sites | 40,000 |
| Overall failure rate | 89.49% |
| Mean ground-truth defect probability | 0.8949 |
| Lowest predicted DOE risk | 0.8817 (88.17%) |
| CD Cp | 5.78 |
| CD Cpk | 5.62 |
| Number of CD X-bar signals | 6,577 |
| Number of failure p-chart signals | 70 |

The Cp and Cpk values were calculated using the observed minimum and maximum CD values as provisional specification limits. Since the ELWVB dataset does not provide actual manufacturing USL and LSL specifications, these values should be interpreted as analytical capability indicators rather than certified production-process capability indices.

The high mean defect probability indicates that the wafer contains substantial modeled defect risk. Consequently, the analysis focuses not only on overall yield but also on identifying where the risk is concentrated and which process variables are associated with it.

### 7.2 Spatial Wafer Analysis

The researcher generated spatial maps of the ground-truth defect probability, observed failure, critical dimension, film thickness, and Monte Carlo 95th-percentile defect probability.

The true_p_defect_map_recreated.png and failure_map_recreated.png provide the primary view of the spatial distribution of wafer risk. The comparison demonstrates that failure is not purely a random site-level phenomenon. Instead, wafer position and local process variation contribute to spatially structured differences in predicted defect probability.

The Monte Carlo 95th-percentile map provides a conservative risk view by highlighting regions that can exhibit elevated defect probability across Monte Carlo realizations. Comparing this map with the observed failure map allows high-risk regions to be prioritized for further process investigation.

The CD and thickness maps were subsequently compared with the defect maps. This comparison supports the use of CD and thickness as process-related factors in the DOE analysis.

### 7.3 DOE Analysis

A 3 × 3 retrospective factorial DOE was constructed using CD variation and film-thickness variation. Each variable was divided into three empirical levels: Low, Medium, and High.

The observed failure rates for the nine factor combinations were:
| CD Level | Thickness | Observed Failure Rate |
|---|---:|---|
| Low | Low | 88.05% |
| Low | Medium | 90.36% |
| Low | High | 90.55% |
| Medium | Low | 87.94% |
| Medium | Medium | 90.07% |
| Medium | High  | 90.45% |
| High | Low | 87.57% |
| High | Medium | 90.17% |
| High | High | 90.28% |

The results indicate a clear relationship between thickness level and failure probability. Across the three CD levels, the Low-thickness condition consistently produced lower failure rates than the Medium- and High-thickness conditions.

The lowest observed failure rate was obtained for the High-CD / Low-thickness combination at 87.57%. However, the fitted logistic DOE response surface identified Low CD / Low thickness as the combination with the lowest predicted failure probability, at approximately 88.17%.

The difference between the observed minimum and model-predicted minimum demonstrates the importance of distinguishing between a raw factorial-cell result and a fitted statistical response. The fitted model smooths the observed data and incorporates the estimated interaction between CD and thickness.

The DOE main-effect and interaction plots therefore provide evidence that thickness variation is an important factor associated with wafer-site failure. The interaction analysis should be considered when selecting process conditions because the effect of one factor may depend on the level of the other.

Importantly, the DOE is interpreted as a retrospective/model-based engineering analysis, rather than a controlled physical experiment. The ELWVB observations were not generated through randomized assignment of process treatments. Therefore, the results demonstrate statistical association and process sensitivity rather than proving that changing CD or thickness would causally produce the observed reduction in failure.

### 7.4 SPC Analysis

The researcher applied subgroup-based SPC using groups of five wafer-site observations. X-bar and R charts were generated for CD and film thickness, while a p-chart was used to monitor the proportion of failed sites.

The CD X-bar analysis identified 6,577 subgroups outside the calculated control limits, while the failure p-chart identified 70 subgroups outside the corresponding control limits.

The large number of CD X-bar signals requires careful interpretation. The ELWVB dataset represents spatial wafer locations rather than chronological production observations. Consequently, grouping consecutive rows of the dataset into subgroups does not represent conventional run-to-run manufacturing SPC. The 6,577 signals should therefore not be interpreted as 6,577 actual manufacturing disturbances.

Instead, the result demonstrates that conventional sequential SPC becomes highly sensitive when applied directly to spatially structured wafer data. The high signal count suggests that the CD measurements contain substantial spatial structure and that a spatially appropriate monitoring method would be more suitable than treating wafer coordinates as production time.

The p-chart produced 70 signals, indicating that several subgroups exhibit failure proportions that differ substantially from the overall process level. These regions should be cross-referenced with the wafer defect-probability and hotspot maps.

### 7.5 Process Capability

The calculated CD capability indicators were:

C_{p} = 5.7848 and C_{pk} = 5.6276

The close relationship between Cp and Cpk indicates that the estimated CD distribution is relatively well centered within the provisional limits used in the analysis.

However, these values should not be interpreted as evidence that an actual semiconductor manufacturing process is highly capable. The dataset does not specify engineering tolerances for CD. The analysis therefore used the observed CD range as provisional limits. A production capability study would require specification limits defined by the device, lithography process, or manufacturing engineering requirements.

### 7.6 Overall Interpretation

Three main findings emerge from the combined DOE and SPC analysis.

First, the wafer exhibits substantial spatially structured defect risk, with an overall failure rate of 89.49%. The spatial maps demonstrate that defect risk should be evaluated geographically across the wafer rather than only through a single overall yield value.

Second, the DOE indicates that film thickness is strongly associated with wafer-site failure. Low-thickness conditions produced lower observed failure rates across all CD levels. The response-surface model also identified a low-risk region involving low CD and low thickness. This suggests that thickness control should be investigated as a potential process-improvement opportunity.

Third, the SPC analysis demonstrates the importance of selecting an appropriate monitoring structure. The large number of CD X-bar signals is partly a consequence of applying sequential SPC to spatially ordered wafer data. For semiconductor wafer monitoring, spatial control charts or wafer-map-based anomaly detection would therefore be more appropriate than directly interpreting spatial observations as a chronological process stream.

## 8. Process-Engineering Recommendations

Based on the combined spatial, DOE, and SPC results, the researcher recommends the following process-engineering actions.

### 8.1 Prioritize High-Risk Wafer Regions

Regions with consistently elevated defect probability should be prioritized for engineering investigation. The ground-truth probability map, failure map, and Monte Carlo 95th-percentile map should be compared to identify persistent high-risk regions rather than relying solely on individual failed sites.

### 8.2 Investigate Film-Thickness Variation

The DOE results show that the low-thickness condition consistently produced lower observed failure rates than the medium- and high-thickness conditions. Film-thickness uniformity should therefore be investigated as a potential process-improvement variable.

Potential investigation areas include coating uniformity, deposition conditions, wafer-edge effects, and spatial thickness gradients.

### 8.3 Investigate CD–Thickness Interaction

The DOE interaction analysis indicates that CD and thickness should not necessarily be optimized independently. Process engineers should examine whether controlling one variable changes the sensitivity of wafer failure to the other.

### 8.4 Use Spatial SPC Rather Than Conventional Sequential SPC

The large number of CD X-bar signals demonstrates that conventional sequential SPC is not ideally suited to the spatial structure of the ELWVB dataset.

For future implementation, wafer coordinates should be incorporated directly into monitoring methods. Examples include spatial control charts, wafer-map residual analysis, hotspot detection, and spatial anomaly scores.

### 8.5 Use Probability-Based Inspection

Because the dataset provides continuous defect probabilities rather than only binary failure labels, probability-based monitoring provides additional information. A process engineer can prioritize sites or wafer regions according to predicted risk rather than applying a single pass/fail threshold.

### 8.6 Reassess the Process After Corrective Action

After a process intervention, the same DOE/SPC framework should be rerun. Improvement should be demonstrated through reductions in:

- overall failure rate
- mean defect probability
- high-risk wafer area
- hotspot intensity and
- abnormal spatial variation.

## 9. Limitations

Several limitations should be considered when interpreting the results.
1. Synthetic benchmark: ELWVB is a synthetic benchmark and therefore does not directly represent measurements from a production semiconductor fabrication facility.
2. Retrospective DOE: The DOE factors were derived from observed CD and thickness values rather than controlled experimental treatments. Therefore, the results identify associations rather than establish causal effects.
3. Spatial dependence: Wafer sites are spatially related. Treating individual sites as independent observations may underestimate uncertainty. Future analysis should use spatial block validation and spatial statistical methods.
4. SPC ordering: The dataset does not provide chronological lot or production-run information. Consequently, the current X-bar/R analysis uses spatially ordered observations and should be interpreted as a methodological demonstration rather than a true production control chart.
5. Capability specifications: The Cp and Cpk calculations use provisional limits based on the observed CD range because actual engineering specification limits were not provided.
6. Stochastic failure: The ELWVB failure mechanism contains stochastic behavior. Repeated simulations or different data partitions may therefore produce different numerical model results.
7. Generalizability: Results obtained from ELWVB should not automatically be transferred to a real fabrication process without validation against actual process measurements.

## 10. Future Extension

The following extensions would strengthen the methodology:
- spatial block cross-validation to reduce overly optimistic model evaluation;
- XGBoost or LightGBM comparison with the current models;
- Gaussian-process and spatial statistical modeling;
- convolutional neural networks for wafer-map classification;
- SHAP-based model interpretation;
- defect-cost-sensitive decision thresholds;
- spatially adapted SPC and wafer-map control charts;
- capability analysis using actual engineering USL and LSL specifications;
- chronological lot-level SPC when production-history data become available; and
- development of a Streamlit-based process-engineering dashboard.

A particularly valuable extension would combine spatial SPC with machine-learning anomaly detection. Such a system could identify abnormal wafer regions while simultaneously estimating the probability and potential severity of failure.

## 11. Conclusion

The study demonstrates an integrated semiconductor manufacturing analytics framework combining spatial wafer analysis, DOE, SPC, and predictive defect-risk assessment.

The analysis of 40,000 wafer sites produced an overall failure rate of 89.49% and a mean ground-truth defect probability of approximately 0.8949. The DOE analysis identified a strong association between thickness level and failure, with the lowest observed factorial failure rate of 87.57% occurring under the High-CD/Low-thickness condition. The fitted DOE model produced a lowest predicted failure risk of approximately 88.17%.

The SPC analysis identified 70 failure p-chart signals and a large number of CD X-bar signals. Rather than interpreting the latter as thousands of real manufacturing disturbances, the researcher identified the underlying methodological issue: the ELWVB data are spatial rather than chronological. This finding motivates the use of spatial SPC methods for future semiconductor applications.

Overall, the project demonstrates that semiconductor process analysis can benefit from integrating spatial defect mapping, experimental-design principles, statistical process monitoring, and predictive analytics. The strongest engineering value lies in using these methods together: spatial maps identify where problems occur, DOE identifies process-variable relationships, SPC identifies abnormal variation, and predictive models provide a quantitative basis for prioritizing corrective action.
