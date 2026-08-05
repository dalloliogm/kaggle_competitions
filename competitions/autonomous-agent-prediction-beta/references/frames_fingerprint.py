"""Fingerprint the exact model inputs common.py produces for every practice task.

Hashes the native and encoded frames that feed CatBoost/LightGBM/ExtraTrees/
logistic. Identical fingerprints mean identical model inputs, hence identical
models and identical AUC -- a stronger check than comparing scores.
"""
import hashlib
import json
import sys
from pathlib import Path

SCRIPTS = sys.argv[1]
DATA = Path(sys.argv[2])
sys.path.insert(0, SCRIPTS)

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
import common  # noqa: E402


def digest(frame: pd.DataFrame) -> str:
    h = hashlib.sha256()
    for col in frame.columns:
        h.update(str(col).encode())
        s = frame[col]
        # Normalise representation so a dtype-container difference alone
        # (object vs arrow-backed str) does not register as a data difference.
        if pd.api.types.is_numeric_dtype(s) and not pd.api.types.is_bool_dtype(s):
            arr = pd.to_numeric(s, errors="coerce").to_numpy(dtype="float64", na_value=np.nan)
            h.update(np.ascontiguousarray(arr).tobytes())
        else:
            h.update(chr(31).join(s.astype(str).tolist()).encode())
    return h.hexdigest()[:16]


out = {"pandas": pd.__version__, "tasks": {}}
for task in sorted(DATA.glob("train_*")):
    try:
        train, test, sample, id_col, target_col, features, y = common.load_task(task)
        nat_tr, nat_te, nat_cats = common.native_frames(train, test, features)
        enc_tr, enc_te, enc_cats = common.encoded_frames(train, test, features)
        out["tasks"][task.name] = {
            "cats": sorted(nat_cats),
            "n_cat": len(nat_cats),
            "native_train": digest(nat_tr),
            "native_test": digest(nat_te),
            "encoded_train": digest(enc_tr),
            "encoded_test": digest(enc_te),
            "y_sum": int(np.asarray(y).sum()),
            "n_rows": int(len(train)),
        }
    except Exception as exc:  # noqa: BLE001
        out["tasks"][task.name] = {"error": f"{type(exc).__name__}: {exc}"}

print(json.dumps(out, indent=1, sort_keys=True))
