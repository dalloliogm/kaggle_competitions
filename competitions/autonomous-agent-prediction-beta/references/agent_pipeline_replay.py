"""Replay one submitted-agent modeling script in a separate process per task."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import pandas as pd
from sklearn.metrics import roc_auc_score


DEFAULT_DATA_ROOT = Path("/tmp/autonomous-agent-replay/extracted/data")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--script", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--data-root", type=Path, default=DEFAULT_DATA_ROOT)
    parser.add_argument(
        "--feature-mode",
        choices=["none", "numeric", "auto", "adaptive", "plan"],
        default="none",
    )
    parser.add_argument("--plan", type=Path, default=None)
    args = parser.parse_args()

    task_dirs = sorted(args.data_root.glob("train_*"))
    if not task_dirs:
        raise SystemExit(f"No replay tasks found under {args.data_root}")
    script = args.script.resolve()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    results = []

    with tempfile.TemporaryDirectory(prefix="agent-pipeline-replay-") as temp_dir:
        temp_root = Path(temp_dir)
        for task_dir in task_dirs:
            prediction_path = temp_root / f"{task_dir.name}.csv"
            command = [
                sys.executable,
                str(script),
                "--data-dir",
                str(task_dir),
                "--feature-mode",
                args.feature_mode,
                "--output",
                str(prediction_path),
            ]
            if args.feature_mode == "plan":
                if not args.plan:
                    raise SystemExit("--plan is required with feature-mode plan")
                command.extend(["--plan", str(args.plan.resolve())])
            started = time.monotonic()
            completed = subprocess.run(
                command,
                text=True,
                capture_output=True,
                check=False,
            )
            elapsed = time.monotonic() - started
            result = {
                "task": task_dir.name,
                "returncode": completed.returncode,
                "seconds": elapsed,
                "test_auc": None,
                "method": None,
                "cv_auc": None,
                "base_features": None,
                "total_features": None,
                "engineered_features": None,
                "error": None,
            }
            if completed.returncode == 0 and prediction_path.exists():
                prediction = pd.read_csv(prediction_path)
                solution = pd.read_csv(task_dir / "solution.csv")
                target_candidates = [
                    column for column in solution if column in prediction
                ]
                target = target_candidates[-1]
                result["test_auc"] = roc_auc_score(
                    solution[target],
                    prediction[target],
                )
                try:
                    report = json.loads(completed.stdout.strip().splitlines()[-1])
                    feature_metadata = report.get("feature_metadata", {})
                    result.update(
                        {
                            "method": report.get("method"),
                            "cv_auc": report.get("cv_auc"),
                            "base_features": feature_metadata.get("base_features"),
                            "total_features": feature_metadata.get(
                                "total_features",
                                feature_metadata.get("base_features"),
                            ),
                            "engineered_features": len(
                                feature_metadata.get("engineered_features", [])
                            ),
                        }
                    )
                except Exception as error:
                    result["error"] = f"report parse: {error}"
            else:
                result["error"] = (
                    completed.stderr.strip()[-1000:]
                    or completed.stdout.strip()[-1000:]
                    or "modeling command failed"
                )
            results.append(result)
            pd.DataFrame(results).to_csv(args.output, index=False)
            print(json.dumps(result), flush=True)

    scored = pd.DataFrame(results).dropna(subset=["test_auc"])
    print(
        "SUMMARY "
        + json.dumps(
            {
                "tasks": len(results),
                "scored": len(scored),
                "mean_auc": scored["test_auc"].mean(),
                "median_auc": scored["test_auc"].median(),
                "mean_seconds": scored["seconds"].mean(),
                "output": str(args.output),
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
