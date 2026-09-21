#!/usr/bin/env python3
"""Build the bounded synthetic second-child ranker pretraining notebook."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "notebooks" / "exp209-synthetic-second-child-ranker-pretrain"
NOTEBOOK = OUT / "biohub-exp209-synthetic-second-child-ranker.ipynb"
METADATA = OUT / "biohub-exp209-synthetic-second-child-ranker.kernel-metadata.json"


def code(source: str) -> dict:
    return {"cell_type": "code", "execution_count": None, "metadata": {}, "outputs": [],
            "source": source.splitlines(keepends=True)}


def main() -> None:
    cells = [
        {"cell_type": "markdown", "metadata": {}, "source": [
            "# Biohub Exp209 — synthetic second-child ranker pretraining\\n",
            "\\n",
            "Pretrains an interpretable **geometry/motion prior** on Exp204 synthetic lineages. "
            "It does not create a competition submission and cannot be promoted without a real, "
            "embryo-held-out fine-tune result. Images are intentionally excluded: Exp204 found no "
            "synthetic held-out lift beyond geometry.\\n",
        ]},
        code("""from pathlib import Path
import glob, json
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import average_precision_score, roc_auc_score

RNG = np.random.default_rng(209)
VOXEL_UM = np.array([1.625, 1.625, 1.625], dtype=np.float32)
NATIVE_TO_POOLED = np.array([1.0, 4.0, 4.0], dtype=np.float32)
JITTER_UM = 0.75
MAX_CANDIDATES = 8
MAX_DISTANCE_UM = 16.0
roots = sorted(glob.glob('/kaggle/input/**/biohub_synthetic/sequences', recursive=True))
assert roots, 'Attach the completed Exp204 capped synthetic lineage builder output.'
sequence_dir = Path(roots[0])
files = sorted(sequence_dir.glob('seq_*.npz'))
assert files, f'No sequence files under {sequence_dir}'
print(f'{len(files)} synthetic sequences from {sequence_dir}')
"""),
        code("""def load_sequence(path):
    with np.load(path, allow_pickle=False) as z:
        nodes = z['nodes'].astype(np.float32).copy()
        edges = z['edges'].astype(np.int64)
        divisions = z['divisions'].astype(np.int64)
    nodes[:, 1:4] /= NATIVE_TO_POOLED
    assert np.all((nodes[:, 1:4] >= 0) & (nodes[:, 1:4] < 64))
    return nodes, edges, divisions

def children_and_parents(n_nodes, edges):
    children = [[] for _ in range(n_nodes)]
    parents = np.full(n_nodes, -1, dtype=np.int64)
    for src, dst in edges:
        children[int(src)].append(int(dst)); parents[int(dst)] = int(src)
    return children, parents

def feature_row(nodes, source, primary, candidate, parents):
    p = nodes[:, 1:4]
    src, pri, cand = p[source], p[primary], p[candidate]
    # Detection-like coordinate jitter prevents the ranker exploiting exact simulator geometry.
    src = src + RNG.normal(0, JITTER_UM, 3) / VOXEL_UM
    pri = pri + RNG.normal(0, JITTER_UM, 3) / VOXEL_UM
    cand = cand + RNG.normal(0, JITTER_UM, 3) / VOXEL_UM
    step_p = (pri - src) * VOXEL_UM
    step_c = (cand - src) * VOXEL_UM
    sibling = (cand - pri) * VOXEL_UM
    parent = parents[source]
    if parent >= 0:
        prev = p[parent] + RNG.normal(0, JITTER_UM, 3) / VOXEL_UM
        velocity = (src - prev) * VOXEL_UM
        predicted_midpoint = src + (src - prev)
    else:
        velocity = np.zeros(3, dtype=np.float32)
        predicted_midpoint = src
    norm = lambda x: float(np.linalg.norm(x))
    cosine = float(np.dot(step_p, step_c) / max(norm(step_p) * norm(step_c), 1e-4))
    motion_cosine = float(np.dot(velocity, (0.5 * (pri + cand) - predicted_midpoint) * VOXEL_UM) /
                          max(norm(velocity) * norm((0.5 * (pri + cand) - predicted_midpoint) * VOXEL_UM), 1e-4))
    return [norm(step_c), norm(sibling), abs(norm(step_c) - norm(step_p)), cosine,
            norm((0.5 * (pri + cand) - predicted_midpoint) * VOXEL_UM), motion_cosine]

FEATURE_NAMES = ['source_candidate_um', 'sister_separation_um', 'step_asymmetry_um',
                 'primary_candidate_cosine', 'motion_midpoint_residual_um', 'motion_midpoint_cosine']
