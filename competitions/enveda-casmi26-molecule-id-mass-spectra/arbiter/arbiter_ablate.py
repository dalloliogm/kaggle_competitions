#!/usr/bin/env python3
"""Feature-group ablation + swap precision for the unbiased arbiter. usage: arbiter_ablate.py PAIRS.parquet"""
import sys, numpy as np, pandas as pd, lightgbm as lgb
from sklearn.metrics import roc_auc_score
df = pd.read_parquet(sys.argv[1]); mols = df.molecule_id.unique()
G = {'ice': ['d_ice', 'ice_ch', 'ice_rank_ch', 'ice_rank_L'], 'gl': ['d_gl', 'gl_ch', 'gl_rank_ch', 'gl_rank_L'],
     'frag': ['frag_L', 'frag_ch', 'd_frag', 'frag_rank_ch', 'frag_rank_L'], 'lib': ['library_max'],
     'struct': ['tanimoto', 'same_formula', 'd_heavy', 'd_rings'], 'meta': ['n_spectra', 'n_adducts', 'ch_rank']}
T = df[(df.y_leader + df.y_ch) == 1].copy(); T['y'] = T.y_ch
def cv(feats, reps=5):
    aucs = []
    for rep in range(reps):
        perm = dict(zip(mols, np.random.default_rng(rep).permutation(len(mols)))); f = T.molecule_id.map(perm) % 5; p = pd.Series(index=T.index, dtype=float)
        for k in range(5):
            m = lgb.LGBMClassifier(n_estimators=120, learning_rate=.05, num_leaves=7, min_child_samples=15, subsample=.8, colsample_bytree=.8, reg_lambda=5, verbose=-1)
            m.fit(T[f != k][feats], T[f != k].y); p[f == k] = m.predict_proba(T[f == k][feats])[:, 1]
        aucs.append(roc_auc_score(T.y, p))
    return np.mean(aucs)
allf = sum(G.values(), [])
print('all unbiased AUC %.4f' % cv(allf))
for g in G: print('drop %-7s AUC %.4f' % (g, cv([f for f in allf if f not in G[g]])))
for g in G: print('only %-7s AUC %.4f' % (g, cv(G[g] + ['ch_rank'] if g != 'meta' else G[g])))
for s in ('S2', 'S1'):
    t = T[T.subset == s]; print(s, 'pairs', len(t), 'leader-true share %.3f' % (1 - t.y.mean()))
