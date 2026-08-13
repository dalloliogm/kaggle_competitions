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

## V13 LLM Planner Opportunity Screen

- A target-blind LLM planner has something real to choose: the hindsight-best
  single feature family improved mean held-out AUC by 0.00280 across the 16
  official tasks and improved 15 tasks. This is a ceiling, not a deployable
  policy, because it uses solutions only after prediction to identify the best
  family.
- OOF argmax captured less than half the ceiling (+0.00131 held-out mean), and
  the seemingly strict gate (at least +0.0015 OOF, all 3 screen folds positive,
  no fold below -0.002) still accepted two harmful false positives out of three
  accepted tasks. Fold consistency under one CV seed is not enough.
- Frequency counts were the only broadly positive universal family (+0.00082
  mean held-out AUC). Signed logs were approximately neutral; missingness,
  interactions, polynomial terms, and row statistics regressed on average even
  though some had large task-specific wins.
- The next safety layer should require repeat-seed and cross-model agreement.
  Prompt cleverness cannot repair a noisy promotion statistic.
- The v13 executor gates the final planned model directly against the best
  deterministic portfolio OOF prediction. A rejected plan writes no CSV and is
  never offered to `submit_predictions`, fixing v10's wrong-level gate.
- The 3-seed × 3-model follow-up produced 882 task/model/seed/family rows. A
  strict agreement rule (mean OOF gain >= 0.0015, at least 7/9 positive runs,
  all three model means positive, all three seed means positive, and a
  non-negative weakest-model mean) retained only `train_10` signed logs and
  `train_13` frequency features. Both had positive mean held-out gains.
- Adding the correct final-model comparison retained only `train_13` frequency
  features with logistic regression: +0.00654 three-seed OOF and +0.00281
  three-seed held-out AUC versus the best baseline model. Spread over all 16
  tasks, that is only about +0.00018, so the LLM branch is a rare specialist.
- Model diversity mattered more than seed repetition alone. A cheaper HGB +
  ExtraTrees audit still admitted one false positive when selecting the final
  model; adding one-hot logistic removed it, but made several task audits take
  minutes. Replacing logistic with a faster diverse auditor is the next design
  problem.
- Kaggle notebook version 1 ran for 3,403 seconds, completed 12/16 tasks, then
  died without a model traceback (`DeadKernelError`). Long replay cells must
  checkpoint after every task. The two-seed subset retains the same two stable
  families and final positive specialist as the three-seed audit, while cutting
  expected hosted runtime by roughly one third.
- Version 2 disproved wall time as the main failure mode: it reached the same
  task boundary in only 1,999 seconds and checkpointed 468 rows before the
  kernel died. `gc.collect()` could not release model-library allocations still
  retained by the process. Run each task in a fresh worker process; process exit
  gives Kaggle a hard memory-reclamation boundary between schemas.
- A failed notebook-push helper must not be followed by a blind direct push of
  its staging directory: the folder may still contain an older version. After
  any helper failure, copy the notebook and metadata explicitly and inspect the
  staged code (or pull the remote source) before pushing with `uvx kaggle`.
- Fresh forked workers fixed cumulative memory retention and carried hosted v4
  through `train_13`, but `train_14` still produced a native exit `-11`. A
  tutorial notebook should not make a 30+ minute native-library stress test its
  default save path. Embed the exact completed audit for stable rendering and
  keep expensive recomputation explicit and opt-in.
- Hosted notebook version 5 confirmed that design: it completed in seconds and
  emitted an 882-row CSV exactly equal to the completed local audit, with 16
  tasks, 3 model families, 3 seeds, and finite numeric values.

## Public Freeroll Reproduction and Model Choice

- Our v12 was not an exact reproduction of Naji's public 0.823 package. It
  lowered Pro temperature from 0.7 to 0.55, halved the thinking budget from
  4096 to 2048, capped the loop at eight iterations, restricted feature
  families, forbade target-derived features, and added tighter file/command
  guards. Those changes improved safety and auditability but confound any
  comparison with the public 0.823 result.
