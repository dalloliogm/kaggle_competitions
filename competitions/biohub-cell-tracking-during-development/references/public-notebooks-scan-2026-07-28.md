# Public notebook scan - 2026-07-28

Scan of Kaggle public kernels since the last snapshot (~2026-07-20). Filtered to
genuinely new/interesting approaches; the rest are forks of the pilkwang
two-seed lineage we already build on, or metric-hack variants we exclude.

## Actionable: framewise detection-field retention guard (NEW axis)

- Kernel: `indarkarhana/biohub-dual-seed-frame-retention-guard-v1` (34 votes,
  2026-07-28). Public LB **0.913** vs their exact backbone reproduction 0.912
  (**+0.001** from the guard alone).
- Idea: on our EXACT backbone (pilkwang two-seed, det 0.96875, edge thr 0.48,
  DeepCenter, ILP), add a per-frame, label-free "detector-collapse guard". For
  each frame count pooled local-max candidates from the primary field
  `N_tau(primary)` and from the blend `N_tau(blend)`; retention
  `r = N_tau(blend)/N_tau(primary)`. If `r < 0.90` (secondary seed suppressed a
  coherent group on that frame), that frame falls back to primary-only
  detection; otherwise inference is the standard blend. Frozen before scoring,
  movie-independent, no labels/LB feedback.
- Why it matters to us: this is a **detection-side** axis, ORTHOGONAL to
  everything we have tuned (det blend weight, edge weight, adaptive edge fusion,
  post-mix temperature - all edge/linking-side). Implemented as a runtime source
  patch on the same `det_logits[f] = (1-w)*primary + w*secondary_aligned` block
  that exists in our cell 10, gated by
  `BIOHUB_DUAL_SEED_MIN_CANDIDATE_RETENTION=0.90`. Directly graftable.
- Best experiment: graft the guard onto our Exp148 backbone (adaptive edge
  fusion, itself 0.913). The two mechanisms are orthogonal (detection-side vs
  edge-side) and each independently reaches 0.913, so stacking could exceed it.
  Candidate = Exp154.

## Useful infra: lightweight local CV harness (No Hack)

- Kernel: `yusuketogashi/clean-approach-lightweight-local-cv-no-hack` ("Biohub
  132", 162 votes, 2026-07-23). Clean baseline 0.908.
- Two parts: (a) a **fixed-8 local CV** that runs under a guard AFTER the hidden
  submission is written and validated (cannot overwrite it) - addresses our
  long-standing lack of a trustworthy offline harness; (b) a conservative
  short-track rescue (exactly-5-node components, mean learned-edge prob >= 0.90,
  mean edge distance <= 2.75 um, budget min(0.6% nodes, 60)).
- Note: we already have `BIOHUB_ADAPTIVE_SHORT_TRACK_RESCUE` (kept disabled), and
  our min-track-len sweep (Exp130/131) was flat at 0.907, so the rescue itself is
  ~neutral for us. The **local CV harness** is the borrowable part.

## Diversity candidate (ensemble only): divaug heatmap detector

- Kernel: `xiaoleilian/biohub-ct-mix-divaug` (129 votes, 2026-07-20). A DIFFERENT
  detector family: 2x 3D U-Net centre-heatmap models
  (`unet3d_bright.pt` preproc none + `unet3d_traintophat.pt` preproc tophat),
  heatmaps averaged, two-pass um-gated Hungarian linking, peak threshold 0.15. No
  LB stated in the writeup; the heatmap family historically scores below the
  learned-graph lineage. Only interesting as independent ensemble diversity
  (same rationale as the v34 Exp135 direction), not as a standalone.

## Not new / excluded

- `pilkwang/biohub-cell-tracking-two-seeds-logit-blend` (our backbone),
  `amanatar/optimized-biohub-max-score(-v2)`, `romanrozen/biohub-best-score`,
  `zoli800/...two-seeds-logit-blend...`, `navazshfathi/best-score-biohub`,
  `chukkkk/...learned-graph-w-gap-recovery` - reruns/forks of the two-seed or
  learned-graph lineage, no new mechanism.
- `kirneo/metric-hack-last-call-update` (102 votes), other "metric hack" kernels
  - excluded by our strict no-hack strategy decision (2026-07-20).
- Various EDA notebooks (`liamob96/eda-starter`, `muhammad4hmed/...visual-eda`,
  `nusrati/data-understanding`) - no modeling content.
