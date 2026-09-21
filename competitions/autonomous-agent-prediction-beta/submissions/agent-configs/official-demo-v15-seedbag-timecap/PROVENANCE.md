# Provenance

This v12 package adapts the public Kaggle architecture from:

- Naji, [LB 0.823 | The Freeroll Gemini Pro Strategy](https://www.kaggle.com/code/najiama/lb-0-823-the-freeroll-gemini-pro-strategy)
- Kun Zhang, [Deterministic Portfolio Replication s018](https://www.kaggle.com/code/beicicc/deterministic-portfolio-replication-s018)

The deterministic baseline and portfolio remain recognizable so their public
result can be reproduced and audited. This version changes the Pro prompt to:

- forbid target-derived features and target transformations;
- bound optimization to eight iterations;
- stop early on time or budget pressure;
- cap generated feature columns;
- restrict file and command access; and
- omit explicit final selection so the harness retains the two best public
  submissions.

The downloaded Kaggle metadata did not expose an explicit license field. Keep
the attribution with any private or public derivative.
