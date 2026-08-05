# Tasks

## Current Goal

- Submission `55214880` (`official-demo-v15-seedbag-timecap`) uploaded 2026-08-03,
  consuming the day's slot. Archive sha256 `bc0d88ac...`. It is v12 plus 3-seed
  averaging gated to tasks under 800 training rows and a hard wall-clock deadline
  checked between folds. **Submitted as runtime insurance, not an expected score
  gain**: offline it is identical to v12 above the threshold and worth roughly
  +0.0001 on the 16-task mean below it. **Completed at 0.822**, tying v12 and
  v13 and matching the pre-registered "no change" band (0.820-0.823) exactly.
- Six independent levers were measured on 2026-08-03 and all came back null or
  negative (see LEARNINGS "Saturation Evidence"). Do not spend further slots on
  modelling variants without new evidence.
- **Submitted 2026-08-04 as `55224297`: `public-naji-v14-gemini-pro-exact`**
  (archive sha256 `4fe5ea5c...` re-verified byte-for-byte at upload, agent name
  `weighted_cv_pipeline_with_pro_freeroll` and Pro temperature 0.7 both
  confirming the unconstrained variant). **Completed at 0.822** — the public
  notebook reports 0.823 for this exact package, so the reproduction proves
  ~0.001 leaderboard gaps are session noise. Unconstrained LLM governance ties
  v12's constrained version.
  Diffing it against our v12 showed the two are the *same pipeline*:
  `common.py` and `quick_baseline.py` are byte-identical, and `run_portfolio.py`
  differs only in scaffold comments plus two CatBoost kwargs. The entire
  difference is Pro-stage governance — v12 forbids target encoding and any
  y-derived feature and caps the agent at one unsupervised family per iteration,
  while the public version tells an "elite Kaggle Grandmaster" to iterate freely,
  at temperature 0.7 vs 0.55 and thinking_budget 4096 vs 2048. So this slot
  tests **unconstrained vs constrained LLM feature engineering**, which is the
  open question v13 only answered for the constrained case. Note the public
  0.823 is within the ~±0.002 session noise of our 0.822: expect a variance
  outcome, not a gain.
