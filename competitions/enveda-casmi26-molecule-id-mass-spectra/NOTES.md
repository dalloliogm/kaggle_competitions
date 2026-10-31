# Notes

## Recap of the challenge so far (written 2026-10-31; ends 2026-12-14, entry/merger deadline 2026-12-07)

### Timeline of our work
- Oct 3: library-retrieval baseline LB 0.140 -> own FP-MLP + candidates 0.191 -> public FPNet swap 0.292 (v4). Priors tuned on the NP panel hurt (v5 0.255); more FPNets did not help (v6 0.290).
- Oct 4-6: forks of the public pipeline (FPNet + LightGBM rankers + PubChem tier + ICEBERG/GLACIER fusion) = **LB 0.363-0.379** (best 0.379, v30 fork with POP_MU 0.15). We declined the "visible-id pair" leak notebooks that claimed 0.41x.
- Oct 9-10: "prize path" (own FPNet trained only on train.parquet+COCONUT, no third-party weights): LB 0.261 -> 0.274 (train3). Prize-eligible but ~0.1 below the public frontier.
- Oct 10-31: no activity from us. Field moved from ~0.41 to **0.477 (public code) / 0.517 (leaderboard top)**.
- Oct 31: forked the current public 0.477 notebook (busyaprime m1) as `dalloliogm/casmi26-fork-m1-0477` and submitted it (ref 57838262, commit run ~35 min, scoring rerun pending; expect ~7 h).

### State of the field (2026-10-31)
- Leaderboard top 0.517 (Oleksandr Parfionov, Savko), then 0.504, 0.501, 0.495... ~4,300 teams. Gold line ~0.481 (rank 18 on 10-29). 231 teams sit at exactly 0.477, 175 at 0.472: **the public pipeline is saturated** - 122 of 133 public notebooks scoring >=0.46 attach the same `dmitriigluzdov/casmi26-attributed-v4g-reproduction-assets`.
- Lineage of the 0.477 notebook: Gluzdov "Data behind Spectra to Structures" 0.465 -> Saner Turhaner neural RRF (weight .25) 0.466 -> Roman Rozen leader-safe consensus (ranks 2-25 at .50) 0.468 -> alex chilton ranks 2-25 at .75 = 0.472 -> Roman Tamrazov fragment check (<=2-bond-cleavage MetFrag-lite, untrained) 0.472 -> busyaprime merge (fragment-check leader moves taken from the V2 order on top of the .75 order) **0.477**.
- Negative results documented there: Ahmed Berat Ozer's long-trained neural model -0.019; NX isomer reranker -0.058; provenance reranker +0.000; leader-rule knob sweeps +-0.004 (i.e. noise).
- Public LB is ~31% of the test (~125 molecules): one rank 2->1 move = 0.004. Differences <=0.005 between public notebooks are noise (thread 753525). Top-10 teams are not authors of any public notebook, so 0.50+ uses private ideas.

### Hosts' rulings that matter (discussion threads)
- 750330 (10-17): non-commercial (CC-BY-NC) open data now allowed; NIST and proprietary data are not (derived weights included).
- 748882 / 752541 / 753662 (10-25..30): weights/intermediates need public original training/generation code to be prize-eligible; hosts "reserve the right" to remove non-reproducible submissions from the leaderboard; checks have historically covered prize (sometimes gold) zone only. Pre-built free, openly accessible datasets are OK if not built from proprietary data (David Healey, 10-30); open follow-ups on whether shared weight datasets (ahmedberatozer/*, prvsiyan/*) count.
- 745072: earlier answer - non-commercial inputs make a solution ineligible to win (superseded in part by 750330).
- 752846/753400/751300: Class 3 (novel structures) is unsolved by everyone; rule-based biotransformation of analogs recovers few.
- Final: 2 submissions selectable; private = ~69% of molecules, so keep one diverse pick.

### Where the signal is (hypotheses for the remaining 6 weeks)
1. The public pipeline's ceiling is ~0.477; gains of 0.04 (top teams) come from something not in public notebooks - likely a better spectrum->structure encoder (DreaMS / larger FPNet), Class-3 handling, or better candidate generation.
2. Our own prize-path FPNet (0.274 alone) is far weaker than the shared `sanpier/casmi-spectrum-model-v1` neural scorer; the gap is encoder quality/training data (they likely use the whole 2.5M spectra + COCONUT with longer training).
3. Fragment-coverage scoring (untrained) gave +0.005: cheap physics-style features still add signal.
