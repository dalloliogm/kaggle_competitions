# Feature-Engineered CatBoost Recipe

- Infer target and ID columns from train/test/sample structure.
- Treat object, boolean, and bounded-cardinality integer features as categorical.
- Use stratified CatBoost fold models with early stopping and average test probabilities.
- Submit and select an unengineered baseline before optional analysis.
- Transform predictors only. A binary target has no normality requirement.
- Bound engineered features to frequency encoding, robust row statistics,
  skew-aware monotonic transforms, and a few unsupervised interactions.
- Treat an LLM transformation plan as advisory input constrained by an allowlist,
  never as arbitrary executable code.
- Use the replay-tested adaptive gate for the live second candidate. Numeric,
  automatic, and direct-plan modes are research ablations rather than live
  defaults.
- If CatBoost is unavailable or fails, use ordinal encoding plus histogram gradient boosting.
- Clip probabilities and preserve the exact sample-submission schema.
- Always keep a constant-prior fallback.
