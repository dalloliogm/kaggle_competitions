# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-06-14 | Character-level causal Transformer baseline | Pending Kaggle run | TBD | TBD | `notebooks/char_transformer_baseline.ipynb` | 4 layers, d_model 256, 4 heads, char vocab from train text, validation PPL. |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-06-14 | Initial baseline notebook | Added robust CSV loading, inferred text column, char tokenizer, Transformer LM training loop, artifact saving, test diagnostics. | Pending | TBD | Ready to run on Kaggle | Confirm exact submission schema and tune model size/context after first PPL. |

## Backlog

| Idea | Rationale | Expected impact | Cost | Priority |
| --- | --- | --- | --- | --- |
| Confirm sample submission / leaderboard schema | Kaggle pages fetched by script did not include sample submission or required columns. | Required for valid submission if notebook output is expected. | Low | High |
| Increase model capacity within constraints | Baseline is conservative and likely underfits. | Medium to high | Medium | Medium |
| Tune context length | Longer context can improve PPL for Chinese prose but attention cost grows quadratically. | Medium | Medium | Medium |
| Add LR warmup and checkpoint averaging | Stabilizes Transformer LM training. | Medium | Low | Medium |

## Abandoned

| Approach | Why dropped | Evidence | Revisit if |
| --- | --- | --- | --- |
| TBD | TBD | TBD | TBD |
