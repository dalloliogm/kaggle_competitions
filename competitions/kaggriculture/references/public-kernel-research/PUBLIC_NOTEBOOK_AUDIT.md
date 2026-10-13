# Kaggriculture Public Notebook Audit

Snapshot date: 2026-09-07

## Scope

- Ingested metadata for the first 200 competition-scoped public notebooks,
  sorted by vote count.
- Downloaded and inspected the actual latest source for four candidate agents.
- Extracted `main.py` without executing arbitrary notebook setup code.
- Verified syntax and ran each game in a fresh process under
  `kaggle-environments==1.32.7`, whose defaults match the official competition
  files.
- Queried exact public score metadata for a focused set of high-vote, recent,
  or high-claim notebooks. Scores are snapshots and can drift.

## Downloaded Candidate Comparison

| Candidate | Public notebook | Verified score | Source evidence | Local screen |
| --- | --- | ---: | --- | --- |
| PUB-001 | [Shape the Shop Work the Pasture](https://www.kaggle.com/code/tetsutani/shape-the-shop-work-the-pasture-kaggriculture), v11 | 2494.7 | Notebook-published SHA matched `2b97e2c653018ac4aeffb8463ec91c8f26b097b4cef81289acc25ccdbc68f916` | 10/10 vs starter; 10/10 vs Salem |
| ALT-001 | [Farming Score: A Mathematical Approach](https://www.kaggle.com/code/lynnsakurai/farming-score-a-mathematical-approach) | 2471.3 | Notebook-published SHA matched `1dc166ae2bf0c56a44fac4482f469b8812968c4cb32459cb9860f5077897a7d4` | 10/10 vs starter; statistically indistinguishable from PUB-001 across 20 side-swapped seeds |
| ALT-002 | [Public State Router](https://www.kaggle.com/code/thomastschinkel/kaggriculture-public-state-router-74-5-win-rate) | 2195.8 | Exact `%%writefile main.py` extraction | 10/10 vs starter; 10/10 vs Salem; slightly weaker than PUB-001 |
| ALT-003 | [Kaggriculture 2900+](https://www.kaggle.com/code/salemali7/kaggriculture-2900) | 1203.7 | Exact `%%writefile main.py` extraction | 10/10 vs starter; 0/10 vs PUB-001 |

The `2900+` and `74.5% Win Rate` phrases are author claims or titles, not the
current verified Kaggle score. The exact score lookup is the promotion evidence.

## Other Scores Checked

| Notebook | Verified public score |
| --- | ---: |
| [Kaggriculture Apex V7 God Emperor](https://www.kaggle.com/code/avioon/kaggriculture-apex-v7-god-emperor) | 2374.5 |
| [Kaggriculture Adaptive Farm Intelligence](https://www.kaggle.com/code/flexonafft/kaggriculture-adaptive-farm-intelligence) | 2156.3 |
| [V58 Minimax Closed Loop](https://www.kaggle.com/code/kaitofukami/238-238-known-streams-v58-minimax-closed-loop) | 1850.2 |
| [V29 Adaptive Market Hysteresis](https://www.kaggle.com/code/boatlee/v29-r1-adaptive-market-hysteresis) | 1841.7 |
| [The Soil Remembers Rain](https://www.kaggle.com/code/prvsiyan/kaggriculture-frontier-the-soil-remembers-rain) | 1672.7 |
| [The Moon Counts Melons](https://www.kaggle.com/code/prvsiyan/kaggriculture-frontier-the-moon-counts-melons) | 1648.1 |
| [Adaptive Farming Strategy](https://www.kaggle.com/code/tetsutani/adaptive-farming-strategy-for-kaggriculture) | 1569.9 |
| [Read the Market, Choose the Farm](https://www.kaggle.com/code/indarkarhana/rank-top10-read-the-market-choose-the-farm) | 1542.4 |

Some notebook score queries returned `None` and were not used as promotion
evidence. The broad top-score endpoint also returned a bounded HTTP 429, so this
is a focused audit rather than proof that PUB-001 is the globally highest-scored
public notebook.

## Lineage And Strategy

PUB-001 is a stored-route controller with four prefix-compatible route tails.
It switches only at three public-state checkpoints: Yarn Store presence at turn
226, carrot price at turn 360, and milk inventory at turn 433. A bounded repair
layer digs weeds on otherwise wasted actions, clamps infeasible sells, sells
dead stock, projects shed capacity, and leaves one of 100 shed slots free at day
close.

ALT-001 inherits PUB-001's route and repair stack and adds exact liquidation at
the final executable turn. The change is theoretically non-negative because
unsold final inventory has zero value, but the 20-seed direct panel produced the
same aggregate result as PUB-001. PUB-001 retains the stronger verified public
score and is therefore the first candidate.

## Local Evidence Boundaries

- All four extracted agents completed every 720-turn screen without errors.
- Against `starter`, all four won 10/10; this opponent is too weak to separate
  them.
- Against ALT-003 (Salem), PUB-001, ALT-001, and ALT-002 each won 10/10.
- PUB-001 versus ALT-001 across 20 seeds and both seats: 2 wins, 36 ties, and 2
  losses for ALT-001, with zero mean bank difference. The non-ties were seat
  effects paired across the two orientations.
- These tests establish runtime compatibility and relative behavior on selected
  seeds. They do not reproduce the public ladder opponent distribution.

## Recommendation

Prepare exact PUB-001 as the first submission candidate. Keep ALT-001 as a
fallback/second candidate only after PUB-001's live validation episode and early
ladder behavior are known. Do not upload either without checking the frozen
archive checksum and obtaining explicit approval.
