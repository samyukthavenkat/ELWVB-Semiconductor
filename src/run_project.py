from pathlib import Path
import json
import warnings
warnings.filterwarnings("ignore")

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.metrics import (
    roc_auc_score, average_precision_score, accuracy_score, precision_score,
    recall_score, f1_score, brier_score_loss, confusion_matrix,
    ConfusionMatrixDisplay
)
from sklearn.inspection import permutation_importance

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "wafer_site_data.csv"
OUT = ROOT / "outputs"
OUT.mkdir(exist_ok=True)

if not DATA.exists():
    raise FileNotFoundError(
        "wafer_site_data.csv is not present. Put the ELWVB CSV in data/ and rerun."
    )

df = pd.read_csv(DATA)

expected = [
    "x","y","r","cd","thickness","hotspot","hotspot_mask",
    "E_true","p_defect","failure","p_mle","p50_mc","p95_mc"
]
missing = [c for c in expected if c not in df.columns]
if missing:
    raise ValueError(f"Missing expected columns: {missing}")

print(f"Loaded {len(df):,} rows and {df.shape[1]} columns.")
print("\nFailure rate:", df["failure"].mean())
print("Mean true defect probability:", df["p_defect"].mean())

# ---------------------------------------------------------------------
# 1. Spatial maps
# ---------------------------------------------------------------------
def wafer_map(column, title, filename, cmap="magma"):
    piv = df.pivot_table(index="y", columns="x", values=column, aggfunc="mean")
    fig, ax = plt.subplots(figsize=(7, 6))
    im = ax.imshow(
        piv.values,
        origin="lower",
        extent=[df.x.min(), df.x.max(), df.y.min(), df.y.max()],
        aspect="equal",
        cmap=cmap
    )
    ax.set_xlabel("X (normalized)")
    ax.set_ylabel("Y (normalized)")
    ax.set_title(title)
    fig.colorbar(im, ax=ax, label=column)
    fig.tight_layout()
    fig.savefig(OUT / filename, dpi=220)
    plt.close(fig)

for col, title, fn in [
    ("p_defect", "Ground-truth defect probability", "true_p_defect_map_recreated.png"),
    ("failure", "Observed failure map", "failure_map_recreated.png"),
    ("cd", "Critical dimension variation", "cd_map.png"),
    ("thickness", "Film thickness variation", "thickness_map.png"),
]:
    wafer_map(col, title, fn)

# ---------------------------------------------------------------------
# 2. Radial and hotspot analysis
# ---------------------------------------------------------------------
df["radial_bin"] = pd.cut(
    df["r"],
    bins=[-np.inf, 0.25, 0.50, 0.75, 1.0, np.inf],
    labels=["0-0.25", "0.25-0.50", "0.50-0.75", "0.75-1.00", ">1.00"]
)

radial = (
    df.groupby("radial_bin", observed=False)
      .agg(n=("failure","size"),
           failure_rate=("failure","mean"),
           mean_p_defect=("p_defect","mean"),
           mean_cd=("cd","mean"),
           mean_thickness=("thickness","mean"))
      .reset_index()
)
radial.to_csv(OUT / "radial_analysis.csv", index=False)

hotspot = (
    df.groupby("hotspot_mask")
      .agg(n=("failure","size"),
           failure_rate=("failure","mean"),
           mean_p_defect=("p_defect","mean"),
           mean_cd=("cd","mean"),
           mean_thickness=("thickness","mean"))
      .reset_index()
)
hotspot.to_csv(OUT / "hotspot_analysis.csv", index=False)

fig, ax = plt.subplots(figsize=(7, 4.5))
ax.bar(radial["radial_bin"].astype(str), radial["failure_rate"])
ax.set_xlabel("Radial distance bin")
ax.set_ylabel("Failure rate")
ax.set_title("Failure rate by wafer radial region")
fig.tight_layout()
fig.savefig(OUT / "radial_failure_rate.png", dpi=220)
plt.close(fig)

# ---------------------------------------------------------------------
# 3. Correlation analysis
# ---------------------------------------------------------------------
numeric = [
    "x","y","r","cd","thickness","hotspot","hotspot_mask",
    "E_true","p_defect","failure","p_mle","p50_mc","p95_mc"
]
corr = df[numeric].corr(method="spearman")
corr.to_csv(OUT / "spearman_correlation.csv")

fig, ax = plt.subplots(figsize=(10, 8))
im = ax.imshow(corr.values, aspect="auto", cmap="coolwarm", vmin=-1, vmax=1)
ax.set_xticks(range(len(corr.columns)))
ax.set_yticks(range(len(corr.index)))
ax.set_xticklabels(corr.columns, rotation=75, ha="right", fontsize=8)
ax.set_yticklabels(corr.index, fontsize=8)
ax.set_title("Spearman correlation matrix")
fig.colorbar(im, ax=ax, label="Spearman rho")
fig.tight_layout()
fig.savefig(OUT / "correlation_matrix.png", dpi=220)
plt.close(fig)

# ---------------------------------------------------------------------
# 4. Model preparation
# ---------------------------------------------------------------------
features = ["x","y","r","cd","thickness","hotspot","hotspot_mask"]
X = df[features].copy()
y = df["failure"].astype(int)

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.25, stratify=y, random_state=42
)

models = {
    "Logistic Regression": Pipeline([
        ("scale", StandardScaler()),
        ("model", LogisticRegression(max_iter=2000, class_weight="balanced"))
    ]),
    "Random Forest": RandomForestClassifier(
        n_estimators=300, random_state=42, n_jobs=-1,
        class_weight="balanced_subsample", min_samples_leaf=5
    ),
    "Gradient Boosting": GradientBoostingClassifier(random_state=42)
}

results = []
fitted = {}

