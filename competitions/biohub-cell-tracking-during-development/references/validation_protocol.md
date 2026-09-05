# Robust Biohub validation protocol

This protocol is the promotion gate for new Biohub experiments. It is designed
to reduce selection bias and public-leaderboard overfitting; it does not claim
that local validation can predict the private leaderboard exactly.

## Split policy

- Group by complete movie/dataset. Never split individual frames or cells across
  train and validation.
- Keep embryo prefixes represented in every development fold where possible.
- Maintain two layers: rotating development folds for tuning and a final
  holdout whose labels and scores are not inspected until a candidate is frozen.
- Record the exact dataset lists and protocol version beside every result.
- If the final holdout is used to choose between candidates, it becomes a
  development fold and must be replaced; do not reuse it as confirmatory evidence.

The current labelled split is useful for debugging but is not a final holdout.
Historical local/public rank inversions mean that a local gain is evidence about
the mechanism, not a private-LB forecast.

## Promotion gate

A candidate may be promoted only when all conditions below are met:

1. The hypothesis and candidate grid were written down before scoring.
2. The exact official metric is reported per movie and pooled.
3. Mean and median improve against the incumbent, with no unacceptable
   regression on any embryo prefix or individual movie.
4. Edge Jaccard, division Jaccard, node recall, node-count ratio, and
   edge/division error counts are reported separately.
5. Candidate ranking is stable under the planned grouped folds and small,
   predeclared perturbations of thresholds or weights.
6. Controls are included: incumbent, mechanism-off control, and candidate.
7. The output passes the structural harness and the independent download-time
   validator, with an artifact SHA recorded before any upload.

One positive fold, a tiny pooled gain, or a public-LB tick alone is insufficient.

## Stability checks

For each candidate record per-movie mean, median, standard deviation, minimum,
worst-movie delta, and the number of regressions. Also compare node, edge, and
division counts against the incumbent. Large graph-size changes require an
explicit explanation because they can move the adjusted metric independently
of tracking quality.

Perturbations should be small and predeclared, for example the neighbouring
detector-fusion weights or geometry caps. If the candidate loses its advantage
under small perturbations or changes rank between folds, classify it as fragile
and do not promote it.

## Evidence labels

Use these labels in notes and maps:

- `STRUCTURAL_PASS`: output format and graph invariants passed.
- `LOCAL_PROXY`: grouped labelled validation result; not private-LB evidence.
- `PUBLIC_LB`: scored public submission result.
- `PRIVATE_LB`: only a final/private score can support this label.
- `HELD`: valid but not promoted or submitted.

Never describe `STRUCTURAL_PASS` or `LOCAL_PROXY` as evidence of private-LB
improvement.
