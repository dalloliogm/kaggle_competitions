# Enveda CASMI 2026 — Molecule ID from Mass Spectra

## Links

- Competition: https://www.kaggle.com/competitions/enveda-CASMI26-molecule-id-mass-spectra
- Kaggle workspace slug: `enveda-casmi26-molecule-id-mass-spectra`
- Kaggle CLI slug: `enveda-casmi26-molecule-id-mass-spectra` (lowercase works)
- Official pages saved in `references/` (data_description, Evaluation, Timeline, Code_Requirements, rules)

## Objective

Predict the 2D structure (SMILES) of an unknown molecule from its MS/MS spectra (de novo / retrieval). Predictions are **per `molecule_id`** (1–16 spectra each, median 3), so evidence from all of a molecule's spectra must be aggregated into one ranked list of up to 25 SMILES.

Test: ~1,500 spectra / ~400 molecules, all Bruker timsTOF, monoisotopic mass 157–1159 Da. Hidden novelty classes: (1) in public spectral libraries, (2) known structure in PubChem/COCONUT but no public spectra, (3) novel structure (not in PubChem). Focus is natural-product-like chemistry.

## Evaluation

- Metric: MRR@25 per molecule (reciprocal rank of first correct guess, 0 if none in top 25).
- Match: RDKit tautomer-canonicalised, InChIKey14 (connectivity only; stereo/tautomer ignored).
- Validation approach: group by `inchikey14`, never split a molecule across folds; prefer `enveda-np-examples` / timsTOF as the closest proxy; also stratify by "seen in library" vs not to mimic classes 1–3.
- Public/private leaderboard notes: TBD. Visible test.parquet is a sample of *train* — replaced by hidden set on re-run.

## Data

- Kaggle input path: `/kaggle/input/enveda-casmi26-molecule-id-mass-spectra/`
- Local data path: `data/enveda-casmi26-molecule-id-mass-spectra/` (train.parquet is ~3 GB; not downloaded)
- Files: `train.parquet` (~2.5M spectra, ~275k structures, label `normalized_smiles`), `test.parquet`, `sample_submission.csv`
- Key train libs: enveda-180 (1.15M, timsTOF but synthetic drug-like), pluskal_ms2, riken (plant), gnps, massbank, mona, spectraverse, msdial, drug_plus, **enveda-np-examples** (1,151 spectra / 250 common NPs, same pipeline as test), masaryk
- Use `collision_energy_ev` (aligned to test). Test adducts: [M+H]+, [M+NH4]+, [M-H2O+H]+, [M-2H2O+H]+, [M+Na]+, [M+K]+, [M-H]-, [M-H2O-H]-, [M+CH2O2-H]-, [M+Cl]-.

## Submission

- Expected file: `submission.csv` (must be produced by a Notebook)
- Required columns: `molecule_id,smiles` — smiles = up to 25 candidates joined by `;`, best first; each molecule_id exactly once; no nulls.
- Generated outputs: `submissions/`

## Rules And Constraints

- External data: freely & publicly available data and pretrained models allowed (COCONUT, PubChem, MassIVE/GeMS, DreaMS, FragHub, etc.)
- Internet: disabled in submission notebook
- GPU/TPU: CPU or GPU notebook, <= 9 h run-time
- Team: max 5; merger deadline 2026-12-07
- Timeline: start 2026-09-14, entry deadline 2026-12-07, final submission 2026-12-14 (23:59 UTC)
- Prizes: $50k total (1st $16k)

## Current Baseline

- Local CV: TBD
- Public LB: 0.191 (v2 blend: candidates + FP model + library cosine; baseline lib-only was 0.140)
- Notebook/kernel: dalloliogm/casmi26-candidates-fp-v2 (v2), needs kernel output of dalloliogm/casmi26-fp-model-train
