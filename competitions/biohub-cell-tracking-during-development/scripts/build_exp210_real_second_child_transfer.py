#!/usr/bin/env python3
"""Build the embryo-held-out transfer gate for the Exp209 synthetic ranker."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "notebooks" / "exp210-real-second-child-transfer"
NOTEBOOK = OUT / "biohub-exp210-real-second-child-transfer.ipynb"
METADATA = OUT / "biohub-exp210-real-second-child-transfer.kernel-metadata.json"


def code(source: str) -> dict:
    return {"cell_type": "code", "execution_count": None, "metadata": {}, "outputs": [],
            "source": source.splitlines(keepends=True)}


def main() -> None:
    cells = [
        {"cell_type": "markdown", "metadata": {}, "source": [
            "# Biohub Exp210 — real embryo-held-out second-child transfer\\n\\n",
            "Evaluates the Exp209 synthetic geometry/motion prior on the real lineage graphs. "
            "This is **conditional identity validation** only: true division sources and GT-node candidates "
            "are jittered to mimic localization noise. It cannot justify a submission or an image model.\\n",
        ]},
        code("""import json, subprocess, sys
from collections import defaultdict
from pathlib import Path
import numpy as np
from sklearn.linear_model import SGDClassifier
from sklearn.metrics import average_precision_score, roc_auc_score

def ensure(package, module=None):
    try: __import__(module or package)
    except ImportError: subprocess.run([sys.executable, '-m', 'pip', 'install', '-q', package], check=True)
ensure('tracksdata')
import tracksdata as td

RNG = np.random.default_rng(210)
VOXEL_UM = np.array([1.625, 0.40625, 0.40625], dtype=np.float32)
JITTER_UM, MAX_DISTANCE_UM, MAX_CANDIDATES = 0.75, 16.0, 8
FEATURE_NAMES = ['source_candidate_um', 'sister_separation_um', 'step_asymmetry_um',
                 'primary_candidate_cosine', 'motion_midpoint_residual_um', 'motion_midpoint_cosine']
input_root = Path('/kaggle/input')
train_candidates = [p for p in input_root.rglob('train') if p.is_dir() and any(p.glob('*.zarr'))] if input_root.exists() else []
mount_report = {'top_level': [p.name for p in input_root.iterdir()] if input_root.exists() else [],
                'train_candidates': [str(p) for p in train_candidates]}
Path('/kaggle/working/exp210_input_mount.json').write_text(json.dumps(mount_report, indent=2))
assert train_candidates, f'Competition train input is required; mount report: {mount_report}'
train_dir = train_candidates[0]
prior = {'feature_names': FEATURE_NAMES,
         'mean': [10.340670585632324, 11.28427505493164, 6.1645708084106445, -0.020783843472599983, 6.427213668823242, -0.35534948110580444],
         'scale': [3.6594369411468506, 3.8921639919281006, 3.487333297729492, 0.5854313969612122, 2.7527952194213867, 0.49876657128334045],
         'coef': [-1.944502224241194, -1.311408107013591, -0.7044181286420426, -0.891100875171484, 0.36086645119956345, 0.35386928955306923],
         'intercept': -2.7651535797738824,
         'provenance': 'Exp209 synthetic_second_child_ranker.json'}
print('train:', train_dir, '| prior:', prior['provenance'])
"""),
        code("""def graph_for(path):
    g = td.graph.IndexedRXGraph.from_geff(path)
    return g[0] if isinstance(g, tuple) else g

def load_real_graph(path):
    g = graph_for(path)
    rows = list(g.node_attrs(attr_keys=['t', 'z', 'y', 'x']).iter_rows(named=True))
    nodes = np.array([[float(r['t']), float(r['z']), float(r['y']), float(r['x'])] for r in rows], dtype=np.float32)
    edges = np.asarray(list(g.graph.edge_list()), dtype=np.int64)
    if edges.size == 0: edges = np.empty((0, 2), dtype=np.int64)
    return nodes, edges

def children_and_parents(n_nodes, edges):
    children = [[] for _ in range(n_nodes)]; parents = np.full(n_nodes, -1, dtype=np.int64)
    for src, dst in edges:
        children[int(src)].append(int(dst)); parents[int(dst)] = int(src)
    return children, parents

def feature(nodes, source, primary, candidate, parents):
    p = nodes[:, 1:4]
    jitter = lambda x: x + RNG.normal(0, JITTER_UM, 3) / VOXEL_UM
    src, pri, cand = jitter(p[source]), jitter(p[primary]), jitter(p[candidate])
    step_p, step_c = (pri-src)*VOXEL_UM, (cand-src)*VOXEL_UM
    sibling = (cand-pri)*VOXEL_UM
    parent = parents[source]
    if parent >= 0:
        prev = jitter(p[parent]); velocity = (src-prev)*VOXEL_UM; pred = src + (src-prev)
    else:
        velocity = np.zeros(3); pred = src
    norm = lambda x: float(np.linalg.norm(x))
    cosine = float(np.dot(step_p, step_c) / max(norm(step_p)*norm(step_c), 1e-4))
    midpoint_vec = (0.5*(pri+cand)-pred)*VOXEL_UM
    motion_cos = float(np.dot(velocity, midpoint_vec) / max(norm(velocity)*norm(midpoint_vec), 1e-4))
    return [norm(step_c), norm(sibling), abs(norm(step_c)-norm(step_p)), cosine, norm(midpoint_vec), motion_cos]

