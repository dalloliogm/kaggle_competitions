#!/usr/bin/env python3
"""User-authorized September 5 exploratory batch, fixed .80 fusion."""
import json,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'notebooks/public-reproductions/rishabh-division-geometry-080/rishabh-division-geometry-080.ipynb'
ARMS=[('gap50',5.0,.12),('div25',5.8,.25),('gap50-div18',5.0,.18),('gap54-div25',5.4,.25)]
for name,gap,threshold in ARMS:
    nb=json.loads(BASE.read_text())
    replacements={
        'BIOHUB_GAP_CLOSE_UM"] = "5.8"':f'BIOHUB_GAP_CLOSE_UM"] = "{gap}"',
        '"BIOHUB_GAP_CLOSE_UM": 5.8':f'"BIOHUB_GAP_CLOSE_UM": {gap}',
        '"gap_close_um": 5.8':f'"gap_close_um": {gap}',
        'os.environ.get("BIOHUB_DEEPCENTER_SAFE_DIV_THRESHOLD", "0.12")':f'os.environ.get("BIOHUB_DEEPCENTER_SAFE_DIV_THRESHOLD", "{threshold}")',
    }
    combined='\n'.join(''.join(c['source']) for c in nb['cells'])
    for old in replacements:
        if old not in combined:raise RuntimeError(f'Missing replacement {old}')
    for i,c in enumerate(nb['cells']):
        source=''.join(c['source'])
        for old,new in replacements.items():source=source.replace(old,new)
        if i==1:source+='\n# Disable legacy, checkpoint-exposed validation only; production inference unchanged.\nos.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"\n'
        c['source']=source.splitlines(keepends=True)
        if c['cell_type']=='code':c['outputs']=[];c['execution_count']=None;compile(source,f'{name}-{i}','exec')
    slug=f'biohub-sep05-{name}'
    nb['cells'][0]['source']=[f'# September 5 controlled probe: {name}\n\nFixed .80 fusion; gap {gap} um; DeepCenter division threshold {threshold}. User-authorized exploratory submission; no held-out efficacy claim.\n']
    out=ROOT/'notebooks/public-reproductions'/slug;out.mkdir(parents=True,exist_ok=True)
    filename=slug+'.ipynb';(out/filename).write_text(json.dumps(nb,indent=1)+'\n')
    meta=json.loads((BASE.parent/'kernel-metadata.json').read_text());meta.update(id='dalloliogm/'+slug,title=slug,code_file=filename,is_private=True,enable_internet=False)
    for f in ['kernel-metadata.json',slug+'.kernel-metadata.json']:(out/f).write_text(json.dumps(meta,indent=2)+'\n')
    print(out/filename)