for name, model in models.items():
    model.fit(X_train, y_train)
    fitted[name] = model
    prob = model.predict_proba(X_test)[:, 1]
    pred = (prob >= 0.5).astype(int)

    results.append({
        "model": name,
        "roc_auc": roc_auc_score(y_test, prob),
        "pr_auc": average_precision_score(y_test, prob),
        "accuracy": accuracy_score(y_test, pred),
        "precision": precision_score(y_test, pred, zero_division=0),
        "recall": recall_score(y_test, pred, zero_division=0),
        "f1": f1_score(y_test, pred, zero_division=0),
        "brier": brier_score_loss(y_test, prob),
    })

metrics = pd.DataFrame(results).sort_values("roc_auc", ascending=False)
metrics.to_csv(OUT / "model_metrics.csv", index=False)
print("\nModel results:")
print(metrics.to_string(index=False))

# Best model confusion matrix
best_name = metrics.iloc[0]["model"]
best_model = fitted[best_name]
best_prob = best_model.predict_proba(X_test)[:, 1]
best_pred = (best_prob >= 0.5).astype(int)

fig, ax = plt.subplots(figsize=(5, 5))
ConfusionMatrixDisplay(
    confusion_matrix(y_test, best_pred),
    display_labels=["Pass", "Fail"]
).plot(ax=ax, values_format="d")
ax.set_title(f"Confusion matrix — {best_name}")
fig.tight_layout()
fig.savefig(OUT / "confusion_matrix.png", dpi=220)
plt.close(fig)

# ROC curves
fig, ax = plt.subplots(figsize=(7, 5))
for name, model in fitted.items():
    prob = model.predict_proba(X_test)[:, 1]
    fpr = []
    tpr = []
    thresholds = np.unique(np.r_[1.0, prob, 0.0])[::-1]
    P = max(y_test.sum(), 1)
    N = max((1-y_test).sum(), 1)
    for t in thresholds:
        pred = (prob >= t).astype(int)
        tp = ((pred == 1) & (y_test.values == 1)).sum()
        fp = ((pred == 1) & (y_test.values == 0)).sum()
        fn = ((pred == 0) & (y_test.values == 1)).sum()
        tn = ((pred == 0) & (y_test.values == 0)).sum()
        tpr.append(tp / P)
        fpr.append(fp / N)
    ax.plot(fpr, tpr, label=f"{name} (AUC={roc_auc_score(y_test, prob):.3f})")

ax.plot([0,1], [0,1], linestyle="--", linewidth=1)
ax.set_xlabel("False positive rate")
ax.set_ylabel("True positive rate")
ax.set_title("ROC comparison")
ax.legend()
fig.tight_layout()
fig.savefig(OUT / "roc_comparison.png", dpi=220)
plt.close(fig)

# ---------------------------------------------------------------------
# 5. Feature importance
# ---------------------------------------------------------------------
perm = permutation_importance(
    best_model, X_test, y_test, n_repeats=10,
    random_state=42, scoring="roc_auc"
)
imp = pd.DataFrame({
    "feature": features,
    "importance_mean": perm.importances_mean,
    "importance_std": perm.importances_std
}).sort_values("importance_mean", ascending=False)
imp.to_csv(OUT / "feature_importance.csv", index=False)

fig, ax = plt.subplots(figsize=(7, 4.5))
ax.barh(imp["feature"], imp["importance_mean"])
ax.set_xlabel("Mean permutation importance (ROC-AUC)")
ax.set_title(f"Feature importance — {best_name}")
ax.invert_yaxis()
fig.tight_layout()
fig.savefig(OUT / "feature_importance.png", dpi=220)
plt.close(fig)

# ---------------------------------------------------------------------
# 6. Probability calibration against supplied ground truth probability
# ---------------------------------------------------------------------
# p_defect is a continuous ground-truth probability supplied by the benchmark.
# We compare model predictions with the binary outcomes and also summarize
# the supplied benchmark probability itself.
calibration = pd.DataFrame({
    "observed_failure": y_test.values,
    "best_model_probability": best_prob
})
calibration["probability_bin"] = pd.cut(
    calibration["best_model_probability"],
    bins=np.linspace(0, 1, 11),
    include_lowest=True
)

cal_summary = (
    calibration.groupby("probability_bin", observed=False)
    .agg(mean_predicted=("best_model_probability","mean"),
         observed_failure_rate=("observed_failure","mean"),
         n=("observed_failure","size"))
    .reset_index()
)
cal_summary.to_csv(OUT / "model_calibration.csv", index=False)

fig, ax = plt.subplots(figsize=(6, 6))
ax.plot(cal_summary["mean_predicted"], cal_summary["observed_failure_rate"], marker="o")
ax.plot([0,1], [0,1], linestyle="--")
ax.set_xlabel("Mean predicted failure probability")
ax.set_ylabel("Observed failure frequency")
ax.set_title("Probability calibration")
fig.tight_layout()
fig.savefig(OUT / "calibration_plot.png", dpi=220)
plt.close(fig)

# ---------------------------------------------------------------------
# 7. Engineering summary
# ---------------------------------------------------------------------
summary = {
    "n_sites": int(len(df)),
    "grid_expected": "200 x 200",
    "overall_failure_rate": float(df["failure"].mean()),
    "mean_true_p_defect": float(df["p_defect"].mean()),
    "best_model": best_name,
    "best_model_metrics": metrics.iloc[0].to_dict(),
    "feature_importance": imp.to_dict(orient="records"),
    "benchmark_reference_auc_mle": 0.5841,
    "benchmark_reference_auc_logistic": 0.5842,
}
(OUT / "project_summary.json").write_text(json.dumps(summary, indent=2, default=float))

print(f"\nBest model: {best_name}")
print(f"Outputs written to: {OUT}")
