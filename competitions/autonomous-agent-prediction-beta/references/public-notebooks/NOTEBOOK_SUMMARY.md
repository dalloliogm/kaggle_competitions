# Public Notebook Source Summary

Reviewed on 2026-07-09.

## Notebooks

| Notebook | Local copy | Main value | Caveats |
| --- | --- | --- | --- |
| `sidhaarthshree/autonomous-agent-prediction-a-to-z-guide` | `a-to-z-guide/autonomous-agent-prediction-a-to-z-guide.ipynb` | Strongest implementation reference for a robust autonomous-agent submission. | Treat code as a source of design patterns; verify exact ADK schema against official demo/sample before upload. |
| `nursrijan/agent-starter-dynamic-automl-guide` | `dynamic-automl-guide/agent-starter-dynamic-automl-guide.ipynb` | Simple AutoML skill package layout and path-resolution workaround. | Contains hard-coded practice-data paths and says there are 18 datasets, while the official description says 16. |

## A-to-Z Guide: Reusable Patterns

- Uses defensive path detection for Kaggle input roots.
- Performs bounded per-dataset EDA instead of loading everything blindly.
- Builds schema-agnostic baseline functions around ID/target inference, mixed numeric/categorical preprocessing, and ROC-AUC CV.
- Demonstrates hierarchical agent config:
  - root `agent.yaml`
  - prompt files under `prompts/`
  - sub-agent config under `tools/`
  - reusable skill folder under `skills/`
- Adds a structural validator for:
  - missing config files
  - `!include` handling
  - path traversal outside the submission root
  - allowed tool names
  - recursive `agent_tool` configs
  - required `generate_content_config`
  - `SKILL.md` manifests
- Demonstrates deliberately broken config validation, which is useful for regression tests.
- Tests richer tabular features:
  - row-wise numeric aggregates
  - top-correlation numeric interactions
  - K-fold target encoding
  - bounded randomized search over histogram gradient boosting
- Converts the teaching scaffold into a more realistic `feature-engineer` skill:
  - discover files without fixed names
  - blacklist `solution`, `answer`, `truth`, and `ground` files
  - infer ID/target columns
  - normalize non-numeric binary labels
  - downsample large training data before expensive search
  - scale search effort by size and remaining time
  - write a valid constant-prior fallback on failure
- Rewrites the system prompt around one hidden dataset per evaluation session, not a loop over all practice folders.
- Uses an anti-loop rule: if the agent is unsure, it must run the modeling skill or submit the existing `submission.csv`.
- Validates final `submission.zip` contents, not only the source folder.

## Dynamic AutoML Guide: Reusable Patterns

- Clear minimal folder layout:
  - `agent.yaml`
  - `prompts/system.md`
  - optional `configs/sampling.yaml`
  - `skills/automl/SKILL.md`
  - `skills/automl/scripts/run_automl.py`
- Path-resolution workaround for skill scripts that execute outside `/work`:
  - try the given path
  - search parent directories
  - fall back to `/work/<path>`
- Model stack:
  - LightGBM
  - XGBoost
  - CatBoost
  - OOF predictions
  - simple blend-weight search
- Feature engineering options:
  - low-cardinality numeric columns as categorical
  - ordinal encoding
  - row-level numeric statistics
  - frequency encoding
  - OOF target encoding
- The script writes predictions using the sample submission shape.

## Recommended First Baseline

Use the A-to-Z guide as the primary design and borrow only the dynamic guide's portable AutoML packaging ideas.

The first real agent should do the minimum reliable sequence:

1. Call `get_status`.
2. Run a schema-agnostic feature-engineer skill.
3. Immediately call `submit_predictions` on the generated `submission.csv`.
4. Attempt at most one improvement if budget remains.
5. Call `select_submission` before budget is low.

## What To Promote Into Repo Knowledge

- A reusable "agent-config competition" playbook in the repo-local Kaggle workspace skill.
- A structural validator for `submission.zip` agent submissions.
- A local replay harness pattern for competitions that ship solved training mini-competitions.
- A standard anti-loop prompt block for autonomous Kaggle agents.
- A schema-agnostic tabular modeling skill template with fallback prediction behavior.
