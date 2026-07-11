# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-09 | `official-demo-v4-extracted-reference-agent` | n/a | 0.815 | Pending | Kaggle submission `54491765` | First completed submission. Extracted directly from official demo notebook because custom prompt variants failed to call `submit_predictions`. |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-09 | Source review: public A-to-Z guide | Identified schema-agnostic discovery, structural validator, anti-loop prompt, fallback submission, runtime caps, and zip validation patterns. | n/a | n/a | Strongest source for first baseline design. | Reimplement as a clean local agent config rather than copying notebook-generated files verbatim. |
| 2026-07-09 | Source review: dynamic AutoML starter | Identified simple AutoML skill layout, path resolution to `/work`, model blending pattern, and packaging flow. | n/a | n/a | Useful but less robust; hard-coded paths and config-key assumptions need verification. | Borrow only portable ideas after checking official demo/sample. |
| 2026-07-09 | v1 custom direct-script package | Root `autopredict.py` plus skill copy; zip had to be named exactly `submission.zip` for upload. | Synthetic smoke test passed locally. | n/a | Kaggle submission `54491451` errored: agent completed without `submit_predictions`. | Filename mattered for upload; prompt/tool behavior did not force submission. |
| 2026-07-09 | v2 custom package with `run_skill_script` | Added official-style subagent and extra skill tools. | n/a | n/a | Kaggle submission `54491555` errored: `run_skill_script` not found in registry. | Runtime available tools are `edit_file`, `get_status`, `read_file`, `run_command`, `select_submission`, `submit_predictions`, `write_file`. |
| 2026-07-09 | v3 custom direct-run-command package | Removed unavailable skill tools; first required action was `run_command`. | Synthetic smoke test passed locally. | n/a | Kaggle submission `54491615` errored: agent completed without `submit_predictions`. | Direct command-first prompt still insufficient. |
| 2026-07-09 | v4 official demo extraction | Extracted official demo `%%writefile` cells into `submission.zip`. | n/a | 0.815 | Kaggle submission `54491765` completed. | Use as the live baseline; next variant must preserve official tool structure and known-submit behavior. |
| 2026-07-09 | v5 official demo plus model recipe | Preserved official structure, removed stale `run_skill_script` references, added stronger modeling recipe. | n/a | n/a | Upload rejected with generic `400 Bad Request`; no submission row created. | Likely daily-limit/gate behavior or stricter package validation; retry later only after checking slot availability. |

## Backlog

| Idea | Rationale | Expected impact | Cost | Priority |
| --- | --- | --- | --- | --- |
| Minimal valid agent with anti-loop prompt | The scoring session is autonomous; a model that never submits scores zero. | High | Medium | P0 |
| Structural validator for agent folders and zip files | Bad `agent.yaml`, broken `!include`, missing `SKILL.md`, or stale zip will fail before modeling matters. | High | Low | P0 |
| Offline replay harness over training mini-competitions | The provided `solution.csv` files make it possible to evaluate strategies without spending submissions. | High | Medium | P0 |
| Schema-agnostic feature-engineer skill | Hidden sessions may vary schema; hard-coding `row_id`/`target`/file names is brittle. | High | Medium | P0 |
| Runtime-aware model selection | Sandbox time is finite; unbounded AutoML can fail to submit. | High | Medium | P1 |
| Optional GBDT blend | Can improve AUC if packages are available and runtime allows. | Medium | Medium | P2 |
| Promote reusable agent-config workflow into repo templates | This competition format is directly relevant to making the repo better at Kaggle competitions. | Medium | Medium | P2 |

## Abandoned

| Approach | Why dropped | Evidence | Revisit if |
| --- | --- | --- | --- |
| Long EDA before first submission | In an autonomous session, delay can burn the budget and leave no valid submission. | Public A-to-Z guide explicitly demotes EDA until after a baseline submit. | Only after first baseline is already locked in. |
| Fixed `train_01` path in agent script | Hidden sessions give one task directory; fixed practice paths are not portable. | Dynamic AutoML notebook uses fixed `/kaggle/input/.../train_01/...` in its local test command. | Keep only as a local notebook example, never in submitted agent code. |
| Adding `run_skill_script` to `agent.yaml` tools | The live evaluator rejects it. | Submission `54491555`: `Tool 'run_skill_script' not found in registry`. | Only if Kaggle updates the runtime tool registry. |
| Repeated blind uploads after generic `400 Bad Request` | The API does not expose a useful error body through the CLI, and the competition has a 5/day limit. | v5 upload rejected without creating a row after four recorded submissions and one earlier upload-gate rejection. | Revisit tomorrow or with a way to inspect full HTTP response details. |
