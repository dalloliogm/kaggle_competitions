import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import pandas as pd
from compare_validation_reports import compare, load_rows, aggregate
from promotion_gate import verify_packet
import await_validate_submit as submit

class MetricComparisonTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(); self.root=Path(self.temp.name)
    def tearDown(self): self.temp.cleanup()
    def report(self,name,rows):
        p=self.root/name; pd.DataFrame(rows).to_csv(p,index=False); return p
    def row(self,movie='a_1',adj=.8,tp=8,fp=1,fn=1,dtp=0,dfp=0,dfn=1):
        return dict(dataset=movie,adjusted_edge_jaccard=adj,edge_tp=tp,edge_fp=fp,edge_fn=fn,division_tp=dtp,division_fp=dfp,division_fn=dfn)
    def test_division_only_gain_is_not_lost_to_edge_score(self):
        a=self.report('a.csv',[self.row()]); b=self.report('b.csv',[self.row(dtp=1,dfn=0)])
        r=compare(a,[b])['results'][0]
        self.assertAlmostEqual(r['official_score_delta'],.1)
        self.assertAlmostEqual(r['mean_delta'],.1)
    def test_official_aggregation_is_not_macro_average(self):
        rows=[self.row('a_1',adj=.5,tp=1,fp=0,fn=0,dtp=1,dfn=0),self.row('a_2',adj=.9,tp=9,fp=0,fn=0,dtp=0,dfn=9)]
        out=aggregate(load_rows(self.report('x.csv',rows)))
        self.assertAlmostEqual(out['score'],.87)
    def test_no_divisions_drops_term(self):
        out=aggregate(load_rows(self.report('x.csv',[self.row(dfn=0)])))
        self.assertIsNone(out['division_jaccard']); self.assertAlmostEqual(out['score'],.8)
    def test_official_and_legacy_aliases(self):
        r=self.row(); r['adj_edge_jaccard']=r.pop('adjusted_edge_jaccard'); r['stem']=r.pop('dataset')
        r['div_tp']=r.pop('division_tp'); r['div_fp']=r.pop('division_fp'); r['div_fn']=r.pop('division_fn')
        self.assertAlmostEqual(aggregate(load_rows(self.report('x.csv',[r])))['score'],.8)
    def test_missing_movies_rejected(self):
        with self.assertRaisesRegex(ValueError,'mismatched'):
            compare(self.report('a.csv',[self.row()]),[self.report('b.csv',[self.row('b_1')])])
    def test_duplicates_and_bad_counts_rejected(self):
        for rows in ([self.row(),self.row()],[self.row(tp=-1)],[self.row(tp=.5)],[self.row(adj=float('nan'))]):
            with self.assertRaises(ValueError): load_rows(self.report('bad.csv',rows))
    def test_list_json_supported(self):
        p=self.root/'a.json'; p.write_text(json.dumps([self.row()])); self.assertEqual(len(load_rows(p)),1)
    def test_edge_only_report_rejected(self):
        with self.assertRaisesRegex(ValueError,'missing official'):
            load_rows(self.report('x.csv',[dict(dataset='a',adjusted_edge_jaccard=.9)]))
    def test_zero_edge_movie_reported_not_silently_scored(self):
        a=self.report('a.csv',[self.row(),self.row('a_2',tp=0,fp=0,fn=0,dfn=0)])
        r=compare(a,[a])['results'][0]
        self.assertEqual(r['macro_unscored_movies'],['a_2'])
    def test_unapproved_packet_rejected(self):
        p=self.root/'packet.json'; p.write_text('{"status":"HELD"}')
        with self.assertRaises(ValueError): verify_packet(p,'x','a/b',1)
    def test_wrong_artifact_rejected(self):
        p=self.root/'packet.json'; p.write_text(json.dumps(dict(status='APPROVED_FOR_SUBMISSION',artifact_sha256='wrong')))
        with self.assertRaisesRegex(ValueError,'match'): verify_packet(p,'x','a/b',1)
    def test_submit_requires_packet_before_network(self):
        with patch('sys.argv',['guard','a/b','1','test','--submit']),patch.object(submit,'run') as network:
            with self.assertRaises(SystemExit): submit.main()
            network.assert_not_called()
    def test_failed_cli_call_raises(self):
        with patch.object(submit.subprocess,'run') as command:
            command.return_value.returncode=1; command.return_value.stderr='failure'; command.return_value.stdout=''
            with self.assertRaises(RuntimeError): submit.run(['competitions','submit'])