- **OPEN — USER ACTION REQUIRED, deadline 2026-08-06 23:59 UTC: select the two
  final submissions in the Kaggle web UI.** There is **no API for this** —
  verified against `KaggleApi`, which exposes no finals-selection method — so it
  cannot be automated from this workspace. Go to the competition's *My
  Submissions* page and select:
  - **`55214880`** — `official-demo-v15-seedbag-timecap`, public 0.822
  - **`55171041`** — `official-demo-v13-profile-planner`, public 0.822

  If nothing is selected, Kaggle auto-selects by best public score, which is an
  arbitrary tie-break across our five packages that all sit inside the noise
  band.

  **This replaces the earlier `55130084` (v12) + `55171041` (v13)
  recommendation.** The change is v15 in place of v12, on a dominance argument
  verified by diffing the two packages on 2026-08-04: they differ only in
  `agent.yaml`'s `name` field and in `run_portfolio.py`. At or above 800
  training rows v15 runs the identical single-seed path, i.e. it *is* v12 there;
  below 800 rows it adds the measured-positive 3-seed bag (+0.0037 / +0.0052 on
  the two 500-row tasks); and it adds the wall-clock deadline v12 lacks, closing
  the unbounded-runtime tail risk (v12's `train_11` portfolio ran 859 seconds).
  Both packages completed live at 0.822, so v15 is weakly better on score,
  strictly better on tail behaviour, and equally proven. `55171041` is kept as
  the second pick for package-level diversification, not for its score: the
  private mini-competition is different data, and v13's target-blind JSON
  planner is the most mechanistically distinct strong package we have.
  See LEARNINGS "Finals Selection" for the full argument.

- Reproduce the public 0.823 Gemini Pro freeroll exactly, then isolate whether a
  model-only switch to `claude-sonnet-5` improves it. Both v14 packages are
  built and pass the official compiler. The user chose Sonnet first: submission
  `55180862` failed before agent execution because Claude rejected the
  `temperature` field. Corrected retry `55183078` is now `PENDING`, and the
  exact Gemini control remains unsubmitted.
- Submission `55171041` (`official-demo-v13-profile-planner`) completed at
  **0.822**, tying v12 rather than improving it.
- Preserve and understand the new live best, submission `55130084`
  (`official-demo-v12-portfolio-pro-freeroll`, public score **0.822**), while
  keeping the exact validated archive and replay evidence reproducible.
- Submission `55011609` (`official-demo-v5-model-recipe-retry-20260726`) completed at 0.818 and did not improve on v6.
- Submission `55029319` (`official-demo-v8-adaptive-feature-gate-llm-advisory`)
  errored because `submit_predictions` was never called.
- Submission `55030429` (`official-demo-v9-v5-shell-adaptive-recovery`) completed 2026-07-27 at `0.818`; did not improve on v6.
- Submission `55045683` (`official-demo-v9-pick-best-model`, a separate branch built 2026-07-25, queued behind the daily quota until today) completed 2026-07-28 at `0.819` — **tied v6 exactly** despite scoring higher offline (0.828 vs 0.826 on the 3-folder sample). See LEARNINGS.md/APPROACHES.md: this is evidence the 3-folder offline sample can't reliably discriminate small AUC deltas; prefer the full 16-task replay set for future close calls.

- Submission `55072857` (`official-demo-v10-llm-plan-gated`) completed
  2026-07-29 at **`0.808`** — a regression, and it consumed the 2026-07-29 slot.
  The LLM plan really did execute this time, but the package pushed
  `autopredict.py`'s CatBoost-primary output into the submission pool and told
  the agent to submit it even on a gate rejection. Do not build on v10.
- Submission `55105170` (`official-demo-v11-pick-best-plus-catboost`) completed
  2026-07-30 at **`0.810`**. It repaired v10's candidate-selection flaw by
  placing CatBoost inside the proven pick-best selector, but the synthetic
  categorical gain did not generalize to the hidden evaluation. Do not promote
  CatBoost into the live default from these local regimes.
- The 2026-07-31 quota refresh was verified live: **0 used, 1 remaining**.
  `official-demo-v12-portfolio-pro-freeroll` passed source and extracted-ZIP
  compilation, then completed a solution-blind replay over all 16 official
  tasks. Public-selected full AUC averaged **0.80288** and private AUC averaged
  **0.80379**, improving on the previous best full replay (v8 adaptive,
  0.80013). Submission `55130084` completed at **0.822**, improving the
  previous live best by 0.003; today's quota is now exhausted.

## Next Experiments

- Revalidate the corrected Sonnet package, then ask before resubmitting it. At
  the next daily reset, submit
  `public-naji-v14-gemini-pro-exact` as the required control. Do not infer model
  quality from Sonnet versus v12: the exact public strategy also differs
  materially from our bounded v12 derivative.
- Do not use Claude Opus for this freeroll. It is allowed, but its official
  $5/M input and $25/M output pricing is too expensive for the $4 session
  budget. `claude-sonnet-5` is the credible higher-capability budget match.
- **SUBMITTED 2026-08-05 00:23 UTC as `55253408`: the identical-code `v12`
  variance measurement.** This consumed the day's slot (`0 submissions remaining
  today` confirmed at upload); one slot remains, on 2026-08-06.
  - **Verification performed at upload.** The archive was rebuilt from
    `agent-configs/official-demo-v12-portfolio-pro-freeroll/`, which `git status`
    and `git log` confirm is unchanged since commit `c0b6312` — the commit that
    recorded the original 0.822 as `55130084`. All 13 files were sha256-compared
    against that source and match. `agent.yaml` sits at the archive root with
    `name: v12_portfolio_pro_freeroll`, and `configs/sampling_pro.yaml` reports
    `temperature: 0.55` with `thinking_budget: 2048`, both confirming the
    constrained variant rather than the unconstrained public one. The extracted
    archive additionally passes: all scripts compile, all YAML parses, and all
    six `!include` targets resolve relative to their including file.
  - **Archive structure was matched to the original deliberately.** The first
    rebuild produced 13 file entries and no directory entries. The original
    upload carried 19 entries — 13 files plus 6 explicit directory entries — so
    the zip was rebuilt to include them. Content equality is what matters for
    the measurement, but leaving a structural difference in place would have
    been an uncontrolled variable in an experiment whose whole point is that
    *nothing* changed. Final archive sha256
    `79343a2345c76bd6176f80bba83aabb045d7b51fe7c0cc851cda91a167a223c5`.
  - **The zip hash does not and cannot match the recorded
    `50dea3b9d661c9ef80eac505ddcade41a2a18596cbe704d34e0ffe4375eff34c`**, because
    zip entries embed file mtimes and a git checkout rewrites them. Verify this
    package by content, never by archive hash.
  - **Expected result ~0.822 +/- 0.002.** Anything outside 0.820-0.824 would
    have been the real finding, because every score comparison in this workspace
    assumes that noise band.
  - **RESULT: `0.822` — `COMPLETE` 12 minutes after upload, inside the band and
    at its exact centre.** Identical code reproduced its score. Since the
    leaderboard shows three decimals, the two runs differ by less than ~0.001,
    which is tighter than the assumed +/-0.002 — but this is one paired
    observation and does not estimate a standard deviation. See LEARNINGS
    "Identical-Code Variance Run" for what it does and does not establish,
    including that it makes the naji-exact 0.823/0.822 gap *harder* to explain as
    session noise rather than easier.
- **Set expectations honestly: this slot could not meaningfully raise the
  expected private score.** With two finals the private board shows the better of
  the two, and any two independent equal-quality draws have the same
  expectation. We already held five completed packages inside the noise band. The
  slot was spent for the measurement, not for a gain.
- **Submissions `55130084` (v12) and `55214880` (v15) are complete at 0.822.**
  Beyond the single deliberate variance run above, do not resubmit either.
- **2026-08-06 slot: STAGED — `official-demo-v16-dtype-hardened`.** The user chose
  on 2026-08-05 to spend the final slot on dtype hardening rather than hold it or
  take a third variance draw. `submissions/submission.zip` holds v16, sha256
  `51a44e9e8ce049ea685af8ac2cdd78f41bb23050bbc04b1094b99ae11622b15e`, 19 entries
  / 13 files matching the v15 layout, `agent.yaml` name `v16_dtype_hardened`, Pro
  temperature 0.55, scripts compile, YAML parses, all `!include` targets resolve.
  - **Why it is safe to spend the last slot on.** v16 is v15 plus dtype-container
    handling only — no modelling change. Verified as *identical model inputs*:
    frame fingerprints match v15 exactly on all 16 tasks under pandas 2.3.3, and
    the full portfolio's six candidate CV AUCs, selected candidate and error dict
    match on train_03/06/08/15. On the current Kaggle image it is
    indistinguishable from the package that scored 0.822.
  - **What it buys.** Under pandas 3.0.5, v15 collapses on 12 of 16 tasks —
    train_06 and train_08 fall to AUC **0.500** and two candidates error out. v16
    reproduces the pandas-2 results exactly there. This is insurance against a
    base-image upgrade between now and whenever the private sessions run.
  - **Selection rule: only make v16 a final if it completes at ~0.822.** If it
    errors or drops, keep `55214880` (v15) + `55171041` (v13).
- **Submit at the 2026-08-06 00:00 UTC reset.** Deadline 2026-08-06 23:59 UTC, so
  submit early — the last run took 12 minutes, but leave room for a retry.
- If the LLM-plan idea is revisited, restructure it so the plan changes the
  features used by the **agent's own ensemble script** (the pick-best-of-K
  selector), rather than introducing `autopredict.py` as a second submission
  candidate. Keep v9's rule: submit the optional candidate **only** when it shows
  positive evidence of being better, never "once anyway."
- Do not retry the v11 gated-CatBoost direction without broader replay evidence.
  Its native-categorical view and 0.003 OOF promotion margin improved the
  selected synthetic categorical task, but the live score still fell to 0.810.
- Deadline is 2026-08-06; roughly one slot per day remains. Prefer one
  well-motivated change per slot over compounding several.

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
- Replayed the v12 quick baseline and deterministic six-candidate portfolio on
  all 16 official tasks with `solution.csv` absent from every modeling
  directory. Saved 112 candidate scores, public/private selection diagnostics,
  and the scorer under `references/v12-portfolio-*`.
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
- Built the local v13 target-blind JSON planner prototype on 2026-08-01:
  - retained v12 quick/portfolio fallbacks;
  - added a solution-blind predictor profiler and strict one-family JSON DSL;
  - gated the actual planned model against the best portfolio OOF prediction;
  - ensured rejected plans produce no submission candidate;
  - ran the compact six-family opportunity screen over all 16 official tasks;
  - saved `references/v13-planner-opportunity-replay.csv` and the executed
    `notebooks/autonomous-agent-v13-llm-feature-planner.ipynb`.
- Held v13 from Kaggle upload/submission because the current single-seed gate
  accepted two harmful false positives in the opportunity screen.
- Completed the multi-seed, multi-model v13 stability experiment on 2026-08-01:
  - 3 CV seeds, HGB, ExtraTrees, and one-hot logistic regression;
  - 882 scored rows across all 16 practice tasks;
  - strict cross-model/cross-seed family agreement removed the measured false
    positives;
  - the final-model gate retained one positive held-out specialist;
  - saved `references/v13-planner-stability-replay.csv` and runner
    `references/v13_planner_stability_replay.py`.
- Private Kaggle notebook
  `dalloliogm/autonomous-agent-v13-stable-llm-feature-planning`:
  - version 1 failed after 3,403 seconds with `DeadKernelError` after completing
    `train_01` through `train_12`; the single long cell exceeded the practical
    hosted runtime/resource envelope before writing its final CSV;
  - version 2 used two CV seeds across the same three model families and
    checkpointed after every task. It preserved 468 valid rows through
    `train_12`, then failed after 1,999 seconds with the same `DeadKernelError`
    as `train_13` began, identifying cumulative process memory as the likely
    constraint rather than total wall time;
  - an attempted version 3 push accidentally reused the stale version-2 staging
    folder after `kaggle_push_notebook.sh` exited before copying (the local
    Kaggle executable was absent). Pulling the remote source proved that v3 did
    not contain the repair;
  - version 4 genuinely ran the isolated-worker code and crossed the previous
    boundary, checkpointing all 468 rows through `train_13`; the `train_14`
    worker then segfaulted with exit code `-11`;
  - version 5 defaults to the exact embedded 882-row completed three-seed audit
    and retains the full replay as an explicit `RUN_HOSTED_REPLAY=True` stress
    test. The embedded frame matches the repository CSV exactly, and the full
    default notebook executes locally without cell errors;
  - hosted version 5 completed successfully on 2026-08-01. Its downloaded CSV
    has 882 rows, 16 tasks, all 3 model families and all 3 seeds, finite numeric
    values, and matches the repository audit exactly.
- Packaged and submitted `official-demo-v13-profile-planner` on 2026-08-01:
  - final archive SHA-256:
    `17ca4e362835c5001f3f1ec011ee2bd331353fcb597c6fc25982ce6621582b8d`;
  - archive integrity, YAML includes/tools, and extracted Python compilation
    passed; the extracted portfolio smoke produced six 10,000-row candidates
    with exact sample schema/ID order and finite predictions;
  - Kaggle submission `55171041` was accepted and is `PENDING`; today's single
    submission slot is consumed.

## Questions

- Re-check the deadline before serious submission work; current CLI metadata says `2026-08-06 23:59:00`, but Kaggle timelines can change.
- Verify the exact supported ADK config keys against the demo notebook/sample submission before uploading. The public notebooks disagree on `agent.yaml` shape (`instruction`/`tools` versus `system_prompt`/`allowed_tools`).
- Verify which Python packages are preinstalled inside the evaluation sandbox before relying on LightGBM, XGBoost, or CatBoost.
