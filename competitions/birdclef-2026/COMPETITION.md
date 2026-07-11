# Birdclef 2026

## Links

- Competition: https://www.kaggle.com/competitions/birdclef-2026
- Kaggle workspace slug: `birdclef-2026`
- Kaggle CLI slug: `birdclef-2026`

## Objective

Acoustic species identification: given 5-second soundscape audio windows, predict the probability that each species (bird, amphibian, insect) was present. Multi-label, multi-class classification over ~200+ species.

## Evaluation

- Metric: macro-averaged ROC-AUC (skips classes with no true positive labels)
- Each row = one 5-second audio window identified by `row_id`
- Validation approach: TBD (OOF validation with stratified splits recommended)
- Public/private leaderboard notes: TBD

## Data

- Kaggle input path: `/kaggle/input/birdclef-2026/`
- Key files:
  - `train_audio/<taxon_id>/<iNat_id>.ogg` — labeled training recordings
  - `train.csv` — metadata with species labels (~6.8 MB, large dataset)
  - `taxonomy.csv` — species taxonomy mapping
  - `test_soundscapes/` — unlabeled 5-second soundscape clips for inference
  - `sample_submission.csv` — one column per species, one row per test window

## Submission

- Expected file: `submission.csv`
- Required columns: `row_id` + one probability column per species
- Generated outputs: `submissions/`

## Rules And Constraints

- External data: TBD
- Internet: TBD
- GPU/TPU: TBD
- Team/merge rules: TBD
- Deadline: 2026-06-03

## Current Baseline

- Local CV: TBD
- Public LB: 0.917 (ProtoSSM v4 ensemble, `birdclef-2026-acoustic-species-identification.ipynb`)
- Pipeline: Perch embeddings → ProtoSSM → MLP → ResidualSSM → TTA → per-taxon temperature scaling
