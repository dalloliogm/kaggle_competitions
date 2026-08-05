"""Schema discovery and submission helpers for the robust tabular skill."""

from __future__ import annotations

import glob
import json
import os
from pathlib import Path

import numpy as np
import pandas as pd


BAD_TOKENS = ("solution", "answer", "truth", "ground", "labelled_test")


def runtime_workdir() -> Path:
    """Return the harness data directory, with a current-directory fallback for offline tests."""
    override = os.environ.get("ROBUST_TABULAR_WORKDIR")
    if override:
        candidate = Path(override).expanduser().resolve()
        if candidate.is_dir():
            return candidate
    harness = Path("/work")
    if harness.is_dir():
        names = {path.name.lower() for path in harness.glob("*.csv")}
        if any("train" in name for name in names) and any("test" in name for name in names):
            return harness
    return Path.cwd()


def _safe_csvs(task_dir: str | os.PathLike[str]) -> list[str]:
    paths = glob.glob(os.path.join(str(task_dir), "**", "*.csv"), recursive=True)
    return [
        path
        for path in paths
        if not any(token in os.path.basename(path).lower() for token in BAD_TOKENS)
    ]


def discover_files(task_dir: str | os.PathLike[str] = ".") -> tuple[str, str, str | None]:
    csvs = _safe_csvs(task_dir)

    def pick(required: tuple[str, ...], forbidden: tuple[str, ...] = ()) -> str | None:
        for path in sorted(csvs, key=lambda value: (len(Path(value).parts), len(value))):
            name = os.path.basename(path).lower()
            if any(token in name for token in required) and not any(token in name for token in forbidden):
                return path
        return None

    train_path = pick(("train",), ("sample", "submission"))
    test_path = pick(("test",), ("sample", "submission"))
    sample_path = pick(("sample_submission", "samplesubmission", "sample-submission"))
    if train_path is None or test_path is None:
        raise FileNotFoundError(f"train/test CSV not found; visible CSV count={len(csvs)}")
    return train_path, test_path, sample_path


def infer_id(train: pd.DataFrame, test: pd.DataFrame, sample: pd.DataFrame | None) -> str | None:
    if sample is not None and len(sample.columns) and sample.columns[0] in test.columns:
        return str(sample.columns[0])
    preferred = ("row_id", "id", "sample_id", "record_id", "uid", "index")
    for column in test.columns:
        low = str(column).lower()
        if low in preferred or low.endswith("_id"):
            return str(column)
    for column in test.columns:
        if column in train.columns and train[column].is_unique and test[column].is_unique:
            return str(column)
    return None


def infer_target(train: pd.DataFrame, test: pd.DataFrame, sample: pd.DataFrame | None, id_col: str | None) -> str:
    train_only = [column for column in train.columns if column not in test.columns and column != id_col]
    preferred = ("target", "label", "class", "outcome", "response", "y")
    for column in train_only:
        if str(column).lower() in preferred:
            return str(column)
    if len(train_only) == 1:
        return str(train_only[0])
    for column in train_only:
        if train[column].nunique(dropna=True) == 2:
            return str(column)
    if sample is not None:
        for column in sample.columns[1:]:
            if column in train.columns:
                return str(column)
    raise ValueError(f"binary target could not be inferred from train-only columns={train_only}")


def normalize_binary(y: pd.Series) -> np.ndarray:
    values = list(pd.unique(y.dropna()))
    if len(values) != 2:
        raise ValueError(f"expected binary target, found {len(values)} values")
    if pd.api.types.is_numeric_dtype(y) and set(values).issubset({0, 1, 0.0, 1.0}):
        return y.astype(int).to_numpy()
    positive = sorted(values, key=lambda value: str(value))[-1]
    return (y == positive).astype(int).to_numpy()


def load_task(task_dir: str | os.PathLike[str] = "."):
    train_path, test_path, sample_path = discover_files(task_dir)
    train = pd.read_csv(train_path, engine="pyarrow")
    test = pd.read_csv(test_path, engine="pyarrow")
    sample = pd.read_csv(sample_path, engine="pyarrow") if sample_path else None
    id_col = infer_id(train, test, sample)
    target_col = infer_target(train, test, sample, id_col)
    features = [column for column in test.columns if column in train.columns and column != id_col]
    if not features:
        raise ValueError("no shared modeling features")
    y = normalize_binary(train[target_col])
    return train, test, sample, id_col, target_col, features, y


def _is_string_extension_dtype(dtype) -> bool:
    """True for pandas string extension dtypes, which are not object dtype.

    pandas 3.x returns an arrow-backed string dtype from
    ``read_csv(..., engine="pyarrow")`` where pandas 2.x returned ``object``.
    That dtype is neither object nor categorical, so without this check every
    text column is silently classified numeric.

    Additive by construction: on pandas 2.x those columns *are* object dtype, so
    the caller's first predicate already matches and this can never change the
    result there.
    """
    string_dtype = getattr(pd, "StringDtype", None)
    if string_dtype is not None and isinstance(dtype, string_dtype):
        return True
    arrow_dtype = getattr(pd, "ArrowDtype", None)
    if arrow_dtype is not None and isinstance(dtype, arrow_dtype):
        try:
            import pyarrow as pa

            pa_type = dtype.pyarrow_dtype
            return bool(
                pa.types.is_string(pa_type)
                or pa.types.is_large_string(pa_type)
                or pa.types.is_dictionary(pa_type)
            )
        except Exception:
            return False
    return str(getattr(dtype, "name", "")) in {"str", "string"}


