#!/usr/bin/env python3
"""m1 (public 0.477) + POST-MERGE tail rescue.

Why post-merge: putting rescue>0 into CUSTOM changes candidate sets, and m1's merge cell then SKIPS every molecule whose set differs
(merge_report 'candidate_set_differs'), dropping the fragment check's rank-1 moves (the step that takes 0.472 -> 0.477). So CUSTOM keeps
rescue=0 and this script appends a cell AFTER the merge that lets outside candidates compete by neural score for the last N places.
Ranks 1..25-N are untouched (asserted). usage: build_m1_rescue.py SRC.ipynb OUT.ipynb [slots] [outsiders]"""
import json, sys
src, out = sys.argv[1:3]
slots = int(sys.argv[3]) if len(sys.argv) > 3 else 5
outs = int(sys.argv[4]) if len(sys.argv) > 4 else 40
nb = json.load(open(src)); cells = nb['cells']
assert ''.join(cells[15]['source']).lstrip().startswith('# ── Variant M'), 'unexpected cell layout'
c1 = ''.join(cells[1]['source'])
old = "OUTSIDERS_PER_MOLECULE = 20"
assert c1.count(old) == 1
cells[1]['source'] = c1.replace(old, f"OUTSIDERS_PER_MOLECULE = {outs}").splitlines(True)
TAIL = f'''# ── Post-merge tail rescue: outside candidates compete (neural score) for the last {slots} places; ranks 1-{25-slots} untouched ──
import json as _json, traceback as _tb, shutil as _sh
import numpy as _np, pandas as _pd
TAIL_SLOTS = {slots}
TAIL_REPORT = {{'status': 'disabled'}}
try:
    _sub = _pd.read_csv(ROOT / 'submission.csv', dtype=str, keep_default_na=False)
    _sub.to_csv(ROOT / 'submission_pre_tail.csv', index=False)
    _outs = consensus.read_outsiders(ROOT / 'outsider_neural_features.parquet')
    _nf = _pd.read_parquet(ROOT / 'neural_candidate_features.parquet')
    _nf = _nf[_nf.neural_ok.astype(bool)]
    _smap = {{(m, s): float(v) for m, s, v in zip(_nf.molecule_id.astype(str), _nf.smiles.astype(str), _nf.neural_score)}}
    _rows, _changed, _admitted, _skipped = [], 0, 0, 0
    for _r in _sub.itertuples():
        _lst = [g for g in _r.smiles.split(';') if g]
        _new = _lst
        if _r.molecule_id in _outs and len(_lst) >= TAIL_SLOTS:
            _sc = [_smap.get((_r.molecule_id, s), _np.nan) for s in _lst]
            if all(_np.isfinite(v) for v in _sc[-TAIL_SLOTS:]):
                _cand, _n = consensus.rescue_tail(_lst, _sc, _outs[_r.molecule_id], TAIL_SLOTS)
                if _n > 0 and _cand[:len(_lst) - TAIL_SLOTS] == _lst[:len(_lst) - TAIL_SLOTS] and len(set(_cand)) == len(_cand) <= 25:
                    _new = _cand; _changed += 1; _admitted += _n
            else:
                _skipped += 1
        _rows.append(';'.join(_new))
    _out = _sub.assign(smiles=_rows)
    assert _out.molecule_id.is_unique and len(_out) == len(_sub)
    assert all(1 <= len(s.split(';')) <= 25 and len(set(s.split(';'))) == len(s.split(';')) for s in _out.smiles)
    assert all(a.split(';')[:20] == b.split(';')[:20] for a, b in zip(_sub.smiles, _out.smiles))
    _out.to_csv(ROOT / 'submission.csv', index=False)
    TAIL_REPORT = dict(status='ok', slots=TAIL_SLOTS, molecules_changed=_changed, outsiders_admitted=_admitted, skipped_missing_scores=_skipped)
except Exception:
    _tb.print_exc()
    if (ROOT / 'submission_pre_tail.csv').is_file():
        _sh.copy2(ROOT / 'submission_pre_tail.csv', ROOT / 'submission.csv')
    TAIL_REPORT = {{'status': 'failed, restored'}}
(ROOT / 'tail_rescue_report.json').write_text(_json.dumps(TAIL_REPORT, default=str))
print('TAIL_RESCUE', TAIL_REPORT)
'''
cells.insert(16, {'cell_type': 'code', 'metadata': {}, 'execution_count': None, 'outputs': [], 'source': TAIL.splitlines(True)})
CLEAN = '''# ── Housekeeping: drop bulky intermediate folders so the saved output stays small ──
import shutil as _sh2
for _d in ('ice_site', 'eng', 'v43_v4code', 'work', 'numba_cache', 'smoke_comp', 'variants_check'):
    _sh2.rmtree(ROOT / _d, ignore_errors=True)
'''
cells.append({'cell_type': 'code', 'metadata': {}, 'execution_count': None, 'outputs': [], 'source': CLEAN.splitlines(True)})
cells.insert(0, {'cell_type': 'markdown', 'metadata': {}, 'source': [
    f"**Fork note (dalloliogm, 2026-11-08):** busyaprime's public `lb-0-477-two-0-472-fixes-merged-the-right-way` (credits below) plus one cell AFTER the final merge: "
    f"outside candidates (`OUTSIDERS_PER_MOLECULE={outs}`) may take the last {slots} places by neural score (the notebook's own `consensus.rescue_tail`). "
    f"Ranks 1-{25-slots} are unchanged (asserted); the fragment-check merge is unaffected. Plus an output-cleanup cell.\n"]})
json.dump(nb, open(out, 'w'), indent=1); print('wrote', out, slots, outs)
