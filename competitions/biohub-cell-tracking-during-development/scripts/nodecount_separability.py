import numpy as np, json
from pathlib import Path
from scipy.spatial import cKDTree
S=Path("/tmp/claude-0/-home-user-kaggle-competitions/079e2126-1615-5dfd-bdeb-d1a861286f6c/scratchpad")
PRED=S/"nodecount/tracking_repo/predictions/unknown/unet_transformer_val/split_0"
rows=np.load(S/"sep_cache.npy", allow_pickle=True)
import zarr
SCALE=np.array([1.625,0.40625,0.40625])
X=[];Y=[];G=[]
for gi,r in enumerate(rows):
    root=PRED/f"{r['stem']}.geff"
    t=np.asarray(zarr.open(str(root/"nodes/props/t/values"),mode="r")[:])
    z=np.asarray(zarr.open(str(root/"nodes/props/z/values"),mode="r")[:])
    y=np.asarray(zarr.open(str(root/"nodes/props/y/values"),mode="r")[:])
    x=np.asarray(zarr.open(str(root/"nodes/props/x/values"),mode="r")[:])
    pos=np.stack([z,y,x],1)*SCALE
    tmax=max(1,int(t.max()))
    dens=np.zeros(len(t)); nnd=np.zeros(len(t))
    for tt in np.unique(t):
        m=np.where(t==tt)[0]
        tr=cKDTree(pos[m])
        dens[m]=tr.query_ball_point(pos[m],10.0,return_length=True)-1
        if len(m)>1:
            d,_=tr.query(pos[m],k=2); nnd[m]=d[:,1]
    # centre-relative position (annotators may favour a sub-volume)
    c=pos.mean(0); rad=np.linalg.norm(pos-c,axis=1)
    f=np.stack([r["tracklen"],r["deg"],t/tmax,dens,nnd,rad,
                pos[:,0],pos[:,1],pos[:,2]],1)
    X.append(f);Y.append(r["m"]);G.append(np.full(len(t),gi))
X=np.vstack(X);Y=np.concatenate(Y);G=np.concatenate(G)
print(f"{X.shape[0]:,} nodes, {Y.sum():,} positive ({Y.mean()*100:.2f}%)")
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.model_selection import GroupKFold
K=0.411
oof=np.zeros(len(Y))
for tr,te in GroupKFold(n_splits=4).split(X,Y,G):
    m=HistGradientBoostingClassifier(max_iter=150,learning_rate=0.1,random_state=0)
    m.fit(X[tr],Y[tr]); oof[te]=m.predict_proba(X[te])[:,1]
from sklearn.metrics import roc_auc_score
print(f"grouped-CV AUC = {roc_auc_score(Y,oof):.4f}  (0.5 = annotation is unpredictable)\n")
print(f"{'keep top-p by score':<24}{'nodes rm':>10}{'matched rm':>12}{'nodes/TP':>10}{'':>8}")
best=0
for p in (0.05,0.1,0.2,0.3,0.5,0.7,0.8,0.9):
    thr=np.quantile(oof,p)          # drop the p lowest-scoring nodes
    mask=oof<thr
    nr=int(mask.sum()); mr=int((mask&Y.astype(bool)).sum())
    ntp=nr/(mr*K) if mr else float('inf')
    best=max(best,ntp if mr else 0)
    print(f"drop lowest {p*100:>4.0f}%{'':<11}{nr:>10,}{mr:>12,}{ntp:>10,.0f}{'  PAYS' if ntp>422 else '':>8}")
print(f"\nbest learned exchange rate: {best:,.0f} vs break-even 422")
