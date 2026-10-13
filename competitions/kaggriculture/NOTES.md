# Notes

## EDA Observations

- This is a 2-player, 720-turn planning game, not a supervised prediction task.
- The opponent's farm and the shared market/town are public; shed, seeds, and
  carried inventories are private to each player.
- Only banked coins at season end count. A policy needs an explicit liquidation
  phase and must avoid shed overflow (100 non-seed items).
- Crops die after two consecutive unwatered days; planting day already counts
  as the first missed day. Animals have one day of initial feed grace.
- Premium products can crash to the $1 price floor under oversupply, so profit
  estimates that assume fixed base prices are misleading.

## Feature Ideas

- Day/hour, remaining season, unit position, planted crop age, care state,
  expected yield readiness, market price/inventory displacement, repeated town
  shops, free shed capacity, and marginal travel/action cost.

## Model Ideas

- Deterministic daily scheduler with separate planting, maintenance, harvest,
  transport, and liquidation priorities.
- Short-horizon search for openings, then rule-based operations.
- Replay-derived behavior cloning only after inspecting strong public episodes
  and defining a compact legal action representation.

## Useful References

- `references/competition-files/unpacked/README.md`: full mechanics.
- `references/competition-files/unpacked/AGENTS.md`: API and submission guide.
- `../../docs/kaggle-simulation-competition-playbook.md`: replay-first workflow.
- https://www.kaggle.com/competitions/kaggriculture
- `references/public-kernel-research/PUBLIC_NOTEBOOK_AUDIT.md`: exact public
  notebook provenance, score screen, code lineage, and local evidence.
