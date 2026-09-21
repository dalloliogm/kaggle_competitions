#!/usr/bin/env python3
"""Build the fail-safe azimuth-conditioned ROGII GS1.30 notebook fork."""

from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
NOTEBOOK_DIR = REPO_ROOT / "competitions/rogii-wellbore-geology-prediction/notebooks"
BASE_NOTEBOOK = NOTEBOOK_DIR / "rogii-frontier-lab-clean.ipynb"
BASE_METADATA = NOTEBOOK_DIR / "rogii-frontier-lab-clean.kernel-metadata.json"
OUT_NOTEBOOK = NOTEBOOK_DIR / "rogii-gs130-azimuth-conditioned.ipynb"
OUT_METADATA = NOTEBOOK_DIR / "rogii-gs130-azimuth-conditioned.kernel-metadata.json"

KERNEL_ID = "dalloliogm/rogii-gs130-azimuth-conditioned"
KERNEL_TITLE = "ROGII GS1.30 | Azimuth Conditioned"
AZIMUTH_DATASET = "dalloliogm/rogii-gs130-azimuth-models-v1"


MOUNT_COMPAT = '''\
# Kaggle may provision code runs with either the namespaced or legacy input layout.
_competition_data_candidates = (
    '/kaggle/input/competitions/rogii-wellbore-geology-prediction',
    '/kaggle/input/rogii-wellbore-geology-prediction',
)
COMPETITION_DATA_ROOT = next(
    (p for p in _competition_data_candidates if (Path(p) / 'train').exists()),
    _competition_data_candidates[0],
)
_ridge_artifact_candidates = (
    '/kaggle/input/datasets/ravaghi/wellbore-geology-prediction-artifacts',
    '/kaggle/input/wellbore-geology-prediction-artifacts',
)
RIDGE_ARTIFACT_ROOT = next(
    (p for p in _ridge_artifact_candidates if Path(p).exists()),
    _ridge_artifact_candidates[0],
)
print('competition data root:', COMPETITION_DATA_ROOT)
print('ridge artifact root:', RIDGE_ARTIFACT_ROOT)


'''


AZIMUTH_HELPERS = '''\
_AZ_AXIS = None
_AZ_AXIS_SOURCE = None


def _trajectory_unit_vector(hw):
    """Return a robust MD-oriented horizontal unit vector and displacement."""
    survey = hw.loc[:, ["X", "Y", "MD"]].apply(pd.to_numeric, errors="coerce").dropna()
    survey = survey.sort_values("MD", kind="mergesort")
    n = len(survey)
    if n < 20:
        return None, 0.0, "insufficient_rows"
    k = max(10, int(np.ceil(0.05 * n)))
    k = min(k, n // 2)
    start = survey.iloc[:k][["X", "Y"]].median().to_numpy(dtype=float)
    end = survey.iloc[-k:][["X", "Y"]].median().to_numpy(dtype=float)
    vector = end - start
    length = float(np.linalg.norm(vector))
    if not np.isfinite(vector).all() or not np.isfinite(length) or length <= 1e-8:
        return None, 0.0, "invalid_displacement"
    return vector / length, length, "ok"


def _canonical_azimuth_axis(axis):
    axis = np.asarray(axis, dtype=float).reshape(-1)
    if axis.size != 2 or not np.isfinite(axis).all():
        raise ValueError("azimuth axis must contain two finite values")
    norm = float(np.linalg.norm(axis))
    if norm <= 1e-8:
        raise ValueError("azimuth axis has zero length")
    axis = axis / norm
    if axis[0] < 0 or (abs(axis[0]) < 1e-8 and axis[1] > 0):
        axis = -axis
    return axis.astype(np.float64)


def _fit_azimuth_axis(train_wids, data_dir):
    """Fit the unsigned dominant survey axis using training X/Y/MD only."""
    moment = np.zeros((2, 2), dtype=float)
    used = 0
    for wid in sorted(train_wids):
        path = Path(data_dir) / f"{wid}__horizontal_well.csv"
        try:
            hw = pd.read_csv(path, usecols=["X", "Y", "MD"])
            unit, length, _ = _trajectory_unit_vector(hw)
        except Exception:
            continue
        if unit is None or length < float(AZIMUTH_MIN_DISPLACEMENT):
            continue
        moment += np.outer(unit, unit)
        used += 1
    if used == 0:
        return None
    _, vectors = np.linalg.eigh(moment)
    return _canonical_azimuth_axis(vectors[:, -1])


def _azimuth_features(hw, axis):
    unit, length, status = _trajectory_unit_vector(hw)
    if unit is None:
        return dict(az_dir=0.0, az_conf=0.0, az_cos=0.0, az_sin=0.0), status
    az_cos, az_sin = float(unit[0]), float(unit[1])
    if axis is None:
        return dict(az_dir=0.0, az_conf=0.0, az_cos=az_cos, az_sin=az_sin), "axis_unavailable"
    confidence = float(abs(np.dot(unit, axis)))
    direction = 1.0 if float(np.dot(unit, axis)) >= 0 else -1.0
    if length < float(AZIMUTH_MIN_DISPLACEMENT):
        direction, status = 0.0, "short_displacement"
    elif confidence < float(AZIMUTH_MIN_CONFIDENCE):
        direction, status = 0.0, "cross_axis"
    values = dict(az_dir=direction, az_conf=confidence, az_cos=az_cos, az_sin=az_sin)
    if not np.isfinite(np.fromiter(values.values(), dtype=float)).all():
        return dict(az_dir=0.0, az_conf=0.0, az_cos=0.0, az_sin=0.0), "nonfinite"
    return values, status


'''


