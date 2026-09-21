# Trackastra kickoff prompt (for a fresh chat)

Self-contained prompt to start a new session implementing the Trackastra linker
as an alternate-architecture experiment. Paste the block below verbatim. It is
the LAST-RESORT diversity option (highest ceiling, biggest build); prefer the v34
graft (Exp155) or the nnU-Net flow detector first if those show signal.

---

```
Implement the Trackastra linker as an alternate-architecture experiment for the
BioHub Cell Tracking competition in this repo (dalloliogm/kaggle_competitions).

## Context you need
- Workspace: competitions/biohub-cell-tracking-during-development/. Read
  COMPETITION.md, TASKS.md (CURRENT STATUS), APPROACHES.md, LEARNINGS.md, and
  references/public-notebooks-scan-2026-07-28.md + references/public-model-
  inventory-2026-07-22.md BEFORE proposing anything, so prior experiments aren't
  redone.
- Our current best public LB is 0.913 (Exp148: pilkwang two-seed logit blend +
  adaptive edge fusion). Every cheap knob (detection blend weight, edge weight,
  post-mix temperature, framewise retention guard) is exhausted at 0.913. The
  next lever is model diversity.
- Task metric: adjusted_edge_jaccard + 0.1*division_jaccard. Data is 3D+time
  microscopy at /kaggle/input/biohub-cell-tracking-during-development/ (zarr
  under test/). Submission is node/edge rows: columns
  id,dataset,row_type,node_id,t,z,y,x,source_id,target_id; node rows carry
  integer centroids, edge rows carry source_id/target_id (one-frame spans),
  unused fields = -1. Structural invariants: globally unique ids, node_id unique
  per (dataset,node_id), every edge endpoint exists in the same dataset, max
  indegree 1, max outdegree 2, no negative coords.

## What Trackastra is / the plan
Trackastra (Gallusser & Weigert 2024) is a transformer that LINKS already-detected
cells across frames (predicts associations + divisions, then solves assignment).
It would REPLACE our linker stage (node-transformer edge-predictor + ILP), keeping
our detections. Pretrained weights are mirrored at
subinium/biohub-trackastra-public-weights-mirror (general_2d + ctc). A public
reference that wired DoG->Trackastra is
jirkaborovec/biohub-celltrack-dog-trackastra-graph-trans - use it as the starting
template, don't build from scratch.

## The three known frictions (solve explicitly)
1. OFFLINE PACKAGING: kernels run with internet disabled. You cannot pip install
   trackastra - vendor the package + deps as an attached wheel/dataset and make
   imports resolve offline.
2. 2D vs 3D: the public weights are 2D+time; our data is 3D+time. Decide and
   justify: per-z-slice + stitch, max-projection, or a 3D adaptation. This is the
   main risk; prototype it small first.
3. FORMAT CONVERSION: convert our detections -> Trackastra input (mask/detection +
   images), run association, convert its lineage -> the node/edge submission
   format with all invariants above.

## Detections to feed it
Reuse our existing detector output rather than re-detecting: our detection stage
is the pilkwang TemporalUNet3D (weights in pilkwang/biohub-tracking-support-pack-
50ep-v1). Extract centroids exactly as Exp148 does. First milestone: get
Trackastra linking OUR detections end-to-end on one test movie.

## Kaggle execution (this repo's conventions - CLI not installed, use uvx)
- Auth: ACCESS_TOKEN in ~/.kaggle/access_token; verify with
  `uvx --index-url https://pypi.org/simple kaggle config view` (auth_method:
  ACCESS_TOKEN). If a `kaggle` binary is needed by scripts/kaggle_push_notebook.sh,
  make a shim that execs `uvx --index-url https://pypi.org/simple kaggle "$@"`.
- This is a NOTEBOOK ("code") competition: raw CSV upload 400s. Submit via
  `kaggle competitions submit <slug> -k owner/kernel-slug -v <version>
  -f submission.csv -m "..."` after pushing the kernel with
  scripts/kaggle_push_notebook.sh.
- ENV NOTE: api.kaggle.com works here but www.kaggleusercontent.com (the kernel
  output CDN) is egress-blocked, so you CANNOT download kernel outputs to validate
  locally. Validate the submission IN-KERNEL (structural harness before writing
  submission.csv) and submit via the API. GPU cap is 2 concurrent sessions.
- Develop on a new branch (e.g. claude/biohub-trackastra-<slug>); commit + push
  each working milestone. Number this Exp156+ and record it in TASKS.md.

## Deliverable & guardrails
Milestone 1: Trackastra linking our detections on one movie, structurally valid.
Milestone 2: full 4-movie submission.csv passing the in-kernel harness.
Milestone 3: submit and record the public LB vs the 0.913 incumbent.
Be honest about the ceiling: we're ~rank 200/1400 and the medal cliff is ~0.950;
this is a diversity probe, not a guaranteed jump. If the 2D->3D transfer looks
hopeless in prototyping, say so and stop rather than forcing it.
```
