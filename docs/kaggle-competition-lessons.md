# Reusable Kaggle competition lessons

This document collects durable lessons from completed competitions. It is a
planning guide, not a substitute for the competition-specific `AGENTS.md`,
`COMPETITION.md`, validation protocol, or submission rules.

## 1. Find the real bottleneck before tuning the visible one

A public score plateau does not prove that the detector, feature set, or base
model is saturated. Separate the pipeline into meaningful stages and ask which
stage lacks information:

- input and preprocessing;
- detection or representation;
- temporal identity or matching;
- event prediction;
- global selection or optimization;
- repair, calibration, and output writing.

If a pipeline has already exhausted threshold and post-processing sweeps, the
next experiment should usually introduce a new representation or independent
failure mode, not another nearby value of the same knob.

For tracking problems, a per-object temporal model can be more valuable than a
stronger frame-level detector. A queried object can be trained to predict its
future location, previous location, event state, or occupancy around candidate
matches. This turns identity and event prediction into learned evidence rather
than leaving them to distance heuristics.

## 2. Build the out-of-fold world early

Do not let a model trained on all available examples decide whether its own
post-processing is good. Create grouped OOF predictions before tuning the
downstream stack. The grouping unit should match the likely distribution shift:
video, subject, embryo, well, patient, time block, or other independent unit.

Use the official metric on the final artifact, not only an intermediate loss or
component metric. Keep the following separate in experiment records:

- in-sample score;
- grouped OOF score;
- external or copied-data score;
- public leaderboard score;
- private leaderboard score.

An in-sample gain is a hypothesis. A public gain is evidence about a small,
possibly biased test slice. Neither is private-transfer evidence by itself.

## 3. Use small, targeted manual annotation when labels are weak

Manual labels are often a high-leverage intervention, especially when the
provided labels are sparse, biased toward easy cases, or contain too few rare
events. A small set of carefully selected examples can teach the model a
representation that the existing labels do not support.

Use a baseline to select examples that are uncertain, visually ambiguous,
rare, systematically missed, or representative of a new domain. For temporal
or structured data, annotate the surrounding context rather than an isolated
record: neighbouring frames, object identity, event state, or the full local
structure may be what makes the label learnable.

Treat manual annotation as a controlled data intervention:

- keep the selection policy and annotation tool/process in the experiment log;
- hold out a completely untouched grouped validation set;
- inspect inter-annotator disagreements or re-review a sample when feasible;
- use the manual set first for fine-tuning, active-learning queries, hard
  negatives, or high-confidence pseudo-label generation;
- do not claim generalization merely because the model fits the manually
  selected examples.

The right question is not whether manual annotation is scalable. It is whether
a small manual seed exposes the missing signal, after which pseudo-labeling or
active learning can expand coverage safely.

## 4. Treat public-LB tuning as a noisy measurement

Before the competition closes, public submissions are useful for detecting large
regressions and testing genuinely orthogonal mechanisms. They are poor grounds
for selecting among many variants that differ by one or two displayed units.

Record the expected direction before reading the leaderboard. If a candidate
wins only because it was selected after many probes, mark it as public-LB
selected rather than validated. Preserve a conservative anchor and at least
one structurally different candidate; do not spend every slot on near-duplicate
artifacts.

After the close, actively seek solution write-ups and private-score tables.
They often reveal that detector tuning did not transfer while continuity,
identity, or conservative repair did.

## 5. Use controlled ablation ladders

Maintain a fixed base artifact and add stages in an interpretable order. For a
structured prediction pipeline, a useful ladder is:

1. base representation or detector;
2. motion or context features;
3. candidate matcher;
4. event/division model;
5. calibrated global optimizer;
6. gap repair or continuity repair;
7. coordinate or output refinement;
8. safe writer and structural validation.

Do not attribute the entire gain to the last stage in a cumulative history. A
stage can be valuable only in combination with another stage, but that claim
needs a controlled comparison or a clearly labelled interaction experiment.

## 6. Prefer robust mechanisms over public-board tricks

The mechanisms most likely to transfer are those tied to the data-generating
process: identity consistency, motion compensation, physically plausible
continuity, conservative event evidence, and coordinate precision. Be cautious
with rules that only alter counts, prune rare structures, or target one visible
subset unless they survive grouped validation.

For graph tasks, report the exchange rate as well as the theoretical ceiling:
how many nodes, edges, or events must change for the metric to improve, and how
many true positives are lost in the process. A large oracle ceiling can be
irrelevant when every available rule crosses the wrong side of that exchange
rate.

## 7. Make reproducibility part of the experiment

Every candidate should have:

- a unique experiment ID and immutable base identity;
- source and input provenance;
- configuration and runtime settings;
- output hash and structural validation result;
- the exact public/private/OOF claim, with its ruler named;
- a record of whether it was submitted, held, rejected, or duplicated.

Use cached outputs and previous artifacts before requesting new GPU time. Many
questions about post-processing, runtime guards, graph validity, and count
behaviour can be answered without rerunning the expensive model.

## 8. Competition-close checklist

Before submitting a candidate:

- verify current daily allowance and all in-flight submissions;
- validate the final file, not an intermediate file;
- confirm runtime, internet, accelerator, and required filename;
- verify the output hash is new and the notebook version is the intended one;
- retain a conservative known-good candidate;
- record the expected private-transfer rationale separately from the public
  score.

The goal is not to maximize the number of submissions. It is to maximize the
information gained per slot while preserving a valid final fallback.

## Biohub source examples

These principles were sharpened by the Biohub post-competition write-ups:

- [1st-place solution: per-cell visual tracker](https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/writeups/1st-place-solution)
- [3rd-place solution: 2.5D/3D ensembles and lineage optimization](https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/writeups/3rd-place-solution)
- [12th-place solution: public/private validation post-mortem](https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/writeups/12th-place-solution)
