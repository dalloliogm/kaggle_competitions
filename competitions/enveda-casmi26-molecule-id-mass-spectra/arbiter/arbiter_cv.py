#!/usr/bin/env python3
"""Grouped-CV evaluation of a rank-1 arbiter on pairwise features (see build_pair_features.py).

usage: arbiter_cv.py PAIRS.parquet [repeats]
For each molecule: leader = final rank 1; challengers = ranks 2..K. A model scores P(challenger is truth | exactly one of the
two is). We swap the best challenger into rank 1 (old leader -> rank 2) when P > threshold. Reports net MRR change per threshold,
for an 'unbiased' feature set and a 'biased' one (adds neural/engine ranks), by subset (S2 / S1 / all).
Reciprocal rank is computed on the top-K list only (ranks beyond K are unchanged by a swap except the moved challenger).
"""
import sys
import numpy as np, pandas as pd
import lightgbm as lgb
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import GroupKFold
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline
from sklearn.impute import SimpleImputer

df = pd.read_parquet(sys.argv[1]); reps = int(sys.argv[2]) if len(sys.argv) > 2 else 5
UNB = ['d_ice', 'd_gl', 'ice_ch', 'gl_ch', 'ice_rank_ch', 'ice_rank_L', 'gl_rank_ch', 'gl_rank_L', 'frag_L', 'frag_ch', 'd_frag',
       'frag_rank_ch', 'frag_rank_L', 'library_max', 'n_spectra', 'n_adducts', 'tanimoto', 'same_formula', 'd_heavy', 'd_rings', 'ch_rank']
CLEAN = [f for f in UNB if f not in ('library_max', 'n_spectra', 'n_adducts')]  # drop molecule-level proxies of subset/difficulty
BIA = UNB + ['d_neural', 'neural_ch', 'd_main_rank', 'd_pre_rank', 'engine2_ch', 'engine2_L', 'pubchem_ch']
mols = df.molecule_id.unique()
sub = df.groupby('molecule_id').subset.first()
# baseline reciprocal rank of truth within the top-K list (leader = 1)
def base_rr(g):
    if g.y_leader.iloc[0] == 1: return 1.0
    hit = g[g.y_ch == 1]
    return 1.0 / hit.ch_rank.iloc[0] if len(hit) else 0.0
def swapped_rr(g, ch_rank):
    # challenger at ch_rank moves to 1, old leader to 2, items 2..ch_rank-1 shift down by one only if above ch_rank? new=[ch,L]+rest(without ch)
    if g.y_ch[g.ch_rank == ch_rank].iloc[0] == 1: return 1.0
    if g.y_leader.iloc[0] == 1: return 0.5
    hit = g[g.y_ch == 1]
    if not len(hit): return 0.0
    r = hit.ch_rank.iloc[0]
    # original position r (2..K); after removing ch (ranks above r shift up) and inserting [ch, L] in front: new pos = r+1 if r<ch_rank else r
    return 1.0 / (r + 1) if r < ch_rank else 1.0 / r
base = pd.Series({m: base_rr(g) for m, g in df.groupby('molecule_id')})
print('baseline top-K MRR: all %.4f S2 %.4f S1 %.4f' % (base.mean(), base[sub == 'S2'].mean(), base[sub == 'S1'].mean()))
orac = pd.Series({m: 1.0 if g.y_leader.iloc[0] == 1 or g.y_ch.max() == 1 else 0.0 for m, g in df.groupby('molecule_id')})
print('oracle (best swap) MRR: %.4f' % orac.mean())
train_df = df[(df.y_leader + df.y_ch) == 1].copy()  # exactly one of the pair is the truth
train_df['y'] = train_df.y_ch
def models():
    return {'logreg': make_pipeline(SimpleImputer(strategy='median'), StandardScaler(), LogisticRegression(C=0.3, max_iter=500)),
            'lgbm': lgb.LGBMClassifier(n_estimators=120, learning_rate=0.05, num_leaves=7, min_child_samples=15, subsample=0.8,
                                       colsample_bytree=0.8, reg_lambda=5.0, verbose=-1)}
THR = [0.5, 0.55, 0.6, 0.65, 0.7, 0.8]
res = []
for fname, feats in (('clean', CLEAN), ('unbiased', UNB), ('biased', BIA)):
    for mname in ('logreg', 'lgbm'):
        out = {t: [] for t in THR}; auc_l = []
        for rep in range(reps):
            rng = np.random.default_rng(rep); perm = dict(zip(mols, rng.permutation(len(mols))))
            gkf = GroupKFold(n_splits=5)
            grp = df.molecule_id.map(perm) % 5
            P = pd.Series(index=df.index, dtype=float)
            for k in range(5):
                tr = train_df[train_df.molecule_id.map(perm) % 5 != k]; te = df[grp == k]
                mdl = models()[mname]; mdl.fit(tr[feats], tr.y)
                P.loc[te.index] = mdl.predict_proba(te[feats])[:, 1]
            d = df.assign(p=P)
            # AUC on pairs that decide something
            from sklearn.metrics import roc_auc_score
            dd = d[(d.y_leader + d.y_ch) == 1]; auc_l.append(roc_auc_score(dd.y_ch, dd.p))
            for t in THR:
                new = {}
                for m, g in d.groupby('molecule_id'):
                    j = g.p.idxmax()
                    new[m] = swapped_rr(g, int(g.loc[j, 'ch_rank'])) if g.loc[j, 'p'] > t else base[m]
                new = pd.Series(new)
                out[t].append((new.mean() - base.mean(), new[sub == 'S2'].mean() - base[sub == 'S2'].mean(),
                               new[sub == 'S1'].mean() - base[sub == 'S1'].mean(), int((new != base).sum())))
        for t in THR:
            a = np.array(out[t]); res.append(dict(features=fname, model=mname, thr=t, d_all=a[:, 0].mean(), sd=a[:, 0].std(),
                                                 d_S2=a[:, 1].mean(), d_S1=a[:, 2].mean(), n_changed=a[:, 3].mean(), auc=np.mean(auc_l)))
r = pd.DataFrame(res); pd.set_option('display.width', 200)
print(r.round(4).to_string(index=False))
r.to_csv('arbiter_cv_results.csv', index=False)
