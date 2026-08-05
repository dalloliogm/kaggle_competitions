"""Run the real quick_baseline.py stage per task and score it against solution.csv.

End-to-end: executes the actual submitted script through its own entry point,
then grades the CSV it wrote. Catches breakage anywhere in the pipeline, not
just in the dtype predicate.
"""
import json
import os
import runpy
import sys
import tempfile
import shutil
from pathlib import Path

SCRIPTS = Path(sys.argv[1])
DATA = Path(sys.argv[2])
TASKS = sys.argv[3].split(",") if len(sys.argv) > 3 else None

import pandas as pd  # noqa: E402
from sklearn.metrics import roc_auc_score  # noqa: E402

out = {"pandas": pd.__version__, "tasks": {}}
for task in sorted(DATA.glob("train_*")):
    if TASKS and task.name not in TASKS:
        continue
    work = Path(tempfile.mkdtemp())
    try:
        # Solution-blind: copy only what the agent would see.
        for f in ["train.csv", "test.csv", "sample_submission.csv"]:
            if (task / f).exists():
                shutil.copy(task / f, work / f)

        os.environ["ROBUST_TABULAR_WORKDIR"] = str(work)
        sys.argv = [str(SCRIPTS / "quick_baseline.py")]
        sys.path.insert(0, str(SCRIPTS))
        for mod in ["common"]:
            sys.modules.pop(mod, None)
        runpy.run_path(str(SCRIPTS / "quick_baseline.py"), run_name="__main__")
        sys.path.remove(str(SCRIPTS))

        pred = pd.read_csv(work / "quick_baseline.csv")
        sol = pd.read_csv(task / "solution.csv")
        id_col = sol.columns[0]
        # solution.csv carries a trailing `Usage` (Public/Private) column that is
        # NOT the label. Grade against the real target column only.
        pcol = [c for c in pred.columns if c != id_col][-1]
        truth_cols = [c for c in sol.columns if c not in (id_col, "Usage")]
        ycol = pcol if pcol in truth_cols else truth_cols[-1]
        merged = sol.merge(pred, on=id_col, suffixes=("_true", "_pred"))
        yt = merged[ycol + "_true"] if ycol + "_true" in merged else merged[ycol]
        yp = merged[pcol + "_pred"] if pcol + "_pred" in merged else merged[pcol]
        assert pd.api.types.is_numeric_dtype(yt), f"truth column {ycol} is not numeric"
        assert len(merged) == len(pred), f"merge dropped rows: {len(merged)} vs {len(pred)}"
        res = {"all": round(float(roc_auc_score(yt, yp)), 5)}
        if "Usage" in sol.columns:
            for part in ("Public", "Private"):
                m = merged["Usage"] == part
                if m.any():
                    res[part.lower()] = round(float(roc_auc_score(yt[m], yp[m])), 5)
        out["tasks"][task.name] = res
    except Exception as exc:  # noqa: BLE001
        out["tasks"][task.name] = f"ERROR {type(exc).__name__}: {exc}"
    finally:
        shutil.rmtree(work, ignore_errors=True)

print("RESULT " + json.dumps(out, sort_keys=True))
