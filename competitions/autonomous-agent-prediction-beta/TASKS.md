# Tasks

## Current Goal

- Improve on completed submission `54972472` (`official-demo-v6-blended-baseline`, public score `0.819`) without losing the known-good official demo submission behavior. **Still the live best as of 2026-07-28** — four follow-up attempts (v5-retry, v9-v5-shell-adaptive-recovery, v9-pick-best-model) have all completed at 0.818-0.819, none beating it.
- Submission `55011609` (`official-demo-v5-model-recipe-retry-20260726`) completed at 0.818 and did not improve on v6.
- Submission `55029319` (`official-demo-v8-adaptive-feature-gate-llm-advisory`)
  errored because `submit_predictions` was never called.
- Submission `55030429` (`official-demo-v9-v5-shell-adaptive-recovery`) completed 2026-07-27 at `0.818`; did not improve on v6.
- Submission `55045683` (`official-demo-v9-pick-best-model`, a separate branch built 2026-07-25, queued behind the daily quota until today) completed 2026-07-28 at `0.819` — **tied v6 exactly** despite scoring higher offline (0.828 vs 0.826 on the 3-folder sample). See LEARNINGS.md/APPROACHES.md: this is evidence the 3-folder offline sample can't reliably discriminate small AUC deltas; prefer the full 16-task replay set for future close calls.

## Next Experiments

- Defer the schema-adaptive specialist ensemble until the exact v6 source package is recovered.
- Do not submit the independent CatBoost specialist as a standalone agent: its 16-task replay mean was 0.7990, with three tasks below 0.70.
- Retain the v8 adaptive modeling payload for replay comparison, but do not
  resubmit its failed control shell.
- Monitor v9 submission `55030429`; it preserves the proven v4/v5 agent name,
  generation settings, initial `data_analyst` delegation, and session-ending
  warning rather than using a `run_command`-first control prompt.
- Create `submissions/agent-configs/baseline-autonomous-tabular/` with:
  - `agent.yaml` at archive root
  - a low-temperature system prompt with an anti-loop rule
  - a `feature-engineer` skill script that discovers train/test/sample files, infers ID and target columns, and writes fallback predictions on failure
  - a local structural validator for `agent.yaml`, `!include` paths, tool names, skill manifests, and final zip contents
- Download or mount the full training set locally only if needed for offline replay; keep large generated data out of git.
- Build a replay harness over the provided `train_01`... training folders:
  - hide `solution.csv` from the modeling script
  - train on `train.csv`
  - predict `test.csv`
  - score against `solution.csv` with ROC AUC
  - aggregate per-folder scores and runtime
- Compare three modeling levels:
  - fast logistic regression / HistGradientBoosting fallback
  - row-wise numeric aggregates plus interactions and CV-safe target encoding
  - LightGBM/XGBoost/CatBoost blend if available in the target environment
- Package and validate `submission.zip` locally before any Kaggle upload.
- After first live submission, inspect public feedback and record exact outcome in `APPROACHES.md` and `LEARNINGS.md`.
- If `54491765` errors, retrieve the detailed API error with:
  - `.venv/bin/python` plus `KaggleApi().competition_submissions('autonomous-agent-prediction-beta')`
- If another custom package is needed, keep the zip filename exactly `submission.zip` and do not include `run_skill_script`.
- Before the next upload, check whether the daily quota has reset. Live Kaggle
  metadata reports a 1/day limit, but an errored run may be refunded even while
  a naive history-based counter still says the quota is exhausted.

## Done

- Initialized workspace from the official Kaggle URL on 2026-07-09.
- Confirmed Kaggle metadata on 2026-07-09: `userHasEntered=True`, deadline `2026-08-06 23:59:00`, 43 teams, reward `Swag`.
- Pulled official description, evaluation, rules, and file listing into `references/`.
- Confirmed Kaggle CLI data access by downloading `data/train_01/DATA.md` and `data/train_01/sample_submission.csv`.
- Pulled public notebooks:
  - `sidhaarthshree/autonomous-agent-prediction-a-to-z-guide`
  - `nursrijan/agent-starter-dynamic-automl-guide`