ARTIFACT_LOADER = '''\
def _load_model_set(root, expected_names=None):
    """Load a feature/model set and verify its inference shape before feature building."""
    import json, joblib
    root = Path(root)
    feature_path = root / "features.json"
    if not feature_path.exists():
        raise ValueError("features.json missing")
    features = json.load(open(feature_path))
    if not isinstance(features, list) or not features or len(features) != len(set(features)):
        raise ValueError("features.json must be a non-empty unique ordered list")
    if expected_names is None:
        model_paths = sorted(root.glob("lgb*.pkl"))
    else:
        model_paths = [root / name for name in expected_names]
        if any(not path.exists() for path in model_paths):
            raise ValueError(f"expected model files missing: {list(expected_names)}")
        discovered = sorted(path.name for path in root.glob("lgb*.pkl"))
        if discovered != sorted(expected_names):
            raise ValueError(f"unexpected lgb model set: {discovered}")
    if not model_paths:
        raise ValueError("no lgb*.pkl models found")
    models = [joblib.load(path) for path in model_paths]
    for path, model in zip(model_paths, models):
        if not callable(getattr(model, "predict", None)):
            raise ValueError(f"{path.name} has no predict method")
        count = getattr(model, "n_features_in_", None)
        if count is not None and int(count) != len(features):
            raise ValueError(f"{path.name} expects {count} features, features.json has {len(features)}")
    return features, models, model_paths


def _load_conditioned_artifact():
    reasons = []
    expected_models = tuple(AZIMUTH_EXPECTED_MODELS)
    for root_text in AZIMUTH_MODEL_ROOTS:
        dataset_root = Path(root_text)
        root = dataset_root / "conditioned" if (dataset_root / "conditioned").is_dir() else dataset_root
        if not root.exists():
            reasons.append(f"{dataset_root}: absent")
            continue
        try:
            features, models, model_paths = _load_model_set(root, expected_models)
            missing = [name for name in AZIMUTH_FEATURES if name not in features]
            if missing:
                raise ValueError(f"features.json missing azimuth features: {missing}")
            manifest_path = root / "azimuth_manifest.json"
            if not manifest_path.exists():
                raise ValueError("azimuth_manifest.json missing")
            manifest = json.load(open(manifest_path))
            manifest_features = manifest.get("feature_list", manifest.get("features"))
            if manifest_features != features:
                raise ValueError("manifest feature order does not exactly match features.json")
            if manifest.get("azimuth_features_active") is not True:
                raise ValueError("manifest does not identify an active conditioned artifact")
            if list(manifest.get("model_files", expected_models)) != list(expected_models):
                raise ValueError("manifest model_files mismatch")
            axis_raw = np.asarray(manifest.get("axis"), dtype=float).reshape(-1)
            if axis_raw.size != 2 or not np.isfinite(axis_raw).all():
                raise ValueError("manifest axis must contain two finite values")
            axis_norm = float(np.linalg.norm(axis_raw))
            if not (0.99 <= axis_norm <= 1.01):
                raise ValueError(f"manifest axis must be unit length, got {axis_norm}")
            axis = _canonical_azimuth_axis(axis_raw)
            thresholds = manifest.get("thresholds", manifest)
            min_disp = float(thresholds.get("min_displacement", np.nan))
            min_conf = float(thresholds.get("min_confidence", np.nan))
            if not np.isfinite([min_disp, min_conf]).all():
                raise ValueError("manifest thresholds missing or non-finite")
            if not np.isclose(min_disp, AZIMUTH_MIN_DISPLACEMENT) or not np.isclose(min_conf, AZIMUTH_MIN_CONFIDENCE):
                raise ValueError("manifest thresholds do not match notebook configuration")
            if manifest.get("deployable") is not True:
                raise ValueError("artifact did not pass the builder deployment gates")
            gates = manifest.get("gates")
            if not isinstance(gates, dict) or not gates or not all(value is True for value in gates.values()):
                raise ValueError("manifest deployment gates are absent or not all true")
            return dict(active=True, reason="compatible conditioned artifact", root=root,
                        features=features, models=models, model_paths=model_paths,
                        manifest=manifest, axis=axis)
        except Exception as exc:
            reasons.append(f"{root}: {type(exc).__name__}: {exc}")
    return dict(active=False, reason="; ".join(reasons) or "no azimuth artifact roots configured",
                root=None, features=None, models=None, model_paths=[], manifest=None, axis=None)


def _load_clean_artifact():
    reasons = []
    for root_text in LEARNED_MODEL_ROOTS:
        root = Path(root_text)
        if not root.exists():
            reasons.append(f"{root}: absent")
            continue
        try:
            features, models, model_paths = _load_model_set(root)
            return dict(root=root, features=features, models=models, model_paths=model_paths)
        except Exception as exc:
            reasons.append(f"{root}: {type(exc).__name__}: {exc}")
    return None, "; ".join(reasons) or "no clean learned artifact roots configured"


def _write_azimuth_runtime_audit(state, **updates):
    import json
    payload = {
        "requested": bool(RUN_AZIMUTH_CONDITIONING),
        "active": bool(state.get("active", False)),
        "reason": str(state.get("reason", "unknown")),
        "artifact_dir": str(state.get("root")) if state.get("root") is not None else None,
        "axis": ([float(v) for v in state.get("axis")] if state.get("axis") is not None else None),
        "expected_features": list(AZIMUTH_FEATURES),
        "expected_models": list(AZIMUTH_EXPECTED_MODELS),
    }
    payload.update(updates)
    with open(CFG.OUT / "azimuth_runtime_audit.json", "w") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
    return payload


'''


