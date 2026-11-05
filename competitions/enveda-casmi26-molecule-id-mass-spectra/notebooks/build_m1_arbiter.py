#!/usr/bin/env python3
"""Build the m1 + rank-1 arbiter notebook: busyaprime's public 0.477 notebook with one extra cell after the final merge.

usage: build_m1_arbiter.py SRC.ipynb OUT.ipynb [threshold]
The extra cell = arbiter/arbiter_apply.py (verbatim) + the 1500 validation training pairs (base64 parquet) + a guarded call.
On any error the previous submission.csv (before the arbiter) is restored.
"""
import base64, json, sys
from pathlib import Path

src, out = sys.argv[1:3]
thr = float(sys.argv[3]) if len(sys.argv) > 3 else 0.8
here = Path(__file__).resolve().parent.parent / 'arbiter'
nb = json.load(open(src)); cells = nb['cells']
assert ''.join(cells[15]['source']).lstrip().startswith('# ── Variant M'), 'unexpected cell layout'
pairs_b64 = base64.b64encode((here / 'pairs_validation_2026-11-01.parquet').read_bytes()).decode()
code = (here / 'arbiter_apply.py').read_text() + f'''

# ── run (guarded): any failure restores the answer file as the m1 merge wrote it ──
import io, base64, shutil, traceback, time as _t
ARBITER = True
ARBITER_THR = {thr}
PAIRS_B64 = "{pairs_b64}"
ARBITER_REPORT = {{'status': 'disabled'}}
if ARBITER:
    try:
        if (_t.time() - NB_T0) > 8.2 * 3600:
            ARBITER_REPORT = {{'status': 'skipped: runtime budget'}}
        else:
            _pairs = pd.read_parquet(io.BytesIO(base64.b64decode(PAIRS_B64)))
            ARBITER_REPORT = apply_arbiter(ROOT, _pairs, ROOT / 'frag_rescore.py', thr=ARBITER_THR)
    except Exception:
        traceback.print_exc()
        if (ROOT / 'submission_pre_arbiter.csv').is_file():
            shutil.copy2(ROOT / 'submission_pre_arbiter.csv', ROOT / 'submission.csv')
        ARBITER_REPORT = {{'status': 'failed, restored'}}
print('ARBITER', ARBITER_REPORT)
'''
cell = {'cell_type': 'code', 'metadata': {}, 'execution_count': None, 'outputs': [], 'source': code.splitlines(True)}
cells.insert(16, cell)
cells.insert(0, {'cell_type': 'markdown', 'metadata': {}, 'source': [
    "**Fork note (dalloliogm, 2026-11-05):** busyaprime's public `lb-0-477-two-0-472-fixes-merged-the-right-way` (credits below) plus ONE added cell "
    "after the final merge: a rank-1 arbiter (LightGBM on ICEBERG/GLACIER, fragment coverage and structure features, trained on 1500 validation pairs from "
    "our held-out run of this same pipeline; swaps the leader with a rank 2-6 candidate only when P > threshold). Code: `arbiter/` in github.com/dalloliogm/kaggle_competitions.\n"]})
nb['cells'] = cells
json.dump(nb, open(out, 'w'), indent=1)
print('wrote', out, 'threshold', thr)
