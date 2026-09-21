# Synthetic 3D microscopy dataset: source audit

Audited 2026-08-18 from the current public Kaggle notebook sources, without
downloading the 18.5 GB output or running/submitting a competition notebook.

## Sources inspected

- Explorer: <https://www.kaggle.com/code/josefreitasalvesneto/synthetic-3d-microscopy-data-for-cell-tracking>
  (SHA-256 `f038937e995f7d007a4d1d6723e2e7595744be41b7ad3a569c8205a13f0748bd`)
- Generator: <https://www.kaggle.com/code/josefreitasalvesneto/biohub-synthetic-dataset>
  (SHA-256 `04ed49b48c896dea94b2d47d5f59c00479d53a1cba109925642be0dccb9a97e5`)

Both notebook metadata files list the Biohub competition as their sole
competition source and list no external dataset source.

## What the released output builder actually uses

The output-producing path is `run_dataset_build()`, enabled by
`DSBUILD_RUN=1`. It:

- calibrates per-field counts and a shell geometry from the first ten videos of
  one training embryo, using DoG detections;
- creates static volumes with `gen_volume_native`: parametric super-Gaussian
  nuclei, dark medium, emitted-light halo, anisotropic Gaussian PSF, Poisson and
  Gaussian camera noise, and XY stride pooling;
- creates six-frame sequences by evolving synthetic particles with a
  persistent Ornstein-Uhlenbeck-like velocity plus collective drift; divisions
  branch a parent into two daughter particles with sampled sister separation.

The published builder does *not* call the older `build_template_bank`,
`liquid_model`, real-residual, or histogram-matching branches that also exist
in the notebook. Those branches use real image templates, fields, and texture,
but they are not on the released dataset-build path. This distinction matters:
the release is calibrated to competition training data, but its output images
are not direct composites of real training frames.

## Material limitations for our use case

1. **The division label is a simulated graph event, not a measured mitotic
   appearance.** At a branching step the generator renders the two daughter
   positions; it does not model a real pre-division morphology, chromatin
   dynamics, or segmentation transition. It can supervise graph geometry and
   motion, but does not establish an image-specific mitosis detector.
2. **The division rate is deliberately high.** The build uses `DS_DIV_RATE=0.05`
   per transition, versus the notebook's stated real rate of about 0.26% of
   nodes. A model trained on these examples needs explicit class-prior control;
   copying its output probability threshold to real data would be unsafe.
3. **The sequence labels use native XY coordinates while sequence images are
   stored after 4x XY stride pooling.** `nodes` stores `tr["pos"]` in the
   `(64, 256, 256)` native coordinate frame, while `volumes` is
   `(T, 64, 64, 64)`. An adapter must divide node `y,x` by four before image
   feature extraction. The provided `voxel_um_pooled=[1.625,1.625,1.625]`
   confirms that this conversion is intended but not performed in the saved
   node array.
4. **The sequences are short (`T=6`) and collision-avoiding.** They suit a
   two-frame edge pretraining task, but they do not reproduce long-term lineage
   structure, occlusion, or difficult crowded interaction dynamics.
5. **Calibration generalisation is weakly established.** The builder calibrates
   on one embryo's first ten videos. The explorer demonstrates distributional
   comparisons, but no held-out real benchmark of division or link prediction
   is supplied.

## Practical conclusion

Do not replace the Exp183 detector/linker or train a direct mitosis-image model
from this data. The defensible first use is a bounded pretraining control for
the existing two-frame association stage:

1. write an adapter that produces pooled-coordinate pair examples and preserves
   a provenance manifest;
2. pretrain only a second-child / branching-candidate scorer on synthetic
   sequences, with real-prior weighting;
3. fine-tune it on the real train graphs while keeping detection and primary
   child association frozen;
4. generate a diagnostic-only Exp183 fork and submit only if it selectively
   changes existing safe-division candidates, leaves ordinary edges essentially
   intact, and passes the usual output and graph audits.

This remains a model-diversity experiment. The labelled real division set is
too sparse for trustworthy local model selection, so synthetic holdout tests
would validate the implementation only; public-LB comparison would still decide
whether the branch transfers.
