# Scale Lab 25 Project 3 LLM

## Links

- Competition: https://www.kaggle.com/competitions/scale-lab-25-project-3-llm/code
- Kaggle workspace slug: `scale-lab-25-project-3-llm`
- Kaggle CLI slug: `scale-lab-25-project-3-llm`

## Objective

Train a constrained character-level Transformer language model on the provided Lu Xun corpus.

## Evaluation

- Metric: Perplexity (PPL) on the test set.
- Validation approach: chronological token split from `train.csv`, with validation negative log-likelihood converted to perplexity.
- Public/private leaderboard notes: TBD

## Data

- Kaggle input path: `/kaggle/input/scale-lab-25-project-3-llm/`
- Local data path: `data/scale-lab-25-project-3-llm/`
- Key files: `train.csv`, `test.csv`

## Submission

- Expected file: `submission.csv`
- Required columns: TBD; fetched Kaggle metadata did not include a sample submission.
- Generated outputs: `submissions/`

## Rules And Constraints

- External data: TBD
- Internet: TBD
- GPU/TPU: Kaggle runtime recommended for training.
- Team/merge rules: TBD
- Model constraints: Transformer architecture; at most 6 layers, hidden size <=512, heads <=8, total parameters <=50M, vocabulary <=8k.
- Tokenizer constraint: character-level tokenizer from unique training characters and punctuation.

## Current Baseline

- Local CV: Pending Kaggle run.
- Public LB: TBD
- Notebook/kernel: `notebooks/char_transformer_baseline.ipynb`
