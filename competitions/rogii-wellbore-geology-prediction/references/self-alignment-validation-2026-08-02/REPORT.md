# Direction-gated lateral self-alignment masked-prefix screen

## Outcome

The current self-alignment implementation does **not** qualify for integration into s4000.

The deterministic screen covered 60 training wells, three mask fractions, 180 well/fraction cases, and 946,541 scored rows. It used only shortened `TVT_input` prefixes plus always-visible trajectory and GR columns. True tail direction was used only for diagnostic slices.

## Results

- Strict nested-prefix gate activation: 3/180 cases (1.67%).
- Pooled improvement over the constant anchor: +0.0259 ft.
- Well-bootstrap mean improvement: +0.0267 ft; 95% interval [-0.1995, +0.2700].
- Negative-tail diagnostic improvement: +0.2947 ft.
- Fraction improvements: 0.50 = 0.0000 ft, 0.65 = -0.4090 ft, 0.75 = +0.8640 ft.
- Correlation-only gate activation: 97.2%; mean bootstrap effect approximately -48.8 ft.

The negative-tail slice suggests that the geological idea can work for isolated wells, particularly at the 0.75 mask. However, the effect is too sparse and unstable to justify changing the current best submission pipeline. High GR correlation is common even when the inferred TVT path is wrong, so it cannot serve as the deployment gate by itself.

## Decision

- Keep submission `55170737` (s4000, public score 6.435) untouched.
- Do not create or submit an s4000 self-alignment fork from this version.
- If revisited, require multi-cut calibration consistency and test the revised gate on a fresh held-out well set rather than tuning and re-evaluating on these 60 wells.

Machine-readable evidence is in `summary.json`, `masked_prefix_metrics.csv`, and `masked_prefix_well_metrics.csv`.
