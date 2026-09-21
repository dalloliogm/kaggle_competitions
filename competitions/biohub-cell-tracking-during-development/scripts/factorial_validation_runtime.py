"""Embedded after the incumbent's prediction cells by build_validation_factorial.py.
This file uses notebook globals and is not a standalone program.
"""
import copy
import polars as pl
import hashlib
import importlib.metadata
from tracking_cellmot.metrics import evaluate as official_evaluate, per_sample_metrics, node_recall

def load_factorial_geff(path):
    loaded = td.graph.IndexedRXGraph.from_geff(path)
    # Kaggle's tracksdata returns (graph, metadata); support graph-only versions too.
    graph = loaded[0] if isinstance(loaded, tuple) else loaded
    if not hasattr(graph, 'node_attrs') or not hasattr(graph, 'edge_attrs'):
        raise TypeError(f'Unexpected GEFF loader result: {type(graph).__name__}')
    return graph

FACTORIAL_ARMS = {
    'incumbent': (5.8, 0.12, True),
    'gap_only': (5.0, 0.12, True),
    'threshold_only': (5.8, 0.25, True),
    'both': (5.0, 0.25, True),
    'divisions_off': (5.8, 0.12, False),
}

def factorial_graph(nodes, edges):
    graph=td.graph.InMemoryGraph()
    for key in ('z','y','x'): graph.add_node_attr_key(key, pl.Float64, 0.0)
    ids={}
    for nid,n in nodes.items():
        ids[nid]=graph.add_node({k:(int(n[k]) if k=='t' else float(n[k])) for k in ('t','z','y','x')})
    for edge in edges:
        graph.add_edge(ids[int(edge['source_id'])],ids[int(edge['target_id'])],{})
    return graph

def factorial_estimate(path):
    def search(value):
        if isinstance(value,dict):
            if 'estimated_number_of_nodes' in value: return value['estimated_number_of_nodes']
            for item in value.values():
                found=search(item)
                if found is not None: return found
        if isinstance(value,list):
            for item in value:
                found=search(item)
                if found is not None: return found
    for name in ('zarr.json','.zattrs'):
        if (path/name).is_file():
            value=search(json.loads((path/name).read_text()))
            if value is not None and float(value)>0: return float(value)
    raise ValueError(f'Missing true-node estimate: {path}')

def factorial_rows(nodes,edges):
    return {'nodes':[{k:n[k] for k in ('node_id','t','z','y','x')} for n in nodes.values()],
            'edges':[[int(e['source_id']),int(e['target_id'])] for e in edges]}

out=WORKING_DIR/'factorial_validation'; out.mkdir(exist_ok=True)
metric_rows={arm:[] for arm in FACTORIAL_ARMS}
stage_rows=[]
expected=set(sum(FROZEN_SPLIT['development_folds'].values(),[]))
if set(val_stems)!=expected: raise RuntimeError('Validation sample list differs from frozen manifest')
# Only use the exact current inference method, never first-match rglob results.
val_dir=_prediction_dir_for_method(val_method_prefix)
if {p.stem for p in val_dir.glob('*.geff')} != expected:
    raise RuntimeError('Missing or extra validation predictions')
original=(GAP_CLOSE_UM,DEEPCENTER_SAFE_DIV_THRESHOLD,OUTPUT_SAFE_DIVISIONS,TEST_DIR)
try:
    TEST_DIR=TRAIN_DIR
    for stem in sorted(expected):
        raw=load_factorial_geff(val_dir/f'{stem}.geff')
        nodes={int(r['node_id']):{k:r[k] for k in ('node_id','t','z','y','x')} for r in raw.node_attrs().iter_rows(named=True)}
        edges=[{'source_id':int(r['source_id']),'target_id':int(r['target_id']), 'edge_prob':r.get('edge_prob')} for r in raw.edge_attrs().iter_rows(named=True)]
        for arm,(gap,threshold,divisions) in FACTORIAL_ARMS.items():
            GAP_CLOSE_UM,DEEPCENTER_SAFE_DIV_THRESHOLD,OUTPUT_SAFE_DIVISIONS=gap,threshold,divisions
            FACTORIAL_ACTIVE_ARM=arm
            processed,links,stats=filter_output_graph(copy.deepcopy(nodes),copy.deepcopy(edges),dataset=stem,deepcenter_bundle=DEEPCENTER_VETO_DETECTOR)
            graph=factorial_graph(processed,links)
            truth=load_factorial_geff(TRAIN_DIR/f'{stem}.geff')
            result=official_evaluate(graph,truth,scale=VOXEL_SCALE_UM,max_distance=7.0)
            row={'dataset':stem, **per_sample_metrics(result,factorial_estimate(TRAIN_DIR/f'{stem}.geff'),node_recall(graph,truth)), 'num_pred_edges':len(links)}
            metric_rows[arm].append(row)
            stage_rows.append({'dataset':stem,'arm':arm,**stats})
            (out/f'{arm}-{stem}-graph.json').write_text(json.dumps(factorial_rows(processed,links),default=lambda x:x.item(),sort_keys=True))
            # Persist each arm/movie immediately so later errors do not erase evidence.
            pd.DataFrame(metric_rows[arm]).to_csv(out/f'{arm}.csv',index=False)
finally:
    GAP_CLOSE_UM,DEEPCENTER_SAFE_DIV_THRESHOLD,OUTPUT_SAFE_DIVISIONS,TEST_DIR=original
    FACTORIAL_ACTIVE_ARM='incumbent_test'
pd.DataFrame(stage_rows).to_csv(out/'stage_stats.csv',index=False)
(out/'split_manifest.json').write_text(json.dumps(FROZEN_SPLIT,indent=2))
(out/'runtime_manifest.json').write_text(json.dumps({
    'status':'LOCAL_PROXY','scorer':OFFICIAL_SCORER_MANIFEST,
    'source_notebook_sha256':SOURCE_NOTEBOOK_SHA256,
    'packages':{n:importlib.metadata.version(n) for n in ('tracksdata','polars','numpy','scipy','torch')},
    'arms':FACTORIAL_ARMS,'movies':sorted(expected),
    'checkpoint_training_exposure':FROZEN_SPLIT['checkpoint_exposure'],
},indent=2))
print('Factorial diagnostics complete; checkpoint-exposed LOCAL_PROXY, not promotion evidence.')