MAIN = '''\
def main():
    import json
    global _AZ_AXIS, _AZ_AXIS_SOURCE
    t0 = time.time()
    train_wids = sorted(p.stem.replace("__horizontal_well", "") for p in (CFG.DATA/"train").glob("*__horizontal_well.csv"))
    test_wids = sorted(p.stem.replace("__horizontal_well", "") for p in (CFG.DATA/"test").glob("*__horizontal_well.csv"))
    if CFG.N_TRAIN_WELLS: train_wids = train_wids[:CFG.N_TRAIN_WELLS]
    print(f"train wells: {len(train_wids)} | test wells: {len(test_wids)}")

    az_state = _load_conditioned_artifact() if RUN_AZIMUTH_CONDITIONING else dict(
        active=False, reason="azimuth conditioning disabled", root=None, features=None,
        models=None, model_paths=[], manifest=None, axis=None)
    if az_state["active"]:
        _AZ_AXIS = np.asarray(az_state["axis"], dtype=np.float64)
        _AZ_AXIS_SOURCE = "artifact_manifest"
        print(f"AZIMUTH ACTIVE: validated {az_state['root']} before feature construction")
    else:
        _AZ_AXIS = None
        _AZ_AXIS_SOURCE = None
        print(f"AZIMUTH FALLBACK: {az_state['reason']}")

    clean_artifact, clean_reason = _load_clean_artifact()
    init_imputers(train_wids)   # preserves a manifest axis; otherwise fits train-only diagnostics

    # --- test features are always computed dynamically (works on the hidden test set) ---
    print("building lik-PF + features (test)...", flush=True)
    likpf_test = build_likpf(test_wids, "test")
    test_df = add_likpf_features(build_features(test_wids, "test", is_train=False), likpf_test).reset_index(drop=True)

    az_nonfinite = None
    az_group_counts = {}
    if all(name in test_df.columns for name in AZIMUTH_FEATURES):
        az_matrix = test_df[list(AZIMUTH_FEATURES)].to_numpy(dtype=float)
        az_nonfinite = int((~np.isfinite(az_matrix)).sum())
        if az_nonfinite:
            test_df.loc[:, list(AZIMUTH_FEATURES)] = np.where(np.isfinite(az_matrix), az_matrix, 0.0)
        if "well" in test_df:
            well_dirs = test_df.groupby("well", sort=True)["az_dir"].first()
            az_group_counts = {str(float(k)): int(v) for k, v in well_dirs.value_counts().sort_index().items()}
    elif az_state["active"]:
        az_state.update(active=False, reason="conditioned features were not emitted by build_well")

    if az_state["active"] and az_nonfinite:
        az_state.update(active=False, reason=f"conditioned features contain {az_nonfinite} non-finite values")
    if az_state["active"]:
        runtime_missing = [name for name in az_state["features"] if name not in test_df.columns]
        if runtime_missing:
            az_state.update(active=False, reason=f"conditioned runtime features missing: {runtime_missing}")

    # If runtime feature validation fails, switch to the original clean artifact without rebuilding features.
    if az_state["active"]:
        selected = az_state
    elif clean_artifact is not None:
        selected = dict(active=False, reason=az_state["reason"], axis=az_state.get("axis"), **clean_artifact)
        print(f"AZIMUTH FALLBACK: loading exact clean learned models from {selected['root']}")
    else:
        selected = dict(active=False, reason=f"{az_state['reason']}; clean artifact unavailable: {clean_reason}",
                        root=None, features=None, models=None, model_paths=[], axis=az_state.get("axis"))

    sample_template = pd.read_csv(CFG.DATA/"sample_submission.csv")[["id"]].copy()
    sample_template["id"] = sample_template["id"].astype(str)
    precomputed_path, precomputed_sub = _find_precomputed_learned_submission(sample_template["id"])
    cv_final = None

    if selected.get("models") is not None:
        print(f"INFERENCE mode - loading models from {selected['root']}", flush=True)
        feats = selected["features"]
        missing_features = [c for c in feats if c not in test_df.columns]
        for c in missing_features:
            test_df[c] = 0.0
        Xt = test_df[feats].values.astype(np.float32)
        meta_test = np.mean([model.predict(Xt) for model in selected["models"]], axis=0)
        fallback = float(test_df["last_known_tvt"].mean())
    elif precomputed_sub is not None:
        print(f"INFERENCE mode - using id-exact precomputed clean learned submission from {precomputed_path}", flush=True)
        precomputed_sub.to_csv(CFG.OUT/"submission.csv", index=False)
        _write_azimuth_runtime_audit(selected, axis_source=_AZ_AXIS_SOURCE,
                                     test_well_group_counts=az_group_counts,
                                     nonfinite_feature_values=az_nonfinite,
                                     fallback="clean_precomputed_submission")
        return precomputed_sub, cv_final
    else:
        # ---------- full TRAIN from scratch (self-contained clean fallback) ----------
        print("building lik-PF (train)...", flush=True)
        likpf_train = build_likpf(train_wids, "train")
        print("building features (train)...", flush=True)
        train_df = add_likpf_features(build_features(train_wids, "train", is_train=True), likpf_train)
        feats = [c for c in train_df.columns if c not in {"well", "id", "target"}
                 and not (c.startswith("likpf_scale_") or c == "likpf_mean") and c in test_df.columns]
        if not selected.get("active"):
            feats = [c for c in feats if c not in AZIMUTH_FEATURES]
        print(f"features: {len(feats)} | train rows: {len(train_df)} | test rows: {len(test_df)}")
        meta_oof, meta_test, OOF, TEST = train_stack(train_df, test_df, feats)
        y = train_df["target"].values.astype(float)
        cv_final = rmse(train_df["last_known_tvt"].values + y, make_prediction(train_df, meta_oof, None))
        print(f"\\n*** tuned CV pooled-RMSE (TVT) = {cv_final:.4f} ***")
        fallback = float(train_df["last_known_tvt"].mean() + y.mean())

    test_pred = make_prediction(test_df, meta_test, None)
    sub = pd.read_csv(CFG.DATA/"sample_submission.csv")
    sub["tvt"] = sub["id"].map(dict(zip(test_df["id"], test_pred))).fillna(fallback)
    sub.to_csv(CFG.OUT/"submission.csv", index=False)
    _write_azimuth_runtime_audit(selected, axis_source=_AZ_AXIS_SOURCE,
                                 selected_feature_count=len(feats),
                                 selected_model_files=[p.name for p in selected.get("model_paths", [])],
                                 test_well_group_counts=az_group_counts,
                                 nonfinite_feature_values=az_nonfinite,
                                 fallback=(None if selected.get("active") else "clean_learned_pipeline"))
    print(f"submission.csv written ({len(sub)} rows) in {time.time()-t0:.0f}s")
    return sub, cv_final

sub, cv_final = main()
sub.head()
'''


