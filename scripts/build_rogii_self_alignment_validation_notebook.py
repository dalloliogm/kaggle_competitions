#!/usr/bin/env python3
"""Populate the ROGII lateral self-alignment masked-prefix experiment notebook."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NOTEBOOK = (
    ROOT
    / "competitions"
    / "rogii-wellbore-geology-prediction"
    / "notebooks"
    / "rogii-lateral-self-alignment-masked-prefix.ipynb"
)


def markdown(source: str) -> dict:
    return {"cell_type": "markdown", "metadata": {}, "source": source}


def code(source: str) -> dict:
    return {
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": source,
    }


cells = [
    markdown(
        """# ROGII direction-gated lateral self-alignment: masked-prefix validation

**Question.** Does the horizontal well's own high-resolution GR prefix provide a reliable trajectory signal when the hidden path moves backward through TVT?

This tests the geological hint in [discussion 698825](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/698825): lateral GR can correlate with an earlier part of itself and may be more informative than the lower-resolution typewell GR on negative-TV T paths.

The experiment is target-safe. For each training well it shortens the published `TVT_input` prefix, predicts every later row using only the shortened prefix plus always-visible trajectory/GR columns, and scores against `TVT`. A nested holdout inside the retained prefix chooses the non-self baseline and the self-alignment blend weight. True tail direction is used only for diagnostic slices, never for prediction or gating.

The public s4000 result of **6.435** is the live reference, but this standalone validator does not reproduce the complete GS1.30 stack. Passing means “worth integrating into s4000 for a paired test,” not “submission-ready.”"""
    ),
    markdown(
        """## Predeclared plan and gates

1. Mask each well at 50%, 65%, and 75% of its original known prefix.
2. Compare constant-anchor, local-linear, prefix-fit datum-plane, raw reverse self-alignment, and two deployable gates.
3. Report row-weighted RMSE, equal-well RMSE, negative-tail and nonnegative-tail slices, activation rate, and a well bootstrap.
4. Treat the strict gate as promising only if it improves pooled RMSE by at least 0.10 ft, improves at least two mask fractions, improves the negative-tail slice by at least 0.25 ft, and has a positive 95% bootstrap lower bound.

The default deterministic 90-well screen is exploratory. Set `ROGII_MASK_MAX_WELLS=0` for all 773 wells before integrating the method into a submission notebook."""
    ),
    code(
        """from __future__ import annotations

import hashlib
import json
import os
import platform
import time
from pathlib import Path

import numpy as np
import pandas as pd

SEED = 20260802
MASK_FRACTIONS = (0.50, 0.65, 0.75)
MAX_WELLS = int(os.environ.get("ROGII_MASK_MAX_WELLS", "90"))  # 0 = all eligible
MIN_ORIGINAL_KNOWN = 500
MIN_RETAINED_PREFIX = 220
CALIBRATION_RETAIN_FRACTION = 0.72
MIN_CALIBRATION_ROWS = 90
BEAM_SIZE = 48
BEAM_FORGET = 0.997
STRICT_MIN_CAL_GAIN = 0.10
STRICT_MIN_MAIN_CORR = 0.25
CORR_ONLY_THRESHOLD = 0.50
BOOTSTRAP_DRAWS = int(os.environ.get("ROGII_MASK_BOOTSTRAP_DRAWS", "2000"))
SAVE_ROW_PREDICTIONS = bool(int(os.environ.get("ROGII_MASK_SAVE_ROWS", "0")))

def resolve_data_root() -> Path:
    candidates = [
        os.environ.get("ROGII_DATA_ROOT"),
        "/kaggle/input/competitions/rogii-wellbore-geology-prediction",
        "/kaggle/input/rogii-wellbore-geology-prediction",
        "/tmp/rogii-masked-prefix-data/extracted",
    ]
    for raw in candidates:
        if not raw:
            continue
        path = Path(raw)
        if (path / "train").is_dir():
            return path
    raise FileNotFoundError("Set ROGII_DATA_ROOT to a directory containing train/")

DATA_ROOT = resolve_data_root()
default_output = Path("/kaggle/working/self_alignment_validation") if Path("/kaggle/working").exists() else Path(
    "competitions/rogii-wellbore-geology-prediction/references/self-alignment-validation-2026-08-02"
)
OUTPUT_DIR = Path(os.environ.get("ROGII_MASK_OUTPUT_DIR", str(default_output)))
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

