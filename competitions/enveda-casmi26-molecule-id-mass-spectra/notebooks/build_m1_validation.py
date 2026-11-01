#!/usr/bin/env python3
"""Build the validation/feature-dump variant of busyaprime's public m1 notebook (LB 0.477).

usage: build_m1_validation.py SRC.ipynb OUT.ipynb

SRC is `kaggle kernels pull busyaprime/lb-0-477-two-0-472-fixes-merged-the-right-way`.
The pinned 0.465 pipeline (base64 in wrapper cell 8) only reads the real competition folder, so we
  1. patch three of its cells so an env var CASMI_VAL_COMP can redirect the data folder,
  2. re-pin its base64 + SHA-256 in the wrapper,
  3. add a prep cell that builds a purged train.parquet + held-out test.parquet + labels,
  4. add a final cell that scores every answer variant and keeps the candidate/score tables as outputs.
Everything else (pipeline, neural scorer, consensus, fragment check) is unchanged.
"""
import base64
import hashlib
import json
import re
import sys

src, out = sys.argv[1:3]
nb = json.load(open(src))
cells = nb['cells']
text = lambda i: ''.join(cells[i]['source'])


def code(s):
    return {'cell_type': 'code', 'metadata': {}, 'execution_count': None, 'outputs': [], 'source': s.splitlines(True)}


def md(s):
    return {'cell_type': 'markdown', 'metadata': {}, 'source': s.splitlines(True)}


def sub1(s, old, new):
    assert s.count(old) == 1, (old, s.count(old))
    return s.replace(old, new)


# ---- 1+2: patch the pinned pipeline ------------------------------------------------------------------------------
c8 = text(8)
m = re.search(r"FROZEN_B64 = '([A-Za-z0-9+/=]+)'", c8)
frozen = json.loads(base64.b64decode(m.group(1)))
fc = frozen['cells']


def fsrc(i):
    return ''.join(fc[i]['source'])


def fset(i, s):
    fc[i]['source'] = s.splitlines(True)


fset(4, sub1(fsrc(4), 'def locate_data_dir():\n',
             "def locate_data_dir():\n    if os.environ.get('CASMI_VAL_COMP'):\n"
             "        return Path(os.environ['CASMI_VAL_COMP']).resolve()\n"))
fset(26, sub1(fsrc(26), "COMP = os.path.dirname(find('test.parquet'))",
              "COMP = os.environ.get('CASMI_VAL_COMP') or os.path.dirname(find('test.parquet'))"))
fset(28, sub1(fsrc(28), "    assert comp in {f'/kaggle/input/{slug}', f'/kaggle/input/competitions/{slug}'}",
              "    assert os.environ.get('CASMI_VAL_COMP') or comp in {f'/kaggle/input/{slug}', f'/kaggle/input/competitions/{slug}'}"))
raw = json.dumps(frozen).encode()
new_sha = hashlib.sha256(raw).hexdigest()
new_b64 = base64.b64encode(raw).decode()
old_sha = re.search(r"FROZEN_SHA256 = '([0-9a-f]{64})'", c8).group(1)
c8 = c8.replace(m.group(1), new_b64).replace(old_sha, new_sha)
cells[8]['source'] = c8.splitlines(True)

# ---- config + session ------------------------------------------------------------------------------------------
cells[1]['source'] = (text(1) + "\n# VALIDATION: build a purged train + held-out test from train.parquet and run the whole pipeline on it\n"
                      "VALIDATION = True\nVAL_N_S2, VAL_N_S1, VAL_SEED = 200, 100, 0\n").splitlines(True)