- The 2026-08-02 official `models.yaml` permits Anthropic, Google, open-source,
  xAI, and Qwen models. It does not list a frontier hosted OpenAI GPT model;
  only `gpt-oss-20b` and `gpt-oss-120b` are available from OpenAI's family.
- `claude-sonnet-5` is the cleanest higher-capability challenger under the $4
  session budget: $2/M input and $10/M output, compared with Gemini 3.1 Pro
  Preview at $2/M input and $12/M output. Claude Opus 4.5-4.8 is allowed but
  costs $5/M input and $25/M output, which sharply reduces iteration room.
- Stronger on general benchmarks does not imply stronger here. The freeroll's
  critical behavior is reliable tool use, safe Python editing, and rapid
  feedback-driven iteration. Run the exact Gemini package as the control before
  spending a separate daily slot on the Claude-only swap.
- The pulled public notebook exposes no explicit license. Preserve attribution,
  avoid publishing unattributed derivatives, and prefer static extraction plus
  official compiler validation over executing the third-party agent locally.

## Headroom Analysis (2026-08-02, offline, zero slots spent)

Computed directly from `references/v12-portfolio-candidate-replay.csv` (16 tasks
x 7 candidates) plus fresh runs on the downloaded practice data. These bound how
much is left in the current approach, and they are mostly negative results.

- **Candidate selection is saturated — stop working on it.** Over v12's pool:
  always-`rank_top2` private mean 0.80348; selecting by public feedback 0.80379
  (+0.00031); selecting by solution-blind CV 0.80369; a cheating oracle 0.80401.
  So the *entire* selection apparatus has a ceiling of **+0.0005**, and the
  realized gain (+0.0003) sits below the ~0.0004 single-task noise floor. Public
  and CV selection each pick the private-optimal candidate on only 10/16 tasks.
  No gate, margin, or feedback rule can be worth much here.
- **Public-feedback selection is partly an illusion.** It buys +0.00060 on the
  public half but only +0.00031 on private, so **+0.00029 of the public gain does
  not transfer.** Leaderboard positions may be inflated by how aggressively a
  team selects on public feedback; the prize-relevant private ranking is a
  different session. Do not chase public-score deltas of this size.
- **The candidates are highly correlated, so adding another GBDT is futile.**
  Mean per-task max-min spread across all 7 candidates is 0.0831, but that is
  driven almost entirely by `logistic`; excluding it the spread collapses to
  **0.0215**. `catboost`, `lightgbm`, `quick`, `rank_all`, and `rank_top2` are
  near-duplicates in ranking terms.
- **Multi-seed averaging helps only very small tasks.** Same folds/params,
  3 seeds vs 1 (CatBoost, native categoricals): train_13 (500 rows) **+0.0037**,
  train_15 (500 rows) **+0.0052**, train_05 (1060) -0.0002, train_09 (1109)
  -0.0019, train_03 (3501) -0.0001, train_16 (1809) +0.0001. Gated to roughly
  n_train < 800 this is worth about **+0.0006 on the 16-task mean** — real, but
  small. Ungated it is noise.
- **v12 has no runtime cap.** `run_portfolio.py` measures elapsed time but never
  bounds it; the `train_11` portfolio took **859 seconds**. This is an unguarded
  tail risk on a larger hidden task, and probably matters more than any of the
  AUC deltas above.
- **Net:** no lever currently in evidence reliably buys the ~+0.004 needed to go
  from 0.822 to the 0.826+ range. Treat further single-slot modeling tweaks as
  roughly coin flips, and prioritize the final-submission choice (private,
  different session) over public-score chasing.

## v15 Seed-Bagging And Runtime Cap (2026-08-03, offline)

