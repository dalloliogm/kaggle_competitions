#!/usr/bin/env python3
"""Build the private, diagnostic-only Exp204 Kaggle notebook."""

from __future__ import annotations

import json
from pathlib import Path


WORKSPACE = Path("competitions/biohub-cell-tracking-during-development")
OUT = WORKSPACE / "notebooks/exp204-synthetic-second-child-pretrain/biohub-exp204-synthetic-second-child-pretrain.ipynb"
META = OUT.with_suffix(".kernel-metadata.json")


def markdown(text: str) -> dict:
    return {"cell_type": "markdown", "metadata": {}, "source": text.splitlines(keepends=True)}


def code(text: str) -> dict:
    return {"cell_type": "code", "metadata": {}, "execution_count": None, "outputs": [], "source": text.splitlines(keepends=True)}


def main() -> None:
    notebook = {
        "nbformat": 4,
        "nbformat_minor": 5,
        "metadata": {
            "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
            "language_info": {"name": "python", "version": "3.12"},
            "kaggle": {"accelerator": "none", "isGpuEnabled": False, "isInternetEnabled": False, "language": "python", "sourceType": "notebook", "competitionSources": ["biohub-cell-tracking-during-development"], "kernelSources": ["josefreitasalvesneto/biohub-synthetic-dataset"]},
        },
        "cells": [
            markdown("""# Exp204 — Synthetic second-child feasibility diagnostic

## Objective

Test whether the public synthetic sequences contain **image evidence** for a
second-child/division decision beyond simple parent–candidate geometry. This is
a private diagnostic notebook: it does not create `submission.csv`, modify the
Exp183 pipeline, or justify a leaderboard submission.

## Success criterion

On held-out *synthetic sequences*, intensity-augmented features must improve
ROC-AUC over the geometry-only control by at least `0.02`. Otherwise the
generator is useful only for geometry/motion augmentation, not an image scorer.

Synthetic hold-out is an implementation check, not evidence of real transfer.
"""),
            code("""from __future__ import annotations

import glob
import json
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import average_precision_score, roc_auc_score

SEED = 204
MAX_SEQUENCE_FILES = 128
MAX_ROWS_PER_CLASS = 30_000
PATCH_RADIUS = 2
MIN_IMAGE_AUC_LIFT = 0.02
NATIVE_TO_POOLED = np.array([1.0, 4.0, 4.0], dtype=np.float32)
POOLED_VOXEL_UM = np.array([1.625, 1.625, 1.625], dtype=np.float32)

roots = sorted(glob.glob('/kaggle/input/**/biohub_synthetic/sequences', recursive=True))
assert roots, 'Attach the public notebook output josefreitasalvesneto/biohub-synthetic-dataset.'
SEQUENCE_DIR = Path(roots[0])
files = sorted(SEQUENCE_DIR.glob('seq_*.npz'))[:MAX_SEQUENCE_FILES]
assert len(files) >= 20, f'Need at least 20 sequence files, found {len(files)}.'
print(f'Using {len(files)} of {len(list(SEQUENCE_DIR.glob("seq_*.npz")))} synthetic sequences from {SEQUENCE_DIR}')
"""),
            markdown("""## Schema adapter

The public images are pooled `(T,64,64,64)` but `nodes[:,1:4]` are native
coordinates. The `/ (1,4,4)` conversion below is mandatory before extracting
image patches or calculating physical distance.
"""),
            code("""def load_sequence(path: Path):
    with np.load(path, allow_pickle=False) as source:
        volumes = np.asarray(source['volumes'])
        nodes_native = np.asarray(source['nodes'], dtype=np.float32)
        edges = np.asarray(source['edges'], dtype=np.int64).reshape(-1, 2)
        divisions = np.asarray(source['divisions'], dtype=np.int64).reshape(-1)
    assert volumes.ndim == 4 and volumes.shape[1:] == (64, 64, 64)
    assert nodes_native.ndim == 2 and nodes_native.shape[1] == 5
    assert np.allclose(nodes_native[:, 0], np.round(nodes_native[:, 0]))
    assert len(edges) == 0 or (edges.min() >= 0 and edges.max() < len(nodes_native))
    if len(edges):
        assert np.all(nodes_native[edges[:, 1], 0] == nodes_native[edges[:, 0], 0] + 1)
        outdegree = np.bincount(edges[:, 0], minlength=len(nodes_native))
        indegree = np.bincount(edges[:, 1], minlength=len(nodes_native))
        assert outdegree.max() <= 2 and indegree.max() <= 1
        assert np.array_equal(np.sort(np.unique(divisions)), np.flatnonzero(outdegree == 2))
    nodes = nodes_native.copy()
    nodes[:, 1:4] /= NATIVE_TO_POOLED
    assert np.all((nodes[:, 1:4] >= 0) & (nodes[:, 1:4] < 64))
    return volumes, nodes, edges


def patch_stats(volume: np.ndarray, coordinate: np.ndarray) -> tuple[float, float, float]:
    z, y, x = np.round(coordinate).astype(int)
    lo = np.maximum([z - PATCH_RADIUS, y - PATCH_RADIUS, x - PATCH_RADIUS], 0)
    hi = np.minimum([z + PATCH_RADIUS + 1, y + PATCH_RADIUS + 1, x + PATCH_RADIUS + 1], volume.shape)
    patch = volume[lo[0]:hi[0], lo[1]:hi[1], lo[2]:hi[2]].astype(np.float32) / 65535.0
    return float(patch.mean()), float(patch.std()), float(patch.max())


def examples_from_sequence(path: Path) -> list[dict]:
    volumes, nodes, edges = load_sequence(path)
    times = nodes[:, 0].astype(int)
    children = [[] for _ in range(len(nodes))]
    for source, target in edges:
        children[int(source)].append(int(target))
    rows = []
    for source, targets in enumerate(children):
        if not targets:
            continue
        target_time = times[source] + 1
        if len(targets) == 2:
            primary, candidate = sorted(targets)
            label, negative_distance = 1, 0.0
        else:
            primary = targets[0]
            alternatives = np.flatnonzero(times == target_time)
            alternatives = alternatives[~np.isin(alternatives, targets)]
            if not len(alternatives):
                continue
            distances = np.linalg.norm((nodes[alternatives, 1:4] - nodes[source, 1:4]) * POOLED_VOXEL_UM, axis=1)
            pick = int(np.argmin(distances))
            if distances[pick] > 12.0:
                continue
            candidate, label, negative_distance = int(alternatives[pick]), 0, float(distances[pick])
        source_to_primary = float(np.linalg.norm((nodes[primary, 1:4] - nodes[source, 1:4]) * POOLED_VOXEL_UM))
        source_to_candidate = float(np.linalg.norm((nodes[candidate, 1:4] - nodes[source, 1:4]) * POOLED_VOXEL_UM))
        sister_distance = float(np.linalg.norm((nodes[candidate, 1:4] - nodes[primary, 1:4]) * POOLED_VOXEL_UM))
        target_volume = volumes[target_time]
        candidate_mean, candidate_std, candidate_max = patch_stats(target_volume, nodes[candidate, 1:4])
        primary_mean, primary_std, primary_max = patch_stats(target_volume, nodes[primary, 1:4])
        rows.append(dict(sequence=path.name, label=label, source_to_primary_um=source_to_primary, source_to_candidate_um=source_to_candidate, sister_distance_um=sister_distance, negative_distance_um=negative_distance, candidate_mean=candidate_mean, candidate_std=candidate_std, candidate_max=candidate_max, primary_mean=primary_mean, primary_std=primary_std, primary_max=primary_max))
    return rows
"""),
            markdown("""## Held-out synthetic control

Sequences—not frames or nodes—are split. The geometry control is compared with
the same classifier supplied with candidate/primary patch statistics.
"""),
            code("""rows = []
for path in files:
    rows.extend(examples_from_sequence(path))
examples = pd.DataFrame(rows)
assert not examples.empty and examples.label.nunique() == 2
examples = (examples.groupby('label', group_keys=False).head(MAX_ROWS_PER_CLASS).reset_index(drop=True))
train_sequences = set(sorted(examples.sequence.unique())[::5])
test_mask = examples.sequence.isin(train_sequences)
test, train = examples.loc[test_mask].copy(), examples.loc[~test_mask].copy()
assert train.label.nunique() == test.label.nunique() == 2

geometry = ['source_to_primary_um', 'source_to_candidate_um', 'sister_distance_um', 'negative_distance_um']
image = ['candidate_mean', 'candidate_std', 'candidate_max', 'primary_mean', 'primary_std', 'primary_max']

def score(features):
    model = LogisticRegression(max_iter=400, class_weight='balanced', random_state=SEED)
    model.fit(train[features], train.label)
    probability = model.predict_proba(test[features])[:, 1]
    return {'roc_auc': float(roc_auc_score(test.label, probability)), 'average_precision': float(average_precision_score(test.label, probability))}

geometry_metrics = score(geometry)
image_metrics = score(geometry + image)
metrics = {'n_files': len(files), 'n_examples': len(examples), 'n_train': len(train), 'n_test': len(test), 'positive_rate_train': float(train.label.mean()), 'positive_rate_test': float(test.label.mean()), 'geometry': geometry_metrics, 'geometry_plus_image': image_metrics, 'image_auc_lift': image_metrics['roc_auc'] - geometry_metrics['roc_auc']}
metrics['decision'] = 'continue_to_real_finetune_design' if metrics['image_auc_lift'] >= MIN_IMAGE_AUC_LIFT else 'stop_image_scorer_branch; retain_only_geometry_motion_augmentation'
print(json.dumps(metrics, indent=2))
pd.DataFrame([metrics]).to_json('synthetic_second_child_metrics.json', orient='records', indent=2)
examples.head(10).to_csv('synthetic_second_child_examples_preview.csv', index=False)
"""),
            markdown("""## Interpretation gate

- A good synthetic ROC-AUC by itself is not success: the branching process may
  be geometrically easy.
- Continue only when image features add the pre-registered `>=0.02` ROC-AUC
  lift and the schema audit is clean.
- Even then, the next step is a frozen-Exp183, real-graph fine-tuning design;
  no submission is authorised from this notebook.
"""),
        ],
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(notebook, indent=1) + "\n")
    META.write_text(json.dumps({"id": "dalloliogm/biohub-exp204-synthetic-second-child-pretrain", "title": "Biohub Exp204 Synthetic Second-Child Diagnostic", "code_file": OUT.name, "language": "python", "kernel_type": "notebook", "is_private": True, "enable_gpu": False, "enable_internet": False, "competition_sources": ["biohub-cell-tracking-during-development"], "kernel_sources": ["josefreitasalvesneto/biohub-synthetic-dataset"]}, indent=2) + "\n")


if __name__ == "__main__":
    main()
