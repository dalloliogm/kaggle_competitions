---
name: robust-tabular
description: Builds reliable binary-classification submissions with a deterministic portfolio plus a target-blind JSON feature planner whose actual candidate is gated against the best portfolio OOF prediction.
---

# Robust Tabular Portfolio

Use the supplied scripts without editing them.

## `scripts/quick_baseline.py`

Discovers the current train, test, and sample-submission files under `/work`; infers the ID and binary target; writes a prior fallback first; then attempts a fast CatBoost model. It always leaves `/work/quick_baseline.csv` when the sample schema is available.

## `scripts/run_portfolio.py`

Runs five-fold candidate models, writes model, equal-rank, and OOF-gated weighted-rank CSVs under `/work`, and prints one final `PORTFOLIO_MANIFEST` JSON line listing the absolute files in cross-validation order. Submit only paths from that manifest.

Both scripts exclude solution, answer, truth, and ground-truth files from discovery. They preserve the sample-submission columns, order, and row count and clip finite probabilities to `[0, 1]`.

## `scripts/run_planned_features.py`

Reads one declarative JSON plan, rejects anything outside the model/feature
allowlist, generates at most 40 target-independent columns, and cross-validates
the planned final model on the portfolio folds. It writes a submission only if
the candidate beats the best deterministic portfolio OOF prediction by at least
0.0015 AUC, wins at least 80% of folds, and loses no fold by more than 0.002.
Rejected plans never create a submission candidate.

## Provenance

This portfolio/freeroll structure was adapted from:

- Naji's public Kaggle notebook, "LB 0.823 | The Freeroll Gemini Pro Strategy".
- Kun Zhang's public deterministic portfolio notebooks, credited by that source.

The v13 planner replaces direct LLM code editing and public-score hill climbing
with a strict JSON contract and deterministic local gate. Final selection is
still left to the evaluation harness.