- **A latent failure mode in the live-best package: `pandas` 3.x silently
  destroys categorical handling.** `common.py` reads CSVs with
  `pd.read_csv(..., engine="pyarrow")`. Under pandas 3.x that returns the new
  pyarrow-backed `str` dtype, which `categorical_columns()` does not recognise,
  so it returns `[]`: CatBoost gets no `cat_features`, LightGBM gets no
  `categorical_feature`, and the logistic candidate crashes on its numeric
  imputer. Measured effect on train_13: **0.639 -> 0.503** (random). Under
  pandas 2.3.3 the same code returns `object` and reproduces the recorded replay
  exactly. Kaggle's image is currently on pandas 2.x so v12/v13/v15 are fine
  today, but a base-image upgrade would silently gut every categorical task.
  Any future package should type-check features explicitly rather than relying
  on `object` dtype. Pin `pandas<3` in any local replay environment or the
  numbers are meaningless.
- **Seed-averaging does not survive contact with the portfolio.** Standalone
  CatBoost gained +0.0037 (train_13) and +0.0052 (train_15) from 3-seed
  averaging, but inside the v12 portfolio the *selected* candidate gained only
  +0.0016 on train_13 and -0.00001 on train_15. The reason is that the selected
  candidate is almost always a rank blend (`rank_top2`/`rank_all`), and
  averaging across models already performs the variance reduction that
  averaging across seeds would provide — the two are substitutes, not
  complements. Expected gain over the 16-task mean is roughly +0.0001, i.e.
  below the ~0.0004 noise floor. Do not expect a live gain from this.
- **The 859-second train_11 portfolio was environment-specific, not intrinsic.**
  The same task ran in 79 seconds here on the same code. The tail risk is real
  but smaller than the recorded figure suggested.
- **A hard runtime cap is nearly free.** Capping train_11 at 25 seconds (vs 79
  unbounded) skipped `extra_trees` and `logistic` for budget, still produced
  four valid candidates, and moved the selected candidate only 0.82662 ->
  0.82650. Because the portfolio runs strongest-first, the models a cap drops
  are the ones that were not going to be selected anyway.
- Net: v15 is best understood as **insurance, not a score improvement** — it
  behaves identically to v12 above 800 training rows and buys bounded runtime
  at a cost of ~0 AUC.

## Saturation Evidence (2026-08-03) — six independent levers, all null

Measured on the real 16-task practice data with a harness verified to reproduce
the recorded v12 replay exactly. Every remaining idea was tested and none beats
v12/v13. Recorded so nobody spends another slot rediscovering this.

| Lever | Measured effect | Note |
| --- | --- | --- |
| Candidate selection / gating | **+0.0005 ceiling** (cheating oracle) | realized +0.0003, below noise |
| LLM feature planner (v13) | **+0.00018** | live 0.822, tied v12 |
| Multi-seed averaging (v15) | **+0.0001** on 16-task mean | rank blending is a substitute |
| CatBoost hyperparameter tuning | **-0.00104** | 25-trial Optuna, inner-CV overfit |
| Pseudo-labelling / transductive | **-0.00015** | no confident rows where it matters |
| Extra gated model class (v11) | **live -0.009** | synthetic gain did not generalize |

- **Hyperparameter tuning actively hurts.** 25-trial Optuna on CatBoost, tuned on
  solution-blind inner 3-fold CV: train_13 +0.00088, train_03 +0.00026, train_08
  +0.00093, but train_05 **-0.00622**, for a mean of **-0.00104**. The tuner wins
  the inner CV and loses the test set. v12's hand-picked constants are not a
  weakness — at this data scale they are near the useful limit.
- **Pseudo-labelling cannot help the tasks that need it.** For small tasks the
  test set dwarfs train (train_13: 500 train vs 10,000 test), which looks like
  free signal. But at a 0.90 confidence threshold, train_13, train_05 and
  train_09 yielded **zero** confident test rows, because their AUC is only
  0.64-0.68. Confidence-based semi-supervision needs a confident model, and the
  weak tasks are weak precisely because the signal is low. Where it did apply it
  was noise (train_16 +0.00056, train_15 -0.00085).
