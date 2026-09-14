"""Stdlib structural validator: same invariants as the workspace harness, no pandas."""
import csv, hashlib, sys, collections
def check(path):
    cols=["id","dataset","row_type","node_id","t","z","y","x","source_id","target_id"]
    nodes={}; indeg=collections.Counter(); outdeg=collections.Counter()
    ids=set(); rows=0; edges=0
    with open(path, newline='') as fh:
        r=csv.DictReader(fh)
        if list(r.fieldnames)!=cols: return None,f"column mismatch: {r.fieldnames}"
        for x in r:
            rows+=1
            if x["id"] in ids: return None,f"duplicate row id {x['id']}"
            ids.add(x["id"])
            if x["row_type"]=="node":
                k=(x["dataset"],x["node_id"])
                if k in nodes: return None,f"duplicate node {k}"
                nodes[k]=int(x["t"])
                for c in ("z","y","x"):
                    if float(x[c])<0: return None,f"negative coord in {k}"
            elif x["row_type"]=="edge":
                edges+=1
                s=(x["dataset"],x["source_id"]); t=(x["dataset"],x["target_id"])
                if s not in nodes or t not in nodes: return None,f"edge endpoint missing {s}->{t}"
                if nodes[t]-nodes[s]!=1: return None,f"edge spans {nodes[t]-nodes[s]} frames"
                outdeg[s]+=1; indeg[t]+=1
            else: return None,f"bad row_type {x['row_type']}"
    mi=max(indeg.values()) if indeg else 0; mo=max(outdeg.values()) if outdeg else 0
    if mi>1: return None,f"max in-degree {mi}"
    if mo>2: return None,f"max out-degree {mo}"
    div=sum(1 for v in outdeg.values() if v>=2)
    sha=hashlib.sha256(open(path,'rb').read()).hexdigest()
    return dict(rows=rows,nodes=len(nodes),edges=edges,max_indeg=mi,max_outdeg=mo,divisions=div,sha=sha),None
if __name__=="__main__":
    res,err=check(sys.argv[1])
    print("FAIL:",err) if err else print({k:v for k,v in res.items()})
