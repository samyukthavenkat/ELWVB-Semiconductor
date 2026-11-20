# MATLAB DOE + SPC module

## Run

From MATLAB, set the current folder to:

`ELWVB_semiconductor_project/matlab`

Then run:

```matlab
ELWVB_DOE_SPC
```

The script expects:

`../data/wafer_site_data.csv`

## DOE

The ELWVB benchmark does not contain physical scanner settings such as exposure
dose and focus. Therefore, the MATLAB implementation uses CD variation and
thickness variation as engineering factors.

Three quantile levels are created for each factor:

- Low
- Medium
- High

This gives a 3 x 3 retrospective factorial structure. Main effects, interaction,
descriptive ANOVA, logistic regression and a response surface are generated.

Because the original observations are not randomized treatment assignments, the
DOE results must be described as retrospective/model-based engineering analysis,
not causal experimental evidence.

## SPC

The script uses groups of five observations and generates:

- X-bar chart for CD
- R chart for CD
- p-chart for failure
- X-bar chart for thickness
- R chart for thickness
- Cp and Cpk for CD
- Out-of-control subgroup identification

The current benchmark has no production-time or lot sequence. Therefore row order
is used only as an analytical grouping mechanism. If lot/time order is supplied,
the subgrouping should be changed to that real sequence.

## Outputs

The MATLAB script writes all charts and result tables to:

`../outputs_matlab/`

Expected outputs include:
- DOE_factorial_summary.csv
- DOE_ANOVA_failure.csv
- DOE_logistic_coefficients.csv
- DOE_optimum.csv
- DOE_main_effects_failure.png
- DOE_interaction_failure.png
- DOE_response_surface.png
- SPC_Xbar_CD.png
- SPC_R_CD.png
- SPC_p_chart_failure.png
- SPC_Xbar_Thickness.png
- SPC_R_Thickness.png
- SPC_CD_capability.csv
- SPC_signals.csv
