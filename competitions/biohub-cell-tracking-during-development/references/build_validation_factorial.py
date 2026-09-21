#!/usr/bin/env python3
"""Build a private diagnostic from the exact .80 incumbent; no submission calls.

Inference is shared across arms because only downstream gap/division settings
change. Each arm receives a fresh deep copy of the same raw graph.
"""
import ast
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'notebooks/public-reproductions/rishabh-division-geometry-080/rishabh-division-geometry-080.ipynb'
OUT=ROOT/'notebooks/diagnostics/frozen-gap-division-factorial'

def main():
    nb=json.loads(SOURCE.read_text())
    source_sha=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    frozen=json.loads((ROOT/'references/incumbent_manifest.json').read_text())
    if source_sha!=frozen['notebook_sha256']:
        raise ValueError('Incumbent source changed; review and freeze a new manifest before rebuilding')
    split=json.loads((ROOT/'references/validation_split_manifest.json').read_text())
    vendor=ROOT/'references/official-scorer-075fc5f'
    scorer=json.loads((vendor/'manifest.json').read_text())
    payload={p:(vendor/p).read_text() for p in scorer['files']}
    boot='''# Frozen experiment and official scorer; no network needed.
import hashlib, json, sys
from pathlib import Path
'''+f'FROZEN_SPLIT = {split!r}\nOFFICIAL_SCORER_MANIFEST = {scorer!r}\nSOURCE_NOTEBOOK_SHA256 = {source_sha!r}\nSCORER_FILES = {payload!r}\n'+'''
_scorer_root=Path('/kaggle/working/frozen_official_scorer')
for _name,_text in SCORER_FILES.items():
    _path=_scorer_root/_name; _path.parent.mkdir(parents=True,exist_ok=True)
    _path.write_text(_text)
    if hashlib.sha256(_path.read_bytes()).hexdigest()!=OFFICIAL_SCORER_MANIFEST['files'][_name]:
        raise RuntimeError('Official scorer checksum mismatch')
sys.path.insert(0,str(_scorer_root))
FACTORIAL_ACTIVE_ARM='incumbent_test'
FACTORIAL_STAGE_ROWS=[]
def factorial_snapshot(stage,dataset,nodes,edges):
    from collections import Counter
    degree=Counter(int(e['source_id']) for e in edges)
    FACTORIAL_STAGE_ROWS.append({'arm':FACTORIAL_ACTIVE_ARM,'dataset':dataset,'stage':stage,
        'nodes':len(nodes),'edges':len(edges),'divisions':sum(n==2 for n in degree.values())})
'''
    nb['cells'][0]['source']=['# Frozen gap/division factorial diagnostics\n\n',
        'Four controlled arms plus a divisions-off control share .80 detections. ',
        'Official scorer pinned; existing development movies are checkpoint-exposed. ',
        'No independent holdout claim and no automatic competition submission.\n']
    # Keep original inference code, inject non-mutating stage counts.
    for cell in nb['cells']:
        if cell['cell_type']!='code': continue
        s=''.join(cell['source'])
        stages=[('    print(f"  [{dataset}] after edge-filter+motion-relink:', 'association'),
                ('    print(f"  [{dataset}] after gap-closing (single-frame + gap2):','gaps'),
                ('    _geo_cands = stats[','divisions'),
                ('    print(f"  [{dataset}] after division-geometry-filter+prune-isolated:','pruning'),
                ('    print(f"  [{dataset}] FINAL:','final')]
        for anchor,stage in stages:
            if anchor in s:
                if s.count(anchor)!=1: raise ValueError(f'Ambiguous stage anchor: {anchor}')
                s=s.replace(anchor,f'    factorial_snapshot({stage!r},dataset,nodes_by_id,edges)\n'+anchor)
        cell['source']=s.splitlines(keepends=True)
        cell['outputs']=[]; cell['execution_count']=None
    selection=''.join(nb['cells'][8]['source'])
    a=selection.index('if VALIDATOR_ENABLE and TRAIN_DIR.exists():')
    b=selection.index('\ndef _merge_validator_shards',a)
    selection=selection[:a]+'''if not VALIDATOR_ENABLE or not TRAIN_DIR.exists():
    raise RuntimeError('Frozen diagnostic requires labelled train data')
val_stems=sorted(sum(FROZEN_SPLIT['development_folds'].values(),[]))
for stem in val_stems:
    if not (TRAIN_DIR/f'{stem}.zarr').exists() or not (TRAIN_DIR/f'{stem}.geff').exists():
        raise RuntimeError(f'Missing frozen validation movie {stem}')
'''+selection[b:]
    nb['cells'][8]['source']=selection.splitlines(keepends=True)
    nb['cells'][9]['source']=(ROOT/'scripts/factorial_validation_runtime.py').read_text().splitlines(keepends=True)
    nb['cells'].insert(1,{'cell_type':'code','metadata':{},'execution_count':None,'outputs':[],'source':boot.splitlines(keepends=True)})
    nb['cells'].append({'cell_type':'code','metadata':{},'execution_count':None,'outputs':[], 'source':["pd.DataFrame(FACTORIAL_STAGE_ROWS).to_csv(WORKING_DIR/'factorial_validation'/'stage_counts.csv',index=False)\n"]})
    # Clear inherited output-related claims; this artifact is diagnostic-only.
    for i,c in enumerate(nb['cells']):
        if c['cell_type']=='code': ast.parse(''.join(c['source']),filename=f'cell-{i}')
    OUT.mkdir(parents=True,exist_ok=True)
    filename='frozen-gap-division-factorial.ipynb'
    (OUT/filename).write_text(json.dumps(nb,indent=1)+'\n')
    meta=json.loads((SOURCE.parent/'kernel-metadata.json').read_text())
    meta.update(id='dalloliogm/biohub-frozen-gap-division-factorial',title='Biohub Frozen Gap Division Factorial',code_file=filename,is_private=True,enable_internet=False)
    for name in ('kernel-metadata.json','frozen-gap-division-factorial.kernel-metadata.json'):
        (OUT/name).write_text(json.dumps(meta,indent=2)+'\n')
    manifest={'status':'PREPARED_DIAGNOSTIC_ONLY','source':str(SOURCE.relative_to(ROOT)), 'source_sha256':source_sha,
              'notebook_sha256':hashlib.sha256((OUT/filename).read_bytes()).hexdigest(),
              'hypothesis':'Gap distance and division image threshold interact; isolate main effects and interaction at fixed .80 fusion.',
              'arms':{'incumbent':[5.8,.12],'gap_only':[5.0,.12],'threshold_only':[5.8,.25],'both':[5.0,.25],'divisions_off':[5.8,.12]},
              'scorer_revision':scorer['revision'],'split_manifest_sha256':hashlib.sha256((ROOT/'references/validation_split_manifest.json').read_bytes()).hexdigest(),
              'max_movie_regression':.002,'synthetic_branch':'HELD: require actual detector candidates on current base',
              'selection_rule':'Diagnostic only while checkpoint exposure prevents an independent holdout; no promotion on this run.'}
    (ROOT/'references/factorial_experiment_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(OUT/filename)
if __name__=='__main__': main()