def examples(path, embryo):
    nodes, edges = load_real_graph(path); children, parents = children_and_parents(len(nodes), edges)
    times = nodes[:, 0].astype(int); rows = []
    for source, kids in enumerate(children):
        if len(kids) != 2: continue
        primary, positive = kids if RNG.integers(2) else kids[::-1]
        target = np.flatnonzero(times == times[source] + 1); target = target[target != primary]
        d = np.linalg.norm((nodes[target, 1:4]-nodes[source, 1:4])*VOXEL_UM, axis=1)
        pool = target[d <= MAX_DISTANCE_UM]
        if positive not in pool: pool = np.append(pool, positive)
        pool = sorted(pool, key=lambda i: (i != positive, np.linalg.norm((nodes[i,1:4]-nodes[source,1:4])*VOXEL_UM)))[:MAX_CANDIDATES]
        if positive not in pool: pool[-1] = positive
        for candidate in pool:
            rows.append((embryo, source, int(candidate == positive), feature(nodes, source, primary, int(candidate), parents)))
    return rows

geffs = sorted(train_dir.rglob('*.geff'))
by_embryo = defaultdict(list)
for path in geffs: by_embryo[path.stem.split('_')[0]].append(path)
assert len(by_embryo) == 2, f'Expected two embryos, found {list(by_embryo)}'
rows = [row for embryo, paths in by_embryo.items() for path in paths for row in examples(path, embryo)]
embryo = np.array([r[0] for r in rows]); source = np.array([f'{r[0]}:{r[1]}' for r in rows])
y = np.array([r[2] for r in rows], dtype=np.int8); X = np.asarray([r[3] for r in rows], dtype=np.float32)
assert y.sum() > 0, 'No real division candidates found.'
print({e: {'candidates': int((embryo==e).sum()), 'positives': int(y[embryo==e].sum())} for e in sorted(by_embryo)})
"""),
        code("""def prior_score(X):
    return 1/(1+np.exp(-(np.asarray(prior['intercept']) + ((X-np.asarray(prior['mean']))/np.asarray(prior['scale'])) @ np.asarray(prior['coef']))))

def geometry_score(X):
    # Non-learned baseline: smaller source/candidate and sibling distances are preferable.
    return -(X[:, 0] + 0.5*X[:, 1] + 0.5*X[:, 2])

def listwise(y, score, source):
    ranks=[]
    for s in np.unique(source):
        idx=np.flatnonzero(source==s); pos=idx[y[idx]==1]
        if len(pos)!=1: continue
        ranks.append(1+int(np.sum(score[idx]>score[pos[0]])))
    ranks=np.asarray(ranks)
    return {'n_events': int(len(ranks)), 'top1': float(np.mean(ranks==1)), 'mrr': float(np.mean(1/ranks))}

def evaluate(y, score, source):
    return {'roc_auc': float(roc_auc_score(y, score)), 'average_precision': float(average_precision_score(y, score)), 'listwise': listwise(y, score, source)}

def finetune_score(X_train, y_train, X_test):
    mean, scale = X_train.mean(0), np.maximum(X_train.std(0), 1e-5)
    # Convert Exp209's standardised coefficients into the current real-feature scaling.
    prior_coef = np.asarray(prior['coef']); prior_mean=np.asarray(prior['mean']); prior_scale=np.asarray(prior['scale'])
    init_coef = prior_coef * scale / prior_scale
    init_intercept = float(prior['intercept'] + np.sum(prior_coef*(mean-prior_mean)/prior_scale))
    model=SGDClassifier(loss='log_loss', penalty='l2', alpha=0.08, learning_rate='constant', eta0=0.01, random_state=210)
    z=(X_train-mean)/scale; model.partial_fit(z[:2], y_train[:2], classes=np.array([0,1]))
    model.coef_[0]=init_coef; model.intercept_[0]=init_intercept
    weights=np.where(y_train==1, 0.5/max(y_train.mean(),1e-4), 0.5/max(1-y_train.mean(),1e-4))
    for _ in range(30): model.partial_fit(z, y_train, sample_weight=weights)
    return model.predict_proba((X_test-mean)/scale)[:,1]

results={}
for held in sorted(by_embryo):
    test=embryo==held; train=~test
    geo, synth = geometry_score(X[test]), prior_score(X[test])
    tuned = finetune_score(X[train], y[train], X[test])
    results[held]={'geometry': evaluate(y[test], geo, source[test]), 'synthetic_prior': evaluate(y[test], synth, source[test]), 'synthetic_plus_real_finetune': evaluate(y[test], tuned, source[test])}
Path('/kaggle/working/real_second_child_transfer_metrics.json').write_text(json.dumps(results, indent=2))
print(json.dumps(results, indent=2))
"""),
        {"cell_type": "markdown", "metadata": {}, "source": [
            "## Promotion gate\\n\\n",
            "Promotion requires the fine-tuned model to beat both controls on **both** embryo-held-out MRRs, "
            "with no reduction in top-1 accuracy. Even then, it advances only to an Exp203 detector-candidate "
            "transfer diagnostic; it is not submission-ready.\\n",
        ]},
    ]
    nb={"cells":cells,"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"},"language_info":{"name":"python","version":"3.12"},"kaggle":{"accelerator":"none","isGpuEnabled":False,"isInternetEnabled":True,"language":"python","sourceType":"notebook","competitionSources":["biohub-cell-tracking-during-development"],"kernelSources":[]}},"nbformat":4,"nbformat_minor":5}
    OUT.mkdir(parents=True, exist_ok=True); NOTEBOOK.write_text(json.dumps(nb, indent=1)+"\n")
    METADATA.write_text(json.dumps({"id":"dalloliogm/biohub-exp210-second-child-transfer","title":"Biohub Exp210 Second Child Transfer","code_file":NOTEBOOK.name,"language":"python","kernel_type":"notebook","is_private":True,"enable_gpu":False,"enable_internet":True,"competition_sources":["biohub-cell-tracking-during-development"],"kernel_sources":[]},indent=2)+"\n")


if __name__ == '__main__': main()
