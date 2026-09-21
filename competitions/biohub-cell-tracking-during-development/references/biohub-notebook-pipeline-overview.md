# Biohub notebook pipeline overview

<div style="display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px;align-items:stretch;margin:12px 0 18px">
<div style="border:1px solid #82acd1;border-top:5px solid #3979b7;padding:10px"><strong>1. Detect cells</strong><br><small>Find 3D cell centres in each frame.</small></div>
<div style="border:1px solid #aa9db9;border-top:5px solid #716a80;padding:10px"><strong>2. Score possible links</strong><br><small>Score candidate descendants in the next frame.</small></div>
<div style="border:1px solid #8fbd9b;border-top:5px solid #126b2c;padding:10px"><strong>3. Select a global graph</strong><br><small>Choose mutually compatible links with ILP constraints.</small></div>
<div style="border:1px solid #d6ad60;border-top:5px solid #b36a00;padding:10px"><strong>4. Repair and label lineages</strong><br><small>Repair gaps, relink motion, prune, and label divisions.</small></div>
</div>

## How this notebook implements the pipeline

| Stage | Implementation here | Provenance and role |
|---|---|---|
| Detect cells | U-Net/transformer detector with detection-time augmentation and a shared detection field from the attached model artifacts. | Public `pilkwang/biohub-tracking-support-pack-50ep-v1` and temporal seed `pilkwang/biohub-temporal-unet3d-seed314159-v1`; adapted competition notebook code. |
| Score possible links | Learned association probabilities, four-view edge TTA with reliability log-pooling, and the 22-feature local association ranker blended at 85/15. Exp196 adds a bounded three-frame forward-acceleration lookahead. | Public `pilkwang/biohub-local-association-ranker-unet300-v1` is used as an attached model artifact. The lookahead is the Exp196 change; it is not attributed to the source notebook. |
| Select a global graph | Binary lineage decisions are solved with ILP-style appearance, disappearance, division, parent, child, and adjacent-frame constraints. | The learned support-pack pipeline and its public graph-recipe lineage provide the base; this notebook exposes the configured costs and audits the emitted graph. |
| Repair and label lineages | `filter_output_graph` applies motion relinking, one-frame gap repair, safe-division rules, short-track filtering, and line-fit smoothing. DeepCenter is used only to confirm marginal synthetic gap repairs. | Gap/repair code is the adapted Biohub competition pipeline. DeepCenter comes from the attached `biohub-deepcenter-unet3d-center-prior-v1` model artifact. |

The full experiment history and stage assignments are recorded in the [Biohub approach timeline](https://dalloliogm.github.io/kaggle_competitions/biohub-approach-timeline.html). A clean structural audit is necessary but does not by itself establish a leaderboard gain.
