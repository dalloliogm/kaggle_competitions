# Provenance

This v13 package retains the public deterministic architecture from:

- Naji, [LB 0.823 | The Freeroll Gemini Pro Strategy](https://www.kaggle.com/code/najiama/lb-0-823-the-freeroll-gemini-pro-strategy)
- Kun Zhang, [Deterministic Portfolio Replication s018](https://www.kaggle.com/code/beicicc/deterministic-portfolio-replication-s018)

The quick baseline and deterministic portfolio remain recognizable so their
public result can be reproduced and audited. This version replaces direct
Pro-stage Python editing with an original strict JSON feature DSL, target-blind
predictor profiler, and fold-stable OOF gate. The planner:

- cannot inspect or transform the binary target;
- proposes at most three plans with exactly one allowlisted family each;
- cannot write executable code;
- generates at most 40 columns;
- submits a planned candidate only after it beats the best deterministic
  portfolio OOF prediction under mean and fold-level criteria; and
- leaves final selection to the evaluation harness.

The downloaded Kaggle metadata did not expose an explicit license field. Keep
the attribution with any private or public derivative.
