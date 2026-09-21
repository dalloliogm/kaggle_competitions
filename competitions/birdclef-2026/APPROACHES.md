# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-04 | ProtoSSM v4 ensemble | TBD | 0.917 | TBD | birdclef-2026-acoustic-species-identification.ipynb | Perch → ProtoSSM + MLP → ResidualSSM → TTA → per-taxon temp scaling |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2025 | Perch v2 baseline (5s crops) | crop → Perch embeddings → MLP | TBD | 0.906 | Good starting point | Used as backbone for ProtoSSM |
| 2025 | Weighted blend (2025) | blend of multiple 2025 models | TBD | 0.88 | Solid but below ProtoSSM | Superseded |
| 2025 | Only-in-LB blend | blend restricted to LB species | TBD | 0.834 | Lower than full blend | Abandoned |

## Backlog

| Idea | Rationale | Expected impact | Cost | Priority |
| --- | --- | --- | --- | --- |
| Fine-tune Perch on 2026 train data | Domain shift from iNat → soundscapes | High | High | Medium |
| SSAST / BirdNET as alternative backbone | Different inductive bias than Perch | Medium | Medium | Low |
| Per-species threshold optimization | ROC-AUC metric rewards calibration | Medium | Low | Medium |

## Abandoned

| Approach | Why dropped | Evidence | Revisit if |
| --- | --- | --- | --- |
| TBD | TBD | TBD | TBD |
