# Orbit Wars postmortem

Date: 2026-07-09

## Final result

- Team: Orbitiamo (`dalloliogm`)
- Final rank: 394 / 4730
- Final score: 1102.3
- Medal: bronze
- Final counted submission: `53980317` (`pa-prodweight`)

Cutoffs from the final leaderboard snapshot:

- Bronze/top 10% cutoff: rank 473, score 1089.5
- Silver/top 5% cutoff: rank 236, score 1136.0
- Gold/top 1% cutoff: rank 47, score 1349.0
- Winner: Isaiah @ Tufa Labs, score 1865.1

## What the top submissions did differently

### 1st place: scaled self-play RL

Public write-up: <https://www.kaggle.com/competitions/orbit-wars/discussion/714324>

Key mechanics:

- Single 200M-parameter transformer trained for 15B self-play RL steps.
- Entity-based observation: planets, fleets, comets, player/global summary tokens, scratch tokens.
- Target-based action space: choose whether each eligible source launches, choose a target, then choose fleet size with a learned distribution.
- PPO self-play, training 2P and 4P simultaneously.
- Strong submission engineering: int8/4-bit quantization, capped visible fleets, fallback to a smaller 5M model when overage time became tight.
- Evaluation against previous best checkpoints; promote a checkpoint only after strong head-to-head performance.

Direct replay spot check of submission `53993189` showed a very different launch rhythm from our heuristic:

- Many no-op turns.
- When acting, usually 1-3 launching sources per active turn.
- Most launches were effectively all-in from the source planet (`>=90%` of available ships in 236/270, 91/98, and 97/112 sampled launches across three replays).

Interpretation: the best agent was not winning through many tiny tactical corrections. It learned when to wait, then commit strongly, with enough model capacity to understand whether the commitment was strategically safe.

### 2nd place: compact RL with all-in action simplification

Public write-up: <https://www.kaggle.com/competitions/orbit-wars/discussion/723728>

Key mechanics:

- 4.3M-parameter ModernBERT + 1D-CNN model.
- Features are a 20-step no-action future timeline per body: production, radial/angular coordinates, per-player ships, and ships needed to capture.
- Action space simplified to two actions per body: no-op or all-in toward a short-distance target with ETA < 20.
- Inference uses rotation augmentation and opponent-permutation augmentation.
- Started with imitation learning from high-quality replay data, then moved to PPO/self-play from scratch; final model trained for 10B steps.
- Maintained a fast Rust local arena and OpenSkill-style local leaderboard.

Important lesson: action-space simplification was a strength, not a weakness. Top replays showed that no-op and all-in dominated strong play, so the model spent capacity on choosing source/target/timing rather than learning arbitrary fractional fleet sizing.

### Strong rule-based agents: deeper planning than ProducerLite

Public write-up: <https://www.kaggle.com/competitions/orbit-wars/discussion/713354>

Key mechanics:

- Dedicated early-game search over neutral capture sequences, scoring production at a 30-60 step horizon.
- Future state forecasting for each planet 20-30 steps ahead.
- Target-wise planning instead of source-wise planning, enabling multi-source cooperation.
- Scenario categories: neutral captures, defenses, reinforcements, strong attacks, weak attacks, sniper opportunities.
- Evaluation includes both value gained at the target and vulnerability created at source planets.
- Delayed execution: can wait for a better future opportunity instead of always launching immediately.
- Reinforcement chains, e.g. A -> B -> C, to bring productive planets online earlier.

This is the most useful comparison for our heuristic path: our final bots were still mainly single-source, current-turn wave planners. The strongest rule-based agents were closer to a receding-horizon planner with early-game opening search and target-level plan evaluation.

## Gap analysis against our final agents

Our final line of improvement was correct but shallow:

- Fixed the 2P/4P router bug.
- Added per-source budget caps to reduce 4P overcommitment.
- Added production weighting to target selection.

That was enough for bronze, but not enough for silver/gold. The top submissions attacked the same failure modes at a more fundamental level:

1. We patched overcommitment; they modeled future ownership and source vulnerability.
2. We weighted production in a shortlist; they optimized production compounding over future capture sequences.
3. We selected single-source waves greedily; they either learned multi-source coordination or explicitly searched target-wise plans.
4. We treated local benchmarks as noisy but did not build a reliable rating arena; top competitors built fast simulators and checkpoint-vs-checkpoint evaluation loops.
5. We stayed rule-based because of time; gold was dominated by RL/self-play.

## Practical takeaways for the next simulation competition

1. Build the fast simulator/arena first.
   - The top RL and rule-based solutions both depended on cheap evaluation.
   - For agent competitions, local throughput is the main multiplier.

2. Use replay data earlier.
   - Behavioral cloning or replay mining can reveal action-space structure.
   - Here, the key insight was that strong agents mostly used no-op/all-in/short ETA actions.

3. Simplify the action space before scaling.
   - A constrained but well-chosen action space can outperform flexible hand tuning.
   - Source -> target + no-op is a good default abstraction for planet-war games.

4. If staying rule-based, implement opening search and target-wise planning.
   - Greedy per-source planning has a bronze-level ceiling.
   - Production compounding, source vulnerability, delayed execution, and multi-source plans are the next tier.

5. Treat 2P and 4P mix as a first-class variable.
   - Several write-ups mention that public/final matchmaking mix changed.
   - Training/evaluation should track separate 2P/4P ratings and a blended score under multiple plausible mixes.

6. Preserve exact live-state instrumentation.
   - Our biggest jump came from detecting that the router never actually called the intended 4P agent.
   - Future agents should log/count routing, player count, launch style, and failure mode from real ladder replays from day one.
