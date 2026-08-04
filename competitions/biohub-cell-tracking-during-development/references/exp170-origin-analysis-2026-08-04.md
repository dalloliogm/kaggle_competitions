# Exp170 origin analysis - 43% of our misses are self-inflicted (2026-08-04)

Second diagnostic run of the UNCHANGED Exp148 stack on the five labelled movies
(`dalloliogm/biohub-exp170-error-dump-v2`, kernel **v2** COMPLETE, no submission
slot spent). Raw artifacts: `error_dump_v2.csv`, `tp_baseline.csv`,
`error_summary_v2.csv`.

> **v1 of this kernel produced nothing.** `IndexedRXGraph.from_geff` returns
> `(graph, GeffMetadata)`; the new ILP-comparison call unpacked it as a bare
> graph and raised `AttributeError: 'tuple' object has no attribute 'node_attrs'`
> on every dataset. Because the whole per-dataset body sat under a single
> `try/except`, that one line destroyed the entire dump. v2 unpacks the tuple and
> isolates ILP loading in its own `try`, so an ILP failure now degrades to
> `have_ilp=False` instead of losing the dataset's error rows.

## The FP accounting is now solved

Exp169 had to leave a trust boundary open: it could reconstruct TP and FN exactly
but under-counted FP (69 of 138 in the dense movie). Exp170 tested three
candidate rules against the official counts:

| dataset | official FP | `source` | `source_or_target` | `any_matched` |
| --- | ---: | ---: | ---: | ---: |
| `44b6_0113de3b` | 2 | 1 | **2** | 4 |
| `44b6_0b24845f` | 3 | 2 | **3** | 7 |
| `44b6_33b596bf` | 0 | 0 | **0** | 1 |
| `6bba_05b6850b` | 19 | 11 | **19** | 38 |
| `6bba_05db0fb1` | 138 | 69 | **138** | 216 |

**`source_or_target` reproduces the official FP count exactly on all five
movies.** A predicted edge is a false positive when *either* endpoint matched an
annotated GT node. FP-side conclusions are now as trustworthy as FN-side ones.

## MAIN FINDING - post-processing destroys correct ILP solutions

Every missed GT edge was classified by whether it was present in the ILP-solved
graph (before our post-processing) or absent from both:

| dataset | FN | `post_processing_broke_it` | `upstream_ilp_or_model` |
| --- | ---: | ---: | ---: |
| `44b6_0113de3b` | 3 | 3 | 0 |
| `44b6_0b24845f` | 2 | 2 | 0 |
| `44b6_33b596bf` | 0 | 0 | 0 |
| `6bba_05b6850b` | 12 | 5 | 7 |
| `6bba_05db0fb1` | 80 | **32** | 48 |
| **total** | **97** | **42 (43%)** | **55 (57%)** |

**42 of 97 missed edges were correct in the ILP solution and were thrown away by
our own post-processing.** This is a fixable loss class that sits entirely inside
code we control. It directly refutes the pessimistic reading of Exp169 (that the
plateau is a linker-model limit).

### How the 42 are lost

| pattern | count | meaning |
| --- | ---: | --- |
| exactly 1 predicted child | 33 | a step **replaced** the correct ILP child |
| 0 predicted children | 8 | a correct edge was **deleted** outright |
| 2 predicted children | 1 | a division was inserted over it |

- The true child node **still exists in our output in 39 of 42 cases**
  (`tgt_detected`), so this is not a detection problem.
- For the 33 replacements the median angle between the true step and the chosen
  step is **128.8 deg** (p25 87.2, p75 151.3) - the substitute child sits in
  roughly the *opposite* direction from the true motion.
- `chosen_nearer` splits 19/15, so the step is not simply defaulting to the
  nearest neighbour. It is applying a directional rule that is inverted or
  mis-scaled for these cases.
- Every one of the 42 has `gt_parent_n_children == 1`, so none of them are
  division ambiguity.

By contrast the 55 upstream misses have a *lower* median `parent_to_true_um`
(3.50 vs 5.52) - these are short steps the model never proposed, a genuinely
different and harder class.

