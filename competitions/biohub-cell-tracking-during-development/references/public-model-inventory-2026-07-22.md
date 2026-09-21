# Public pretrained models available (2026-07-22 survey)

Searched Kaggle datasets/kernels for alternative detector and linker weights,
since six axes are bracketed at the 0.910 ceiling and the only remaining lever is
a genuinely different model.

## Drop-in compatible with our ensemble (same unet_transformer architecture)

- **`subinium/biohub-v34-retrain-weights-mirror`** (CC0). `unet_transformer/split_0/
  edge_predictor_best.pth`, 8,360,813 bytes. **config.json IDENTICAL to ours**
  (32ch, [32,64,128], downsample [1,4,4], window 2, pool 5.0). Size differs from
  our 8,363,159 -> a SEPARATE training run. This is an INDEPENDENTLY-TRAINED model
  of the identical architecture - the genuine ensemble diversity we could not
  afford to train (~483 T4-hours). Adds to Exp133's ensemble with one path.
  HIGHEST-VALUE FIND.
- `hongdaekim/biohub-350ep-checkpoint-pin-v1`, `-300ep-` (CC0). README confirms
  these PIN pilkwang's OWN run at earlier epochs (same lineage as our 402ep), so
  correlated - low added diversity, like our best/last. hongdaekim already uses
  350ep as a second ensemble checkpoint.

## Genuinely different architectures (integration projects, not drop-in)

- `justinkim1216/biohub-nnunet-flow-support-v1` + `-center-support-v1`:
  flow-field + center-prediction detectors (biohub_flow_unet.pt / biohub_center_unet.pt,
  ~5 MB each) with a compact `source/model.py`. Different detector; flow-based =
  the temporal-affinity linking idea from the forum.
- `subinium/biohub-trackastra-public-weights-mirror`: Trackastra linker
  (ctc/model.pt 110 MB, general_2d/model.pt 43 MB). Different transformer linker;
  needs the trackastra package and segmentation masks. Biggest project.
  Reference kernel: `jirkaborovec/biohub-celltrack-dog-trackastra-graph-trans`.
- `drkongvis/biohub-v4-3dunet-pretrained-weights`: different 3D U-Net detector
  (unet3d.pt 16 MB, unet3d_pretrained.pt 49 MB).
- `drkongvis/biohub-v1-diffusion-refine-weights`: diffusion refinement (12 MB).
- `pilkwang/biohub-local-association-ranker-unet300-v1`: tiny alternative
  linker/reranker (local_association_ranker.pt 20 KB) + feature stats.

## Recommended next action

Add `subinium/biohub-v34-retrain-weights-mirror` to the Exp133 checkpoint
ensemble as a genuinely independent member. Zero training, one path. Sequence
after Exp133 (correlated ensemble) scores, to separate "ensembling helps" from
"independent diversity helps".
