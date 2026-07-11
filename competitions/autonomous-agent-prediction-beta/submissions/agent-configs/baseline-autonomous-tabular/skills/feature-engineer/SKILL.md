---
name: feature-engineer
description: Fallback-safe schema-agnostic tabular binary-classification prediction script.
---

# Feature Engineer

Use `scripts/autopredict.py` to discover train/test/sample files, infer ID and target columns, fit a fast tabular classifier, and write a valid probability submission.

The script must never read answer-like files such as `solution.csv`.