FINAL_AUDIT_CELL = '''\
# Refresh the azimuth audit after every downstream mutation and the final schema guard.
import hashlib as _hashlib
import json as _json

_az_audit_path = CFG.OUT / "azimuth_runtime_audit.json"
_az_final_path = CFG.OUT / "submission.csv"
if _az_audit_path.exists() and _az_final_path.exists():
    _az_audit = _json.load(open(_az_audit_path))
    _az_final = pd.read_csv(_az_final_path)
    _az_audit["final_submission"] = {
        "rows": int(len(_az_final)),
        "columns": list(_az_final.columns),
        "unique_ids": int(_az_final["id"].astype(str).nunique()),
        "finite_tvt": bool(np.isfinite(pd.to_numeric(_az_final["tvt"], errors="coerce")).all()),
        "sha256": _hashlib.sha256(_az_final_path.read_bytes()).hexdigest(),
    }
    _az_learned_path = CFG.OUT / "learned_trajectory_submission.csv"
    if _az_learned_path.exists():
        _az_learned = pd.read_csv(_az_learned_path)[["id", "tvt"]].rename(columns={"tvt": "learned_tvt"})
        _az_cmp = _az_final[["id", "tvt"]].merge(_az_learned, on="id", how="left", validate="one_to_one")
        _az_diff = np.abs(_az_cmp["tvt"].to_numpy(float) - _az_cmp["learned_tvt"].to_numpy(float))
        _az_audit["final_vs_learned"] = {
            "changed_over_1e_6": int((_az_diff > 1e-6).sum()),
            "mean_abs_difference": float(np.mean(_az_diff)),
            "rms_difference": float(np.sqrt(np.mean(_az_diff ** 2))),
        }
    with open(_az_audit_path, "w") as _handle:
        _json.dump(_az_audit, _handle, indent=2, sort_keys=True)
    print("azimuth runtime audit refreshed after final submission guard:", _az_audit_path)
else:
    print("AZIMUTH AUDIT WARNING: final submission or runtime audit is absent")
'''


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one {label} replacement, found {count}")
    return text.replace(old, new, 1)