- Rebuilt and executed the local tutorial notebook:
  - `notebooks/autonomous-agent-prediction-beta-competition-tutorial.ipynb`
  - covers competition mechanics, a runnable synthetic baseline, agent-package
    preflight, submissions v1-v6, the 16-task CatBoost replay, and public
    notebook approaches
  - public leaderboard and notebook scores were refreshed on 2026-07-27;
    leaderboard-only methods are explicitly marked as unknown
- Uploaded private Kaggle notebook version 1 on 2026-07-27 and confirmed its
  hosted execution completed:
  - `dalloliogm/autonomous-agent-prediction-beta-tutorial`
- Uploaded private Kaggle notebook version 2 with the v8 feature ablations,
  target-normality explanation, and LLM advisory design; its hosted execution
  completed successfully.
- Added source-level notes and repo-improvement backlog in `references/`.
- Submitted four agent packages on 2026-07-09:
  - `54491451`: custom v1, errored with no `submit_predictions`
  - `54491555`: custom v2, errored because `run_skill_script` is unavailable
  - `54491615`: custom v3, errored with no `submit_predictions`
  - `54491765`: official-demo v4, completed with public score `0.815`
- Attempted v5 (`official-demo-v5-model-recipe-no-run-skill-script`); upload rejected with generic `400 Bad Request` and no row.
- Submission `54972472` (`official-demo-v6-blended-baseline`) completed on 2026-07-25 with public score `0.819`.
- Retried the validated v5 archive on 2026-07-26 as submission `55011609`; upload succeeded and evaluation is pending.
- Submission `55011609` completed with public score `0.818`.
- Downloaded the complete official practice archive and discovered 16 replay tasks.
- Built `official-demo-v7-catboost-specialist` independently of v6 and replayed it on all 16 tasks.
- Recorded per-task results in `references/catboost-specialist-v7-replay.csv`; no Kaggle slot was spent.
- Replayed an AutoGluon 1.5.0 classical portfolio on all 16 tasks and recorded
  `references/autogluon-classical-replay.csv`; its 0.7995 mean effectively tied
  the standalone CatBoost specialist.
- Screened Mitra zero-shot on deterministic 1,000-row samples and recorded the
  result in `references/mitra-vs-autogluon-sampled-replay.csv`; quality tied the
  classical portfolio while CPU runtime was 28x to 173x slower.
- Documented package availability, licensing, runtime evidence, and the TabPFN
  verdict in `references/automl-foundation-model-assessment.md`.
- Built `official-demo-v8-feature-engineered` with a mandatory first baseline,
  a solution-blind LLM transformation adviser, and a deterministic adaptive
  feature candidate.
- Replayed the broad portfolio, numeric-only ablation, and adaptive gate on all
  16 tasks. Recorded:
  - `references/feature-engineered-v8-replay.csv` (broad, mean 0.7981)
  - `references/feature-engineered-v8-numeric-replay.csv` (numeric, mean 0.7994)
  - `references/feature-engineered-v8-adaptive-replay.csv` (adaptive, mean 0.8001)
- Packaged the v8 branch as `submissions/submission.zip`; archive integrity,
  source-folder compilation, and extracted-archive compilation all passed the
  official starter-kit validator.
- Submitted the v8 archive as Kaggle submission `55029319`, consuming the
  nominal single 2026-07-27 slot. It errored because the agent never called
  `submit_predictions`, and Kaggle subsequently refunded the slot.
- Rebuilt the candidate as v9 on the byte-identical v5 `agent.yaml` and proven
  first-valid-submission workflow, with adaptive feature engineering demoted to
  an optional post-baseline candidate.
- Validated both v9 source and extracted ZIP with the official ADK compiler;
  its smoke output matched the sample schema/order with 10,000 unique IDs and
  finite predictions.
- Submitted v9 as `55030429`; Kaggle accepted the refunded slot and evaluation
  is pending.

## Questions

- Re-check the deadline before serious submission work; current CLI metadata says `2026-08-06 23:59:00`, but Kaggle timelines can change.
- Verify the exact supported ADK config keys against the demo notebook/sample submission before uploading. The public notebooks disagree on `agent.yaml` shape (`instruction`/`tools` versus `system_prompt`/`allowed_tools`).
- Verify which Python packages are preinstalled inside the evaluation sandbox before relying on LightGBM, XGBoost, or CatBoost.
