"""Fail-closed evidence checks for a reviewed Biohub promotion packet.

This verifies recorded evidence, not the truth of human scientific judgments.
No packet is generated as approved by the experiment builder.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
from compare_validation_reports import compare

REVIEW_CHECKS = ('hypothesis_preregistered', 'checkpoint_exposure_reviewed',
                'scorer_revision_verified', 'mechanism_off_control_reviewed',
                'grouped_stability_passed', 'holdout_reviewed', 'image_review_passed')

def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def verify_packet(path: Path, artifact_sha: str, kernel: str, version: int) -> dict:
    packet=json.loads(path.read_text())
    if packet.get('status') != 'APPROVED_FOR_SUBMISSION':
        raise ValueError('Promotion packet has not been approved')
    if packet.get('artifact_sha256') != artifact_sha or packet.get('kernel') != kernel or packet.get('kernel_version') != version:
        raise ValueError('Promotion packet does not match downloaded artifact/kernel/version')
    if not packet.get('reviewer') or not packet.get('reviewed_at'):
        raise ValueError('Missing recorded reviewer/date')
    checks=packet.get('review_checks',{})
    if any(checks.get(k) is not True for k in REVIEW_CHECKS):
        raise ValueError('Required scientific review checks are incomplete')
    evidence=packet.get('evidence',{})
    required=('incumbent_report','candidate_report','split_manifest','stability_report','mechanism_off_report','image_review','experiment_manifest','official_scorer_manifest')
    paths={}
    for key in required:
        record=evidence.get(key,{})
        rel=record.get('path')
        if not rel: raise ValueError(f'Missing evidence: {key}')
        target=(path.parent/rel).resolve()
        if not target.is_file() or file_sha(target) != record.get('sha256'):
            raise ValueError(f'Missing or changed evidence: {key}')
        paths[key]=target
    split=json.loads(paths['split_manifest'].read_text())
    if split.get('evidence') != 'HELD_OUT' or not split.get('final_holdout'):
        raise ValueError('No independently held-out validation evidence; keep candidate HELD')
    holdout=split['final_holdout']
    development=sum(split.get('development_folds',{}).values(),[])
    if len(set(holdout))!=len(holdout) or set(holdout)&set(development):
        raise ValueError('Holdout overlaps development or contains duplicates')
    for role in ('primary','secondary','deepcenter'):
        exposure=split.get('checkpoint_exposure',{}).get(role,{})
        if not isinstance(exposure,dict) or exposure.get('status')!='TRAINING_LIST_VERIFIED':
            raise ValueError(f'Unverified checkpoint exposure: {role}')
        if not isinstance(exposure.get('train_datasets'),list) or set(holdout)&set(exposure['train_datasets']):
            raise ValueError(f'Holdout exposed to checkpoint training: {role}')
    from compare_validation_reports import load_rows
    if set(load_rows(paths['candidate_report']).dataset)!=set(holdout):
        raise ValueError('Promotion reports must cover exactly the frozen final holdout')
    experiment=json.loads(paths['experiment_manifest'].read_text())
    if experiment.get('max_movie_regression')!=packet.get('max_movie_regression'):
        raise ValueError('Regression tolerance differs from preregistration')
    # Recompute rather than trusting a prewritten comparison verdict.
    result=compare(paths['incumbent_report'],[paths['candidate_report']])['results'][0]
    tolerance=packet.get('max_movie_regression')
    if not isinstance(tolerance,(int,float)) or not 0 <= tolerance <= 0.01:
        raise ValueError('A predeclared movie regression tolerance in [0, .01] is required')
    if result['mean_delta'] is None or result['median_delta'] is None:
        raise ValueError('Missing macro metric evidence')
    if result['official_score_delta'] <= 0 or result['mean_delta'] <= 0 or result['median_delta'] <= 0 or result['worst_delta'] < -tolerance:
        raise ValueError('Candidate fails aggregate/macro/worst-movie promotion criteria')
    if result['macro_unscored_movies']:
        raise ValueError('Unscored movies in promotion reports')
    for group in result['by_embryo'].values():
        if group['candidate']['score'] < group['incumbent']['score']-tolerance:
            raise ValueError('Unacceptable embryo regression')
    return packet
