"""Rank-1 arbiter applied to a finished answer file (runs inside the Kaggle notebook after the m1 merge).

For every processed molecule: leader = rank 1; challengers = ranks 2..K. A LightGBM model trained on the 1500 validation
pairs (clean, within-molecule features only: ICEBERG/GLACIER, fragment coverage, leader-challenger structure) gives
P(challenger is the truth | exactly one of the two is). If the best challenger has P > thr it moves to rank 1, the old leader to
rank 2, everything else keeps its order. Trained and applied with fixed seeds. Training pairs: arbiter/pairs_validation_2026-11-01.parquet,
produced by arbiter/build_pair_features.py from the validation dump of the same pipeline.
"""
import importlib.util
import sys
from pathlib import Path
import numpy as np
import pandas as pd

CLEAN = ['d_ice', 'd_gl', 'ice_ch', 'gl_ch', 'ice_rank_ch', 'ice_rank_L', 'gl_rank_ch', 'gl_rank_L', 'frag_L', 'frag_ch', 'd_frag',
         'frag_rank_ch', 'frag_rank_L', 'tanimoto', 'same_formula', 'd_heavy', 'd_rings', 'ch_rank']


def pair_features(root, frag_py, K=6, log=print):
    from rdkit import Chem, DataStructs, RDLogger
    from rdkit.Chem import AllChem, rdMolDescriptors
    RDLogger.DisableLog('rdApp.*')
    root = Path(root)
    fr = sys.modules.get('frag_rescore')
    if fr is None or not hasattr(fr, 'score_molecule'):
        spec = importlib.util.spec_from_file_location('frag_rescore', frag_py)
        fr = importlib.util.module_from_spec(spec)
        sys.modules['frag_rescore'] = fr  # numba's on-disk cache re-imports the defining module by name
        spec.loader.exec_module(fr)
    nf = pd.read_parquet(root / 'neural_candidate_features.parquet')
    nf = nf[nf.processed.astype(bool)]
    by_smi = {(r.molecule_id, r.smiles): r for r in nf.itertuples()}
    ans = pd.read_csv(root / 'submission.csv', dtype=str, keep_default_na=False)
    qs = pd.read_parquet(root / 'effective_query_spectra.parquet')
    qs_by_mol = {m: g for m, g in qs.groupby('molecule_id')}
    cache, rows = {}, []
    for a in ans.itertuples():
        lst = [g for g in a.smiles.split(';') if g][:25]
        top = lst[:K]
        if len(top) < 2 or (a.molecule_id, top[0]) not in by_smi or a.molecule_id not in qs_by_mol:
            continue
        sp = [dict(mz=np.asarray(r.ms2_mzs, float), it=np.asarray(r.ms2_normalized_intensities, float), adduct=r.adduct,
                   prec=float(r.precursor_mz), mode=1 if r.ionization_mode == 'positive' else -1)
              for r in qs_by_mol[a.molecule_id].itertuples()]
        try:
            fscore = fr.score_molecule(sp, top, cache=cache)
        except Exception as exc:  # noqa: BLE001
            log(f'arbiter: fragment score failed for {a.molecule_id}: {exc!r}'); continue
        mols = [Chem.MolFromSmiles(s) for s in top]
        fps = [AllChem.GetMorganFingerprintAsBitVect(m, 2, 2048) if m is not None else None for m in mols]
        forms = [rdMolDescriptors.CalcMolFormula(m) if m is not None else None for m in mols]
        ice = [getattr(by_smi.get((a.molecule_id, s)), 'ice', np.nan) for s in top]
        gl = [getattr(by_smi.get((a.molecule_id, s)), 'gl', np.nan) for s in top]
        rk = lambda v: pd.Series(v).rank(ascending=False, method='min').tolist()
        frag_rank = rk([f if f is not None else -1 for f in fscore]); ice_rank = rk(ice); gl_rank = rk(gl)
        L = 0
        for j in range(1, len(top)):
            fl, fc = fscore[L], fscore[j]
            ok = mols[L] is not None and mols[j] is not None
            rows.append(dict(
                molecule_id=a.molecule_id, ch_rank=j + 1, ch_smiles=top[j],
                d_ice=ice[j] - ice[L], d_gl=gl[j] - gl[L], ice_ch=ice[j], gl_ch=gl[j],
                ice_rank_ch=ice_rank[j], ice_rank_L=ice_rank[L], gl_rank_ch=gl_rank[j], gl_rank_L=gl_rank[L],
                frag_L=fl if fl is not None else np.nan, frag_ch=fc if fc is not None else np.nan,
                d_frag=(fc - fl) if fl is not None and fc is not None else np.nan,
                frag_rank_ch=frag_rank[j], frag_rank_L=frag_rank[L],
                tanimoto=DataStructs.TanimotoSimilarity(fps[L], fps[j]) if fps[L] is not None and fps[j] is not None else np.nan,
                same_formula=int(forms[L] == forms[j]),
                d_heavy=(mols[j].GetNumHeavyAtoms() - mols[L].GetNumHeavyAtoms()) if ok else np.nan,
                d_rings=(rdMolDescriptors.CalcNumRings(mols[j]) - rdMolDescriptors.CalcNumRings(mols[L])) if ok else np.nan))
    out = pd.DataFrame(rows)
    if len(out) and out.frag_L.isna().all():
        raise RuntimeError('fragment scores are all missing - refusing to run the arbiter on broken features')
    return out


def fit_arbiter(train_pairs):
    import lightgbm as lgb
    t = train_pairs[(train_pairs.y_leader + train_pairs.y_ch) == 1]
    m = lgb.LGBMClassifier(n_estimators=120, learning_rate=0.05, num_leaves=7, min_child_samples=15, subsample=0.8,
                           colsample_bytree=0.8, reg_lambda=5.0, random_state=0, n_jobs=1, deterministic=True,
                           force_row_wise=True, verbose=-1)
    m.fit(t[CLEAN], t.y_ch)
    return m


def apply_arbiter(root, train_pairs, frag_py, thr=0.8, K=6, log=print):
    root = Path(root)
    feats = pair_features(root, frag_py, K, log)
    if feats.empty:
        return dict(status='no features', swapped=0)
    model = fit_arbiter(train_pairs)
    feats['p'] = model.predict_proba(feats[CLEAN])[:, 1]
    best = feats.loc[feats.groupby('molecule_id').p.idxmax()]
    swaps = best[best.p > thr].set_index('molecule_id')
    ans = pd.read_csv(root / 'submission.csv', dtype=str, keep_default_na=False)
    ans.to_csv(root / 'submission_pre_arbiter.csv', index=False)
    new = []
    for r in ans.itertuples():
        lst = [g for g in r.smiles.split(';') if g]
        if r.molecule_id in swaps.index:
            ch = swaps.loc[r.molecule_id, 'ch_smiles']
            if ch in lst[1:]:
                lst = [ch, lst[0]] + [x for x in lst[1:] if x != ch]
        new.append(';'.join(lst))
    out = ans.assign(smiles=new)
    assert out.molecule_id.is_unique and len(out) == len(ans) and out.smiles.str.len().min() > 0
    assert all(len(set(s.split(';'))) == len(s.split(';')) <= 25 for s in out.smiles)
    out.to_csv(root / 'submission.csv', index=False)
    return dict(status='ok', molecules_scored=int(feats.molecule_id.nunique()), swapped=int(len(swaps)), threshold=thr,
                max_p=float(best.p.max()), mean_best_p=float(best.p.mean()))
