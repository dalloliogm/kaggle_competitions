# Recent public notebook scan: 2026-07-17

Purpose: capture public-notebook ideas that are different enough from the current
Exp073-family work to guide original follow-up submissions.

Downloaded sources are stored under
`references/public-notebooks-2026-07-17/`.

## Highest-value ideas

| Priority | Public notebook | Mechanism | Relation to our work | Recommended action |
| --- | --- | --- | --- | --- |
| P0 | `chiranjithdharma/replace-midpoint-insertion-with-weighted-interpola` | Weighted gap-node interpolation using local endpoint motion rather than pure midpoint placement | New, clean one-factor change to gap-repair geometry; compatible with Exp073/Exp092 family | Build Exp105 around Exp073 or Exp092, with `GAP_MIDPOINT_MOTION_WEIGHT=0.5` and safety clamp `4.0 um` |
| P1 | `yusuketogashi/biohub-another-approach` | Density-adaptive gap repair plus an outside-base local-spacing gate (`8.50 um`) | Very close to Exp090/Exp092; useful precision filter for extra gap links | Use if Exp090/092/103 show promise but need fewer risky added links |
| P1 | `outwrest/metric-hack-minimal-baseline-tta-2gpu` | Test-time augmentation plus different ILP appearance/disappearance costs (`0.0` / `1.4`) | Higher-cost model-inference branch, not just post-processing | Treat as separate GPU-heavy branch after current graph post-processing signals resolve |
| P2 | `xiaoleilian/biohub-cell-tracking-bright-tophat-mix` | Two-detector blend: bright-field U-Net plus top-hat-preprocessed U-Net, threshold `0.15`, NMS `4.0 um` | Different detector family and dependency set | Bigger branch; inspect weight dataset and output density before committing a slot |
| P0 process | `nilsfl/how-reliable-is-local-validation-a-measurement` | Demonstrates public LB can invert local validation ranking for post-processing knobs | Supports our batching strategy | Continue one-factor public-LB probes; do not overtrust held-out train for post-processing rank order |

## Practical interpretation

The current public landscape is mostly converging on the same learned
U-Net/transformer/ILP backbone plus score-oriented graph calibration. The
highest-leverage original space is therefore not another wholesale copy, but
small graph-construction changes that preserve the strong detector:

1. where to place inserted gap nodes;
2. which extra gap links are allowed in dense regions;
3. how permissive safe-division insertion should be;
4. whether TTA or alternative preprocessing materially improves detections.

## Proposed experiment sequence

1. **Exp105: weighted gap-node interpolation**
   - Base: Exp092 if we want to test on the threshold+density branch, or Exp073
     if Exp092-style variants continue tying baseline.
   - Change: replace pure midpoint synthetic gap placement with a local-velocity
     blend and clamp the motion correction.
   - Why: can improve endpoint matching for inserted gap nodes without adding a
     large number of nodes.
   - Submit criteria: run completes, structural checks pass, output is not
     byte-identical to an already submitted candidate, and run statistics show
     gap-node placement actually changed.

2. **Exp106: outside-base spacing gate for density-adaptive gaps**
   - Base: Exp090/Exp092 branch.
   - Change: preserve base gap candidates, but require local spacing around
     extra outside-base candidates, initially `8.50 um`.
   - Why: tests whether density-adaptive additions need a precision guard in
     crowded regions.
   - Submit criteria: only if Exp090/092/103 results suggest density-gap changes
     are not harmful or if Exp105 shows gap geometry matters.

3. **Exp107: TTA / ILP-cost branch**
   - Base: learned inference path with TTA.
   - Change: enable TTA and test ILP appearance/disappearance weights around
     `0.0` / `1.4`.
   - Why: may change raw detections/associations rather than only graph repair.
   - Cost/risk: higher GPU/runtime cost and more moving parts; delay until the
     quick graph-post-processing variants are exhausted.

4. **Detector-preprocessing branch**
   - Base: bright/top-hat public detector mix.
   - Change: inspect attached weights and output density before deciding whether
     to integrate with our graph calibration.
   - Why: different detector errors could complement Exp073.
   - Cost/risk: larger branch with new artifacts; not a quick final-slot probe.

## Current recommendation

Build Exp105 next, after checking Exp104 has completed/submitted. It is the most
original, lowest-cost, and most directly compatible public idea from the
2026-07-17 scan.
