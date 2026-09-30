# Kaggle competition checklist (from post-mortems)

A checklist for any new competition, built from what went wrong in past ones.
Each item names the competition it came from, so its evidence can be checked.
Read it at the start of a competition and again at mid-point.

## Week 1: before any tuning

- [ ] **Decompose the metric and measure headroom per term.** For every
  component (edges, divisions, nodes, ...) compute the current score and the
  maximum achievable, multiplied by its weight. Rank the terms by weighted
  headroom and put the first learned-model effort on the largest one.
  *Biohub 2026: divisions (weight 0.1) sat at Jaccard ~0.15, and a small learned
  division classifier was worth +0.006 private and ~900 ranks. We spent months
  on edge and post-process constants instead.*
- [ ] **Find out how public and private test sets differ** (the data
  description, sample counts, the forum), and **build validation that mimics
  that split**, e.g. hold out a whole embryo, patient, site or time block.
  *Biohub 2026: public was one embryo and private another, sparser one. Our
  validator mixed both, so it could not see the shift that cost everyone about
  0.035.*
- [ ] **Check that every learned component in a copied public pipeline is
  actually called.** Grep for each model or head the notebook loads and confirm
  it runs.
  *Biohub 2026: egoring reported a DivNet that was loaded but never used.*
- [ ] **Estimate how noisy the public board is.** Count the public test samples
  and check the rounding. If a few samples dominate, plan never to select on
  public score.

## Throughout

- [ ] **Validate on held-out data and select on it, not on public.** Use paired,
  per-sample comparisons restricted to the samples a change actually moves
  (`competitions/biohub-cell-tracking-during-development/scripts/paired_sweep_analysis.py`).
  *Gabriel, Biohub 2026: local validation correlated 0.88 with private, public
  only 0.63.*
- [ ] **When a direction is declared exhausted, write down what kind of fix was
  ruled out.** "Geometric gates are exhausted" is not the same as "the term is
  exhausted". Before closing a term, ask whether a learned model on existing
  candidates was tried.
- [ ] **Stop constant tuning once gains fall below the leaderboard's
  resolution.** A held-out gain of about 0.002 did not show on a 3-decimal
  private board. Move to model-level work instead.
- [ ] **When a public notebook jumps the board, adopt it early and look for its
  weakest term**, rather than re-tuning its constants.

## Endgame

- [ ] **Use every submission slot before each 00:00 UTC reset.** See
  "Submission slots" in `AGENTS.md`.
- [ ] **Submit early on the last day.** Scoring can lag about 6 hours.
- [ ] **Make the two final picks genuinely different.** Under best-of-two
  scoring, a near-duplicate second pick adds almost nothing.
  *Gabriel, Biohub 2026: best public plus its parent were near-duplicates, and a
  better private submission went unselected.*
- [ ] **After the close, record private scores for all submissions** in the
  workspace `LEARNINGS.md`, compare them with the held-out evidence, and read
  the top write-ups.
