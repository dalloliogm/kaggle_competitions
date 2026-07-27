# AutoML and tabular foundation-model assessment

Date: 2026-07-27

## Verdict

AutoGluon and Mitra can be evaluated locally, but neither is a good standalone
submission branch for the current autonomous CPU sandbox.

- AutoGluon's classical ensemble was effectively tied with the existing
  CatBoost specialist across all 16 official replay tasks.
- Mitra was effectively tied with AutoGluon's classical ensemble on three
  identical sampled test sets, while taking 28x to 173x longer.
- The official Kaggle Docker manifest includes TPOT, H2O, Optuna, and CatBoost,
  but not AutoGluon, TabPFN, or Mitra.
- The evaluator has no internet, so unavailable packages and model weights
  cannot be installed or downloaded during a session.

The most credible next branch remains a bounded, schema-gated portfolio built
from packages already present in Kaggle's image, with a fast sklearn fallback
and an immediate valid submission.

## AutoGluon classical replay

Configuration:

- AutoGluon Tabular 1.5.0
- explicit LightGBM, CatBoost, XGBoost, random forest, extra trees, logistic
  regression, and weighted ensemble
- `presets="medium_quality"`
- 45-second per-task fit limit
- three CPU workers
- complete 10,000-row test set scored for every task

| Metric | AutoGluon | CatBoost specialist |
| --- | ---: | ---: |
| Mean AUC, 16 tasks | 0.79948 | 0.79902 |
| Median AUC | 0.82335 | 0.81811 |
| Mean AUC, rows >= 2,000 | 0.82699 | 0.82474 |
| Mean AUC, rows < 2,000 | 0.73897 | 0.74243 |
| Per-task wins | 8 | 8 |

AutoGluon's largest gains were `train_10` (+0.0103 AUC) and `train_11`
(+0.0074). It was slightly worse on all five tasks below 2,000 training rows.
Mean elapsed time was 7.75 seconds per task in the local replay.

Raw results: `autogluon-classical-replay.csv`.

## Mitra sampled replay

Mitra 1.5.0 was run in zero-shot mode on CPU. AutoGluon estimated roughly
7.0 GB of required memory. The model weights occupied 289 MB; the complete
temporary Python environment occupied 1.1 GB.

Full 10,000-row inference on `train_13` was stopped after measured throughput
indicated a roughly 14-minute run. Quality comparisons therefore use the same
deterministic 1,000-row test sample for both Mitra and AutoGluon classical.

| Task | Mitra AUC | Classical AUC | Delta | Mitra sec | Classical sec |
| --- | ---: | ---: | ---: | ---: | ---: |
| `train_05` | 0.68426 | 0.68661 | -0.00235 | 118.5 | 4.2 |
| `train_09` | 0.63670 | 0.63959 | -0.00288 | 256.2 | 1.5 |
| `train_13` | 0.62782 | 0.62520 | +0.00262 | 54.5 | 1.0 |

`train_03` did not fit successfully under the available local memory. The
three completed comparisons are within sampling noise on quality but not on
runtime. Mitra is not justified as a CPU specialist on this evidence.

Raw results: `mitra-sampled-replay.csv` and
`mitra-vs-autogluon-sampled-replay.csv`.

## TabPFN feasibility

TabPFN was not benchmarked because it fails three deployment screens:

1. The current TabPFN repository recommends GPU use because CPU inference is
   slow.
2. Current default TabPFN weights use a non-commercial license. The older v2
   path uses a modified Apache license with an additional attribution clause;
   compatibility with the competition's OSI-approved-code requirement should
   be confirmed before submission.
3. TabPFN is absent from the official Kaggle image, and the evaluator cannot
   download packages or weights.

It remains scientifically interesting for a separate GPU benchmark, but it is
not a safe competition-agent dependency today.

## Other AutoML packages in Kaggle's image

The current official `Kaggle/docker-python` manifest contains:

- TPOT
- H2O
- Optuna
- CatBoost

H2O AutoML is the only additional packaged AutoML system worth a bounded
follow-up. It should be tested with a strict runtime cap and an already-written
fallback because it starts a Java service and can consume substantial memory.
TPOT's evolutionary search is a poor match for a time-limited agent unless its
generations and population are made very small, at which point a direct model
portfolio is simpler and more predictable. Optuna is an optimizer rather than
a complete tabular AutoML system and would spend precious time tuning a single
hidden task.

## Sources

- AutoGluon installation:
  https://auto.gluon.ai/stable/install.html
- AutoGluon foundation models and Mitra:
  https://auto.gluon.ai/stable/tutorials/tabular/tabular-foundational-models.html
- Mitra model card:
  https://huggingface.co/autogluon/mitra-classifier
- TabPFN repository and CPU guidance:
  https://github.com/PriorLabs/TabPFN
- TabPFN license:
  https://github.com/PriorLabs/TabPFN/blob/main/LICENSE
- Official Kaggle Python image:
  https://github.com/Kaggle/docker-python
