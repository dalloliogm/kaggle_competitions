#!/usr/bin/env python3
"""Compare complete per-movie metric reports; never substitute edge-only scores.

Counts and adjusted edge Jaccard are required. Macro summaries diagnose stability;
the official aggregate weights adjusted edges and pools division confusion counts.
Legacy column aliases are accepted, but scorer provenance is not inferred.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import numpy as np
import pandas as pd

COUNTS = ('edge_tp', 'edge_fp', 'edge_fn', 'division_tp', 'division_fp', 'division_fn')
ALIASES = {'stem':'dataset', 'sample':'dataset', 'movie':'dataset',
           'adj_edge_jaccard':'adjusted_edge_jaccard', 'div_tp':'division_tp',
           'div_fp':'division_fp', 'div_fn':'division_fn', 'div_jaccard':'division_jaccard',
           't_pred':'num_pred_nodes'}

def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def load_rows(path: Path) -> pd.DataFrame:
    if path.suffix.lower() == '.csv':
        frame = pd.read_csv(path)
    else:
        payload = json.loads(path.read_text())
        if isinstance(payload, list):
            rows = payload
        elif 'metric_summary' in payload:
            metric = payload['metric_summary'] or {}
            if metric.get('skipped', False):
                raise ValueError(f'{path}: metric scoring was skipped')
            rows = metric.get('rows', [])
        else:
            rows = payload.get('rows', [])
        frame = pd.DataFrame(rows)
    frame = frame.rename(columns={k:v for k,v in ALIASES.items() if v not in frame.columns})
    required = ['dataset', 'adjusted_edge_jaccard', *COUNTS]
    missing = sorted(set(required) - set(frame.columns))
    if missing:
        raise ValueError(f'{path}: missing official metric fields {missing}')
    if frame.empty or frame.dataset.isna().any() or frame.dataset.astype(str).str.strip().eq('').any():
        raise ValueError(f'{path}: empty report or missing dataset')
    if frame.dataset.duplicated().any():
        raise ValueError(f'{path}: duplicate datasets; provide one report per arm/fold')
    for key in COUNTS:
        frame[key] = pd.to_numeric(frame[key], errors='raise')
        if not np.isfinite(frame[key]).all() or (frame[key] < 0).any() or (frame[key] % 1 != 0).any():
            raise ValueError(f'{path}: {key} must contain finite nonnegative integers')
    frame['edge_weight'] = frame[['edge_tp','edge_fp','edge_fn']].sum(axis=1)
    frame['adjusted_edge_jaccard'] = pd.to_numeric(frame.adjusted_edge_jaccard, errors='raise')
    positive = frame.edge_weight > 0
    if not np.isfinite(frame.loc[positive, 'adjusted_edge_jaccard']).all():
        raise ValueError(f'{path}: missing/non-finite adjusted score for scored movie')
    if (frame.loc[positive, 'adjusted_edge_jaccard'] < 0).any():
        raise ValueError(f'{path}: negative adjusted edge score')
    # A zero-event movie carries no edge weight. Its macro score is unavailable.
    frame.loc[~positive, 'adjusted_edge_jaccard'] = np.nan
    denominator = frame[['division_tp','division_fp','division_fn']].sum(axis=1)
    frame['division_jaccard'] = frame.division_tp.div(denominator.where(denominator > 0))
    frame['score'] = frame.adjusted_edge_jaccard + 0.1 * frame.division_jaccard.fillna(0)
    frame['embryo'] = frame.dataset.str.split('_').str[0]
    return frame

def aggregate(frame: pd.DataFrame) -> dict:
    totals = {key:int(frame[key].sum()) for key in COUNTS}
    weight = int(frame.edge_weight.sum())
    if not weight:
        raise ValueError('No scored edges in this comparison group')
    edge = float((frame.adjusted_edge_jaccard.fillna(0) * frame.edge_weight).sum()/weight)
    div_n = sum(totals[k] for k in ('division_tp','division_fp','division_fn'))
    division = totals['division_tp']/div_n if div_n else None
    return {**totals, 'adjusted_edge_jaccard':edge, 'division_jaccard':division,
            'score':edge + (0.1*division if division is not None else 0),
            'movies':len(frame), 'movies_without_edge_events':int((frame.edge_weight == 0).sum())}

def delta_summary(base: pd.DataFrame, current: pd.DataFrame) -> dict:
    paired = base.set_index('dataset').join(current.set_index('dataset'), lsuffix='_base', rsuffix='_candidate', validate='one_to_one')
    delta = paired.score_candidate - paired.score_base
    valid = delta.dropna()
    return {'mean_delta':float(valid.mean()) if len(valid) else None,
            'median_delta':float(valid.median()) if len(valid) else None,
            'std_delta':float(valid.std(ddof=0)) if len(valid) else None,
            'worst_delta':float(valid.min()) if len(valid) else None,
            'worst_movie':str(valid.idxmin()) if len(valid) else None,
            'regressions':int((valid < -1e-12).sum()), 'improvements':int((valid > 1e-12).sum()),
            'ties':int((valid.abs() <= 1e-12).sum()),
            'macro_unscored_movies':delta[delta.isna()].index.tolist()}

def compare(incumbent: Path, candidates: list[Path]) -> dict:
    base = load_rows(incumbent)
    results = []
    for candidate in candidates:
        current = load_rows(candidate)
        missing = sorted(set(base.dataset)^set(current.dataset))
        if missing:
            raise ValueError(f'{candidate}: mismatched movies {missing}; partial comparisons are forbidden')
        a,b = aggregate(base), aggregate(current)
        per_movie = []
        for dataset in sorted(base.dataset):
            x=base[base.dataset==dataset].iloc[0]; y=current[current.dataset==dataset].iloc[0]
            row={'dataset':dataset}
            for key in ['score','adjusted_edge_jaccard','division_jaccard',*COUNTS,'node_recall','num_pred_nodes','num_pred_edges','total_node_ratio']:
                if key in base and key in current:
                    for suffix,value in [('incumbent',x[key]),('candidate',y[key]),('delta',y[key]-x[key])]:
                        row[f'{key}_{suffix}'] = float(value) if pd.notna(value) and np.isfinite(value) else None
            per_movie.append(row)
        groups={}
        for prefix in sorted(base.embryo.unique()):
            x=base[base.embryo==prefix]; y=current[current.embryo==prefix]
            if x.edge_weight.sum() and y.edge_weight.sum():
                groups[prefix]={'incumbent':aggregate(x),'candidate':aggregate(y),**delta_summary(x,y)}
        results.append({'candidate':str(candidate), 'candidate_sha256':digest(candidate),
                        'datasets_compared':len(base), 'incumbent':a, 'candidate_aggregate':b,
                        'official_score_delta':b['score']-a['score'],
                        **delta_summary(base,current), 'by_embryo':groups, 'per_movie':per_movie})
    return {'schema_version':2,'evidence':'LOCAL_PROXY','incumbent':str(incumbent),
            'incumbent_sha256':digest(incumbent),'results':results}

def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--incumbent',required=True,type=Path); p.add_argument('candidates',nargs='+',type=Path)
    p.add_argument('--output',type=Path); args=p.parse_args()
    report=compare(args.incumbent,args.candidates)
    value=json.dumps(report,indent=2,sort_keys=True,allow_nan=False)+'\n'
    if args.output: args.output.write_text(value)
    print(value); return 0
if __name__=='__main__': raise SystemExit(main())
