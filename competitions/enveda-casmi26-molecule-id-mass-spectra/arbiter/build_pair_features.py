#!/usr/bin/env python3
"""Pairwise arbiter features from the validation dump (leader vs challenger at final ranks 2..K).

usage: build_pair_features.py DUMP_DIR FRAG_RESCORE_PY OUT.parquet [K]
DUMP_DIR = validation_dump_2026-11-01 (+ effective_query_spectra.parquet from the kernel output).
FRAG_RESCORE_PY = frag_rescore.py from the public m1 notebook (Roman Tamrazov's fragment check; not redistributed here).
'Unbiased' features: ice, gl, library_max, fragment coverage, structural descriptors. 'Biased' features
(neural_*, main/prefusion/engine2/pubchem ranks) come from weights that saw the held-out structures.
"""
import sys, importlib.util, json
from pathlib import Path
import numpy as np, pandas as pd
from rdkit import Chem, DataStructs, RDLogger
from rdkit.Chem import AllChem, rdMolDescriptors
from rdkit.Chem.MolStandardize import rdMolStandardize
RDLogger.DisableLog('rdApp.*')
dump, frag_py, out = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
K = int(sys.argv[4]) if len(sys.argv) > 4 else 6
spec = importlib.util.spec_from_file_location('frag_rescore', frag_py); fr = importlib.util.module_from_spec(spec); spec.loader.exec_module(fr)
nf = pd.read_parquet(dump / 'neural_candidate_features.parquet')
ans = pd.read_csv(dump / 'ans_final_submission.csv', dtype=str)
lab = pd.read_csv(dump / 'val_labels.csv', dtype=str).set_index('molecule_id')
qs = pd.read_parquet(dump / 'effective_query_spectra.parquet')
te = rdMolStandardize.TautomerEnumerator()
def ik14(s):
    m = Chem.MolFromSmiles(s)
    return Chem.MolToInchiKey(te.Canonicalize(m))[:14] if m is not None else None
cache = {}
rows = []
by_smi = {(r.molecule_id, r.smiles): r for r in nf.itertuples()}
for i, a in enumerate(ans.itertuples()):
    if a.molecule_id not in lab.index: continue
    lst = [g for g in a.smiles.split(';') if g][:25]
    truth = lab.loc[a.molecule_id, 'truth_ik14']
    top = lst[:K]
    sp = [dict(mz=np.asarray(r.ms2_mzs, float), it=np.asarray(r.ms2_normalized_intensities, float), adduct=r.adduct,
               prec=float(r.precursor_mz), mode=1 if r.ionization_mode == 'positive' else -1)
          for r in qs[qs.molecule_id == a.molecule_id].itertuples()]
    fscore = fr.score_molecule(sp, top, cache=cache)
    keys = [ik14(s) for s in top]
    mols = [Chem.MolFromSmiles(s) for s in top]
    fps = [AllChem.GetMorganFingerprintAsBitVect(m, 2, 2048) if m is not None else None for m in mols]
    forms = [rdMolDescriptors.CalcMolFormula(m) if m is not None else None for m in mols]
    L = 0
    frag_rank = pd.Series([f if f is not None else -1 for f in fscore]).rank(ascending=False, method='min').tolist()
    ice_rank = pd.Series([getattr(by_smi.get((a.molecule_id, s)), 'ice', np.nan) for s in top]).rank(ascending=False, method='min').tolist()
    gl_rank = pd.Series([getattr(by_smi.get((a.molecule_id, s)), 'gl', np.nan) for s in top]).rank(ascending=False, method='min').tolist()
    for j in range(1, len(top)):
        eL, eC = by_smi.get((a.molecule_id, top[L])), by_smi.get((a.molecule_id, top[j]))
        g = lambda e, c: getattr(e, c) if e is not None else np.nan
        rows.append(dict(
            molecule_id=a.molecule_id, subset=lab.loc[a.molecule_id, 'subset'], ch_rank=j + 1,
            y_leader=int(keys[L] == truth), y_ch=int(keys[j] == truth),
            # unbiased
            d_ice=g(eC, 'ice') - g(eL, 'ice'), d_gl=g(eC, 'gl') - g(eL, 'gl'), ice_ch=g(eC, 'ice'), gl_ch=g(eC, 'gl'),
            ice_rank_ch=ice_rank[j], ice_rank_L=ice_rank[L], gl_rank_ch=gl_rank[j], gl_rank_L=gl_rank[L],
            frag_L=fscore[L] if fscore[L] is not None else np.nan, frag_ch=fscore[j] if fscore[j] is not None else np.nan,
            d_frag=(fscore[j] - fscore[L]) if fscore[j] is not None and fscore[L] is not None else np.nan,
            frag_rank_ch=frag_rank[j], frag_rank_L=frag_rank[L],
            library_max=g(eL, 'library_max'), n_spectra=g(eL, 'n_spectra'), n_adducts=g(eL, 'n_adducts'),
            tanimoto=DataStructs.TanimotoSimilarity(fps[L], fps[j]) if fps[L] is not None and fps[j] is not None else np.nan,
            same_formula=int(forms[L] == forms[j]),
            d_heavy=(mols[j].GetNumHeavyAtoms() - mols[L].GetNumHeavyAtoms()) if mols[L] is not None and mols[j] is not None else np.nan,
            d_rings=(rdMolDescriptors.CalcNumRings(mols[j]) - rdMolDescriptors.CalcNumRings(mols[L])) if mols[L] is not None and mols[j] is not None else np.nan,
            # biased (weights saw the held-out structures)
            d_neural=g(eC, 'neural_score') - g(eL, 'neural_score'), neural_ch=g(eC, 'neural_score'),
            d_main_rank=g(eC, 'main_rank') - g(eL, 'main_rank'), d_pre_rank=g(eC, 'prefusion_rank') - g(eL, 'prefusion_rank'),
            engine2_ch=g(eC, 'engine2_rank'), engine2_L=g(eL, 'engine2_rank'), pubchem_ch=g(eC, 'pubchem_rank')))
    if i % 50 == 0: print(i, len(rows), flush=True)
df = pd.DataFrame(rows)
df.to_parquet(out)
print(df.shape, 'pairs; truth is leader:', int(df.groupby('molecule_id').y_leader.max().sum()), 'truth in ranks 2..K:',
      int(df.groupby('molecule_id').y_ch.max().sum()), 'of', df.molecule_id.nunique())