def source(cell: dict) -> str:
    return "".join(cell.get("source", []))


def build_notebook(base: dict) -> tuple[dict, list[int]]:
    nb = copy.deepcopy(base)
    changed = []

    config = source(nb["cells"][0])
    config = "# ROGII GS1.30 isolated azimuth-conditioned learned-model experiment.\n" + config
    config = replace_once(
        config,
        "LEARNED_MODEL_ROOTS = (\n"
        "    '/kaggle/input/datasets/fleongg/rogii-claude-models-pub',\n"
        "    '/kaggle/input/rogii-claude-models-pub',\n"
        ")",
        "LEARNED_MODEL_ROOTS = (\n"
        "    '/kaggle/input/datasets/fleongg/rogii-claude-models-pub',\n"
        "    '/kaggle/input/rogii-claude-models-pub',\n"
        ")\n"
        "RUN_AZIMUTH_CONDITIONING = True\n"
        "AZIMUTH_MIN_DISPLACEMENT = 250.0\n"
        "AZIMUTH_MIN_CONFIDENCE = 0.50\n"
        "AZIMUTH_FEATURES = ('az_dir', 'az_conf', 'az_cos', 'az_sin')\n"
        "AZIMUTH_EXPECTED_MODELS = ('lgb0.pkl', 'lgb1.pkl', 'lgb2.pkl')\n"
        "AZIMUTH_MODEL_ROOTS = (\n"
        "    '/kaggle/input/datasets/dalloliogm/rogii-gs130-azimuth-models-v1',\n"
        "    '/kaggle/input/rogii-gs130-azimuth-models-v1',\n"
        ")",
        "azimuth configuration",
    )
    nb["cells"][0]["source"] = config.splitlines(keepends=True)
    changed.append(0)

    cfg = source(nb["cells"][4])
    if not cfg.startswith("class CFG:"):
        raise RuntimeError("Unexpected first CFG cell layout")
    nb["cells"][4]["source"] = (MOUNT_COMPAT + cfg).splitlines(keepends=True)
    changed.append(4)

    feature_cell = source(nb["cells"][34])
    feature_cell = replace_once(feature_cell, "def build_well(hw_path, tw_path, is_train, likpf_map=None):", AZIMUTH_HELPERS + "def build_well(hw_path, tw_path, is_train, likpf_map=None):", "azimuth helper insertion")
    feature_cell = replace_once(
        feature_cell,
        "    if len(tw_tvt) < 3: return None\n    pf_a, std_a = run_pf_ancc(hw, tw_tvt, tw_gr)",
        "    if len(tw_tvt) < 3: return None\n"
        "    az_values, _az_status = _azimuth_features(hw, _AZ_AXIS)\n"
        "    pf_a, std_a = run_pf_ancc(hw, tw_tvt, tw_gr)",
        "per-well azimuth calculation",
    )
    feature_cell = replace_once(
        feature_cell,
        '    feats={"well":wid,"id":[f"{wid}_{i}" for i in ev.index],"last_known_tvt":sc(last_tvt),',
        '    feats={"well":wid,"id":[f"{wid}_{i}" for i in ev.index],"last_known_tvt":sc(last_tvt),\n'
        '        "az_dir":sc(az_values["az_dir"]),"az_conf":sc(az_values["az_conf"]),\n'
        '        "az_cos":sc(az_values["az_cos"]),"az_sin":sc(az_values["az_sin"]),',
        "azimuth feature columns",
    )
    feature_cell = replace_once(
        feature_cell,
        "def init_imputers(train_wids):\n    global _FI, _DI\n    _FI = FormationPlaneKNN(train_wids, CFG.DATA/\"train\"); _DI = DenseANCCImputer(train_wids, CFG.DATA/\"train\")",
        "def init_imputers(train_wids):\n"
        "    global _FI, _DI, _AZ_AXIS, _AZ_AXIS_SOURCE\n"
        "    _FI = FormationPlaneKNN(train_wids, CFG.DATA/\"train\"); _DI = DenseANCCImputer(train_wids, CFG.DATA/\"train\")\n"
        "    if _AZ_AXIS is None:\n"
        "        _AZ_AXIS = _fit_azimuth_axis(train_wids, CFG.DATA/\"train\")\n"
        "        _AZ_AXIS_SOURCE = \"train_xy_diagnostic\" if _AZ_AXIS is not None else \"unavailable\"",
        "azimuth axis initialization",
    )
    nb["cells"][34]["source"] = feature_cell.splitlines(keepends=True)
    changed.append(34)

    inference_cell = source(nb["cells"][37])
    precomputed_start = inference_cell.index("def _find_precomputed_learned_submission")
    main_start = inference_cell.index("def main():")
    precomputed = inference_cell[precomputed_start:main_start]
    nb["cells"][37]["source"] = (ARTIFACT_LOADER + precomputed + MAIN).splitlines(keepends=True)
    changed.append(37)

    nb["cells"].append({
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": FINAL_AUDIT_CELL.splitlines(keepends=True),
    })
    changed.append(len(nb["cells"]) - 1)

    for cell in nb["cells"]:
        if cell.get("cell_type") == "code":
            cell["execution_count"] = None
            cell["outputs"] = []
            cell.get("metadata", {}).pop("execution", None)
            cell.get("metadata", {}).pop("papermill", None)
    return nb, changed


