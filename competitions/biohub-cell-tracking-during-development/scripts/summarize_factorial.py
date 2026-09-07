#!/usr/bin/env python3
"""Compare completed factorial outputs, export disagreements and seeded controls.

Compare exact endpoint coordinates; synthetic node IDs can differ between arms.
Annotations can be added to review_queue.csv; unknown labels stay unknown.
"""
import argparse
import json
import random
from pathlib import Path
from compare_validation_reports import compare

ARMS=('gap_only','threshold_only','both','divisions_off')

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('directory',type=Path);a=p.parse_args();root=a.directory
    result=compare(root/'incumbent.csv',[root/f'{arm}.csv' for arm in ARMS])
    deltas={Path(r['candidate']).stem:r['official_score_delta'] for r in result['results']}
    result['interaction_delta']=deltas['both']-deltas['gap_only']-deltas['threshold_only']
    (root/'comparison.json').write_text(json.dumps(result,indent=2,allow_nan=False)+'\n')
    import csv
    events=[]
    rng=random.Random(20260905)
    for base_path in sorted(root.glob('incumbent-*-graph.json')):
        dataset=base_path.name[len('incumbent-'):-len('-graph.json')]
        def spatial_edges(graph):
            nodes={int(n['node_id']):n for n in graph['nodes']}
            def key(n): return tuple(float(n[k]) for k in ('t','z','y','x'))
            return {key(nodes[int(src)])+key(nodes[int(tgt)]):(int(src),int(tgt)) for src,tgt in graph['edges']}
        base=json.loads(base_path.read_text()); base_edges=spatial_edges(base); be=set(base_edges)
        for arm in ARMS:
            current=json.loads((root/f'{arm}-{dataset}-graph.json').read_text()); current_edges=spatial_edges(current); ce=set(current_edges)
            for category,edges,graph in [('removed',be-ce,base),('added',ce-be,current),('unchanged',be&ce,base)]:
                # Fixed seeded sample; not cherry-picked by errors or confidence.
                chosen=rng.sample(sorted(edges),min(20,len(edges)))
                nodes={int(n['node_id']):n for n in graph['nodes']}
                mapping=spatial_edges(graph)
                for edge_key in chosen:
                    src,tgt=mapping[edge_key]
                    s=nodes[src];t=nodes[tgt]
                    events.append({'dataset':dataset,'arm':arm,'change':category,'source_id':src,'target_id':tgt,
                                   'source_t':s['t'],'target_t':t['t'],'z':t['z'],'y':t['y'],'x':t['x'],
                                   'image_path':f'train/{dataset}.zarr','review_label':'UNKNOWN','review_note':''})
    rng.shuffle(events)
    if events:
        with (root/'review_queue.csv').open('w') as f:
            w=csv.DictWriter(f,fieldnames=list(events[0]));w.writeheader();w.writerows(events)
    print(root/'comparison.json')
if __name__=='__main__':main()
