# Repo Improvement Backlog From This Competition

This competition is directly relevant to improving this repository because it turns Kaggle participation itself into an agent-engineering problem. Promote items from this file into repo-level templates or skills only after they are validated locally or by a live submission.

## P0: Agent Submission Validator

Create a reusable validator script for agent-config competitions.

Checks:

- `agent.yaml` exists at the root of the source folder.
- The final `submission.zip` also has `agent.yaml` at archive root.
- `!include` targets exist and do not escape the source root.
- `agent_tool` configs are recursively validated.
- Plain tool names are in an allowlist.
- Every skill folder has `SKILL.md`.
- The zip contains no `__pycache__`, `.pyc`, or known broken/demo files.

Destination idea:

- `scripts/validate_agent_submission.py`
- document from `.codex/skills/kaggle-competition-workspace/references/agent-config-competitions.md`

## P0: Local Mini-Competition Replay Harness

Create a reusable harness for competitions that provide multiple solved practice tasks.

Pattern:

- iterate task folders
- run candidate script with only train/test/sample visible
- forbid `solution`, `answer`, `truth`, and `ground` file reads in submitted code
- score predictions against held-out `solution.csv` outside the candidate
- record ROC AUC, runtime, failure mode, and artifact path

Destination idea:

- `scripts/replay_tabular_mini_competitions.py`
- optional notebook template section for solved-practice-task competitions

## P0: Anti-Loop Prompt Block

Add a standard prompt block for autonomous Kaggle agents:

- submit a valid baseline before optional exploration
- never spend more than one or two turns planning before a tool call
- if unsure, run the modeling skill or submit the current valid file
- select final submission before budget is low

Destination idea:

- `templates/agent-submissions/prompt-blocks/anti-loop.md`

## P1: Schema-Agnostic Tabular Skill Template

Create a clean template skill for hidden tabular binary classification sessions.

Required behavior:

- infer train/test/sample files
- infer ID/target columns
- preserve sample submission columns and row order
- use leakage-safe preprocessing
- cap runtime
- write fallback predictions on failure
- print concise diagnostics

Destination idea:

- `templates/agent-submissions/tabular-binary-agent/`

## P1: Agent-Config Competition Workspace Extension

Extend `init_competition_workspace.py` or the repo-local skill to recognize competitions whose evaluation asks for `submission.zip`/`agent.yaml`.

Behavior:

- create `submissions/agent-configs/`
- add `references/public-notebooks/`
- add a task to build and validate `submission.zip`
- add agent-config-specific sections to `AGENTS.md`

## P2: Public Notebook Review Checklist

This request showed that public notebooks can contain useful patterns and stale/conflicting facts at the same time.

Checklist:

- compare notebook claims against official description/evaluation/rules
- inspect source cells, not only markdown titles
- separate "copyable pattern" from "unverified assumption"
- record local notebook path and exact caveats