PREP = r'''
# ── Validation prep: purged train.parquet + held-out test.parquet + labels (only when VALIDATION) ──
import hashlib, os
from pathlib import Path
import numpy as np, pandas as pd, pyarrow as pa, pyarrow.compute as pc, pyarrow.parquet as pq

VALCOMP = Path('/kaggle/working/valcomp')
TEST_ADDUCTS = ['[M+H]+', '[M+NH4]+', '[M-H2O+H]+', '[M-2H2O+H]+', '[M+Na]+', '[M+K]+', '[M-H]-', '[M-H2O-H]-',
                '[M+CH2O2-H]-', '[M+Cl]-']


def build_valcomp(real_comp):
    t0 = time.time()
    VALCOMP.mkdir(exist_ok=True)
    train_p = real_comp / 'train.parquet'
    light = pq.read_table(train_p, columns=['inchikey14', 'ingest_lib', 'adduct']).to_pandas()
    libs = light.groupby('inchikey14').ingest_lib.agg(lambda s: frozenset(s.unique()))
    n_ok = light[light.adduct.isin(TEST_ADDUCTS) & (light.ingest_lib.isin(['enveda-180', 'enveda-np-examples']))] \
        .groupby(['inchikey14', 'ingest_lib']).size()
    rng = np.random.default_rng(VAL_SEED)
    # S2: structures seen ONLY in enveda-180 (no other public spectra) with 2-8 usable spectra
    s2c = n_ok.xs('enveda-180', level='ingest_lib')
    s2c = s2c[(s2c >= 2) & (s2c <= 8)].index
    s2c = [k for k in s2c if libs[k] == frozenset({'enveda-180'})]
    s2 = list(rng.choice(sorted(s2c), size=min(VAL_N_S2, len(s2c)), replace=False))
    # S1: enveda-np-examples structures (famous natural products; they also exist in other libs; those get purged)
    s1c = sorted(n_ok.xs('enveda-np-examples', level='ingest_lib').index)
    s1 = list(rng.choice(s1c, size=min(VAL_N_S1, len(s1c)), replace=False))
    subset = {k: 'S2' for k in s2}; subset.update({k: 'S1' for k in s1})
    print(f'candidates S2 {len(s2c):,} S1 {len(s1c):,}; picked S2 {len(s2)} S1 {len(s1)}', flush=True)
    keys = pa.array(sorted(subset))
    # held-out spectra = the enveda timsTOF rows of those structures with a test adduct
    tbl = pq.read_table(train_p, filters=[('inchikey14', 'in', sorted(subset))])
    lib = tbl.column('ingest_lib').to_pylist(); ik = tbl.column('inchikey14').to_pylist()
    ad = tbl.column('adduct').to_pylist()
    keep = [i for i in range(tbl.num_rows) if ad[i] in TEST_ADDUCTS and
            lib[i] == ('enveda-180' if subset[ik[i]] == 'S2' else 'enveda-np-examples')]
    held = tbl.take(pa.array(keep))
    hik = held.column('inchikey14').to_pylist()
    mid = {k: 'm_' + hashlib.md5(f'{VAL_SEED}-{k}'.encode()).hexdigest()[:6] for k in sorted(subset)}
    real_test = pq.ParquetFile(real_comp / 'test.parquet').schema_arrow
    tcols = [f.name for f in real_test if f.name not in ('molecule_id', 'spectrum_id')]
    test = held.select(tcols)
    test = test.add_column(0, 'molecule_id', pa.array([mid[k] for k in hik]))
    test = test.add_column(1, 'spectrum_id', pa.array([f's_{i:06d}' for i in range(len(hik))]))
    try:
        test = test.select([f.name for f in real_test]).cast(real_test)
    except Exception as exc:  # noqa: BLE001
        print('test schema cast skipped:', type(exc).__name__, exc)
    pq.write_table(test, VALCOMP / 'test.parquet')
    lab = pd.DataFrame({'molecule_id': [mid[k] for k in hik], 'inchikey14': hik,
                        'normalized_smiles': held.column('normalized_smiles').to_pylist(),
                        'subset': [subset[k] for k in hik]}).drop_duplicates('molecule_id')
    lab['n_spectra'] = lab.molecule_id.map(pd.Series([mid[k] for k in hik]).value_counts())
    lab.to_csv(VALCOMP / 'val_labels.csv', index=False)
    sample = pd.read_csv(real_comp / 'sample_submission.csv', dtype=str).iloc[:1]
    pd.DataFrame({'molecule_id': lab.molecule_id, 'smiles': sample.smiles.iloc[0]}).to_csv(
        VALCOMP / 'sample_submission.csv', index=False)
    # purged train: stream, drop EVERY row of the held-out structures (all libraries)
    pf = pq.ParquetFile(train_p)
    writer = pq.ParquetWriter(VALCOMP / 'train.parquet', pf.schema_arrow, compression='zstd')
    n_in = n_out = 0
    for batch in pf.iter_batches(batch_size=200_000):
        t = pa.Table.from_batches([batch])
        mask = pc.invert(pc.is_in(t.column('inchikey14'), value_set=keys))
        t = t.filter(mask); n_in += batch.num_rows; n_out += t.num_rows
        writer.write_table(t)
    writer.close()
    print(f'purged train: {n_in:,} -> {n_out:,} rows; held-out {lab.shape[0]} molecules / {test.num_rows} spectra '
          f'({lab.subset.value_counts().to_dict()}) in {time.time() - t0:.0f}s', flush=True)
'''
cells.insert(2, code(PREP))
# session cell is now index 3: redirect COMP when VALIDATION
s3 = text(3)
s3 = sub1(s3, "assert COMP is not None, 'Attach the competition data (enveda-CASMI26-molecule-id-mass-spectra)'\n",
          "assert COMP is not None, 'Attach the competition data (enveda-CASMI26-molecule-id-mass-spectra)'\n"
          "REAL_COMP = COMP\nif VALIDATION:\n    build_valcomp(REAL_COMP)\n    COMP = VALCOMP\n"
          "    os.environ['CASMI_VAL_COMP'] = str(VALCOMP)\n")
