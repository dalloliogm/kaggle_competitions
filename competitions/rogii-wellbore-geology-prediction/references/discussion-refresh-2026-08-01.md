# ROGII discussion refresh — 2026-08-01

## Scope

Authenticated Kaggle discussion refresh on 2026-08-01: 120 topics sorted by most recently updated and 825 associated comments. This note focuses on updates since the prior late-July review and on azimuth/drilling direction, sequence models, physics-only pipelines, GR denoising, and final-week selection. Community score reports are treated as anecdotes unless the post also describes a reproducible validation protocol.

## Strongest new or updated evidence

| Topic | Date / update | Evidence | Assessment |
|---|---|---|---|
| [731550 — final two submissions](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/731550) | Created and last updated 2026-07-31 | Competitors strongly favor 773-well CV over the roughly 50-well public slice. Tucker reports five fold models from one 5-fold, 7-seed system spanning public LB 5.2–6.3 despite overall CV 5.13 and tight CV folds. Diversity or a broad inference ensemble is preferred to selecting a lucky public fold. | **High-value, clean process evidence.** No hidden IDs, placeholder dependence, or Q0522-style score probing. Supports selecting by legal masked/grouped CV and error diversity, using LB mainly to reject broken candidates. |
| [728477 — public LB as a precise but biased ruler](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/728477) | Updated 2026-07-30 | Multiple unchanged-kernel series put within-pipeline rerun SD around 0.02–0.04 ft for the tested families, while candidate-selection layers can amplify small numeric changes when alternatives are nearly tied. The thread recommends treating sub-two-sigma deltas on one base as draws, not improvements, and trusting CV for private selection. | **High-value, clean process evidence.** The numeric noise band is pipeline-specific, not universal. It argues against spending slots on marginal tweaks and against choosing a final model from its luckiest draw alone. |
| [719235 — correcting the typewell from known TVT](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/719235) | Updated 2026-07-30 | A new comment shows that the known TVT prefix can partly correct the typewell/GR relationship. | **General idea is legal; displayed evidence is placeholder-bound.** The example is well `000d7d20`, one of the three authoring wells replaced during grading. Treat the plot as an illustration only, never as evidence for a per-well rule or hardcoded correction. |
| [717573 — score without tabular models](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/717573) | Updated 2026-07-28 | One participant reports a pure-physics model at CV 6.258 / LB 7.950; an earlier participant reported CV 6.85 / LB 6.577. No implementation details were disclosed. Other comments report both tabular and non-tabular systems reaching 5.x CV. | **Interesting but not actionable by itself.** It supports physics as an independent ensemble family, but the large CV/LB disagreement and absent code mean we should inspect the known public Physics notebook rather than recreate a method from this thread. |

## Hypothesis check

### Azimuth / drilling direction

The only direct public claim remains [726465](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/726465), last updated 2026-07-18. One highly voted comment says NW- versus SE-drilled wells should be split or given an explicit direction feature because their sequences traverse layers in reverse order. The thread supplies no code, ablation, fold scores, or before/after result for that claim. A top competitor in the same thread reports sub-5 pooled, whole-well CV using only per-well data, but does not confirm azimuth as the cause.

**Verdict:** still a plausible, clean experiment, but the refresh adds no corroboration. Derive direction mechanically from trajectory, validate with whole-well masked-prefix folds, and submit only if the gain survives across folds. Do not treat the comment's “easy win” language as measured evidence.

### Sequence models

- [725086](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/725086), 2026-07-14: inverted Transformer local CV 7.5; no follow-up evidence.
- [722236](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/722236), last updated 2026-07-20: reported NN results include CV 8.9 / LB 8.39 and a 4-seed CNN around CV 9.71. The useful conclusion is that representation, validation, and alignment matter more than depth; a sequence model may add ensemble diversity but is not automatically superior.
- [703344](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/703344), last updated 2026-06-08: `bfloat16` can destroy even a copy-transformer because TVT precision is insufficient; use `float32` for targets/output if revisiting this family.

**Verdict:** no new evidence supports building a sequence model as the next-day submission. It is a longer-term diversity track, not a fast slot candidate.

### Physics and alignment

[702919](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/702919), updated 2026-07-18, reports deterministic Viterbi/DP alignment improving OOF by 0.46 ft but LB by only 0.001 ft. The author concludes that the observation model and independent structural signal matter more than the decoder architecture. [727149](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/727149), updated 2026-07-22, reports PF beating DTW by only 0.18 ± 0.04 ft over five seeds and being most useful through posterior uncertainty as a trust gate.

**Verdict:** do not build another decoder-only variant. Pull and inspect the independent public Physics pipeline first; its value would be decorrelated predictions, not the “physics” label itself.

### GR denoising

The public evidence has not changed. [708367](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/708367) identifies a rotation-frequency FFT peak, while [716289](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/716289) and [727149](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/727149) report a 7-point rolling median or rotation denoise moving a truth-centred datum-localization diagnostic from about 80% to 84%. Those authors explicitly label it a train-side diagnostic, not a deployable score estimate. Another comment in [711308](https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/711308) argues that the remaining ambiguity is geological aliasing rather than removable sensor noise.

**Verdict:** the public claim was narrower than “denoising improves competition RMSE.” It supports denoising for a calibration diagnostic, not wholesale replacement of GR inside a scoring pipeline. Do not stack more smoothing/notch variants without a component-level masked-prefix test.

## Clean-vs-placeholder and Q0522 risk screen

- No newly refreshed discussion provides support for Q0522, hardcoded authoring-well IDs, per-well offsets inferred from public scores, or train/test overlap overrides.
- Topic 719235's new `000d7d20` example is explicitly **placeholder-only evidence**. The transferable hypothesis is prefix-based calibration; the illustrated correction is not transferable.
- Topics 731550 and 728477 are clean model-selection evidence because they reason from CV, repeated unchanged submissions, and model diversity rather than from named public wells.
- Topic 726465's azimuth idea is clean in principle but currently anecdotal.
- The denoising percentages are legal train diagnostics but are centred on truth and therefore must not be presented as deployable hidden-test performance.

## Recommended next move

1. Inspect the independent public Physics notebook and measure prediction/error diversity versus clean GS1.30 before considering a blend.
2. In parallel, implement one minimal azimuth normalization/split experiment and judge it only with grouped whole-well, hidden-suffix simulation.
3. Do not spend a slot on another denoising or decoder-only tweak.
4. For final selection, prefer the best honest CV candidate plus a genuinely decorrelated candidate; do not select a lucky public rerun or a fold solely because of LB.

