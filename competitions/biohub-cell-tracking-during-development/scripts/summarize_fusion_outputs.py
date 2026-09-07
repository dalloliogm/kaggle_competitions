#!/usr/bin/env python3
"""Audit fusion outputs by movie without assuming node IDs align across runs."""
import argparse
import hashlib
import json
from pathlib import Path
import pandas as pd
from biohub_validation_harness import load_submission, structural_report

def summarize(paths):
    outputs=[]
    for path in paths:
        frame=load_submission(path); audit=structural_report(frame,path)
        if not audit.valid: raise ValueError(f'{path}: {audit.errors}')
        movies=[]
        for name,g in frame.groupby('dataset'):
            nodes=g[g.row_type=='node']; edges=g[g.row_type=='edge']
            degree=edges.groupby('source_id').size()
            movies.append({'dataset':name,'nodes':len(nodes),'edges':len(edges),
                           'divisions':int((degree==2).sum()),'frames':int(nodes.t.nunique())})
        stats=path.parent/'run_stats.csv'
        outputs.append({'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                        'movies':movies,'stage_stats':pd.read_csv(stats).fillna('').to_dict('records') if stats.exists() else None})
    return {'evidence':'STRUCTURAL_PASS','warning':'Counts and activation counters do not establish accuracy. Do not compare raw node IDs between fusion runs.','outputs':outputs}
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('outputs',type=Path,nargs='+');p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    a.output.write_text(json.dumps(summarize(a.outputs),indent=2)+'\n')
