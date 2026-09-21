# Biohub validation harness plan

This is the validation strategy we should use before spending more submission
slots. The goal is not to perfectly predict public LB from a tiny labeled set;
the goal is to make every experiment comparable, leakage-aware, and unlikely to
fail Kaggle formatting/scoring.

## Validation layers

### 1. Submission structural validity

Every candidate must pass `scripts/biohub_validation_harness.py` before
submission. Minimum checks:

- exact Biohub submission columns;
- no missing values;
- globally unique row ids;
- dataset-local unique `node_id` values;
- every edge source/target exists in the same dataset;
- every edge spans exactly one frame;
- max indegree `<= 1`;
- max outdegree `<= 2`;
- duplicate directed edges rejected;
- weak component diagnostics recorded.

This layer does not estimate leaderboard score. It exists to avoid wasting slots
on invalid or pathological graphs.

### 2. Official metric on embryo-aware labeled splits

When a candidate can be run on train movies, score it with the official metric
implementation:

`adjusted_edge_jaccard + 0.1 * division_jaccard`

Validation split rules:

- keep splits embryo-disjoint where possible;
- never use random frame-level splits as the main decision signal;
- report metrics by dataset and by embryo prefix, not only aggregate score;
- track edge TP/FP/FN, division TP/FP/FN, node recall, and node-count ratio.

The selected two-movie exact split already proved useful for debugging, but it
underweighted hidden-test divisions. Do not tune division logic from one split
alone.

### 3. Acquisition-artifact diagnostics

The forum scan found a credible report of systematic duplicated adjacent frames
in many `6bba` train videos. The harness should therefore record duplicated-frame
indices whenever image arrays are available.

Use these diagnostics to evaluate frozen-frame-aware candidates:

- links across duplicated transitions should have near-zero displacement;
- motion extrapolation should be disabled across frozen transitions;
- the transition after a frozen run may need a relaxed jump gate;
- apply this conditionally, not as a global gate change.

### 4. Public LB as delayed batch feedback

Current evidence says local validation is imperfect:

- learned U-Net/transformer improved exact validation but dropped public LB;
- no-safe-divisions improved selected validation but dropped public LB;
- Exp101-104 tied or regressed despite structurally valid outputs.

Therefore, for public-test optimization:

- change one mechanism at a time;
- validate structurally;
- submit multiple independent candidates when slots are available;
- compare public LB only after all pending submissions complete;
- record every result in `APPROACHES.md` and `TASKS.md`.

## Command examples

Structural checks on a downloaded Kaggle output:

```bash
python competitions/biohub-cell-tracking-during-development/scripts/biohub_validation_harness.py \
  --submission kaggle_outputs/biohub-exp107-density-gain-0475/submission.csv \
  --out-dir /tmp/biohub-exp107-validation \
  --skip-metric
```

Kaggle exact validation on train predictions, when the tracking repo and train
data are attached:

```bash
python /kaggle/working/biohub_validation_harness.py \
  --submission /kaggle/working/submission.csv \
  --train-dir /kaggle/input/competitions/biohub-cell-tracking-during-development/train \
  --image-dir /kaggle/input/competitions/biohub-cell-tracking-during-development/train \
  --tracking-repo /kaggle/working/tracking_repo \
  --out-dir /kaggle/working/validation
```

## Next implementation steps

1. Call the harness from every new Biohub candidate notebook after writing
   `submission.csv`.
2. Add a train-mode candidate runner around Exp073/Exp092 so we can score the
   current production recipe on multiple embryo-aware folds.
3. Add a small comparison dashboard that reads several `validation_report.json`
   files and ranks candidates by:
   - exact metric summary when available;
   - per-embryo regressions;
   - graph-size deltas;
   - component-size risk;
   - duplicated-frame behavior.