def validate_notebook(base: dict, built: dict, expected_changed: list[int]) -> None:
    if built.get("nbformat") != 4 or not isinstance(built.get("cells"), list):
        raise RuntimeError("invalid notebook shape")
    for idx, cell in enumerate(built["cells"]):
        if cell.get("cell_type") == "code":
            compile(source(cell), f"{OUT_NOTEBOOK.name}:cell-{idx}", "exec")
            if cell.get("execution_count") is not None or cell.get("outputs"):
                raise RuntimeError(f"cell {idx} retained execution state")
    actual_changed = []
    for idx in range(len(base["cells"])):
        before = source(base["cells"][idx])
        after = source(built["cells"][idx])
        if before != after:
            actual_changed.append(idx)
    if len(built["cells"]) != len(base["cells"]) + 1:
        raise RuntimeError("expected exactly one appended audit cell")
    if actual_changed + [len(built["cells"]) - 1] != expected_changed:
        raise RuntimeError(f"unexpected changed cells: {actual_changed}, expected {expected_changed}")
    joined = "\n".join(source(cell) for cell in built["cells"])
    required = ["RUN_AZIMUTH_CONDITIONING = True", "azimuth_manifest.json", "AZIMUTH FALLBACK",
                "azimuth_runtime_audit.json", "_fit_azimuth_axis", "_trajectory_unit_vector"]
    missing = [token for token in required if token not in joined]
    if missing:
        raise RuntimeError(f"missing required azimuth hooks: {missing}")
    if "Q0522" in joined and joined.count("Q0522") != "\n".join(source(cell) for cell in base["cells"]).count("Q0522"):
        raise RuntimeError("Q0522 content changed")