"""),
        code("""def examples_for_file(path, file_id):
    nodes, edges, divisions = load_sequence(path)
    children, parents = children_and_parents(len(nodes), edges)
    times = nodes[:, 0].astype(np.int64)
    rows = []
    for source in divisions:
        kids = children[int(source)]
        if len(kids) != 2:
            continue
        # Randomize which real daughter is treated as the already-linked primary.
        primary, positive = kids if RNG.integers(2) else kids[::-1]
        targets = np.flatnonzero(times == times[int(source)] + 1)
        targets = targets[targets != primary]
        d = np.linalg.norm((nodes[targets, 1:4] - nodes[int(source), 1:4]) * VOXEL_UM, axis=1)
        pool = targets[d <= MAX_DISTANCE_UM]
        if positive not in pool:
            pool = np.append(pool, positive)
        # Keep the true second child and the closest distractors, balanced per source.
        pool = sorted(pool, key=lambda i: (i != positive, np.linalg.norm((nodes[i,1:4]-nodes[int(source),1:4])*VOXEL_UM)))[:MAX_CANDIDATES]
        if positive not in pool:
            pool[-1] = positive
        for candidate in pool:
            rows.append((file_id, int(source), int(primary), int(candidate), int(candidate == positive),
                         feature_row(nodes, int(source), int(primary), int(candidate), parents)))
    return rows

all_rows = []
for file_id, path in enumerate(files):
    all_rows.extend(examples_for_file(path, file_id))
assert all_rows, 'No second-child examples built.'
file_id = np.array([r[0] for r in all_rows])
source_id = np.array([r[1] for r in all_rows])
y = np.array([r[4] for r in all_rows], dtype=np.int8)
X = np.asarray([r[5] for r in all_rows], dtype=np.float32)
print(f'{len(y)} candidates, {int(y.sum())} positives from {len(np.unique(file_id))} sequences')
"""),
        code("""# Sequence-disjoint split: no lineage event leaks across train/test.
test_files = np.zeros(len(files), dtype=bool)
test_files[RNG.choice(len(files), size=max(1, round(0.2 * len(files))), replace=False)] = True
is_test = test_files[file_id]
mean, scale = X[~is_test].mean(0), X[~is_test].std(0)
scale = np.maximum(scale, 1e-5)
model = LogisticRegression(C=0.05, class_weight='balanced', max_iter=1000, random_state=209)
model.fit((X[~is_test] - mean) / scale, y[~is_test])
prob = model.predict_proba((X - mean) / scale)[:, 1]

def listwise_metrics(mask):
    ranks = []
    for source in np.unique(source_id[mask]):
        idx = np.flatnonzero(mask & (source_id == source))
        positives = idx[y[idx] == 1]
        if len(positives) != 1:
            continue
        rank = 1 + int(np.sum(prob[idx] > prob[positives[0]]))
        ranks.append(rank)
    ranks = np.asarray(ranks)
    return {'n_events': int(len(ranks)), 'top1': float(np.mean(ranks == 1)), 'mrr': float(np.mean(1 / ranks))}

metrics = {
    'n_sequences': len(files), 'n_candidates': int(len(y)), 'n_positive': int(y.sum()),
    'synthetic_test_roc_auc': float(roc_auc_score(y[is_test], prob[is_test])),
    'synthetic_test_average_precision': float(average_precision_score(y[is_test], prob[is_test])),
    'synthetic_test_listwise': listwise_metrics(is_test),
    'promotion_gate': 'blocked_pending_real_embryo_heldout_finetune',
    'note': 'Synthetic geometry was previously separable; these coefficients are a regularized prior, not calibrated probabilities.'
}
artifact = {'feature_names': FEATURE_NAMES, 'mean': mean.tolist(), 'scale': scale.tolist(),
            'coef': model.coef_[0].tolist(), 'intercept': float(model.intercept_[0]), 'metrics': metrics}
Path('/kaggle/working/synthetic_second_child_ranker.json').write_text(json.dumps(artifact, indent=2))
print(json.dumps(metrics, indent=2))
"""),
        {"cell_type": "markdown", "metadata": {}, "source": [
            "## Decision\\n\\n",
            "This artifact is **not** submission-ready. Promote it only if a separate real, embryo-held-out "
            "fine-tune shows an improvement over a geometry-only control while preserving a frozen Exp203 control.\\n",
        ]},
    ]
    nb = {"cells": cells, "metadata": {"kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"}, "language_info": {"name": "python", "version": "3.12"}, "kaggle": {"accelerator": "none", "isGpuEnabled": False, "isInternetEnabled": False, "language": "python", "sourceType": "notebook", "competitionSources": ["biohub-cell-tracking-during-development"], "kernelSources": ["dalloliogm/biohub-exp204-capped-synthetic-lineage-builder"]}}, "nbformat": 4, "nbformat_minor": 5}
    OUT.mkdir(parents=True, exist_ok=True)
    NOTEBOOK.write_text(json.dumps(nb, indent=1) + "\n")
    METADATA.write_text(json.dumps({"id": "dalloliogm/biohub-exp209-synthetic-second-child-ranker", "title": "Biohub Exp209 Synthetic Second Child Ranker", "code_file": NOTEBOOK.name, "language": "python", "kernel_type": "notebook", "is_private": True, "enable_gpu": False, "enable_internet": False, "competition_sources": ["biohub-cell-tracking-during-development"], "kernel_sources": ["dalloliogm/biohub-exp204-capped-synthetic-lineage-builder"]}, indent=2) + "\n")


if __name__ == "__main__":
    main()