## Local baseline for ablations

Per-dataset edge Jaccard `TP/(TP+FP+FN)` under the current Exp148 config:

| dataset | J |
| --- | ---: |
| `44b6_0113de3b` | 0.9038 |
| `44b6_0b24845f` | 0.9038 |
| `44b6_33b596bf` | 1.0000 |
| `6bba_05b6850b` | 0.9641 |
| `6bba_05db0fb1` | 0.8350 |
| **mean** | **0.9213** |

## Post-processing steps and their env gates

All steps are env-gated (in notebook cell 6), so ablation needs no code edits:

| step | gate | default |
| --- | --- | --- |
| motion relink | `BIOHUB_OUTPUT_MOTION_RELINK` | `1` |
| line-fit position smoothing | `BIOHUB_OUTPUT_LINEFIT_SMOOTH` | `1` (w 0.8, win 2) |
| single-frame gap close | `BIOHUB_OUTPUT_GAP_CLOSE` | `1` |
| short-track filter | `BIOHUB_OUTPUT_MIN_TRACK_LEN` | `6` |
| safe divisions | `BIOHUB_OUTPUT_SAFE_DIVISIONS` | `1` |
| isolated-node prune | `BIOHUB_OUTPUT_PRUNE_ISOLATED` | `1` |
| DeepCenter gap veto | `BIOHUB_DEEPCENTER_GAP_VETO` | `1` |
| strict gap-2 recovery | `BIOHUB_OUTPUT_GAP2_RECOVERY` | `0` |

Prime suspects from the mechanism above: **motion relink** and **line-fit
smoothing** for the 33 replacements, **short-track filter** for the 8 deletions.

## Standing caveat - local wins can invert on the LB

Do not submit an ablation purely because local score rises. The no-safe-divisions
test improved exact local validation (`0.9548 -> 0.9606`, division FP `4 -> 0`)
but *dropped* the public LB from `0.893` to `0.886` (`TASKS.md:263`). That case
had almost no statistical power (3 annotated divisions); the 42 edges here are a
far larger sample, but the inversion risk is real and any local win should be
treated as a hypothesis to be tested on the LB, not as proof.

## RESULT - the ablation ladder (Exp171/173/175/176, no slots)

All runs use the staged-labelled-movie harness and official `evaluate()` counts.

| config | mean edge J | vs baseline | dense J | dense TP/FP/FN | post-proc FN |
| --- | ---: | ---: | ---: | --- | ---: |
| baseline (Exp148, LB `0.913`) | 0.9214 | - | 0.8350 | 1103/138/80 | 42 |
| `MOTION_RELINK=0` | 0.9476 | **+0.0263** | 0.8831 | 1118/83/65 | 20 |
| **+ `MIN_TRACK_LEN=1`** | **0.9558** | **+0.0345** | 0.8899 | 1123/79/60 | **12** |
| + `GAP_CLOSE=0` | 0.9545 | +0.0331 | 0.8831 | 1118/83/65 | - |
| + `DEEPCENTER_GAP_VETO=0` | 0.9556 | +0.0342 | 0.8884 | 1123/81/60 | - |
| `LINEFIT_SMOOTH=0` | 0.9044 | **-0.0169** | 0.8321 | 1100/139/83 | 30 |

**Motion relink is actively harmful and the short-track filter is mildly so.**
Removing motion relink improves TP, FP *and* FN simultaneously on the dense
movie - the signature of deleting a step that makes genuinely wrong edits, not a
precision/recall trade. This matches the 128.8 deg mis-direction finding above.
Post-processing-caused FN fall 42 -> 20 -> 12.

**Line-fit smoothing, gap close and the DeepCenter veto all earn their keep** -
ablating each of them costs score. The ladder converged at
`MOTION_RELINK=0 + MIN_TRACK_LEN=1`; the remaining 12 post-processing FN are not
attributable to any single remaining step.

Submitted as `exp172` (relink off alone) and `exp174` (the converged config).
Leaderboard verdict pending - see `TASKS.md` for the outcome, and remember the
standing caveat above: the local number is a hypothesis until the LB confirms
it.
