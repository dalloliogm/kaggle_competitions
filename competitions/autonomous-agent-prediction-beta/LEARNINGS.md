# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- Practice data is organized as mini-competition folders with `DATA.md`, `train.csv`, `test.csv`, `sample_submission.csv`, and `solution.csv`.
- Hidden evaluation sessions should be treated as one dataset per session, not a loop over all practice folders.
- `solution.csv` exists for training mini-competitions only and must be excluded from any submitted agent's discovery/modeling path.
- `sample_submission.csv` is the safest source of required output column names, row order, and row count.

## Target And Metric

- Official metric is ROC AUC.
- The target is binary; submissions should be continuous probabilities in `[0, 1]`, not hard labels.
- Local validation should optimize ranking quality, not threshold accuracy.
- A binary target is not expected to follow a normal distribution. Do not log,
  rank, Box-Cox, or otherwise transform it for normality; inspect and transform
  predictors only when their distribution suggests a concrete benefit.

## Validation

- Use stratified CV for binary classification.
- Use out-of-fold encoding for target/frequency features to avoid leakage.
- Build a local replay harness using `solution.csv` only outside the submitted agent. Score predictions after the agent/model has written them.
- For tiny training sets, simpler regularized models may beat complex engineered pipelines due to variance and overfitting.

## Leakage And Rules

- Never read files whose names imply `solution`, `answer`, `truth`, or `ground` in submitted agent code.
- Public notebook review shows a useful blacklist pattern for discovery functions.
- External data and AutoML tools are allowed only if they satisfy accessibility, cost, license, and reproducibility constraints.
- The competition allows public code sharing through Kaggle; private sharing outside teams is not allowed.

## Features

- Useful general-purpose tabular features from public notebooks:
  - row-level numeric aggregates
  - pairwise numeric interactions among high-correlation features
  - frequency encoding for categorical variables
  - K-fold target encoding for categorical variables
- Treat low-cardinality numeric columns as categorical candidates, but verify this does not hurt tree models.
- Turning on all plausible feature families at once reduced the CatBoost
  specialist's 16-task replay mean from 0.7990 to 0.7981.
- Numeric predictor transformations alone reached 0.7994. They helped some
  tasks but hurt others, so non-normality is not by itself a reason to transform
  a predictor for a tree model.
- A replay-derived schema gate reached 0.8001: it kept 12 tasks identical to the
  CatBoost baseline and improved four selected small-table tasks. This is a
  useful candidate, but its thresholds were chosen after ablation results and
  therefore require live validation.
- An LLM can safely assist by reading a solution-blind distribution profile and
  emitting an allowlisted JSON recommendation. It should never generate
  executable feature code, inspect solution files, transform the binary target,
  or override the mandatory first baseline.
- **The v8/v9 "LLM advisory" was a no-op in the submitted packages.** The
  `--feature-mode plan` machinery in `autopredict.py` was fully implemented and
  allowlist-safe, but no system prompt ever instructed the agent to generate a
  profile, request a plan, or pass `--plan`. The profile even told the model
  "the live predictor ... does not execute arbitrary plan changes." That is the
  most likely reason the v9 v5-shell adaptive run scored exactly in line with
  the non-LLM v5 (0.818): the LLM never influenced features at all. Check that
  a feature is actually *wired to the prompt*, not merely implemented, before
  attributing a score to it.
- **Measured noise floor on a single mini-competition is about 0.0004 AUC.**
  Running an empty plan (informationally identical to the plain baseline) still
  produced OOF AUC 0.95929 versus the baseline's 0.95886 on the same data and
  seed, because the plan path changes feature column ordering and CatBoost
  tie-breaking follows it. Any accept/reject rule comparing two feature sets by
  OOF AUC therefore needs a margin comfortably above ~0.0004; a zero-margin gate
  accepted a kitchen-sink plan on a +0.0003 delta that was pure noise. The
  shipped default is `--gate-margin 0.002`, consistent with the existing
  "treat ~0.002 offline deltas as noise" note from the 3-folder analysis.