- **Conclusion: the tabular modelling is saturated at this data scale.** Six
  independent levers all land inside +/-0.001 while the gap to the leaderboard
  top is ~0.008. That gap is unlikely to be a modelling gap we can close by
  tweaking; with 440 teams scored on a single public mini-competition, the top
  of the public board is partly an order statistic over noisy draws. Our own
  reasonable packages span 0.818-0.822 with no clear modelling difference
  between several of them, which is a rough gauge of per-session noise.
- **Practical implication:** stop spending slots on modelling variants. The
  private leaderboard is a *different session*, so the prize-relevant decision
  is which two packages become finals, not squeezing +0.001 out of the public
  score.

## Finals Selection (2026-08-04) — the mechanic, and what it implies

- **The two-session mechanic, stated exactly.** From the official description:
  "Each agent submission runs through two mini-competition sessions, one that
  populates the Public Leaderboard and another that populates the Private
  Leaderboard." So **every submission already has a private score**, computed in
  its own separate agent session and hidden from us. Selecting finals does not
  cause anything to be re-run; it only chooses which two already-computed
  private results count.
- **Consequence: a submission's public score is a weak predictor of its own
  private score.** The two come from independent agent sessions with independent
  LLM stochasticity. The naji-exact reproduction already showed the size of that
  noise directly (identical code, reported 0.823, scored 0.822 here). So among
  packages whose public scores sit inside the noise band — v12, v13, v15 and the
  naji-exact all at 0.822, Sonnet at 0.821 — **the public ranking carries almost
  no information about which will do better privately**. Do not pick finals by
  public score; pick by expected package quality plus completion reliability.
- **There is no Kaggle API for selecting final submissions.** Checked directly:
  `KaggleApi` exposes no such method (`_select_models_interactively` is
  unrelated, it is for Kaggle Models). Finals must be selected in the web UI, on
  the competition's *My Submissions* page, before the deadline. If the user
  selects nothing, **Kaggle auto-selects** — by best public score, which given
  the point above is effectively an arbitrary tie-break among our 0.822s.
- **v15 dominates v12 by construction, so it replaces v12 as the first pick.**
  Diffed the two packages directly: they differ only in `agent.yaml`'s `name`
  and in `run_portfolio.py`. At or above 800 training rows v15 executes the same
  single-seed code path as v12, i.e. it *is* v12 there. Below 800 rows it adds
  the measured-positive 3-seed bag (+0.0037 and +0.0052 on the two 500-row
  tasks). It also adds the wall-clock `Deadline` that v12 lacks — the tail risk
  flagged above, where `train_11` ran 859 unbounded seconds. So v15 is weakly
  better on score and strictly better on tail behaviour, and it has *already
  proven it completes live* (55214880, 0.822).
- **Second pick is for package-level risk, not for score.** The private
  mini-competition is different data. Two draws of one package share any
  systematic misfit to that data; two different packages do not. v13's
  target-blind JSON planner is the most mechanistically distinct of the strong
  packages (LLM planner vs deterministic portfolio), and it completed live at
  0.822.
- **Recommended finals: `55214880` (v15) and `55171041` (v13).** This supersedes
  the earlier "v12 + v13" recommendation; the change is v15 in place of v12, on
  the dominance argument above.
- **Why more submissions cannot help much.** With two finals, the private board
  shows the better of the two. Selecting any two independent, equal-quality
  draws gives the same expectation (about `mu + 0.56*sigma` for two iid draws).
  We already hold five completed packages inside the noise band, so an extra
  slot adds essentially nothing to the expected private score. That is the
  honest reason the remaining slots are low-value — not that they are wasted,
  but that no available action moves the expectation.

## Identical-Code Variance Run (2026-08-05, submission `55253408`)

- **What it is.** `official-demo-v12-portfolio-pro-freeroll` resubmitted with no
  change whatsoever, to send identical code through a fresh public agent session
  and measure session-to-session noise *directly*. Every score comparison in this
  workspace has been assuming a ~+/-0.002 band inferred from indirect evidence;
  this measures it.
