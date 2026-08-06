"""
2D-Alignment U-Net starter for wellbore-geology / geosteering TVT prediction.

Distilled from the ROGII 1st-place solution (Kaggle user w5833946, topic 733220) and
its released code (`seq_NN_main.py`). This is a *minimal, readable reference* — not the
winner's full multi-file codebase — meant as a genuinely different baseline to reach for
next time, instead of the particle-filter / geosteering pipeline that dominated the public
LB but collapsed on the private split (see ../LEARNINGS.md "POST-MORTEM").

────────────────────────────────────────────────────────────────────────────────────────
THE KEY IDEA — reframe regression as 2D ALIGNMENT
────────────────────────────────────────────────────────────────────────────────────────
The public meta treated this as "predict a TVT number per row" (regression / particle
filter). The winner instead treated it as an IMAGE-ALIGNMENT problem:

  Build a 2D grid  [ horizontal-well position  ×  typewell TVT-offset ].
  For each horizontal-well position h, the model outputs a PROBABILITY DISTRIBUTION over
  where that position aligns on the typewell (the offset axis). TVT is then the expected
  value of that distribution. A 2D U-Net cleans up a noisy GR-misfit "cost image" into a
  sharp, smooth alignment map — exactly what CNNs are good at.

Why it wins:
  * The distribution (not a point) naturally represents the bimodal-datum ambiguity
    (GR matches at two positions ~1 bundle apart) — cross-entropy over the offset axis
    learns to hedge instead of committing, which is RMSE-optimal on ambiguous wells.
  * A U-Net imposes spatial smoothness along the well, so predictions are coherent paths.
  * With heavy domain augmentation it GENERALIZES, where tabular/PF plateaued.

────────────────────────────────────────────────────────────────────────────────────────
THE GRID (winner's numbers)
────────────────────────────────────────────────────────────────────────────────────────
  * Horizontal axis  H = 345 positions  (downsample raw rows by 32: 1024 visible + 10000 tail)
  * Typewell   axis  T = 400 positions  (±100 ft around the last visible TVT, 0.5-ft steps)
  * Everything is RELATIVE to `last_visible_TVT` (the anchor) — the model predicts offsets.

────────────────────────────────────────────────────────────────────────────────────────
THE LOSS  (winner's `weighted_huber_ce`)
────────────────────────────────────────────────────────────────────────────────────────
  * Cross-entropy along the typewell axis vs. an exponentially-smoothed target distribution
    centered on the true alignment  (main objective).
  * + Huber loss on the EXPECTED TVT path (prob · grid_tvt summed over the offset axis).
  * + small GR-penalty  mean(prob · |grid_GR - horizontal_GR|).
"""

from __future__ import annotations
import numpy as np
import pandas as pd
import torch
import torch.nn as nn
import torch.nn.functional as F

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────
class CFG:
    H = 345                       # horizontal-well positions (downsampled)
    T = 400                       # typewell offset bins
    tvt_lo, tvt_hi, tvt_step = -100.0, 100.0, 0.5   # offset axis: ±100 ft @ 0.5 ft  -> 400 bins
    target_sigma = 3.0            # ft; width of the smoothed CE target around the truth
    loss_w = dict(ce=1.0, huber=0.3, gr=0.05)
    huber_delta = 5.0             # ft, on normalized TVT residuals
    n_folds = 5

GRID_TVT = np.arange(CFG.tvt_lo, CFG.tvt_hi, CFG.tvt_step, dtype=np.float32)   # (T,) offset bins
assert len(GRID_TVT) == CFG.T


