# Notes

## EDA Observations

- Kaggle CLI check on 2026-07-10: `userHasEntered=True`; deadline reported as
  `2026-07-15 23:59:00`.
- Official data contains 400 JSON task files plus
  `data/neurogolf_utils/neurogolf_utils.py`.
- Task is ONNX-network construction for ARC transformations, not a conventional
  training/inference CSV workflow.
- The helper uses one-hot `[1, 10, 30, 30]` tensors; cells outside the ARC grid
  stay all-zero.
- A quick scan found 262 same-shape tasks, 52 same-shape tasks with preserved
  nonzero masks, and 4 pure per-cell color-map tasks across train/test/arc-gen.

## Feature Ideas

- Classify tasks by shape relation, nonzero-mask behavior, color palette
  changes, and local-neighborhood dependence.
- Prioritize tasks whose transformations can be expressed as small convolutions,
  color maps, fixed flips, shifts, masks, or simple reshape/gather graphs.

## Model Ideas

- Current baseline uses 1x1 convolution networks for pure color maps.
- Next likely useful templates: local convolution rules, fixed affine grid
  transforms, Kronecker-style expansion, crop/pad, and object mask extraction.

## Useful References

- Competition: https://www.kaggle.com/competitions/neurogolf-2026
- Official helper: `data/neurogolf_utils/neurogolf_utils.py`
- Current builder: `scripts/build_color_map_submission.py`
- Current manual package: `submissions/color-map-baseline/submission.zip`