def main() -> None:
    base = json.loads(BASE_NOTEBOOK.read_text())
    metadata = json.loads(BASE_METADATA.read_text())
    built, changed = build_notebook(base)
    validate_notebook(base, built, changed)
    OUT_NOTEBOOK.write_text(json.dumps(built, indent=1, ensure_ascii=False) + "\n")

    metadata = copy.deepcopy(metadata)
    metadata.update(id=KERNEL_ID, title=KERNEL_TITLE, code_file=OUT_NOTEBOOK.name)
    sources = list(metadata.get("dataset_sources", []))
    if AZIMUTH_DATASET not in sources:
        sources.append(AZIMUTH_DATASET)
    metadata["dataset_sources"] = sources
    OUT_METADATA.write_text(json.dumps(metadata, indent=2) + "\n")

    digest = hashlib.sha256(OUT_NOTEBOOK.read_bytes()).hexdigest()
    print(f"built {OUT_NOTEBOOK.relative_to(REPO_ROOT)}")
    print(f"built {OUT_METADATA.relative_to(REPO_ROOT)}")
    print(f"changed source cells: {changed[:-1]} + appended final audit cell {changed[-1]}")
    print(f"compiled {sum(c.get('cell_type') == 'code' for c in built['cells'])} code cells")
    print(f"sha256 {digest}")


if __name__ == "__main__":
    main()