# ─────────────────────────────────────────────────────────────────────────────
# 1) BUILD ONE ALIGNMENT SAMPLE  (the heart of the method)
# ─────────────────────────────────────────────────────────────────────────────
def build_sample(hw: pd.DataFrame, tw: pd.DataFrame, anchor_tvt: float):
    """
    hw : horizontal well, columns MD, Z, GR  (visible prefix + hidden tail, one row each).
    tw : typewell,        columns TVT, GR     (GR as a function of true vertical thickness).
    anchor_tvt : last KNOWN TVT of the visible prefix (our zero-offset reference).

    Returns
      x       : (C, H, T) float input channels for the U-Net
      grid_gr : (H, T)    typewell GR at each (position, candidate-offset) — used by GR loss
      hw_tvt_rel_binned : (H,) true TVT offset per position if known else NaN (for target/eval)
    """
    # --- downsample the horizontal well into H bins (mean-pool rows) ---
    idx = np.linspace(0, len(hw) - 1, CFG.H).round().astype(int)
    hw_gr = hw["GR"].to_numpy(float)[idx]                       # (H,)
    hw_z  = hw["Z"].to_numpy(float)[idx]                        # (H,)

    # --- typewell GR as a callable of absolute TVT ---
    tw = tw.dropna(subset=["TVT", "GR"]).sort_values("TVT")
    def tw_gr(tvt):                                             # nearest-value interpolation
        return np.interp(tvt, tw["TVT"].to_numpy(float), tw["GR"].to_numpy(float),
                         left=np.nan, right=np.nan)

    # --- the 2D GR-misfit "cost image" ---
    # For position h and candidate offset t, the candidate absolute TVT is anchor + GRID[t].
    # (A fuller version also uses Z via the formation-surface prior S = TVT + Z + C — see notes.)
    cand_tvt = anchor_tvt + GRID_TVT[None, :]                   # (1, T) broadcast over H
    grid_gr  = tw_gr(cand_tvt).repeat(CFG.H, axis=0)            # (H, T) expected GR on the typewell
    gr_gap   = np.abs(hw_gr[:, None] - grid_gr)                 # (H, T) misfit — LOW where aligned
    cost     = -gr_gap                                         # high = good match (U-Net input)

    # --- input channels (stack a few cheap, informative ones) ---
    gr_broadcast = np.broadcast_to(hw_gr[:, None], (CFG.H, CFG.T))
    z_broadcast  = np.broadcast_to((hw_z - hw_z[0])[:, None], (CFG.H, CFG.T))   # relative Z
    x = np.stack([
        _znorm(cost),          # the alignment cost image (the key channel)
        _znorm(grid_gr),       # typewell GR context
        _znorm(gr_broadcast),  # horizontal GR context
        _znorm(z_broadcast),   # trajectory (relative Z) — proxy for the TVT+Z surface term
    ]).astype(np.float32)      # (C=4, H, T)

    # --- true offset per position (label), NaN where hidden ---
    if "TVT" in hw.columns:
        hw_tvt_rel = (hw["TVT"].to_numpy(float) - anchor_tvt)[idx]   # (H,) offset from anchor
    else:
        hw_tvt_rel = np.full(CFG.H, np.nan, np.float32)
    return x, grid_gr.astype(np.float32), hw_tvt_rel.astype(np.float32)


def build_target(hw_tvt_rel: np.ndarray) -> np.ndarray:
    """Exponentially-smoothed CE target: for each position, a distribution over the T offset
    bins, peaked at the true offset (a soft one-hot). NaN positions get a uniform row (masked
    out in the loss)."""
    d2 = (GRID_TVT[None, :] - hw_tvt_rel[:, None]) ** 2          # (H, T)
    tgt = np.exp(-d2 / (2 * CFG.target_sigma ** 2))
    known = np.isfinite(hw_tvt_rel)
    tgt[~known] = 1.0
    tgt /= tgt.sum(1, keepdims=True)                            # normalize along typewell axis
    return tgt.astype(np.float32)


def _znorm(a):
    a = np.asarray(a, float)
    m = np.nanmean(a); s = np.nanstd(a) + 1e-6
    return np.nan_to_num((a - m) / s)


# ─────────────────────────────────────────────────────────────────────────────
# 2) MINIMAL 2D U-NET
#    (The winner uses a timm ConvNeXt-small backbone with LayerNorm→BatchNorm and BF16.
#     This tiny from-scratch U-Net is the readable stand-in; swap in timm for real runs.)
# ─────────────────────────────────────────────────────────────────────────────
class DoubleConv(nn.Module):
    def __init__(self, ci, co):
        super().__init__()
        self.net = nn.Sequential(
            nn.Conv2d(ci, co, 3, padding=1), nn.BatchNorm2d(co), nn.ReLU(inplace=True),
            nn.Conv2d(co, co, 3, padding=1), nn.BatchNorm2d(co), nn.ReLU(inplace=True))
    def forward(self, x): return self.net(x)

class UNet2D(nn.Module):
    """Input (B, C, H, T) → per-position logits over the T typewell bins: (B, H, T)."""
    def __init__(self, cin=4, ch=(32, 64, 128)):
        super().__init__()
        self.d1 = DoubleConv(cin, ch[0]); self.d2 = DoubleConv(ch[0], ch[1])
        self.d3 = DoubleConv(ch[1], ch[2])
        self.pool = nn.AvgPool2d(2)                             # avg-pool > learnable, per winner
        self.u2 = DoubleConv(ch[2] + ch[1], ch[1])
        self.u1 = DoubleConv(ch[1] + ch[0], ch[0])
        self.head = nn.Conv2d(ch[0], 1, 1)                     # 1 logit per (H,T) cell
    def _up(self, x, like): return F.interpolate(x, size=like.shape[-2:], mode="bilinear", align_corners=False)
    def forward(self, x):
        e1 = self.d1(x); e2 = self.d2(self.pool(e1)); e3 = self.d3(self.pool(e2))
        d2 = self.u2(torch.cat([self._up(e3, e2), e2], 1))
        d1 = self.u1(torch.cat([self._up(d2, e1), e1], 1))
        return self.head(d1).squeeze(1)                        # (B, H, T) logits over typewell axis


