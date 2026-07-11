---
applyTo: "competitions/**"
---

# Active Kaggle Competition Workspace Instructions

When working under `competitions/<slug>/`, treat that folder's markdown files as local context:

- `COMPETITION.md`: objective, metric, data paths, submission format, rules, and baseline.
- `TASKS.md`: current plan, experiments, completed work, and open questions.
- `NOTES.md`: EDA observations, model ideas, feature notes, links, and leaderboard notes.
- `APPROACHES.md`: tried approaches, scores, outcomes, backlog ideas, and abandoned paths.
- `LEARNINGS.md`: durable insights about data, metric, validation, leakage, modeling, ensembling, and leaderboard behavior.
- `AGENTS.md`: competition-specific instructions.

Preserve Kaggle compatibility. Code intended for Kaggle should use `/kaggle/input/...` and `/kaggle/working`, with local fallbacks only when useful.

Keep generated submission/output files in `submissions/` and avoid committing them unless explicitly requested.
