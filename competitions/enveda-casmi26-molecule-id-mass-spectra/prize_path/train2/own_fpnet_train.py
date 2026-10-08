"""Own spectrum->fingerprint transformer ("prize path": only train.parquet + permissively licensed structure sources).

Stages (each cached in OUT, so the kernel can be re-run / resumed):
  1. prep   : peaks -> padded arrays; structures -> RDKit multi-fingerprint (own bit selection); pool = train structures U COCONUT
  2. train  : BCE on bits + mass-window ranking loss (true structure vs 63 pool structures within +-10 ppm); AdamW + cosine
  3. eval   : identity-disjoint hold-out (hash of inchikey14), MRR@25 inside the +-10 ppm pool window

No third-party weights or derived tables are used. Sources: competition train.parquet, COCONUT (CC BY 4.0), RDKit (BSD).
Env: CASMI_TRAIN, COCONUT_PQ, OUT, HOURS (training wall-clock budget), SMOKE=1 (tiny run), D_MODEL, LAYERS, BATCH.
"""
import os, re, sys, glob, math, time, json, hashlib, subprocess, importlib.metadata
import numpy as np, pandas as pd, pyarrow as pa, pyarrow.parquet as pq, torch, torch.nn as nn, torch.nn.functional as F

try: importlib.metadata.version("rdkit")
except importlib.metadata.PackageNotFoundError:
    tag = f"cp{sys.version_info.major}{sys.version_info.minor}"
    w = sorted(glob.glob(f"/kaggle/input/**/rdkit-*-{tag}-*.whl", recursive=True))
    assert w, f"attach an offline RDKit wheel for {tag}"
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--no-index", "--no-deps", "-q", w[-1]])
from rdkit import Chem, RDLogger, DataStructs
from rdkit.Chem import rdFingerprintGenerator, MACCSkeys
RDLogger.DisableLog("rdApp.*")

def find(name, env):
    p = os.environ.get(env) or next(iter(glob.glob(f"/kaggle/input/**/{name}", recursive=True)), None)
    assert p, f"{name} not found"; return p
TRAIN = find("train.parquet", "CASMI_TRAIN"); COCO = find("coconut_structures.parquet", "COCONUT_PQ")
OUT = os.environ.get("OUT", "/kaggle/working" if os.path.isdir("/kaggle/working") else "."); os.makedirs(OUT, exist_ok=True)
SMOKE = os.environ.get("SMOKE") == "1"; HOURS = float(os.environ.get("HOURS", 7.5))
D = int(os.environ.get("D_MODEL", 384)); L = int(os.environ.get("LAYERS", 6)); BATCH = int(os.environ.get("BATCH", 256))
MAXP = 128; NNEG = 63; PPM = 10.0
dev = "cuda" if torch.cuda.is_available() else "cpu"
t0 = time.time(); log = lambda *a: print(f"[{time.time()-t0:6.0f}s]", *a, flush=True)

ADDUCTS = ["[M+H]+","[M+NH4]+","[M-H2O+H]+","[M-2H2O+H]+","[M+Na]+","[M+K]+","[M-H]-","[M-H2O-H]-","[M+CH2O2-H]-","[M+Cl]-"]
EL = {"H":1.00782503207,"C":12.0,"N":14.0030740048,"O":15.99491461956,"F":18.99840322,"Na":22.9897692809,"P":30.97376163,"S":31.972071,"Cl":34.96885268,"K":38.96370668,"Br":78.9183371,"I":126.904473,"B":11.0093054,"Si":27.9769265325,"Se":79.9165213,"As":74.9215965,"Fe":55.9349375,"Mg":23.985041699,"Ca":39.96259098,"Zn":63.9291422,"Cu":62.9295975,"Li":7.016003437}
_tok = re.compile(r"([A-Z][a-z]?)(\d*)")
def fmass(f):
    if not isinstance(f, str) or not f: return np.nan
    m = 0.0
    for el, n in _tok.findall(f):
        if el not in EL: return np.nan
        m += EL[el] * (int(n) if n else 1)
    return m