- **Identity verification matters more than the archive hash here.** The zip
  sha256 is `79343a23...` and **cannot** match the original `50dea3b9...`,
  because zip entries embed file mtimes and a git checkout rewrites them. The
  meaningful check is content: all 13 files sha256-match the package folder,
  which git confirms is untouched since commit `c0b6312` — the commit that
  recorded the original 0.822. Anyone re-running this must verify by content.
  The archive was also rebuilt to carry the original's 6 explicit directory
  entries, so that archive structure was not left as an uncontrolled difference
  in an experiment whose premise is that nothing changed.
- **Pre-registered expectation: ~0.822 +/- 0.002**, i.e. 0.820-0.824. Recorded
  before the result so the outcome could not be rationalised afterwards.
- **RESULT: `0.822`, completed 12 minutes after upload — inside the band, and at
  its exact centre.** Identical code, fresh public session, identical reported
  score.
- **What this does and does not establish.** The leaderboard reports three
  decimals, so two runs both reading 0.822 means both landed in `[0.8215,
  0.8225)` — the pair differs by **less than ~0.001**. That is a *tighter* bound
  than the +/-0.002 the workspace has been assuming, and it points to
  session-to-session noise being at the small end of that band rather than the
  large end. But this is **one paired observation**: it bounds this pair, it does
  not estimate a standard deviation, and a single pair landing in one rounding
  bucket is also consistent with occasional larger excursions. Do not restate
  this as "noise is under 0.001" — state it as one identical-code pair that
  reproduced.
- **It weakens, rather than confirms, the naji-exact noise reading.** LEARNINGS
  previously treated the public notebook's reported 0.823 versus our 0.822 for
  the same package as direct evidence of ~0.001 session noise. Now that our *own*
  identical-code rerun reproduced its score exactly, pure session noise is a less
  comfortable explanation for that 0.823/0.822 gap; a package-version or
  reporting difference on the public notebook's side is at least as plausible.
  The honest position is that the naji gap is unexplained, not that it measures
  noise.
- **Practical implication, and it points the same way as before.** If
  identical-code noise really is small, then v12, v13, v15 and the naji-exact
  package all landing on 0.822 is more likely to mean those packages are
  *genuinely equivalent* on the public subset than that noise is masking real
  differences. Either way the conclusion is unchanged: the public score cannot
  discriminate them, so finals must be chosen on mechanism and robustness. Small
  noise also *shrinks* the `mu + 0.56*sigma` benefit of holding two independent
  draws, which is a further reason the remaining slot has little expected value.
- **Scope limit worth keeping straight.** This measures session noise on the
  *public* subset only. The public/private difference is not the same quantity:
  it combines a different session *and* a different subset of test labels, so a
  small public-session noise does not imply the private score will sit near the
  public one.

## v16 Dtype Hardening (2026-08-05, offline, measured on all 16 practice tasks)

- **The pandas-3 failure is much larger than previously recorded.** LEARNINGS had
  it as "train_13: 0.639 -> 0.503". Measured properly on pandas 3.0.5 vs 2.3.3,
  **12 of the 16 tasks lose every categorical column** — `categorical_columns()`
  returns `[]` because `read_csv(engine="pyarrow")` yields the arrow-backed `str`
  dtype instead of `object`. End-to-end quick-baseline AUC:

  | task | v15 / pandas 2 | v15 / pandas 3 |
  | --- | --- | --- |
  | train_06 (all 9 features text) | 0.80759 | **0.50000** |
  | train_08 (all 12 features text) | 0.85119 | **0.50000** |
  | train_13 | 0.63233 | 0.50510 |
  | train_15 | 0.84435 | 0.59656 |

  In the full portfolio the same break also *errors out* candidates outright —
  `logistic` dies with "Cannot use median strategy with non-numeric data" and
  `extra_trees` with "invalid or constant OOF predictions".
- **Two fixes were needed, not one.** The dtype predicate was the obvious half.
  The other half is that `cv_logistic` is the one candidate fed the **raw**
  frame, bypassing `native_frames`/`encoded_frames`, so fixing detection alone
  still left it different.