print({"data_root": str(DATA_ROOT), "output_dir": str(OUTPUT_DIR), "max_wells": MAX_WELLS})"""
    ),
    markdown(
        """## Signal preparation and transparent baselines

The baselines deliberately use only information available after the mask:

- `anchor`: last known TVT;
- `linear`: robust recent TVT/MD slope, conservatively clipped;
- `datum`: a ridge-stabilized local plane for `TVT + Z` over X/Y, then `TVT = datum - Z`.

Nested calibration chooses the best of these for each well, avoiding one global baseline that favors a particular trajectory type."""
    ),
    code(
        """def _finite_interp(values: np.ndarray) -> np.ndarray:
    values = np.asarray(values, float)
    ok = np.isfinite(values)
    if not ok.any():
        return np.zeros(len(values), dtype=float)
    idx = np.arange(len(values))
    return np.interp(idx, idx[ok], values[ok])

def _rolling_mean(values: np.ndarray, width: int) -> np.ndarray:
    return pd.Series(values).rolling(width, center=True, min_periods=1).mean().to_numpy(float)

def _signal_features(prefix_gr: np.ndarray, query_gr: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    joined = _finite_interp(np.concatenate([prefix_gr, query_gr]))
    n = len(prefix_gr)
    reference = joined[:n]
    median = float(np.median(reference))
    mad = float(np.median(np.abs(reference - median)))
    scale = max(1.4826 * mad, float(np.std(reference)) * 0.25, 5.0)
    z = (joined - median) / scale
    r7 = _rolling_mean(z, 7)
    r21 = _rolling_mean(z, 21)
    grad = np.gradient(r7)
    features = np.column_stack([z, r7, r21, grad])
    return features[:n], features[n:]

def _rmse(y: np.ndarray, p: np.ndarray) -> float:
    return float(np.sqrt(np.mean((np.asarray(y, float) - np.asarray(p, float)) ** 2)))

def _safe_corr(a: np.ndarray, b: np.ndarray) -> float:
    a = np.asarray(a, float); b = np.asarray(b, float)
    ok = np.isfinite(a) & np.isfinite(b)
    if ok.sum() < 10 or np.std(a[ok]) < 1e-8 or np.std(b[ok]) < 1e-8:
        return 0.0
    return float(np.corrcoef(a[ok], b[ok])[0, 1])

def baseline_paths(prefix: pd.DataFrame, query: pd.DataFrame) -> dict[str, np.ndarray]:
    anchor = float(prefix["TVT_input"].iloc[-1])
    mdq = query["MD"].to_numpy(float)
    md0 = float(prefix["MD"].iloc[-1])
    paths = {"anchor": np.full(len(query), anchor, dtype=float)}

    recent = prefix.tail(min(240, len(prefix)))
    dmd = np.diff(recent["MD"].to_numpy(float))
    dtvt = np.diff(recent["TVT_input"].to_numpy(float))
    valid = np.isfinite(dmd) & np.isfinite(dtvt) & (np.abs(dmd) > 1e-8)
    slope = float(np.median(dtvt[valid] / dmd[valid])) if valid.sum() >= 10 else 0.0
    slope = float(np.clip(slope, -0.05, 0.05))
    paths["linear"] = anchor + slope * (mdq - md0)

    x = prefix[["X", "Y"]].to_numpy(float)
    center = np.nanmean(x, axis=0)
    spread = np.maximum(np.nanstd(x, axis=0), 1.0)
    design = np.column_stack([(x - center) / spread, np.ones(len(prefix))])
    target = (prefix["TVT_input"] + prefix["Z"]).to_numpy(float)
    ridge = np.diag([10.0, 10.0, 0.0])
    coef = np.linalg.solve(design.T @ design + ridge, design.T @ target)
    xq = query[["X", "Y"]].to_numpy(float)
    datum = np.column_stack([(xq - center) / spread, np.ones(len(query))]) @ coef
    paths["datum"] = datum - query["Z"].to_numpy(float)
    return paths
"""
    ),
    markdown(
        """## Reverse lateral-GR beam alignment

The candidate starts at the last visible lateral-GR row and searches backward through the prefix. Each hidden row can stay, move backward by one to four reference rows, or make a small one-row forward correction. Emissions compare raw, 7-row, 21-row, and gradient GR features; a compact beam prevents discontinuous jumps and keeps runtime bounded.

This is deliberately not allowed to inspect hidden TVT. Its confidence uses only the correlation between observed hidden GR and the prefix GR selected by the path."""
    ),
    code(
        """def reverse_self_alignment(prefix: pd.DataFrame, query: pd.DataFrame) -> tuple[np.ndarray, dict]:
    prefix_tvt = prefix["TVT_input"].to_numpy(float)
    ref_features, query_features = _signal_features(
        prefix["GR"].to_numpy(float), query["GR"].to_numpy(float)
    )
    n_ref = len(prefix_tvt)
    if n_ref < MIN_RETAINED_PREFIX or len(query) == 0:
        anchor = float(prefix_tvt[-1])
        return np.full(len(query), anchor), {"corr": 0.0, "coverage": 0.0, "mean_step": 0.0}

    deltas = np.array([-4, -3, -2, -1, 0, 1], dtype=int)
    transition_penalty = np.array([0.32, 0.18, 0.06, 0.00, 0.04, 0.35], dtype=float)
    feature_weights = np.array([0.35, 0.25, 0.35, 0.05], dtype=float)
    states = np.array([n_ref - 1], dtype=int)
    costs = np.array([0.0], dtype=float)
    best_path = np.empty(len(query), dtype=int)

    for i, feat in enumerate(query_features):
        expanded_states = (states[:, None] + deltas[None, :]).reshape(-1)
        expanded_costs = (BEAM_FORGET * costs[:, None] + transition_penalty[None, :]).reshape(-1)
        valid = (expanded_states >= 0) & (expanded_states < n_ref)
        expanded_states = expanded_states[valid]
        expanded_costs = expanded_costs[valid]
        delta_feat = ref_features[expanded_states] - feat
        expanded_costs = expanded_costs + np.sum(delta_feat * delta_feat * feature_weights, axis=1)

        # Collapse duplicate reference indices to their cheapest incoming path.
        order = np.lexsort((expanded_costs, expanded_states))
        sorted_states = expanded_states[order]
        first = np.r_[True, sorted_states[1:] != sorted_states[:-1]]
        unique_positions = order[first]
        cand_states = expanded_states[unique_positions]
        cand_costs = expanded_costs[unique_positions]
        keep = np.argsort(cand_costs)[:BEAM_SIZE]
        states = cand_states[keep]
        costs = cand_costs[keep]
        best_path[i] = states[int(np.argmin(costs))]

    prediction = prefix_tvt[best_path].astype(float)
    prediction += float(prefix_tvt[-1] - prediction[0])
    matched_gr = _finite_interp(prefix["GR"].to_numpy(float))[best_path]
    query_gr = _finite_interp(query["GR"].to_numpy(float))
    steps = np.diff(best_path)
    audit = {
        "corr": _safe_corr(matched_gr, query_gr),
        "coverage": float((n_ref - 1 - np.min(best_path)) / max(n_ref - 1, 1)),
        "mean_step": float(np.mean(steps)) if len(steps) else 0.0,
        "end_reference_index": int(best_path[-1]),
    }
    return prediction, audit
"""
    ),
    markdown(
        """## Nested calibration and deployable gates

For every outer mask, the retained prefix is split again. The inner holdout chooses the best transparent baseline and blend weight without seeing the outer target. Two policies are reported:

- `strict`: requires an inner RMSE gain and moderate outer-GR correlation;
- `corr_gate`: permits a fixed half-blend when outer-GR correlation is exceptionally strong, even if the inner segment did not reverse.

The second policy tests whether correlation can identify a reversal that begins only after the prediction boundary."""
    ),
    code(
        """def calibrated_predictions(prefix: pd.DataFrame, query: pd.DataFrame) -> tuple[dict[str, np.ndarray], dict]:
    cal_n = max(MIN_RETAINED_PREFIX, int(np.floor(len(prefix) * CALIBRATION_RETAIN_FRACTION)))
    cal_n = min(cal_n, len(prefix) - MIN_CALIBRATION_ROWS)
    if cal_n < MIN_RETAINED_PREFIX:
        cal_n = len(prefix)

    outer_base_paths = baseline_paths(prefix, query)
    if cal_n >= len(prefix):
        selected_name = "anchor"
        cal_gain = 0.0
        chosen_weight = 0.0
        cal_corr = 0.0
    else:
        cal_prefix = prefix.iloc[:cal_n].copy()
        cal_query = prefix.iloc[cal_n:].copy()
        cal_base_paths = baseline_paths(cal_prefix, cal_query)
        cal_truth = cal_query["TVT_input"].to_numpy(float)
        base_scores = {name: _rmse(cal_truth, pred) for name, pred in cal_base_paths.items()}
        selected_name = min(base_scores, key=base_scores.get)
        # The long hidden tail is much longer than this inner holdout. Linear and
        # datum paths are retained as diagnostics, but the primary correction is
        # calibrated against the stable anchor to prevent extrapolation artifacts.
        cal_base = cal_base_paths["anchor"]
        cal_self, cal_audit = reverse_self_alignment(cal_prefix, cal_query)
        candidates = {}
        for weight in (0.0, 0.25, 0.50, 0.75, 1.0):
            blend = cal_base + weight * (cal_self - cal_base)
            candidates[weight] = _rmse(cal_truth, blend)
        chosen_weight = min(candidates, key=candidates.get)
        cal_gain = float(candidates[0.0] - candidates[chosen_weight])
        cal_corr = float(cal_audit["corr"])

    outer_base = outer_base_paths["anchor"]
    self_pred, main_audit = reverse_self_alignment(prefix, query)
    calibrated_blend = outer_base + chosen_weight * (self_pred - outer_base)
    negative_move = float(self_pred[-1] - self_pred[0]) < -0.25 if len(self_pred) else False
    strict_active = bool(
        chosen_weight > 0
        and cal_gain >= STRICT_MIN_CAL_GAIN
        and main_audit["corr"] >= STRICT_MIN_MAIN_CORR
        and negative_move
    )
    corr_active = bool(
        main_audit["corr"] >= CORR_ONLY_THRESHOLD
        and main_audit["coverage"] >= 0.02
        and negative_move
    )
    strict = calibrated_blend if strict_active else outer_base
    corr_gate = (
        outer_base + max(float(chosen_weight), 0.50) * (self_pred - outer_base)
        if corr_active else outer_base
    )
    predictions = {
        **outer_base_paths,
        "base_selected": outer_base,
        "self_raw": self_pred,
        "strict": strict,
        "corr_gate": corr_gate,
    }
    audit = {
        "best_transparent_name": selected_name,
        "cal_gain": cal_gain,
        "cal_corr": cal_corr,
        "blend_weight": float(chosen_weight),
        "main_corr": float(main_audit["corr"]),
        "coverage": float(main_audit["coverage"]),
        "mean_step": float(main_audit["mean_step"]),
        "strict_active": strict_active,
        "corr_active": corr_active,
    }
    return predictions, audit

def mask_well(frame: pd.DataFrame, fraction: float) -> tuple[pd.DataFrame, pd.DataFrame] | None:
    known_n = int(frame["TVT_input"].notna().sum())
    if known_n < MIN_ORIGINAL_KNOWN:
        return None
    keep_n = int(np.floor(known_n * fraction))
    if keep_n < MIN_RETAINED_PREFIX or len(frame) - keep_n < MIN_CALIBRATION_ROWS:
        return None
    prefix = frame.iloc[:keep_n].copy()
    prefix["TVT_input"] = prefix["TVT"].astype(float)
    query = frame.iloc[keep_n:].copy()
    return prefix, query
"""
    ),
    markdown("## Run the deterministic masked-prefix screen"),
    code(
        """horizontal_files = sorted((DATA_ROOT / "train").glob("*__horizontal_well.csv"))
eligible = []
for path in horizontal_files:
    frame = pd.read_csv(path, usecols=["MD", "X", "Y", "Z", "TVT", "GR", "TVT_input"])
    if int(frame["TVT_input"].notna().sum()) >= MIN_ORIGINAL_KNOWN:
        eligible.append(path)

if MAX_WELLS > 0 and len(eligible) > MAX_WELLS:
    eligible = sorted(
        eligible,
        key=lambda p: hashlib.sha256(f"{SEED}:{p.stem}".encode()).hexdigest(),
    )[:MAX_WELLS]

print(f"selected {len(eligible)} of {len(horizontal_files)} wells")
started = time.time()
detail_parts = []
well_rows = []

for well_number, path in enumerate(eligible, 1):
    wid = path.stem.replace("__horizontal_well", "")
    frame = pd.read_csv(path, usecols=["MD", "X", "Y", "Z", "TVT", "GR", "TVT_input"])
    for fraction in MASK_FRACTIONS:
        masked = mask_well(frame, fraction)
        if masked is None:
            continue
        prefix, query = masked
        predictions, audit = calibrated_predictions(prefix, query)
        truth = query["TVT"].to_numpy(float)
        md = query["MD"].to_numpy(float)
        true_slope = float(np.polyfit(md, truth, 1)[0]) if len(query) >= 2 else 0.0
        if SAVE_ROW_PREDICTIONS:
            record = pd.DataFrame({
                "well": wid,
                "fraction": fraction,
                "row": query.index.to_numpy(int),
                "truth": truth,
                **{name: values for name, values in predictions.items()},
            })
            detail_parts.append(record)
        well_rows.append({
            "well": wid,
            "fraction": fraction,
            "rows": len(query),
            "true_tail_slope": true_slope,
            "true_negative": bool(true_slope < -1e-4),
            **audit,
            **{f"rmse_{name}": _rmse(truth, pred) for name, pred in predictions.items()},
            **{f"sse_{name}": float(np.sum((truth - pred) ** 2)) for name, pred in predictions.items()},
        })
    if well_number % 10 == 0:
        print(f"{well_number}/{len(eligible)} wells; elapsed {time.time() - started:.1f}s", flush=True)

detail = pd.concat(detail_parts, ignore_index=True) if detail_parts else pd.DataFrame()
well_metrics = pd.DataFrame(well_rows)
print(f"completed {len(well_metrics)} well-fraction cases in {time.time() - started:.1f}s")
"""
    ),
    markdown("## Metrics, uncertainty, and integration decision"),
    code(
        """PREDICTION_COLUMNS = ["anchor", "linear", "datum", "base_selected", "self_raw", "strict", "corr_gate"]

def metric_table(well_metrics: pd.DataFrame) -> pd.DataFrame:
    rows = []
    for fraction in [*MASK_FRACTIONS, "all"]:
        fwells = well_metrics if fraction == "all" else well_metrics[np.isclose(well_metrics["fraction"], fraction)]
        for subset in ("all", "negative", "nonnegative"):
            if subset == "negative":
                use_wells = fwells[fwells.true_negative]
            elif subset == "nonnegative":
                use_wells = fwells[~fwells.true_negative]
            else:
                use_wells = fwells
            if use_wells.empty:
                continue
            for candidate in PREDICTION_COLUMNS:
                rows.append({
                    "fraction": fraction,
                    "subset": subset,
                    "candidate": candidate,
                    "rows": int(use_wells["rows"].sum()),
                    "well_fraction_cases": len(use_wells),
                    "row_rmse": float(np.sqrt(use_wells[f"sse_{candidate}"].sum() / use_wells["rows"].sum())),
                    "equal_well_rmse": float(use_wells[f"rmse_{candidate}"].mean()),
                    "activation_rate_strict": float(use_wells.strict_active.mean()),
                    "activation_rate_corr": float(use_wells.corr_active.mean()),
                })
    return pd.DataFrame(rows)

metrics = metric_table(well_metrics)

unique_wells = np.array(sorted(well_metrics.well.unique()))
rng = np.random.default_rng(SEED)
bootstrap = {}
for candidate in ("strict", "corr_gate"):
    aggregate = well_metrics.groupby("well", sort=True).agg(
        base_sq=("sse_base_selected", "sum"), candidate_sq=(f"sse_{candidate}", "sum"), rows=("rows", "sum")
    ).reindex(unique_wells)
    base_sq = aggregate.base_sq.to_numpy(float)
    candidate_sq = aggregate.candidate_sq.to_numpy(float)
    row_counts = aggregate.rows.to_numpy(float)
    deltas = np.empty(BOOTSTRAP_DRAWS)
    for draw in range(BOOTSTRAP_DRAWS):
        counts = np.bincount(rng.integers(0, len(unique_wells), size=len(unique_wells)), minlength=len(unique_wells))
        rows = float(counts @ row_counts)
        deltas[draw] = np.sqrt((counts @ base_sq) / rows) - np.sqrt((counts @ candidate_sq) / rows)
    bootstrap[candidate] = {
        "draws": BOOTSTRAP_DRAWS,
        "mean": float(deltas.mean()),
        "ci_low": float(np.quantile(deltas, 0.025)),
        "ci_high": float(np.quantile(deltas, 0.975)),
    }

def lookup(candidate: str, subset: str = "all", fraction="all") -> float:
    row = metrics[(metrics.candidate == candidate) & (metrics.subset == subset) & (metrics.fraction.astype(str) == str(fraction))]
    return float("nan") if row.empty else float(row.iloc[0].row_rmse)

strict_overall_gain = lookup("base_selected") - lookup("strict")
strict_negative_gain = lookup("base_selected", "negative") - lookup("strict", "negative")
fraction_gains = {
    str(f): lookup("base_selected", fraction=f) - lookup("strict", fraction=f)
    for f in MASK_FRACTIONS
}
gates = {
    "screen_is_all_eligible": MAX_WELLS == 0,
    "strict_overall_gain_at_least_0_10": strict_overall_gain >= 0.10,
    "strict_negative_gain_at_least_0_25": bool(np.isfinite(strict_negative_gain) and strict_negative_gain >= 0.25),
    "strict_improves_at_least_two_fractions": sum(value > 0 for value in fraction_gains.values()) >= 2,
    "strict_bootstrap_ci_low_positive": bootstrap["strict"]["ci_low"] > 0,
    "predictions_finite": bool(np.isfinite(well_metrics[[f"rmse_{name}" for name in PREDICTION_COLUMNS]].to_numpy(float)).all()),
}
promising_for_s4000_integration = bool(all(value for key, value in gates.items() if key != "screen_is_all_eligible"))

summary = {
    "created_utc": pd.Timestamp.utcnow().isoformat(),
    "code_version": "lateral-self-align-mask-v1",
    "s4000_public_reference": 6.435,
    "selected_wells": len(unique_wells),
    "eligible_mode": "all" if MAX_WELLS == 0 else "deterministic_screen",
    "mask_fractions": list(MASK_FRACTIONS),
    "strict_overall_gain": strict_overall_gain,
    "strict_negative_gain": strict_negative_gain,
    "strict_fraction_gains": fraction_gains,
    "bootstrap": bootstrap,
    "gates": gates,
    "promising_for_s4000_integration": promising_for_s4000_integration,
    "limitations": [
        "This standalone validation does not reproduce the full GS1.30/s4000 prediction path.",
        "True tail direction is used only for diagnostic slices, never for prediction or gating.",
        "A passing screen requires an all-773-well confirmation and then a paired s4000 integration test.",
    ],
    "versions": {"python": platform.python_version(), "numpy": np.__version__, "pandas": pd.__version__},
}

if SAVE_ROW_PREDICTIONS:
    detail.to_csv(OUTPUT_DIR / "masked_prefix_predictions.csv", index=False)
well_metrics.to_csv(OUTPUT_DIR / "masked_prefix_well_metrics.csv", index=False)
metrics.to_csv(OUTPUT_DIR / "masked_prefix_metrics.csv", index=False)
(OUTPUT_DIR / "summary.json").write_text(json.dumps(summary, indent=2) + "\\n")

display(metrics[(metrics.fraction.astype(str) == "all") & (metrics.subset.isin(["all", "negative"]))][
    ["subset", "candidate", "row_rmse", "equal_well_rmse", "activation_rate_strict", "activation_rate_corr"]
])
print(json.dumps(summary, indent=2))
"""
    ),
    markdown(
        """## Interpretation

- If the strict gates fail, do not modify or submit s4000; archive the result as a clean rejection.
- If the 90-well screen passes, rerun with `ROGII_MASK_MAX_WELLS=0` and require the same direction of effect.
- Only after the all-well confirmation should the correction be added to an s4000 fork. That fork must write both the untouched s4000 candidate and the corrected candidate, verify final output differences after all downstream gates, and receive explicit submission approval.
"""
    ),
]

notebook = json.loads(NOTEBOOK.read_text())
for index, cell in enumerate(cells):
    cell["id"] = f"rogii-self-align-{index:02d}"
notebook["cells"] = cells
notebook.setdefault("metadata", {})
notebook["metadata"].setdefault("kernelspec", {"display_name": "Python 3", "language": "python", "name": "python3"})
notebook["metadata"].setdefault("language_info", {"name": "python", "version": "3"})
NOTEBOOK.write_text(json.dumps(notebook, indent=1) + "\n")
print(f"Updated {NOTEBOOK}")