# ----------------------------------------------------------------------------------------------- fingerprints
_G = {}
def gens():
    if not _G:
        g = rdFingerprintGenerator
        _G.update(ecfp4=g.GetMorganGenerator(radius=2, fpSize=2048), ecfp6=g.GetMorganGenerator(radius=3, fpSize=2048),
                  fcfp4=g.GetMorganGenerator(radius=2, fpSize=1024, atomInvariantsGenerator=g.GetMorganFeatureAtomInvGen()),
                  ap=g.GetAtomPairGenerator(fpSize=1024), tt=g.GetTopologicalTorsionGenerator(fpSize=1024))
    return _G
RAW_BITS = 2048 + 2048 + 1024 + 1024 + 1024 + 167
def raw_fp(smi):
    m = Chem.MolFromSmiles(smi)
    if m is None: return None
    g = gens(); parts = [g[k].GetFingerprintAsNumPy(m).astype(np.uint8) for k in ("ecfp4", "ecfp6", "fcfp4", "ap", "tt")]
    parts.append(np.array(list(MACCSkeys.GenMACCSKeys(m)), np.uint8)); return np.concatenate(parts)
def _fp_chunk(smis):
    out = np.zeros((len(smis), RAW_BITS), np.uint8); ok = np.zeros(len(smis), bool)
    for i, s in enumerate(smis):
        r = raw_fp(s)
        if r is not None: out[i] = r; ok[i] = True
    return np.packbits(out, axis=1), ok

def load_npz(p):
    z = np.load(p, allow_pickle=True); return {k: z[k] for k in z.files}      # NpzFile re-reads the whole array on every access: load once
def cached(name):
    for p in [f"{OUT}/{name}"] + glob.glob(f"/kaggle/input/**/{name}", recursive=True):
        if os.path.exists(p): return p