cells[3]['source'] = s3.splitlines(True)

# ---- final cell: score every answer file + keep the dump ---------------------------------------------------------
DUMP = r'''
# ── Validation dump: per-molecule MRR of every answer file + candidate/score tables kept as outputs ──
import glob, shutil, json
from rdkit import Chem, RDLogger
from rdkit.Chem.MolStandardize import rdMolStandardize
RDLogger.DisableLog('rdApp.*')
_te = rdMolStandardize.TautomerEnumerator()
_cache = {}


def ik14(smi):
    if smi in _cache:
        return _cache[smi]
    try:
        m = Chem.MolFromSmiles(smi)
        v = Chem.MolToInchiKey(_te.Canonicalize(m))[:14] if m is not None else None
    except Exception:
        v = None
    _cache[smi] = v
    return v


lab = pd.read_csv(VALCOMP / 'val_labels.csv', dtype=str)
truth = {r.molecule_id: ik14(r.normalized_smiles) for r in lab.itertuples()}
subset_of = dict(zip(lab.molecule_id, lab.subset))
DUMP_DIR = ROOT / 'dump'; DUMP_DIR.mkdir(exist_ok=True)
files = [ROOT / 'submission.csv'] + sorted(Path(p) for p in glob.glob(str(ROOT / 'variants/*.csv'))) + \
        sorted(Path(p) for p in glob.glob(str(ROOT / 'submission_*.csv')))
rows, per_mol = [], {}
for f in files:
    sub = pd.read_csv(f, dtype=str, keep_default_na=False)
    rr = {}
    for r in sub.itertuples():
        guesses = [g for g in r.smiles.split(';') if g][:25]
        keys = [ik14(g) for g in guesses]
        t = truth.get(r.molecule_id)
        rr[r.molecule_id] = next((1.0 / (i + 1) for i, k in enumerate(keys) if k is not None and k == t), 0.0)
    per_mol[f.name] = rr
    ser = pd.Series(rr)
    for name, ids in (('ALL', list(rr)), ('S2', [m for m in rr if subset_of.get(m) == 'S2']),
                      ('S1', [m for m in rr if subset_of.get(m) == 'S1'])):
        rows.append(dict(file=f.name, subset=name, n=len(ids), mrr25=float(ser.reindex(ids).mean()),
                         top1=float((ser.reindex(ids) == 1.0).mean()), hit25=float((ser.reindex(ids) > 0).mean())))
res = pd.DataFrame(rows)
display(res.pivot(index='file', columns='subset', values='mrr25').round(4))
res.to_csv(DUMP_DIR / 'val_scores.csv', index=False)
pd.DataFrame(per_mol).to_csv(DUMP_DIR / 'val_per_molecule_rr.csv')
lab['truth_ik14'] = lab.molecule_id.map(truth); lab.to_csv(DUMP_DIR / 'val_labels.csv', index=False)
keep = ['frozen_candidate_evidence.parquet', 'outsider_evidence.parquet', 'neural_candidate_features.parquet',
        'outsider_neural_features.parquet', 'effective_query_spectra.parquet', 'execution_receipt.json',
        'spectral_parallax_report.json', 'provenance_tournament_report.json', 'merge_report.json']
for name in keep:
    if (ROOT / name).is_file():
        shutil.copy2(ROOT / name, DUMP_DIR / name)
for f in files:
    shutil.copy2(f, DUMP_DIR / ('ans_' + f.parent.name + '_' + f.name))
shutil.copy2(VALCOMP / 'test.parquet', DUMP_DIR / 'val_test.parquet')
# free the big intermediates so the saved version stays small
(VALCOMP / 'train.parquet').unlink(missing_ok=True)
for d in ('work', 'numba_cache', 'smoke_comp', 'p2s_code'):
    shutil.rmtree(ROOT / d, ignore_errors=True)
for p in ROOT.glob('*.parquet'):
    p.unlink()
print('dump size (MB):', sum(p.stat().st_size for p in DUMP_DIR.rglob('*') if p.is_file()) / 1e6)
'''
cells.append(code(DUMP))

cells.insert(0, md("**Validation/feature-dump variant (dalloliogm, 2026-11-01):** copy of busyaprime's public notebook "
                   "`lb-0-477-two-0-472-fixes-merged-the-right-way` (credits below). Differences: `VALIDATION=True` builds a "
                   "purged train + held-out test from `train.parquet` and runs the whole unchanged pipeline on it; three data-path "
                   "cells of the pinned pipeline are patched (re-pinned SHA-256); a final cell scores every answer file against the "
                   "labels and keeps candidate/score tables in `/kaggle/working/dump`. NOT for submission.\n"))
nb['cells'] = cells
json.dump(nb, open(out, 'w'), indent=1)
print('wrote', out, 'new FROZEN_SHA256', new_sha)