- **The subtle part: the missing-value sentinel has to be `None`, not `np.nan`.**
  Under pandas 2 + pyarrow, object columns carry `None` for missing.
  `SimpleImputer` detects NaN with `X != X`, which is **False for `None`**, so on
  the current image those entries are *never imputed* and reach `OneHotEncoder`
  as a category of their own. Normalising to `np.nan` "fixes" that — and thereby
  **changes** behaviour on the current image: measured logistic CV AUC on
  train_08 moved 0.85434 -> 0.84671. The hardening must reproduce pandas 2's
  quirks, not improve on them. Normalising to `None` restores exact equality.
- **`.to_numpy(dtype=object)` can be read-only on pandas 3.** Assigning into it
  raises `ValueError: assignment destination is read-only`, which surfaced as a
  silently-dropped `logistic` candidate. Copy explicitly.
- **Verification standard used: identical model inputs, not just similar
  scores.** Fingerprinted the native and encoded frames for all 16 tasks, plus
  every one of the six portfolio candidates' CV AUCs, the selected candidate, and
  the error dict on 4 tasks:
  - `v16 / pandas 2` == `v15 / pandas 2` — **exactly, all 16 tasks.** So
    submitting v16 to the current image is behaviourally indistinguishable from
    v15, which is what makes it safe to spend the last slot on.
  - `v16 / pandas 3` == `v15 / pandas 2` — **exactly, all 16 tasks.** The
    insurance actually works rather than merely avoiding a crash.
- **Live confirmation: `55283870` completed at 0.822** on 2026-08-06, tying v12,
  v13, v15 and the naji-exact package. The offline claim was that the hardening
  is behaviourally invisible on the current image; the live score is consistent
  with exactly that. Note what this does *not* show: a tie is also what a
  saturated leaderboard produces regardless, so the live result corroborates the
  offline fingerprints rather than independently proving equivalence. The
  fingerprints are the real evidence.
- **Caveat worth keeping.** This was validated against pandas 3.0.5 specifically.
  It is insurance against the *known* dtype-container change, not proof against
  every future pandas release. The `_coerces_entirely_to_nan` backstop is the
  part that is dtype-agnostic and should survive renames of the string dtype.

## FINAL OUTCOME (competition closed 2026-08-06) — read this before reusing anything here

**Final placement: 168 / 570, private score 0.780.** Winner scored 0.783; ranks
2-10 scored 0.782.

Every completed submission's private score, against its public score:

| ref | package | public | private |
| --- | --- | --- | --- |
| 55072857 | v10 llm-plan-gated ("a regression, do not build on v10") | **0.808** | **0.781** |
| 55283870 | v16 dtype-hardened | 0.822 | 0.780 |
| 55253408 | v12 variance rerun | 0.822 | 0.780 |
| 55224297 | naji-exact | 0.822 | 0.780 |
| 55214880 | v15 | 0.822 | 0.780 |
| 55171041 | v13 | 0.822 | 0.780 |
| 55130084 | v12 | 0.822 | 0.780 |
| 55183078 | v14 Sonnet | 0.821 | 0.780 |
| 55045683 | v9 pick-best | 0.819 | 0.780 |
| 54972472 | v6 blended | 0.819 | 0.780 |
| 55030429 | v9 shell | 0.818 | 0.780 |
| 55105170 | v11 CatBoost | 0.810 | 0.779 |
| 54491765 | v4 reference | 0.815 | 0.779 |
| 55011609 | v5 recipe | 0.818 | **0.778** |

- **Public score did not predict private score. At all.** Public spanned
  0.808-0.822 (0.014); private spanned 0.778-0.781 (0.003). The relationship is
  not merely weak, it is **inverted at the extremes**: the best private score we
  ever obtained, 0.781, came from **v10 — our worst public submission and the one
  this file explicitly recorded as a regression to abandon.** The worst private,
  0.778, came from v5 at a respectable 0.818 public.