class OfficialAggregationParity(unittest.TestCase):
    def test_aggregation_matches_pinned_official_function(self):
        # Execute upstream pure aggregation functions verbatim; graph dependencies
        # are unnecessary for this numerical parity test.
        import ast, warnings
        root=Path(__file__).resolve().parents[1]
        source=(root/'references/official-scorer-075fc5f/tracking_cellmot/metrics.py').read_text()
        tree=ast.parse(source)
        names={'_jaccard','summarise'}
        nodes=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in names]
        scope={'warnings':warnings,'COUNT_COLUMNS':('edge_tp','edge_fp','edge_fn','division_tp','division_fp','division_fn','num_pred_nodes'),'SCORE_DIVISION_WEIGHT':.1}
        exec(compile(ast.Module(body=nodes,type_ignores=[]),'<pinned-official-aggregation>','exec'),scope)
        rows=[dict(dataset='a_1',adj_edge_jaccard=.5,edge_tp=1,edge_fp=0,edge_fn=0,division_tp=1,division_fp=0,division_fn=0,num_pred_nodes=10,node_recall=.9),
              dict(dataset='a_2',adj_edge_jaccard=.9,edge_tp=9,edge_fp=0,edge_fn=0,division_tp=0,division_fp=0,division_fn=9,num_pred_nodes=90,node_recall=.8)]
        with tempfile.TemporaryDirectory() as temp:
            path=Path(temp)/'r.json';path.write_text(json.dumps(rows))
            ours=aggregate(load_rows(path));official=scope['summarise'](rows)
        self.assertAlmostEqual(ours['score'],official['score'])
        self.assertAlmostEqual(ours['division_jaccard'],official['division_jaccard'])

class PromotionPacketTests(unittest.TestCase):
    def test_complete_packet_and_tampered_evidence(self):
        from promotion_gate import REVIEW_CHECKS, file_sha
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            rows=[dict(dataset='a_hold',adjusted_edge_jaccard=.8,edge_tp=8,edge_fp=1,edge_fn=1,division_tp=0,division_fp=0,division_fn=1)]
            (root/'base.json').write_text(json.dumps(rows))
            rows[0]['adjusted_edge_jaccard']=.81
            (root/'candidate.json').write_text(json.dumps(rows))
            split={'evidence':'HELD_OUT','final_holdout':['a_hold'],'development_folds':{'a':['a_dev']},
                   'checkpoint_exposure':{k:{'status':'TRAINING_LIST_VERIFIED','train_datasets':['a_train']} for k in ('primary','secondary','deepcenter')}}
            (root/'split.json').write_text(json.dumps(split))
            (root/'experiment.json').write_text('{"max_movie_regression":0.002}')
            (root/'review.json').write_text('{"review":"fixture"}')
            mapping={'incumbent_report':'base.json','candidate_report':'candidate.json','split_manifest':'split.json',
                     'experiment_manifest':'experiment.json','stability_report':'review.json','mechanism_off_report':'review.json','image_review':'review.json','official_scorer_manifest':'review.json'}
            packet={'status':'APPROVED_FOR_SUBMISSION','artifact_sha256':'abc','kernel':'a/b','kernel_version':1,'reviewer':'fixture','reviewed_at':'2026-09-05','max_movie_regression':.002,
                    'review_checks':{k:True for k in REVIEW_CHECKS},'evidence':{k:{'path':v,'sha256':file_sha(root/v)} for k,v in mapping.items()}}
            p=root/'packet.json';p.write_text(json.dumps(packet))
            verify_packet(p,'abc','a/b',1)
            split['checkpoint_exposure']['secondary']['train_datasets']=['a_hold']
            (root/'split.json').write_text(json.dumps(split))
            with self.assertRaisesRegex(ValueError,'changed evidence'): verify_packet(p,'abc','a/b',1)
            packet['evidence']['split_manifest']['sha256']=file_sha(root/'split.json');p.write_text(json.dumps(packet))
            with self.assertRaisesRegex(ValueError,'exposed'): verify_packet(p,'abc','a/b',1)

class FactorialReviewTests(unittest.TestCase):
    def test_moved_synthetic_node_is_not_an_unchanged_edge(self):
        import subprocess, sys
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            metrics=dict(dataset='a_1',adjusted_edge_jaccard=.8,edge_tp=8,edge_fp=1,edge_fn=1,division_tp=0,division_fp=0,division_fn=1)
            for arm in ('incumbent','gap_only','threshold_only','both','divisions_off'):
                pd.DataFrame([metrics]).to_csv(root/f'{arm}.csv',index=False)
                graph={'nodes':[dict(node_id=0,t=0,z=1,y=1,x=1),dict(node_id=1,t=1,z=1,y=1,x=2 if arm=='incumbent' else 3)],'edges':[[0,1]]}
                (root/f'{arm}-a_1-graph.json').write_text(json.dumps(graph))
            subprocess.run([sys.executable,str(Path(__file__).with_name('summarize_factorial.py')),str(root)],check=True,capture_output=True)
            review=pd.read_csv(root/'review_queue.csv')
            self.assertEqual(set(review.change),{'added','removed'})
            self.assertEqual(len(review),8)

class GeffCompatibilityTests(unittest.TestCase):
    def test_graph_and_tuple_loader_results(self):
        import ast, types
        source=Path(__file__).with_name('factorial_validation_runtime.py').read_text()
        node=next(n for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name=='load_factorial_geff')
        graph=types.SimpleNamespace(node_attrs=lambda:None,edge_attrs=lambda:None)
        for result in (graph,(graph,{'metadata':True})):
            td=types.SimpleNamespace(graph=types.SimpleNamespace(IndexedRXGraph=types.SimpleNamespace(from_geff=lambda p:result)))
            scope={'td':td};exec(compile(ast.Module(body=[node],type_ignores=[]),'geff-loader','exec'),scope)
            self.assertIs(scope['load_factorial_geff']('fixture'),graph)

if __name__=='__main__': unittest.main()
