"""Rebuild a PubChem candidate tier from the primary NCBI files (public-domain data), no third-party derivatives.

Sources (https://ftp.ncbi.nlm.nih.gov/pubchem/Compound/Extras/): CID-Mass.gz, CID-SMILES.gz, CID-SID.gz, CID-PMID.gz
Output (same layout as the public 'pubchem-tier' idea): mass-sorted arrays
  pc_mass.npy (float64), pc_cid.npy (int32), pc_lsid.npy / pc_lpmid.npy (float16 log1p counts), pc_off.npy (int64), pc_smiles.npy (uint8 buffer)
Filters: uncharged formula, 100 <= mass <= 1300, documented (n_sid >= MIN_SID or n_pmid >= 1).
Run: python build_pubchem_tier.py OUT_DIR   (streams; ~30-60 min; needs ~10 GB RAM, a few GB disk)
"""
import sys, os, gzip, time, io, urllib.request
import numpy as np, pandas as pd
OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True); BASE = "https://ftp.ncbi.nlm.nih.gov/pubchem/Compound/Extras/"
MIN_SID = int(os.environ.get("MIN_SID", 3)); t0 = time.time()
log = lambda *a: print(f"[{time.time()-t0:6.0f}s]", *a, flush=True)
def stream(name): return gzip.open(urllib.request.urlopen(BASE + name), "rt", newline="\n")
def chunks(name, names, usecols, size=2_000_000, dtype=None):
    return pd.read_csv(stream(name), sep="\t", header=None, names=names, usecols=usecols, chunksize=size, dtype=dtype, na_filter=False, quoting=3)
MAXCID = 200_000_000
pm = np.zeros(MAXCID, np.uint16); n = 0
for ch in chunks("CID-PMID.gz", ["cid", "pmid", "x"], [0], dtype={"cid": np.int64}):
    c = np.bincount(ch.cid.to_numpy(), minlength=0); idx = np.flatnonzero(c); pm[idx] = np.minimum(pm[idx].astype(np.int64) + c[idx], 65535).astype(np.uint16); n += len(ch)
    if n % 20_000_000 < 2_000_000: log("pmid rows", n)
log("pmid done", n)
sid = np.zeros(MAXCID, np.uint32); n = 0
for ch in chunks("CID-SID.gz", ["cid", "sid", "x"], [0], dtype={"cid": np.int64}):
    c = np.bincount(ch.cid.to_numpy(), minlength=0); idx = np.flatnonzero(c); sid[idx] += c[idx].astype(np.uint32); n += len(ch)
    if n % 100_000_000 < 2_000_000: log("sid rows", n)
log("sid done", n)
keep = np.zeros(MAXCID, bool); mass_of = {}; cids, masses = [], []
for ch in chunks("CID-Mass.gz", ["cid", "formula", "m1", "m2"], [0, 1, 3], dtype={"cid": np.int64}):
    ok = (~ch.formula.str.contains(r"[+-]")) & (ch.m2 >= 100) & (ch.m2 <= 1300)
    cc = ch.cid.to_numpy(); ok &= (sid[cc] >= MIN_SID) | (pm[cc] >= 1)
    cids.append(cc[ok.to_numpy()]); masses.append(ch.m2.to_numpy()[ok.to_numpy()].astype(np.float64))
cid = np.concatenate(cids); mass = np.concatenate(masses); keep[cid] = True; log("kept after mass/doc filters", len(cid))
buf = open(f"{OUT}/_buf.bin", "wb"); offs = [0]; got = []; pos = 0
for ch in chunks("CID-SMILES.gz", ["cid", "smi"], [0, 1], dtype={"cid": np.int64}):
    m = keep[ch.cid.to_numpy()]; sub = ch[m]
    for c_, s_ in zip(sub.cid.to_numpy(), sub.smi.to_numpy()):
        b = s_.encode("ascii", "ignore"); buf.write(b); pos += len(b); offs.append(pos); got.append(c_)
log("smiles collected", len(got)); buf.close()
got = np.array(got, np.int64); offs = np.array(offs, np.int64)
cid_to_mass = pd.Series(mass, index=cid); mass_g = cid_to_mass.reindex(got).to_numpy()
order = np.argsort(mass_g, kind="stable"); log("sorted")
raw = np.memmap(f"{OUT}/_buf.bin", dtype=np.uint8, mode="r")
new_off = np.zeros(len(order) + 1, np.int64); lens = (offs[1:] - offs[:-1])[order]; new_off[1:] = np.cumsum(lens)
with open(f"{OUT}/pc_smiles.bin", "wb") as f:
    for s in range(0, len(order), 500_000):
        sel = order[s:s + 500_000]; f.write(b"".join(raw[offs[i]:offs[i + 1]].tobytes() for i in sel))
os.replace(f"{OUT}/pc_smiles.bin", f"{OUT}/pc_smiles.npy.raw"); del raw; os.remove(f"{OUT}/_buf.bin")
sm = np.memmap(f"{OUT}/pc_smiles.npy.raw", dtype=np.uint8, mode="r"); np.save(f"{OUT}/pc_smiles.npy", np.asarray(sm)); os.remove(f"{OUT}/pc_smiles.npy.raw")
cg = got[order]
np.save(f"{OUT}/pc_mass.npy", mass_g[order]); np.save(f"{OUT}/pc_cid.npy", cg.astype(np.int32)); np.save(f"{OUT}/pc_off.npy", new_off)
np.save(f"{OUT}/pc_lsid.npy", np.log1p(sid[cg]).astype(np.float16)); np.save(f"{OUT}/pc_lpmid.npy", np.log1p(pm[cg]).astype(np.float16))
log("done", len(order), "rows; smiles bytes", int(new_off[-1]))
