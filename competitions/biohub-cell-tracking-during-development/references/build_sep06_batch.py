"""Build the five approved Sep 6 probes and one conditional duplicate reserve."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'notebooks/public-reproductions/rishabh-division-geometry-080/rishabh-division-geometry-080.ipynb'
assert hashlib.sha256(BASE.read_bytes()).hexdigest()==json.loads((ROOT/'references/incumbent_manifest.json').read_text())['notebook_sha256']
ARMS={'image08':{'image':'.08'},'diverge50':{'diverge':'5.0'},'image08-diverge50':{'image':'.08','diverge':'5.0'},'symmetry45':{'symmetry':'0.45'},'retention95':{'retention':'0.95'},'reserve-retention85':{'retention':'0.85'}}
manifest={'date':'2026-09-06','authorization':'User said do it to the five-probe execution plan including private runs and audited submissions','status':'AUTHORIZED','arms':{}}
for name,change in ARMS.items():
 nb=json.loads(BASE.read_text());replacements={}
 if 'image' in change:replacements['os.environ.get("BIOHUB_DEEPCENTER_SAFE_DIV_THRESHOLD", "0.12")']=f'os.environ.get("BIOHUB_DEEPCENTER_SAFE_DIV_THRESHOLD", "{change["image"]}")'
 if 'diverge' in change:replacements['BIOHUB_SAFE_DIV_DIVERGE_UM"] = "4.5"']='BIOHUB_SAFE_DIV_DIVERGE_UM"] = "5.0"'
 if 'symmetry' in change:replacements['BIOHUB_SAFE_DIV_SISTER_SYMMETRY_TAU"] = "0.6"']='BIOHUB_SAFE_DIV_SISTER_SYMMETRY_TAU"] = "0.45"'
 if 'retention' in change:
  value=change['retention']
  replacements.update({'BIOHUB_DUAL_SEED_MIN_CANDIDATE_RETENTION"] = "0.90"':f'BIOHUB_DUAL_SEED_MIN_CANDIDATE_RETENTION"] = "{value}"','"BIOHUB_DUAL_SEED_MIN_CANDIDATE_RETENTION": "0.90"':f'"BIOHUB_DUAL_SEED_MIN_CANDIDATE_RETENTION": "{value}"','float(_guard_record["minimum_retention"])\n        != 0.9':f'float(_guard_record["minimum_retention"])\n        != {value}','float(_guard_record["retention"])\n        < 0.9':f'float(_guard_record["retention"])\n        < {value}','"minimum_candidate_retention": 0.9':f'"minimum_candidate_retention": {value}'})
 combined='\n'.join(''.join(c['source']) for c in nb['cells'])
 for old in replacements:assert old in combined,old
 for i,c in enumerate(nb['cells']):
  s=''.join(c['source'])
  for old,new in replacements.items():s=s.replace(old,new)
  if i==1:s+='\nos.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"\n'
  if c['cell_type']=='code':compile(s,f'{name}-cell{i}','exec');c.update(outputs=[],execution_count=None)
  c['source']=s.splitlines(keepends=True)
 nb['cells'][0]['source']=[f'# September 6 exploratory probe: {name}\n\nChanges from the frozen .80 incumbent: {change}. No independent holdout claim.\n']
 slug='biohub-sep06-'+name;out=ROOT/'notebooks/public-reproductions'/slug;out.mkdir(parents=True,exist_ok=True);file=out/(slug+'.ipynb');file.write_text(json.dumps(nb,indent=1)+'\n')
 meta=json.loads((BASE.parent/'kernel-metadata.json').read_text());meta.update(id='dalloliogm/'+slug,title=slug,code_file=file.name,is_private=True,enable_internet=False)
 for path in (out/'kernel-metadata.json',file.with_suffix('.kernel-metadata.json')):path.write_text(json.dumps(meta,indent=2)+'\n')
 manifest['arms'][name]={'changes':change,'kernel':meta['id'],'notebook_sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'reserve':name.startswith('reserve-')}
 print(slug)
(ROOT/'references/authorized-five-batch-2026-09-06.json').write_text(json.dumps(manifest,indent=2)+'\n')
