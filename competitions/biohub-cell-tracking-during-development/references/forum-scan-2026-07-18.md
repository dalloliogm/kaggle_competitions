# Forum scan: 2026-07-18

Source: Kaggle competition discussions fetched with the repo Kaggle account and
cached via the Nvidia Kaggle discussion-ingest helper.

## Actionable threads

### Division metric exploit and patch

- URL: <https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/discussion/727154>
- Author: Thibaut Goldsborough, 2026-07-18.
- Summary: the hosts confirmed an exploit in the division Jaccard score. They
  patched the public metric implementation and plan to rescore submissions.
- Use for us: do not pursue metric-hack graph constructions, fake forks, repeated
  tracks, or negative-time/artificial hub strategies. Re-run local validation
  with the patched evaluator before trusting any division-heavy gain.
- Original-submission implication: keep division changes biologically plausible
  and generated upstream, not post-hoc metric gaming.

### Frozen frames and sudden global jumps

- URL: <https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/discussion/724283>
- Main claim: many `6bba` training videos have exact duplicate adjacent frames,
  while `44b6` apparently does not. A posted scan reported `947` duplicate
  adjacent pairs across `114/128` `6bba` videos and none across `71` `44b6`
  videos.
- Example repeated schedules reported:
  - `6bba_05b6850b`, `6bba_07477033`, `6bba_5b28472a`: duplicate after frames
    `4, 12, 27, 42, 52, 57, 59, 62, 66, 76`.
  - `6bba_1f58c2f6`, `6bba_20852818`, `6bba_80d12824`: duplicate after frames
    `1, 14, 19, 43, 44, 45, 49, 57, 61, 66, 73`.
- Use for us: build a frozen-transition-aware original candidate:
  1. identify exact or near-exact duplicate adjacent frames in each test movie;
  2. across frozen transitions, prefer zero/near-zero displacement links and
     disable normal motion extrapolation;
  3. across the transition after a frozen run ends, allow a slightly relaxed
     displacement/jump gate because physical motion may be accumulated;
  4. apply this only to detected duplicate transitions, not globally.
- Why this differs from our recent probes: Exp105/106/107 only tune gap geometry
  and density thresholds; they do not condition on temporal acquisition artifacts.

### Temporal affinity / flow-field tracking

- URL: <https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/discussion/723655>
- Main idea: treat linking as a temporal affinity or motion-field prediction
  problem, using short tracks or pseudo-labels from several trackers to supervise
  local displacement/link affinity.
- Useful observations from the thread:
  - short links dominate;
  - long predicted links are often wrong and should be filtered aggressively;
  - open-source trackers can provide pseudo-labels for short-track training;
  - dense or rendered point volumes can make temporal U-Net style models easier
    to debug than raw microscopy-only models.
- Use for us: medium-effort branch, not an immediate slot filler. The quickest
  version is not a new deep model; use existing learned edge probabilities plus
  local motion consistency as an affinity rescoring term before Hungarian/ILP
  linking.

### Higher-order cell tracking

- URL: <https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/discussion/726521>
- Main idea: a higher-order cell tracking method and pretrained inference code
  are available at <https://github.com/royerlab/hoct>.
- Caveat: the author notes results depend on segmentation-mask quality, and CPU
  may beat GPU depending on cell count.
- Use for us: possible post-challenge or high-effort branch. It is not the best
  immediate submission candidate unless we can quickly create compatible masks
  from the existing detections/segmentations and validate runtime.

### Scoring timeouts and connected components

- URL: <https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/discussion/724917>
- Main claim: scoring timeouts may be driven by graph connected-component
  structure more than raw node count. Long heavily repaired components may score
  slower than similarly sized fragmented graphs.
- Use for us: keep submission graphs sane:
  - no giant artificial connected components;
  - cap aggressive gap closing/relinking in dense movies;
  - include component-size diagnostics in structural validation.

### Rule-based baseline remains a useful diagnostic

- URL: <https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/discussion/716952>
- Main idea: multi-scale DoG and Hungarian linking were strong because detection
  quality dominated early gains; divisions and gap-closing did not automatically
  improve public LB.
- Use for us: this supports our current bias: avoid further broad division
  tuning after Exp101-104 tied or regressed; prioritize data-artifact-aware
  linking/gap behavior.

### Boundary annotation gaps

- URL: <https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/discussion/726381>
- Main claim: some boundary cells may be split into separate GT lineages when
  they leave/re-enter the field of view.
- Use for us: boundary-aware relinking is risky because biologically continuous
  tracks can be penalized if GT splits them. For boundary-adjacent nodes, prefer
  conservative termination over forced gap closing unless there is strong learned
  edge support.

## Recommended order

1. Build a frozen-transition-aware original candidate on top of Exp073/Exp092.
   This is the best immediate forum-derived experiment because it is cheap,
   original, and conditions on a reported systematic artifact.
2. Add component-size diagnostics to the validator before any more aggressive
   graph repair.
3. Prototype affinity rescoring using existing learned edge probabilities and
   local motion consistency. Do this after the current Exp105/106/107 batch
   resolves, unless submission slots remain and the frozen-frame candidate is
   already queued.
4. Keep HOCT as a larger branch only if we have time to inspect masks/runtime.