- **The finals decision, which this workspace called "the remaining
  prize-relevant action", was worth nothing.** All seven packages at 0.822 public
  scored exactly 0.780 private. Any selection among them produced an identical
  result. The extensive v12-vs-v15-vs-v16 dominance reasoning was real
  engineering and correct on its own terms, but it optimised a quantity that had
  no effect on the outcome.
- **The gap from rank 1 to rank 168 is 0.003 — smaller than the spread across our
  own submissions (0.778-0.781).** So the private leaderboard is noise-dominated
  end to end. Placement here is close to a lottery over near-identical agents,
  and 168th versus 1st is not a 167-place quality difference.
- **What this invalidates.** The "six null levers" and "saturation" findings were
  directionally right but understated: it was not that we had exhausted the
  *public* headroom, it is that **none of the levers, including the ones that
  moved public score by +0.014, moved the private score at all.** A month of
  careful modelling, replay harnesses and package hardening produced zero
  measurable private improvement.
- **What was actually right.** Two calls hold up: stop spending slots on
  modelling variants (correct, though for a stronger reason than given), and
  never trust a ~0.001-0.002 public delta as signal (correct, and the true noise
  floor was even wider than the ±0.002 we settled on).
- **The transferable lesson for the next agent competition of this shape.**
  Before optimising, establish whether the evaluation can *discriminate* at all.
  Here, 570 teams were compressed into a 0.005-wide private band. When the metric
  cannot separate submissions, effort spent on model quality is unrecoverable,
  and the rational strategies are: submit early, submit something that reliably
  completes, and stop. The one genuinely valuable artefact produced was the
  dtype-hardening bug hunt (v16), because that guarded against a *catastrophic*
  failure mode (AUC 0.500), which is the only class of difference this evaluation
  was ever able to see.

## Public Notebooks Worth Learning From (reviewed 2026-08-12, post-close)

Pulled into `references/public-notebooks/`. Two are directly relevant, and one
of them corrects a conclusion recorded in this file.

### 1. Georgy Mamarin, "Your agent's selection policy is worth 0.0005 AUC"

`georgymamarin/your-agent-s-selection-policy-is-worth-0-0005-auc` — the most
valuable notebook in the competition for our purposes. Offline measurement over
all 16 training datasets against shipped `solution.csv`, no LLM in the loop.

- **Independently confirms our selection ceiling.** He measures the perfect
  hindsight oracle at **+0.00049**; our own replay put it at **+0.0005**. Two
  independent measurements, same number.
- **The asymmetry we missed entirely.** We framed selection as a prize worth
  chasing and concluded it was too small to bother with. He frames it correctly:
  the *upside* is +0.0005 but the **worst policy forfeits 0.01664** on train_13,
  thirty times the entire prize. Selection is about capping a downside, not
  chasing a gain — and we never measured the downside at all.
- **Concrete rule.** Pass **one** id to `select_submission`, or omit the call and
  let the harness take the two best public scores. Passing two ids chosen by CV
  lost 0.01664 on the 500-row task; passing one was never worse than 0.00098.
  Our v12 lineage already omitted `select_submission` (see its `PROVENANCE.md`),
  so we were on the right side of this — but by design intuition, not measurement.
- **External confirmation of our final-outcome finding.** He cites two published
  results: Krishna A at public 0.816 / private 0.779, and Jeki Wan Taufik at
  public **0.826** / private **0.779**. A public score *better than our best*
  (0.826 vs 0.822) produced a *worse* private score than ours (0.779 vs 0.780).
  Independent evidence that the public board was not a valid proxy.
- **CORRECTION to this file.** After the identical-code rerun (`55253408`)
  reproduced 0.822 exactly, the "Identical-Code Variance Run" section above
  reasoned that packages sharing a public score are therefore *"genuinely
  equivalent"*. Mamarin measures the opposite directly: two candidates the public
  half cannot separate sit a **median 0.00100 private AUC apart**, one pair in
  ten more than 0.00291, and **61% of apparent ties are real differences**. A
  public tie does not imply equivalence. Our packages did turn out equivalent
  (all 0.780), but the general inference recorded here was wrong.

