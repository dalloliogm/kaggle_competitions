"""Build the original Exp203 classical detector/linker candidate."""

from __future__ import annotations

import json
from pathlib import Path


SOURCE = Path("/tmp/kunal-raw.txt")
OUT = Path(
    "competitions/biohub-cell-tracking-during-development/notebooks/"
    "biohub-exp203-classical-ensemble.ipynb"
)
META = OUT.with_name(OUT.stem + ".kernel-metadata.json")


def md(text: str) -> dict:
    return {"cell_type": "markdown", "metadata": {}, "source": text.splitlines(keepends=True)}


def code(text: str) -> dict:
    return {
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": text.splitlines(keepends=True),
    }


def main() -> None:
    raw = SOURCE.read_text()
    notebook = json.loads(raw[raw.index("{") :])
    cells = [cell for cell in notebook["cells"] if cell.get("source")]

    intro = md(
        """# Exp203 — Three-Classical-Model Cell Tracking

This is an original, submission-shaped adaptation of the classical
detector/linker idea seen in recent public Biohub notebooks. It is not claimed
to reproduce their leaderboard score.

## Hypothesis

Different preprocessing pipelines expose different cell appearances. We
therefore average three independently trained 3D U-Net heatmaps before peak
detection:

- a bright-cell model on the pooled raw volume;
- a top-hat model on a background-subtracted volume;
- a second top-hat checkpoint for an independent model view.

The ensemble averages confidence maps, rather than unioning detections.
Unioning would inflate node counts and is punished by the metric. After
detection, physical NMS prevents duplicate centroids, velocity-aware Hungarian
assignment links adjacent frames, conservative gap repair is applied,
short components are removed, and a local line fit smooths trajectories.

This is deliberately a structurally different branch from our learned
graph/ranker stack. The output audit below is the submission gate."""
    )

    provenance = md(
        """## Provenance and interpretation

Reference inspected: kunaldesale2408/biohub-cell-tracking (current public v4
source). Its verified v3 score belongs to a different learned graph pipeline,
so that 0.916 score is not evidence for this classical branch.

The classical checkpoints come from the public xiaoleilian/biohub-unet3d-weights
and xiaoleilian/biohub-unet3d-weights-v2models datasets.

Expected result: a valid, interpretable candidate with a distinct node and
edge signature. A leaderboard submission should happen only after this
notebook completes and the audit passes."""
    )

    first = "".join(cells[0]["source"])
    cells[0]["source"] = (
        "EXPERIMENT_TAG = 'exp203_classical_three_model_ensemble'\n" + first
    ).splitlines(keepends=True)

    output = """parts = []
for zp in sorted(TEST_DIR.glob("*.zarr")):
    ds = zp.name.replace(".zarr", "")
    T = avail_T(zp)
    if T == 0:
        print("skip", ds)
        continue
    t0 = time.time()
    nodes, edges = track_movie(zp, ds, T)
    parts.extend([nodes, edges])
    print(f"{ds}: T={T} nodes={len(nodes)} edges={len(edges)} runtime={time.time() - t0:.1f}s")

submission = pd.concat(parts, ignore_index=True)
submission.insert(0, "id", np.arange(len(submission), dtype=np.int64))
expected = ["id", "dataset", "row_type", "node_id", "t", "z", "y", "x", "source_id", "target_id"]
assert list(submission.columns) == expected
assert submission["dataset"].notna().all()
assert set(submission["row_type"].unique()) <= {"node", "edge"}

nodes = submission[submission.row_type == "node"].copy()
edges = submission[submission.row_type == "edge"].copy()
node_keys = set(zip(nodes.dataset, nodes.node_id))
assert len(node_keys) == len(nodes), "duplicate dataset/node IDs"
assert all(
    (ds, int(src)) in node_keys and (ds, int(dst)) in node_keys
    for ds, src, dst in zip(edges.dataset, edges.source_id, edges.target_id)
)
assert len(submission) == len(nodes) + len(edges)
assert len(nodes) > 0 and len(edges) > 0

SUBMISSION_PATH = Path("submission.csv")
submission.to_csv(SUBMISSION_PATH, index=False)
print(
    f"Wrote {SUBMISSION_PATH} | rows={len(submission):,} "
    f"nodes={len(nodes):,} edges={len(edges):,}"
)
print(submission.groupby(["dataset", "row_type"]).size().unstack(fill_value=0))
"""
    cells[-1] = code(output)

    notebook["cells"] = [intro, provenance, *cells]
    notebook["metadata"] = {
        "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
        "language_info": {"name": "python", "version": "3.12"},
        "kaggle": {
            "accelerator": "NvidiaTeslaT4",
            "isGpuEnabled": True,
            "isInternetEnabled": False,
            "language": "python",
            "sourceType": "notebook",
            "competitionSources": ["biohub-cell-tracking-during-development"],
            "datasetSources": [
                "xiaoleilian/biohub-unet3d-weights",
                "xiaoleilian/biohub-unet3d-weights-v2models",
            ],
        },
    }
    notebook["nbformat"] = 4
    notebook["nbformat_minor"] = 5
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(notebook, indent=1) + "\n")

    META.write_text(
        json.dumps(
            {
                "id": "dalloliogm/biohub-exp203-classical-ensemble",
                "title": "Biohub Exp203 Classical Three-Model Ensemble",
                "code_file": OUT.name,
                "language": "python",
                "kernel_type": "notebook",
                "is_private": False,
                "enable_gpu": True,
                "enable_internet": False,
                "competition_sources": ["biohub-cell-tracking-during-development"],
                "dataset_sources": [
                    "xiaoleilian/biohub-unet3d-weights",
                    "xiaoleilian/biohub-unet3d-weights-v2models",
                ],
            },
            indent=2,
        )
        + "\n"
    )


if __name__ == "__main__":
    main()