def _coerces_entirely_to_nan(series: pd.Series) -> bool:
    """True when a column holds data but none of it survives numeric coercion.

    The dtype-agnostic backstop. Whatever a future pandas names its text dtype,
    a feature that has values yet yields all-NaN under ``to_numeric`` is text,
    and treating it as numeric hands every model a constant-NaN column. This
    cannot fire for a genuinely numeric column, and deliberately does not fire
    for an all-null column, which stays numeric exactly as before.
    """
    if int(series.notna().sum()) == 0:
        return False
    return int(pd.to_numeric(series, errors="coerce").notna().sum()) == 0


def categorical_columns(frame: pd.DataFrame, features: list[str]) -> list[str]:
    return [
        column
        for column in features
        if pd.api.types.is_object_dtype(frame[column])
        or isinstance(frame[column].dtype, pd.CategoricalDtype)
        or pd.api.types.is_bool_dtype(frame[column])
        or _is_string_extension_dtype(frame[column].dtype)
        or _coerces_entirely_to_nan(frame[column])
    ]


def sklearn_frame(frame: pd.DataFrame, features: list[str], cat_cols: list[str]) -> pd.DataFrame:
    """Return a feature frame using the containers scikit-learn expects.

    Only needed by the estimators fed the *raw* frame (the logistic candidate),
    which never pass through ``native_frames``/``encoded_frames``.

    The goal is to reproduce the pandas 2 containers exactly, *including their
    quirks* -- not to improve on them.

    Under pandas 2, ``read_csv(engine="pyarrow")`` yields object columns whose
    missing entries are ``None``. ``SimpleImputer`` detects NaN with ``X != X``,
    which is False for ``None``, so those entries are never imputed and reach
    ``OneHotEncoder`` as a category of their own. Under pandas 3 the column is an
    arrow-backed string dtype whose missing entries surface as NaN, which *is*
    detected and imputed -- a different fitted model.

    So the sentinel has to be ``None``, not ``np.nan``. Using ``np.nan`` here was
    measured to shift the logistic candidate's CV AUC on train_08 from 0.85434 to
    0.84671, i.e. it would silently change behaviour on the current image, which
    is exactly what this package must not do.
    """
    out = frame[features].copy()
    for column in cat_cols:
        mask = np.asarray(out[column].isna())
        # copy=True is required: pandas 3 can hand back a zero-copy read-only
        # view, and assigning into it raises "assignment destination is
        # read-only".
        values = np.array(out[column].astype(object).to_numpy(dtype=object), dtype=object, copy=True)
        values[mask] = None
        out[column] = pd.Series(values, index=out.index, dtype=object)
    return out


def native_frames(train: pd.DataFrame, test: pd.DataFrame, features: list[str]):
    x_train = train[features].copy()
    x_test = test[features].copy()
    cat_cols = categorical_columns(x_train, features)
    for column in cat_cols:
        x_train[column] = x_train[column].fillna("__MISSING__").astype(str)
        x_test[column] = x_test[column].fillna("__MISSING__").astype(str)
    for column in (item for item in features if item not in cat_cols):
        x_train[column] = pd.to_numeric(x_train[column], errors="coerce").replace([np.inf, -np.inf], np.nan)
        x_test[column] = pd.to_numeric(x_test[column], errors="coerce").replace([np.inf, -np.inf], np.nan)
    return x_train, x_test, cat_cols


def encoded_frames(train: pd.DataFrame, test: pd.DataFrame, features: list[str]):
    x_train = train[features].copy()
    x_test = test[features].copy()
    cat_cols = categorical_columns(x_train, features)
    for column in features:
        if column in cat_cols:
            combined = pd.concat([x_train[column], x_test[column]], ignore_index=True).fillna("__MISSING__").astype(str)
            codes, _ = pd.factorize(combined, sort=True)
            x_train[column] = codes[: len(x_train)]
            x_test[column] = codes[len(x_train) :]
        else:
            tr = pd.to_numeric(x_train[column], errors="coerce").replace([np.inf, -np.inf], np.nan)
            te = pd.to_numeric(x_test[column], errors="coerce").replace([np.inf, -np.inf], np.nan)
            median = float(tr.median()) if tr.notna().any() else 0.0
            x_train[column] = tr.fillna(median)
            x_test[column] = te.fillna(median)
    return x_train.astype(float), x_test.astype(float), cat_cols


def write_submission(
    path: str | os.PathLike[str],
    predictions: np.ndarray,
    test: pd.DataFrame,
    sample: pd.DataFrame | None,
    id_col: str | None,
    target_col: str,
) -> str:
    predictions = np.asarray(predictions, dtype=float)
    predictions = np.nan_to_num(predictions, nan=0.5, posinf=1.0, neginf=0.0)
    predictions = np.clip(predictions, 1e-6, 1 - 1e-6)
    if len(predictions) != len(test):
        raise ValueError(f"prediction rows={len(predictions)} test rows={len(test)}")
    if sample is not None:
        output = sample.copy()
        if len(output) != len(test):
            raise ValueError("sample-submission row count does not match test")
        prediction_cols = [column for column in output.columns if column != id_col]
        if not prediction_cols:
            prediction_cols = [output.columns[-1]]
        output[prediction_cols[-1]] = predictions
    else:
        ids = test[id_col] if id_col and id_col in test.columns else np.arange(len(test))
        output = pd.DataFrame({id_col or "row_id": ids, target_col: predictions})
    if not np.isfinite(output.iloc[:, -1].to_numpy(dtype=float)).all():
        raise ValueError("non-finite predictions after sanitization")
    output.to_csv(path, index=False)
    return str(path)


def rank_unit(values: np.ndarray) -> np.ndarray:
    series = pd.Series(np.asarray(values, dtype=float))
    return series.rank(method="average", pct=True).to_numpy()


def emit_manifest(payload: dict) -> None:
    print("PORTFOLIO_MANIFEST=" + json.dumps(payload, sort_keys=True, separators=(",", ":")))