- Gating an LLM feature plan on out-of-fold AUC bounds the *feature* choice, but
  it does **not** bound the score. Submission `55072857` shipped exactly this
  gate and regressed to `0.808`, the worst completed score since the v4 demo.
- **The gate was placed on the wrong comparison.** The OOF gate is *intra-script*
  (plan features vs baseline features inside `autopredict.py`). The decision that
  actually sets the score is *inter-submission*: which candidate the agent passes
  to `select_submission`. Adding any new candidate to the session creates a fresh
  chance for the agent to select something worse, and no amount of intra-script
  gating touches that risk. Gate the thing that determines the score, not a
  sub-decision upstream of it.
- **`autopredict.py` is CatBoost-primary, and CatBoost is a known weak default
  here** (0.7990 mean over 16 replay tasks, 0.7424 on small tasks, three below
  0.70). The 0.818-0.819 scores come from the *sklearn ensemble* the agent
  writes itself, not from `autopredict.py`. So any prompt that pushes
  `autopredict.py` output into the submission pool is offering the agent a
  historically weaker candidate to select. `0.808` is squarely in the range that
  a CatBoost-primary final selection would produce.
- **Do not remove a guard without first establishing why it exists.** v9's prompt
  said: *"Submit it only when its final JSON report lists at least one
  `feature_metadata.engineered_features` entry."* That guard's purpose was to keep
  a no-op candidate out of the submission pool entirely. The v10 rewrite replaced
  it with "if `gate.decision` says `rejected_plan_kept_baseline` ... that is
  expected and still worth submitting once" — which instructs the agent to submit
  the plain CatBoost baseline precisely when the plan added nothing. Worse, the
  conservative 0.002 margin makes rejection the *likely* branch, so the most
  probable outcome of the design was "submit a weak CatBoost candidate," and the
  prompt actively encouraged it. Two individually reasonable choices (a safe
  margin; an instruction to always submit once) combined into a bad default path.
- Net rule for this competition: an optional post-baseline candidate must be
  submitted **only when it has positive evidence of being better**, never
  "submitted once anyway for information." Session submission slots are also
  final-selection candidates.

## Models