# ─────────────────────────────────────────────────────────────────────────────
# 3) LOSS  (weighted CE + Huber-on-expected-path + GR penalty)
# ─────────────────────────────────────────────────────────────────────────────
def alignment_loss(logits, target, grid_gr, hw_tvt_rel):
    # logits, target, grid_gr : (B, H, T);  hw_tvt_rel : (B, H) true offset (NaN where hidden)
    grid = torch.as_tensor(GRID_TVT, device=logits.device)                       # (T,)
    logp = F.log_softmax(logits, dim=-1)                                         # over typewell axis
    prob = logp.exp()
    mask = torch.isfinite(hw_tvt_rel)                                            # supervise known rows

    ce = -(target * logp).sum(-1)[mask].mean()                                   # cross-entropy
    exp_tvt = (prob * grid).sum(-1)                                              # expected TVT path
    huber = F.huber_loss(exp_tvt[mask], hw_tvt_rel[mask], delta=CFG.huber_delta)
    gr_pen = (prob * grid_gr).sum(-1)[mask].mean()                              # small GR consistency
    w = CFG.loss_w
    return w["ce"] * ce + w["huber"] * huber + w["gr"] * gr_pen


def predict_tvt(logits, anchor_tvt):
    """Expected-value decode: TVT = anchor + Σ_t softmax(logits)[h,t] · grid[t]."""
    grid = torch.as_tensor(GRID_TVT, device=logits.device)
    return anchor_tvt + (F.softmax(logits, -1) * grid).sum(-1)                   # (B, H)


# ─────────────────────────────────────────────────────────────────────────────
# 4) CV + TRAINING SKELETON   (grouped by well — TRUST THIS OVER PUBLIC LB)
# ─────────────────────────────────────────────────────────────────────────────
# The single most important lesson from the post-mortem: build grouped-by-well CV on day 1
# and TRUST IT, even when it disagrees with the public LB. The winner kept XY-neighbor
# features that HURT public LB because CV said +0.3 — and that call survived the shake-up.
#
#   from sklearn.model_selection import GroupKFold
#   gkf = GroupKFold(CFG.n_folds)
#   for tr, va in gkf.split(wells, groups=well_ids):
#       model = UNet2D().cuda()
#       opt = torch.optim.AdamW(model.parameters(), 1e-3)
#       for epoch in range(E):
#           for well in tr:                       # + AUGMENT (see below) — this is decisive
#               x, grid_gr, tvt_rel = build_sample(*well)
#               logits = model(to_gpu(x)[None])
#               loss = alignment_loss(logits, to_gpu(build_target(tvt_rel))[None],
#                                     to_gpu(grid_gr)[None], to_gpu(tvt_rel)[None])
#               loss.backward(); opt.step(); opt.zero_grad()
#       # validate: predict_tvt on va, compare to true tail TVT -> grouped RMSE = your north star
#
# DOMAIN AUGMENTATION that made NNs generalize (apply inside the train loop):
#   * Z-shift:  resample a TVT path keeping (TVT + Z) fixed, via block-bootstrap on real ΔTVT;
#               regenerate GR from the typewell; occasionally inject a fault jump in (TVT+Z).
#   * GR transform:  GR' = a·GR + b on the typewell → forces reliance on SHAPE not absolute level.
#   * Others: reverse-path, MD-stretch, tail-crop, 2D channel masking, PF-channel corruption.
#
# EXTENSIONS toward the winner's full score (~4.8 CV vs ~7.4 for PF alone):
#   * Add a PF probability heatmap as an extra input channel (PF as a FEATURE, not the model).
#   * XY-neighbor channel via the formation-surface prior  S = TVT + Z + C  locally linear
#     ⇒ ΔTVT = a·ΔX + b·ΔY − ΔZ  (weighted LS on spatial neighbors); gate it off for the ~10%
#     of wells with poor neighbor quality.
#   * Swap the toy U-Net for timm `convnext_small` (LayerNorm→BatchNorm, BF16), ensemble seeds/folds.

if __name__ == "__main__":
    # smoke test on synthetic shapes so the pieces are wired correctly
    m = UNet2D(cin=4)
    x = torch.randn(2, 4, CFG.H, CFG.T)
    logits = m(x)
    assert logits.shape == (2, CFG.H, CFG.T), logits.shape
    tgt = torch.softmax(torch.randn(2, CFG.H, CFG.T), -1)
    ggr = torch.randn(2, CFG.H, CFG.T)
    tvt = torch.randn(2, CFG.H); tvt[:, ::3] = float("nan")   # some hidden positions
    print("loss:", float(alignment_loss(logits, tgt, ggr, tvt)))
    print("pred TVT shape:", tuple(predict_tvt(logits, anchor_tvt=11900.0).shape))
    print("OK — starter wired correctly.")
