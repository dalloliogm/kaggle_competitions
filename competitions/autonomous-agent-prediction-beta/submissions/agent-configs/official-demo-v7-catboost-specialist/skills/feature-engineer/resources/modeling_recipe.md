# CatBoost Specialist Recipe

- Infer target and ID columns from train/test/sample structure.
- Treat object, boolean, and bounded-cardinality integer features as categorical.
- Use stratified CatBoost fold models with early stopping and average test probabilities.
- If CatBoost is unavailable or fails, use ordinal encoding plus histogram gradient boosting.
- Clip probabilities and preserve the exact sample-submission schema.
- Always keep a constant-prior fallback.
