# Agent-Config Kaggle Competitions

Use this reference when a Kaggle competition evaluates an autonomous agent or config package instead of a normal `submission.csv`.

## Recognition Signals

- Evaluation page asks for `submission.zip`.
- Archive root must contain `agent.yaml`.
- Submission may include `prompts/`, `tools/`, or `skills/`.
- The submitted agent generates prediction files during an evaluation session.
- Tools include actions such as `run_command`, `submit_predictions`, `select_submission`, or skill execution.

## Workspace Additions

In addition to the standard workspace files, create or track:

- `submissions/agent-configs/` for source folders that build into `submission.zip`.
- `references/public-notebooks/` for source notebooks and summaries.
- `references/repo-improvement-backlog.md` when the competition teaches reusable repo patterns.

## Required Capture

Record these facts in `COMPETITION.md` and `AGENTS.md`:

- expected archive name and root files;
- exact required `agent.yaml` fields from the official demo/sample;
- allowed tools;
- whether internet/package installs are available during evaluation;
- daily and final submission limits;
- any external-data, AutoML, and license constraints;
- runtime metric and whether predictions must be probabilities.

## Implementation Guidance

- Prioritize a valid first `submit_predictions` call over optional EDA.
- Use an anti-loop system prompt so the agent does not reason until budget expires.
- Make modeling scripts schema-agnostic:
  - discover train/test/sample files;
  - infer ID and target columns;
  - preserve sample submission shape;
  - blacklist files with names such as `solution`, `answer`, `truth`, and `ground`.
- Include a fallback writer that always produces a valid weak prediction file.
- Cap row count, CV folds, search iterations, and elapsed time before expensive AutoML.
- Validate the source folder and the final zip separately before upload.

## Public Notebook Review

When public notebooks are provided, inspect source cells and record:

- structural submission patterns;
- validator logic;
- prompt behavior;
- modeling and feature engineering choices;
- runtime safeguards;
- contradictions with official pages.

Do not copy public notebook claims blindly. Treat official pages and real checker behavior as authoritative.