- First baseline should be boring and reliable: preprocessing plus logistic regression or histogram gradient boosting.
- Optional higher-ceiling approach: LightGBM/XGBoost/CatBoost with OOF blending, if packages are available in the sandbox and runtime remains safe.
- Any search must have hard caps on row count, CV folds, iterations, and elapsed time.
- The standalone CatBoost specialist averaged 0.7990 test AUC over all 16 official replay tasks. It averaged 0.8247 on the 11 tasks with at least 2,000 training rows but only 0.7424 on the five smaller tasks, with three scores below 0.70. CatBoost is useful as a gated specialist, not a universal default.
- Evaluating only `train_01`–`train_03` would have been misleading: the CatBoost candidate averaged 0.8315 on those three but degraded substantially across the complete 16-task set.
- AutoGluon classical averaged 0.7995 over the same 16 tasks, essentially tying CatBoost's 0.7990 with eight wins each. Its small-task mean was slightly worse, so the wrapper is not justified as a standalone dependency.
- Mitra zero-shot CPU inference was 28x to 173x slower than AutoGluon classical on identical 1,000-row samples while remaining within 0.003 AUC on all three completed comparisons. AutoGluon estimated about 7 GB RAM, and one 3,501-row task did not fit under the available memory.
- AutoGluon, Mitra, and TabPFN are absent from the current official Kaggle Python image. The offline evaluator cannot install them or download model weights. TPOT, H2O, Optuna, and CatBoost are present.
- Current TabPFN is not a safe submission dependency: its documentation recommends GPU use, the default weights have a non-commercial license, and the older v2 license has an additional attribution provision that needs competition-rule clearance.
- **Do not hand CatBoost the target/frequency-encoded matrix — give it raw
  categoricals via `cat_features`.** Measured 2026-07-30 on a high-cardinality
  categorical synthetic task: CatBoost scored 0.80087 OOF on the encoded view
  (losing to LogisticRegression's 0.80625) and 0.81568 on the native view
  (winning by +0.0094, and +0.0051 on held-out test). Ordered target statistics
  are the one thing CatBoost does better than the sklearn trees; pre-encoding
  removes it and leaves "just another GBDT on identical features." This casts
  some doubt on the earlier "CatBoost/AutoGluon effectively tie" conclusion from
  2026-07-27 — that comparison may have been partly an artifact of the encoded
  feature view rather than a property of the models.
- **A bare argmax over K models is exposed to winner's curse; require a margin
  for any fragile candidate.** Measured 2026-07-30 on a 900-row task: CatBoost
  won out-of-fold by 0.00044 and then *lost* 0.0028 on held-out test. Measured
  OOF noise here is ~0.0004, so argmax can promote a fragile model on noise
  alone. Genuine CatBoost wins were ~0.01 — two orders of magnitude larger — so
  a 0.003 margin separates signal from noise without blocking real gains. Apply
  the margin only to the *newly added* candidate so the proven selector's
  behavior is preserved when the candidate does not clear the bar.
- **Blending diverse-quality models by weighted OOF AUC can hurt more than help.** On a separate 2026-07-25 branch (LR + HistGradientBoostingClassifier + RandomForest + ExtraTrees, all sklearn/in-process/`n_jobs=1`), a weighted blend regressed 3-folder average offline AUC from 0.826 (LR+HGB only) to 0.820, because RF/ET were consistently weaker than HGB (e.g. one task: HGB alone 0.960 vs RF 0.903, ET 0.878) and diluted it even under `(auc-0.5)`-weighting; squaring or raising the weight to the 4th power only clawed back to roughly parity with the 2-model baseline. Switching to **picking the single best-OOF-AUC model instead of blending** recovered a real gain (0.828 avg, beating the 2-model baseline). If ever adding more candidate models to an ensemble here, prefer a best-of-K selector over a weighted blend unless the weighting scheme is proven to suppress weak members much harder than `(auc-0.5)^1`. An untested `official-demo-v9-pick-best-model` package built on this approach lives at `submissions/agent-configs/official-demo-v9-pick-best-model/` (validated structurally + offline, never submitted live due to hitting the daily quota).
- **Hazard — do not use `n_jobs=-1`/`thread_count=-1` with LightGBM/XGBoost/CatBoost in this kind of script, and do not try to fix it with fork-based multiprocessing timeouts.** In local testing (2026-07-25, `uv`-managed environment): (1) `n_jobs=-1` caused a single `LGBMClassifier.fit()` call on a ~15k-row fold to take over 1,000s (one fold took 9,236s), versus ~1-2s for the same fold with `HistGradientBoostingClassifier` — presumed thread-count autodetection misbehaving in a constrained/virtualized CPU environment. (2) A follow-up fix — pin `n_jobs=1`, wrap every model's per-fold `fit()`/`predict_proba()` in a `multiprocessing.Process` (fork context) with a hard `.join(timeout)` + `.terminate()` — itself deadlocked: even plain `LogisticRegression`/`HistGradientBoostingClassifier` with zero GBDT libraries involved hung for the full 30s timeout inside the forked subprocess (vs. ~1-2s unwrapped), a classic fork-after-multi-threaded-process deadlock (numpy/scipy BLAS/OpenMP thread pools initialized at import time leave the forked child with inconsistent lock state). If a hard per-model timeout is ever needed, use `multiprocessing.set_start_method("spawn")` instead of fork (requires picklable, non-lambda model factories, and adds real per-process interpreter-startup overhead), and test it in isolation before combining with GBDT libraries. Given zero measured AUC benefit from GBDT even when partially working, this whole direction was abandoned rather than pursued further.

## Ensembling And Submission Behavior

- Agent behavior matters as much as model choice. The system prompt should force:
  - `get_status`
  - run modeling skill
  - submit first valid `submission.csv`
  - only then attempt one improvement
  - select final submission before budget is low
- Always include a fallback prediction writer; a weak valid submission beats a crash or no submission.
- Validate both the source folder and the final `submission.zip`; a valid folder can still produce a stale or malformed archive.
- Upload filename matters in this beta: uploading the same valid archive as `baseline-autonomous-tabular-20260709.zip` returned a generic `400 Bad Request`, while naming it exactly `submission.zip` succeeded.
- The live tool registry exposed by the harness is: `edit_file`, `get_status`, `read_file`, `run_command`, `select_submission`, `submit_predictions`, `write_file`.
- Historical submission `54491555` failed when `run_skill_script` was requested
  as a normal registry tool. The newer ADK validator now enables the
  experimental skill toolset when a config declares `skills`, and same-day
  public submissions using this portfolio architecture score 0.822–0.823.
  Treat that as strong evidence—but not proof—that the skill-provided
  `run_skill_script` path now works in the live evaluator.
- Custom prompts that only tell the agent to run a bundled script did not lead to a valid `submit_predictions` call in submissions `54491451` and `54491615`; the next strategy should either use the official demo workflow or make the first tool calls even more constrained through official-compatible structure.
- The official-demo structure is the only package so far that completed evaluation; preserve it when iterating.
- A v5 package that preserved official structure but changed prompt/resources was rejected at upload with generic `400 Bad Request` and created no row. This may be daily-limit behavior or stricter package validation.
- Submission `55029319` showed that passing YAML/include checks and dry-run ADK
  compilation does not verify runtime tool use. Its imperative
  `run_command`-first prompt repeated the same terminal failure as v1 and v3:
  the agent ended without ever calling `submit_predictions`.
- The next candidate must preserve the proven v4/v5 orchestration layer,
  including the official agent identity, generation settings, initial
  `data_analyst` delegation, and explicit warning that a text-only response ends
  the session. Modeling improvements should live underneath that shell.
- **Putting the gate on the correct final model decision was necessary but not
  sufficient.** Submission `55105170` kept CatBoost inside the proven
  pick-best-of-K script and required a 0.003 OOF advantage before promotion, yet
  scored only `0.810` versus `0.819` for the sklearn lineage. A +0.0051
  held-out gain on one synthetic categorical regime was not broad enough
  evidence for hidden-task generalization.
- A failed daily submission can be refunded even though a conservative
  submission-history counter still reports the nominal 1/day allowance as
  exhausted. On 2026-07-27, Kaggle accepted recovery submission `55030429`
  after `55029319` errored.

## V12 Portfolio Replay

- The full solution-blind replay materially favors diversity over another
  single-model specialist. Across all 16 tasks, mean full AUC was 0.80243 for
  rank-top-two, 0.79984 for portfolio CatBoost, 0.79930 for rank-all, 0.79679
  for the quick CatBoost baseline, and 0.79374 for LightGBM.
- Simulating the live public-feedback policy selected a candidate with mean
  0.80288 full AUC and 0.80379 private AUC. This was within 0.00003 of the
  per-task full-data oracle and beat v8 adaptive by 0.00276 on average, with 13
  task wins and 3 losses. Public selection did not create an aggregate private
  penalty in this fixed replay, although individual tasks still varied.
- Runtime is normally small (median portfolio time 10.8 seconds), but
  `train_11` took 859 seconds. The quick stage had already written a valid
  prediction before the expensive portfolio began. If the portfolio finishes
  with less than four minutes left, its controller skips those candidates; the
  Pro stage also stops below twelve minutes. Keep those guards unchanged.
- Detailed evidence is in `references/v12-portfolio-candidate-replay.csv`,
  `references/v12-portfolio-selection-replay.csv`, and
  `references/v12-portfolio-replay-summary.txt`.

## Leaderboard Notes

- Submission `55130084`: `COMPLETE`, public score **`0.822`**; v12
  deterministic portfolio plus bounded Gemini Pro freeroll. This improved the
  previous 0.819 live best and confirms that the newer skill-provided
  `run_skill_script` path executes successfully in the evaluator. Uploaded
  2026-07-31 after all 16 solution-blind replays completed and both
  source/extracted archives passed the official compiler.
  Archive SHA-256:
  `50dea3b9d661c9ef80eac505ddcade41a2a18596cbe704d34e0ffe4375eff34c`.
- Submission `55105170`: `COMPLETE`, public score **`0.810`**;
  `official-demo-v11-pick-best-plus-catboost` repaired v10's submission-choice
  flaw and used native categorical CatBoost with a 0.003 OOF promotion margin,
  but still regressed 0.009 from the v6/v9 live best. Do not promote this
  direction without broader replay evidence.
- Submission `55072857`: `COMPLETE`, public score **`0.808`** — a ~0.011
  regression and the worst completed score since the v4 demo baseline.
  `official-demo-v10-llm-plan-gated` was the first package to actually execute
  the LLM feature plan (v8/v9 implemented the machinery but never wired it to a
  prompt). The OOF gate worked as designed in local testing, but it guarded the
  wrong decision: it bounded plan-vs-baseline *features* inside `autopredict.py`
  while the prompt simultaneously pushed `autopredict.py`'s CatBoost-primary
  output into the session's submission pool, and instructed the agent to submit
  it even when the gate rejected the plan. See the Ensembling section — the
  removed v9 `engineered_features` guard existed to prevent exactly this. Do not
  build on v10; revert to the v6 / v9-pick-best lineage.
- Submission `55045683`: `COMPLETE`, public score `0.819`; `official-demo-v9-pick-best-model` (pairwise interactions + pick-best-of-4-models-by-OOF-AUC) tied v6 exactly despite scoring higher offline (0.828 vs 0.826 average on `train_01`–`train_03`). Submitted 2026-07-28 after being blocked by the daily quota since 2026-07-25. Reinforces the existing note below that the 3-folder sample is too small to reliably discriminate small AUC differences — treat ~0.002 offline deltas on that sample as noise, not signal, for future close calls.
- Submission `55030429`: `COMPLETE`, public score `0.818`; v9 (v5-shell adaptive recovery) restored the v5 control shell and made
  adaptive feature engineering optional after the first valid submission, but did not improve on v6.
- Submission `55029319`: `ERROR`; `Agent completed without submitting any valid
  predictions (submit_predictions was never called).` Kaggle refunded its
  2026-07-27 slot.
- Submission `55011609`: `COMPLETE`, public score `0.818`; the model-recipe prompt did not improve on v6.
- Submission `54972472`: `COMPLETE`, public score `0.819`; `official-demo-v6-blended-baseline` is the current live best.
- Submission `54491451`: `ERROR`, detailed API message `Agent completed without submitting any valid predictions (submit_predictions was never called).`
- Submission `54491555`: `ERROR`, detailed API message `Tool 'run_skill_script' not found in registry.`
- Submission `54491615`: `ERROR`, detailed API message `Agent completed without submitting any valid predictions (submit_predictions was never called).`
- Submission `54491765`: `COMPLETE`, public score `0.815`; this is the extracted official demo package and current live baseline.
- v5 upload attempt `official-demo-v5-model-recipe-no-run-skill-script`: generic `400 Bad Request`, no submission row created.
- Leaderboard snapshot on 2026-07-09 after `54491765`: first page ranged from `0.825` down to `0.815`; Giovanni Marco Dall'Olio appeared with score `0.815`.
- Public feedback during a session can guide final selection, but do not design a strategy that depends on probing or overfitting public rows.
- Live Kaggle metadata reported a 1/day submission limit on 2026-07-26, superseding the older 5/day workspace note.
