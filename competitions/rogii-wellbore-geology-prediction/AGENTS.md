# AGENTS.md

Competition-specific instructions for `competitions/rogii-wellbore-geology-prediction`.

## Context

- Competition: Rogii Wellbore Geology Prediction
- Competition URL: https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction
- Metric: RMSE, row-weighted (long hidden tails matter more than short ones)
- Kaggle CLI slug: `rogii-wellbore-geology-prediction`
- **This is a notebook-only ("code") competition** — raw file-upload submission is rejected outright. See "Submitting" below and the root `AGENTS.md`'s "Notebook-only ('code') competitions" section for the general mechanics.

## Working Rules

- Preserve Kaggle compatibility: code that runs on Kaggle should use `/kaggle/input/...` and `/kaggle/working`.
- Prefer small, auditable notebook/script edits over broad refactors.
- Keep root-level Kaggle UI autosaved notebooks in place unless explicitly asked to copy or move one.
- Put active competition notes in this folder: `COMPETITION.md`, `TASKS.md`, `NOTES.md`, `APPROACHES.md`, and `LEARNINGS.md`.
- Before suggesting a new modeling direction, review `APPROACHES.md` and `LEARNINGS.md` to avoid repeating failed experiments — as of 2026-07-24 both contain a lot of hard-won, non-obvious findings (the contact override actively hurts, not just neutral; a train/test row-level overlap exists but doesn't help; submission grading re-executes notebooks separately from your own run).
- Downloaded kernel outputs actually land at the **repo root's** `kaggle_outputs/<kernel-slug>/` (via `scripts/kaggle_output.sh`), not a per-competition `submissions/` folder — the latter was never actually used in practice here despite being in the original template.
- When running on Kaggle from this repository, prefer `../../scripts/kaggle_push_notebook.sh`, `../../scripts/kaggle_status.sh`, and `../../scripts/kaggle_output.sh`. Each pushed notebook has a sidecar `<name>.kernel-metadata.json` file in `notebooks/` — reuse that pattern for new forks (see `notebooks/working-note-*-ablation.ipynb` for examples of single-change ablation forks).

## Submitting

- `kaggle competitions submit -f submission.csv` **always fails** with a swallowed 400 for this competition. Use `api.competition_submit_code(file_name=..., kernel=..., kernel_version=...)` directly (see root `AGENTS.md` for the full recipe).
- **Kaggle only accepts a file literally named `submission.csv`.** To submit a different candidate output from a kernel, the kernel itself must write it out under that name (e.g. append a final cell that copies/overwrites `submission.csv`) — you can't just pick an arbitrary output file from the UI.
- **Submission grading re-executes the notebook in a context separate from your own `kaggle kernels push/status/output` run.** A kernel completing successfully and producing valid output when *you* run it is not proof it'll survive grading — two of ours threw "Notebook Threw Exception" at grading despite clean interactive runs, with zero traceback exposed anywhere (API or website). Be defensive: don't append final cells that assume an intermediate/diagnostic file is guaranteed to exist (some pipeline outputs, like `submission_model_package_only.csv`, are written conditionally) — check existence first or only patch via files confirmed unconditionally written.
- Submission scoring can take 6+ hours to return (observed once) — don't assume a long `PENDING` means something's broken.
- 5 submissions/day, up to 2 Final Submissions selected for judging. Plan final picks deliberately (see `TASKS.md`) rather than relying on auto-selection.

## Competition Constraints

- External data: public code/dataset sharing is **explicitly allowed** by rules 3.6.b (must be shared on Kaggle forums/notebooks, not privately). The shared `koolbox` package and `wellbore-geology-prediction-artifacts`/model-package datasets are all legitimate to use — see `LEARNINGS.md` for the full list and what each does.
- Internet: disabled on all our kernels (`enable_internet: false`) — matches the public notebooks' convention.
- GPU/TPU: **confirmed not required.** The dominant public pipeline auto-detects GPU availability and falls back to CPU cleanly; a Kaggle GPU-quota gap doesn't block progress here.
- Known leakage risks: see `LEARNINGS.md`'s "MAJOR FINDING" section — all 3 test wells are row-level duplicates of same-ID train wells, but this does **not** appear to be exploitable (a near-exact reconstruction still scores ~9.565, not near 0, implying Kaggle's grading answer key doesn't match what's published in `train.csv` for these rows). Also see the "Leakage And Rules" section there for the full strict/offline/never feature-safety boundary the public EDA notebook documents.
