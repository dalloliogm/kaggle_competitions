#!/usr/bin/env python3
"""Execute only the five explicitly approved Sep 6 probes, once each.

Date-bound user-authorized exploratory exception to promotion gating. Both
structural validators, live quota checks, unique hashes and attempt reconciliation
remain mandatory. Resuming an uncertain submission stops rather than reuploading.
"""
import datetime as dt
import hashlib
import json
from pathlib import Path
import subprocess
import time
import sys
from await_validate_submit import validate
from biohub_validation_harness import load_submission,structural_report

ROOT=Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]
STATE=ROOT/'references/sep06-batch-execution.json'
LEDGER=ROOT/'references/submitted_shas.txt'
NAMES=['image08','diverge50','image08-diverge50','symmetry45','retention95','reserve-retention85']
KG=['uvx','--index-url','https://pypi.org/simple','kaggle']

def call(args):
    p=subprocess.run(KG+args,capture_output=True,text=True,timeout=600)
    if p.returncode:raise RuntimeError((p.stdout+p.stderr)[-1500:])
    return p.stdout

def save(state):
    tmp=STATE.with_suffix('.tmp');tmp.write_text(json.dumps(state,indent=2)+'\n');tmp.replace(STATE)

def today_records():
    records=json.loads(call(['competitions','submissions','-c','biohub-cell-tracking-during-development','--format','json']))
    return [r for r in records if r['date'].startswith('2026-09-06')]

def step(state):
    if dt.datetime.now(dt.timezone.utc).date().isoformat()!='2026-09-06':
        raise RuntimeError('Date boundary reached; do not spend another day\'s slots')
    for name in NAMES:
        arm=state['arms'][name]
        if arm['status'] in ('SUBMITTED','RESERVE','DUPLICATE'):continue
        slug='dalloliogm/biohub-sep06-'+name
        token=f'[SEP06:{name}]'
        records=today_records()
        matches=[r for r in records if token in r.get('description','')]
        if matches:
            arm.update(status='SUBMITTED',submission_refs=[r['ref'] for r in matches]);save(state);continue
        if arm['status']=='SUBMITTING':raise RuntimeError(f'Uncertain submission {name}: inspect live records, do not retry')
        if len(records)>=5:raise RuntimeError('All five daily slots already used')
        if arm['status']=='PREPARED':
            notebook=ROOT/'notebooks/public-reproductions'/('biohub-sep06-'+name)/('biohub-sep06-'+name+'.ipynb')
            pushed=subprocess.run([str(REPO/'scripts/kaggle_push_notebook.sh'),str(notebook),slug,'Biohub Sep06 '+name],capture_output=True,text=True,timeout=600)
            message=pushed.stdout+pushed.stderr
            if 'Maximum batch GPU session count' in message:
                print('GPU capacity full; remaining arms stay queued locally',flush=True)
                break
            if pushed.returncode or not __import__('re').search(r'Kernel version (\d+) successfully pushed',message):
                raise RuntimeError('Unexpected push response: '+message[-1000:])
            arm.update(status='WAITING',kernel_version=int(__import__('re').search(r'Kernel version (\d+) successfully pushed',message).group(1)));save(state)
            print('LAUNCHED '+slug+' v'+str(arm['kernel_version']),flush=True)
        status=call(['kernels','status',slug]).strip()
        if 'COMPLETE' not in status:
            if 'ERROR' in status or 'CANCEL' in status:raise RuntimeError(f'{slug}: {status}')
            arm['last_kernel_status']=status;save(state);continue
        version=arm['kernel_version']
        out=REPO/'kaggle_outputs'/('biohub-sep06-'+name+'-v'+str(version)+'-audit');out.mkdir(parents=True,exist_ok=True)
        call(['kernels','output',slug+'/'+str(version),'-p',str(out),'--file-pattern','^(submission.csv|run_stats.csv)$'])
        file=out/'submission.csv'
        good,problems,counts=validate(file)
        independent=structural_report(load_submission(file),file)
        if not good or not independent.valid:raise RuntimeError(f'{slug} invalid: {problems} {independent.errors}')
        sha=hashlib.sha256(file.read_bytes()).hexdigest()
        if sha in LEDGER.read_text():
            arm.update(status='DUPLICATE',sha256=sha,counts=counts);save(state)
            if name=='image08-diverge50':
                state['arms']['reserve-retention85']['status']='PREPARED';save(state)
                print('Interaction output duplicates prior artifact; activating predeclared reserve',flush=True)
                continue
            raise RuntimeError(f'{name}: duplicate artifact {sha}; not submitted')
        arm.update(sha256=sha,counts=counts,artifact=str(file),kernel_version=version,status='AUDITED')
        save(state)
        # Recheck immediately at upload boundary. Persist intent before any request.
        records=today_records()
        if len(records)>=5:raise RuntimeError('Quota filled during audit')
        if any(token in r.get('description','') for r in records):raise RuntimeError('Concurrent submission detected')
        arm['status']='SUBMITTING';save(state)
        print(f'SUBMITTING {name} {sha} {counts}',flush=True)
        response=call(['competitions','submit','biohub-cell-tracking-during-development','-k',slug,'-v',str(version),'-f','submission.csv','-m',f'{token} User-approved exploratory batch; .80 fusion; distinct output passed both validators'])
        print(response.strip(),flush=True)
        records=today_records();matches=[r for r in records if token in r.get('description','')]
        if not matches:raise RuntimeError('Submission response not yet reconciled; do not retry')
        arm.update(status='SUBMITTED',submission_refs=[r['ref'] for r in matches]);save(state)
        with LEDGER.open('a') as f:f.write(f"{sha}  {slug} v{version}  {token} refs {arm['submission_refs']}\n")
        print(f"CONFIRMED {name}: {arm['submission_refs']}",flush=True)
    return sum(a['status']=='SUBMITTED' for a in state['arms'].values())==5

def main():
    import fcntl
    lock=STATE.with_suffix('.lock').open('w')
    fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    auth=json.loads((ROOT/'references/authorized-five-batch-2026-09-06.json').read_text())
    if auth.get('status')!='AUTHORIZED' or auth.get('date')!='2026-09-06':raise RuntimeError('Missing batch authorization')
    state=json.loads(STATE.read_text()) if STATE.exists() else {'date':'2026-09-06','arms':{n:{'status':'RESERVE' if n.startswith('reserve-') else 'PREPARED'} for n in NAMES}}
    save(state)
    while True:
        try:
            if step(state):print('ALL FIVE SUBMISSIONS CONFIRMED',flush=True);return
        except Exception as exc:
            state['error']=str(exc);save(state);print('STOPPED:',exc,flush=True);raise
        print('Waiting for completed audited candidates',flush=True);time.sleep(45)
if __name__=='__main__':main()