### 2. prvsiyan, "The Pandas 3 Trap | Schema-Aware AutoML Agent"

`prvsiyan/the-pandas-3-trap-schema-aware-automl-agent`, published 2026-07-30 —
**a week before we built v16.** Found the same dtype bug independently and used
`pd.api.types.is_string_dtype(dtype)` as the guard.

- Our v16 went further in two respects: a dtype-agnostic backstop (a column with
  data that coerces entirely to NaN is text, whatever the dtype is called), and
  the `None`-vs-`np.nan` sentinel in the raw-frame logistic path, which
  `is_string_dtype` alone does not address.
- But the headline discovery was **not** ours and was public first. Lesson: check
  the public notebook list for a known-failure write-up *before* spending a day
  rediscovering it. We last pulled public notebooks on 2026-07-27 and never
  refreshed.

### 3. Unexplored: the official AIDE agent

`ryanholbrook/autonomous-agent-prediction-beta-aide-agent` (41 votes) is a
different agent architecture from the demo agent we forked for every single
submission. We never evaluated it. Every one of our 19 submissions descends from
the same demo skeleton, which is a real diversity failure given that the private
metric could not separate our variants anyway.

## Leaderboard Notes

- Submission `55224297`: `COMPLETE`, public score **`0.822`** — and this is the
  single most informative submission in the workspace, because it is a *verbatim*
  extraction of a public notebook that reports **0.823**. Running the same
  package produced a different score. That is direct, controlled evidence that
  ~0.001 differences on this leaderboard are **session noise, not strategy**:
  identical code, identical configuration, different number.
- It also closes the LLM-governance question. The package is byte-identical to
  our v12 pipeline except that its Pro stage is unconstrained — permissive
  prompt explicitly inviting target encoding and y-derived features, temperature
  0.7 vs 0.55, thinking budget 4096 vs 2048. It scored exactly what the
  constrained version scores. **How the LLM freeroll stage is governed does not
  measurably affect the score**, in either direction: the constraints in v12 cost
  nothing, and removing them gains nothing.
- Four packages, four different mechanisms, one score: deterministic portfolio
  (v12) 0.822, constrained LLM planner (v13) 0.822, variance-reduced portfolio
  (v15) 0.822, unconstrained LLM freeroll (public exact) 0.822. Combined with the
  six null levers, treat the public score as saturated for this family of
  approach and stop reading ~0.001-0.002 movements as signal.

- Submission `55214880`: `COMPLETE`, public score **`0.822`** — `v15
  seedbag+timecap` ties v12 and v13 at the live best. This is the first
  prediction in this workspace that was made *before* submitting and then held:
  the offline analysis said v15 is identical to v12 above 800 training rows and
  worth ~+0.0001 below it, so 0.820-0.823 was called out in advance as the
  "no change" band. Landing at 0.822 confirms both the package's safety property
  and that the 16-task replay harness now predicts live behaviour well enough to
  screen candidates without spending slots.
- The tie also adds a third independent data point to the saturation evidence: a
  deterministic portfolio (v12), an LLM feature planner (v13), and a
  variance-reduced portfolio (v15) all land on exactly 0.822.

- Submission `55180862`: `ERROR`; the first Sonnet package failed before agent
  execution because the OpenAI-compatible proxy rejects the `temperature` field
  for Claude Sonnet 5. LiteLLM retried the same invalid request 100 times.
  Remove `temperature` as well as `top_p`/`top_k` from the provider-specific
  config before retry. Corrected retry submission `55183078` is now `PENDING`.
  The exact Gemini control remains unaffected.
- Submission `55171041`: `COMPLETE`, public score **`0.822`**; v13 target-blind JSON feature planner over
  the proven v12 quick/portfolio fallbacks. Uploaded 2026-08-01 after archive,
  include/tool, extracted-Python, and 10,000-row portfolio-output validation.
  Archive SHA-256:
  `17ca4e362835c5001f3f1ec011ee2bd331353fcb597c6fc25982ce6621582b8d`.
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