def build_pool():
    p = cached("pool.npz")
    if p: log("using cached", p); return load_npz(p)
    p = f"{OUT}/pool.npz"
    tr = pq.read_table(TRAIN, columns=["inchikey14", "normalized_smiles", "molecular_formula"]).to_pandas().drop_duplicates("inchikey14")
    tr["mass"] = tr.molecular_formula.map(fmass); tr = tr.dropna(subset=["mass"])
    co = pd.read_parquet(COCO, columns=["inchikey", "canonical_smiles", "exact_mass"])
    co = pd.DataFrame({"inchikey14": co.inchikey.str[:14], "normalized_smiles": co.canonical_smiles, "mass": co.exact_mass}).drop_duplicates("inchikey14")
    if SMOKE: co = co.sample(3000, random_state=0)
    pool = pd.concat([tr[["inchikey14", "normalized_smiles", "mass"]], co[~co.inchikey14.isin(set(tr.inchikey14))]], ignore_index=True)
    log("pool candidates", len(pool), "(train", len(tr), "+ coconut-only", len(pool) - len(tr), ")")
    from multiprocessing import Pool
    chunks = np.array_split(pool.normalized_smiles.to_numpy(), max(1, len(pool) // 2000))
    with Pool(os.cpu_count()) as pl: res = pl.map(_fp_chunk, chunks)
    fp = np.concatenate([r[0] for r in res]); ok = np.concatenate([r[1] for r in res])
    pool = pool[ok].reset_index(drop=True); fp = fp[ok]
    # informative bits
    sub = np.unpackbits(fp[np.random.RandomState(0).choice(len(fp), min(len(fp), 200000), replace=False)], axis=1)[:, :RAW_BITS]
    freq = sub.mean(0); bits = np.flatnonzero((freq >= 0.003) & (freq <= 0.997)).astype(np.int32)
    order = np.argsort(pool.mass.to_numpy(), kind="stable"); pool = pool.iloc[order].reset_index(drop=True); fp = fp[order]
    fp_sel = np.packbits(np.unpackbits(fp, axis=1)[:, :RAW_BITS][:, bits], axis=1)
    np.savez(p, keys=pool.inchikey14.to_numpy(object), smiles=pool.normalized_smiles.to_numpy(object), mass=pool.mass.to_numpy(np.float64), fp=fp_sel, bits=bits)
    log("pool saved", len(pool), "selected bits", len(bits)); return load_npz(p)

# ----------------------------------------------------------------------------------------------- spectra
def prep_peaks(mz, it, prec):
    mz = np.asarray(mz, np.float64); it = np.asarray(it, np.float64)
    if len(mz) == 0: return None
    k = (mz > 0) & (mz <= prec + 2.0); mz, it = mz[k], it[k]
    if len(mz) == 0 or it.max() <= 0: return None
    it = it / it.max(); k = it >= 1e-3; mz, it = mz[k], it[k]
    if len(mz) > MAXP: s = np.argsort(-it)[:MAXP]; mz, it = mz[s], it[s]
    o = np.argsort(mz); return mz[o].astype(np.float32), np.sqrt(it[o]).astype(np.float16)

def build_spectra():
    p = cached("spectra.npz")
    if p: log("using cached", p); return load_npz(p)
    p = f"{OUT}/spectra.npz"
    cols = ["inchikey14", "ms2_mzs", "ms2_normalized_intensities", "precursor_mz", "adduct", "ionization_mode", "collision_energy_ev"]
    mz, it, nv, meta = [], [], [], []
    for b in pq.ParquetFile(TRAIN).iter_batches(batch_size=50000, columns=cols):
        d = b.to_pandas()
        for r in d.itertuples():
            pk = prep_peaks(r.ms2_mzs, r.ms2_normalized_intensities, r.precursor_mz)
            if pk is None: continue
            n = len(pk[0]); a = np.zeros(MAXP, np.float32); c = np.zeros(MAXP, np.float16); a[:n] = pk[0]; c[:n] = pk[1]
            ce = r.collision_energy_ev; ce = [x for x in ce if x == x] if ce is not None else []
            mz.append(a); it.append(c); nv.append(n)
            meta.append((r.inchikey14, r.precursor_mz, ADDUCTS.index(r.adduct) if r.adduct in ADDUCTS else len(ADDUCTS),
                         1.0 if r.ionization_mode == "positive" else -1.0, float(np.mean(ce)) if ce else 0.0, 1.0 if ce else 0.0, min(len(ce), 8) if ce else 1))
        if SMOKE and len(mz) > 20000: break
        log("spectra", len(mz))
    m = pd.DataFrame(meta, columns=["key", "prec", "adduct", "mode", "ce", "ce_known", "n_merged"])
    np.savez(p, mz=np.stack(mz), it=np.stack(it), nv=np.array(nv, np.int16), key=m.key.to_numpy(object), prec=m.prec.to_numpy(np.float32), adduct=m.adduct.to_numpy(np.int16),
             mode=m["mode"].to_numpy(np.float32), ce=m.ce.to_numpy(np.float32), ce_known=m.ce_known.to_numpy(np.float32), n_merged=m.n_merged.to_numpy(np.int16))
    return load_npz(p)

# ----------------------------------------------------------------------------------------------- model
class SinEmb(nn.Module):
    def __init__(s, dim, lo=-2.0, hi=3.3):
        super().__init__(); n = dim // 2
        s.register_buffer("inv", 2 * math.pi / torch.pow(10.0, (hi - lo) * torch.linspace(0, 1, n) + lo))
    def forward(s, x): a = x.unsqueeze(-1) * s.inv; return torch.cat([a.sin(), a.cos()], -1)
class Block(nn.Module):
    def __init__(s, d, h, p):
        super().__init__(); s.h = h; s.n1 = nn.LayerNorm(d); s.qkv = nn.Linear(d, 3 * d); s.o = nn.Linear(d, d); s.n2 = nn.LayerNorm(d)
        s.ff = nn.Sequential(nn.Linear(d, 4 * d), nn.GELU(), nn.Dropout(p), nn.Linear(4 * d, d)); s.dr = nn.Dropout(p)
    def forward(s, x, pad):
        B, N, Dm = x.shape; q, k, v = s.qkv(s.n1(x)).view(B, N, 3, s.h, Dm // s.h).permute(2, 0, 3, 1, 4)
        a = F.scaled_dot_product_attention(q, k, v, attn_mask=(~pad)[:, None, None, :])
        x = x + s.dr(s.o(a.transpose(1, 2).reshape(B, N, Dm))); return x + s.dr(s.ff(s.n2(x)))
class SpecNet(nn.Module):
    def __init__(s, nbits, d=384, layers=6, heads=6, p=0.1):
        super().__init__(); s.nbits = nbits
        s.mz = SinEmb(d); s.nl = SinEmb(d); s.inten = nn.Linear(2, d); s.pk = nn.Linear(3 * d, d)
        s.prec = SinEmb(d); s.ad = nn.Embedding(len(ADDUCTS) + 1, d); s.ce = SinEmb(d // 4, 0.0, 2.2); s.gl = nn.Linear(d + d // 4 + 4, d)
        s.blocks = nn.ModuleList([Block(d, heads, p) for _ in range(layers)]); s.norm = nn.LayerNorm(d)
        s.head = nn.Sequential(nn.Linear(2 * d, 2048), nn.GELU(), nn.Dropout(p), nn.Linear(2048, nbits))
    def forward(s, mz, it, pad, prec, ad, ce, ce_known, merged, mode):
        B, N = mz.shape; nl = (prec[:, None] - mz).clamp(min=0)
        pk = s.pk(torch.cat([s.mz(mz), s.nl(nl), s.inten(torch.stack([it, it * it], -1))], -1))
        g = s.gl(torch.cat([s.prec(prec), s.ce(ce / 10.0 + 1.0), ce_known[:, None], merged[:, None], mode[:, None], torch.log1p(prec)[:, None] / 10.0], -1)) + s.ad(ad)
        x = torch.cat([g[:, None], pk], 1); pad = torch.cat([torch.zeros(B, 1, dtype=torch.bool, device=pad.device), pad], 1)
        for b in s.blocks: x = b(x, pad)
        x = s.norm(x); m = (~pad[:, 1:]).float()[..., None]; mean = (x[:, 1:] * m).sum(1) / m.sum(1).clamp(min=1)
        return s.head(torch.cat([x[:, 0], mean], -1))

def batch_tensors(S, idx, aug=False):
    n = S["nv"][idx].astype(np.int64); mz = torch.from_numpy(S["mz"][idx]).to(dev); it = torch.from_numpy(S["it"][idx].astype(np.float32)).to(dev)
    pad = torch.arange(MAXP, device=dev)[None] >= torch.from_numpy(n).to(dev)[:, None]
    if aug:  # peak dropout + small m/z jitter
        drop = (torch.rand_like(it) < 0.1) & ~pad; it = it.masked_fill(drop, 0.0); mz = mz + torch.randn_like(mz) * 0.002
    T = lambda a, dt=torch.float32: torch.from_numpy(np.asarray(a)).to(dev, dt)
    return (mz, it, pad, T(S["prec"][idx]), T(S["adduct"][idx].astype(np.int64), torch.long), T(S["ce"][idx]), T(S["ce_known"][idx]),
            T(S["n_merged"][idx] / 4.0), T(S["mode"][idx]))

def unpack(packed, nb):
    sh = torch.arange(7, -1, -1, device=packed.device, dtype=torch.uint8)
    return ((packed.unsqueeze(-1) >> sh) & 1).reshape(*packed.shape[:-1], -1)[..., :nb].float()

# ----------------------------------------------------------------------------------------------- main
def main():
    pool = build_pool(); S = build_spectra(); nb = len(pool["bits"]); log("bits", nb, "spectra", len(S["nv"]))
    pkeys = pool["keys"]; pmass = pool["mass"]; kidx = {k: i for i, k in enumerate(pkeys)}
    pfp = torch.from_numpy(pool["fp"]).to(dev)
    sp_pool = np.array([kidx.get(k, -1) for k in S["key"]]); keep = np.flatnonzero(sp_pool >= 0)
    h = np.array([int(hashlib.md5(k.encode()).hexdigest()[:8], 16) % 100 for k in pkeys])       # identity-disjoint split by structure hash
    is_val_struct = h < 3; sp_val = np.zeros(len(sp_pool), bool); sp_val[keep] = is_val_struct[sp_pool[keep]]
    tr_idx = keep[~sp_val[keep]]; va_idx = keep[sp_val[keep]]; log("train spectra", len(tr_idx), "val spectra", len(va_idx))
    by_struct = pd.Series(tr_idx).groupby(sp_pool[tr_idx]).apply(np.array); s_ids = by_struct.index.to_numpy(); s_lists = by_struct.to_list()
    net = SpecNet(nb, D, L, max(1, D // 64)).to(dev); log("params", sum(p.numel() for p in net.parameters()) / 1e6, "M")
    opt = torch.optim.AdamW(net.parameters(), lr=3e-4, weight_decay=0.01, betas=(0.9, 0.98))
    ck = f"{OUT}/ownfp.pt"; step = 0
    for cand in [ck] + glob.glob("/kaggle/input/**/ownfp.pt", recursive=True):
        if os.path.exists(cand):
            c = torch.load(cand, map_location=dev); net.load_state_dict(c["model"]); opt.load_state_dict(c["opt"]); step = c["step"]; log("resumed", cand, "step", step); break
    use_amp = dev == "cuda"; amp_dt = torch.bfloat16 if use_amp and torch.cuda.get_device_capability()[0] >= 8 else torch.float16
    scaler = torch.amp.GradScaler(enabled=use_amp and amp_dt == torch.float16)
    total = int(os.environ.get("STEPS", 400 if SMOKE else 150000)); warm = 200 if SMOKE else 2000
    lr_at = lambda s: 3e-4 * min(1, (s + 1) / warm) * (0.5 * (1 + math.cos(math.pi * min(1, max(s / total, (time.time() - tstart) / (HOURS * 3600))))))
    rng = np.random.RandomState(step); tstart = time.time()
    def evaluate(max_struct=1500):
        net.eval(); rr = []; vs = pd.Series(va_idx).groupby(sp_pool[va_idx]).apply(np.array)
        with torch.no_grad():
            for sid in vs.index[:max_struct]:
                ix = vs[sid][:4]; args = batch_tensors(S, ix)
                with torch.autocast(dev, dtype=amp_dt, enabled=use_amp): z = net(*args).float().mean(0)
                m = S["prec"][ix[0]]; lo, hi = np.searchsorted(pmass, [pmass[sid] * (1 - PPM * 1e-6), pmass[sid] * (1 + PPM * 1e-6)])
                sc = (unpack(pfp[lo:hi], nb) @ z); r = int((sc > sc[sid - lo]).sum()) + 1; rr.append(1 / r if r <= 25 else 0.0)
        net.train(); return float(np.mean(rr)) if rr else float("nan")
    net.train(); tl = 0.0; last_eval = time.time()
    while step < total and (time.time() - tstart) < HOURS * 3600:
        half = BATCH // 2
        idx = np.concatenate([rng.choice(tr_idx, half), np.array([s_lists[j][rng.randint(len(s_lists[j]))] for j in rng.randint(len(s_lists), size=BATCH - half)])])
        true = sp_pool[idx]; lo = np.searchsorted(pmass, pmass[true] * (1 - PPM * 1e-6)); hi = np.searchsorted(pmass, pmass[true] * (1 + PPM * 1e-6))
        neg = np.minimum(lo[:, None] + (rng.rand(len(idx), NNEG) * (hi - lo)[:, None]).astype(np.int64), len(pmass) - 1)
        cand = np.concatenate([true[:, None], neg], 1); dup = (cand[:, 1:] == true[:, None])
        for g in opt.param_groups: g["lr"] = lr_at(step)
        args = batch_tensors(S, idx, aug=True); ct = torch.from_numpy(cand).to(dev)
        with torch.autocast(dev, dtype=amp_dt, enabled=use_amp):
            z = net(*args)
        z = z.float(); Fc = unpack(pfp[ct], nb)                              # (B, 1+NNEG, nbits)
        sc = torch.einsum("bkn,bn->bk", Fc, z); sc[:, 1:] = sc[:, 1:].masked_fill(torch.from_numpy(dup).to(dev), -1e4)
        loss_rank = F.cross_entropy(sc, torch.zeros(len(idx), dtype=torch.long, device=dev)); loss_bce = F.binary_cross_entropy_with_logits(z, Fc[:, 0])
        loss = loss_rank + 5.0 * loss_bce; opt.zero_grad(set_to_none=True); scaler.scale(loss).backward(); scaler.unscale_(opt)
        nn.utils.clip_grad_norm_(net.parameters(), 1.0); scaler.step(opt); scaler.update(); step += 1; tl += loss.item()
        if step % 200 == 0: log(f"step {step} loss {tl/200:.3f} (rank {loss_rank.item():.3f} bce {loss_bce.item():.4f})"); tl = 0.0
        if time.time() - last_eval > 1800 or step == total:
            log(f"step {step} held-out-identity MRR@25 (pool window) = {evaluate(400):.3f}")
            torch.save(dict(model=net.state_dict(), opt=opt.state_dict(), step=step, nbits=nb, d=D, layers=L), ck); last_eval = time.time()
    torch.save(dict(model=net.state_dict(), opt=opt.state_dict(), step=step, nbits=nb, d=D, layers=L), ck)
    log(f"final step {step} held-out-identity MRR@25 = {evaluate(1500):.3f}")
main()
