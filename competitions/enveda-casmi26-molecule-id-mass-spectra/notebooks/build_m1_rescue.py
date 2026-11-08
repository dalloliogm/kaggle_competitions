#!/usr/bin/env python3
"""m1 (public 0.477) + tail rescue: outside candidates compete by neural score for the last N places (ranks 26-N..25).
Only config changes to busyaprime's notebook (CUSTOM rescue, OUTSIDERS_PER_MOLECULE) + a cleanup cell. Ranks 1..25-N are unchanged.
usage: build_m1_rescue.py SRC.ipynb OUT.ipynb [slots] [outsiders]"""
import json, sys
src, out = sys.argv[1:3]
slots = int(sys.argv[3]) if len(sys.argv) > 3 else 5
outs = int(sys.argv[4]) if len(sys.argv) > 4 else 40
nb = json.load(open(src)); cells = nb['cells']
c1 = ''.join(cells[1]['source'])
for old, new in (("CUSTOM = dict(w_top=0.25, w_mid=0.75, rescue=0)", f"CUSTOM = dict(w_top=0.25, w_mid=0.75, rescue={slots})"),
                 ("OUTSIDERS_PER_MOLECULE = 20", f"OUTSIDERS_PER_MOLECULE = {outs}")):
    assert c1.count(old) == 1, old
    c1 = c1.replace(old, new)
cells[1]['source'] = c1.splitlines(True)
CLEAN = '''# ── Housekeeping: drop bulky intermediate folders so the saved output stays small ──
import shutil as _sh
for _d in ('ice_site', 'eng', 'v43_v4code', 'work', 'numba_cache', 'smoke_comp', 'variants_check'):
    _sh.rmtree(ROOT / _d, ignore_errors=True)
'''
cells.append({'cell_type': 'code', 'metadata': {}, 'execution_count': None, 'outputs': [], 'source': CLEAN.splitlines(True)})
cells.insert(0, {'cell_type': 'markdown', 'metadata': {}, 'source': [
    f"**Fork note (dalloliogm, 2026-11-08):** busyaprime's public `lb-0-477-two-0-472-fixes-merged-the-right-way` (credits below) with two configuration changes: "
    f"`CUSTOM rescue={slots}` (outside candidates may take the last {slots} places by neural score) and `OUTSIDERS_PER_MOLECULE={outs}`; plus an output-cleanup cell. Ranks 1-{25-slots} are unchanged.\n"]})
json.dump(nb, open(out, 'w'), indent=1); print('wrote', out, slots, outs)
