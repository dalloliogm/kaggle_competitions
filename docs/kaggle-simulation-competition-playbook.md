# Kaggle simulation competition playbook

Use this playbook for Kaggle competitions where the submission is an agent or
bot that plays repeated episodes, for example Kaggle Environments games such as
Orbit Wars or Maze Crawler.

The core lesson from Orbit Wars: public replays are not just debugging artifacts.
They can be turned into a training dataset and can reveal the right action
abstraction before spending days tuning heuristics.

## First-pass checklist

Do these early, before committing to a heuristic-only path:

1. Confirm the competition type.
   - Is the submission an `agent(obs)` function, `main.py`, or package archive?
   - Are episodes/replays public or downloadable?
   - Are there public replay datasets, daily episode indexes, or Meta Kaggle
     tables with submission/team ratings?

2. Build replay tooling.
   - Download several episodes for our submissions and high-scoring public
     submissions when IDs are available.
   - Parse each step into `(observation, action, reward/status)` records.
   - Track player count, seat, source planet/body, target or inferred target,
     ship count, no-op frequency, launch ETA, and win/loss.

3. Mine strong-player behavior.
   - Filter episodes to strong teams or strong submissions using public score,
     leaderboard rank, Meta Kaggle, or curated public replay datasets.
   - Separate 2-player and 4-player games when game modes differ.
   - Compare action distributions before designing the model or heuristic:
     no-op rate, all-in rate, partial-send rate, target distance/ETA, and
     number of launches per active turn.

4. Decide the action abstraction from replay evidence.
   - Prefer the simplest action space that covers strong behavior.
   - For Orbit Wars, top agents showed that `no-op` and near-all-in launches to
     short-ETA targets dominated; arbitrary fractional fleet sizing was less
     important than source/target/timing.
   - If the official action is low-level, such as angle and ship count, consider
     converting it to a higher-level label such as source -> target plus
     all-in/no-op.

5. Create a behavior-cloning baseline if feasible.
   - Supervised input: encoded board state at step `t`.
   - Supervised target: the move made by a strong player at step `t`.
   - Use this to validate observation encoding, action labels, and model capacity.
   - A behavior-cloned model can be a starting point for self-play RL, but even
     without RL it can expose useful policy patterns.

6. Build an arena before large tuning.
   - Run local head-to-head and multi-agent evaluation in separate processes.
   - Track separate ratings/metrics for each game mode.
   - Treat live ladder replays as ground truth when local results disagree.

## Replay-to-training dataset pattern

For each replay step and player:

```text
input:
    observation before action
    current player id
    game mode / player count
    optional no-action future projection

target:
    no-op or launch
    source body
    target body, inferred from trajectory if needed
    ship count bucket or all-in flag
```

Useful filters:

- Keep only high-rated submissions or teams.
- Keep games after major environment/rule updates.
- Drop actions that cannot be mapped into the chosen action space.
- Drop or flag timeouts, invalid actions, and malformed trajectories.
- Keep separate validation sets by episode, not by individual step, to avoid
  leakage from adjacent states.

## When to use RL or imitation learning

Use imitation learning when:

- public replays are abundant;
- strong players have consistent action patterns;
- the action space can be reconstructed reliably;
- you need a quick way to test observation encoding and model architecture.

Use self-play RL when:

- the environment can be simulated quickly;
- you can run enough games to get stable improvement;
- the policy must exceed the public replay distribution;
- you have a reliable promotion/evaluation loop against prior checkpoints.

Use a heuristic planner when:

- compute is limited;
- replay labels are sparse or hard to reconstruct;
- deterministic forecasting and search can capture most of the game logic.

For strong heuristic agents, prioritize:

- early-game opening search;
- target-wise planning rather than only source-wise greedy moves;
- future ownership/ship projection;
- source vulnerability scoring;
- delayed execution when waiting creates a better opportunity;
- multi-source or chained reinforcement plans.

## Workspace artifacts to create

In a competition workspace, create or update:

- `TASKS.md`: add replay mining, action-space analysis, behavior cloning, and
  arena-building tasks.
- `LEARNINGS.md`: record discovered action distributions and replay-derived
  strategy patterns.
- `APPROACHES.md`: separate heuristic, behavior-cloning, and self-play tracks.
- `references/replays/`: store downloaded sample replays or indexes.
- `scripts/`: add replay parsers, action label extractors, and arena runners.

Do not submit an ML agent only because behavior cloning trains locally. First
validate runtime packaging, inference speed, and live ladder behavior.

## Lessons added from Kaggriculture (2026-10)

1. **Run the first-pass checklist before tuning, not after.** Five days went
   into heuristic tuning that plateaued at ~600 ladder rating; submitting a
   public agent moved it to ~1600 in a day. The checklist above would have
   surfaced that on day one.

2. **A public-agent survey is itself a first-pass step.** In a mature
   simulation competition the public notebooks carry a collaborative lineage
   (Apache-2.0, month-long attribution chains) far beyond what a fresh
   hand-built agent reaches. Extract them, benchmark them head-to-head, and
   treat the best as the baseline to beat. `competitions/kaggriculture/tools/
   extract_notebook_agent.py` recovers an agent from a notebook without
   executing it (base85/base64 tar.gz, gzip or lzma, often in
   implicitly-concatenated chunks, sometimes with a published SHA-256).

3. **Score against the built-in baseline does not rank agents.** Repeatedly:
   the highest scorer against `starter` lost every head-to-head game. Only
   position-balanced head-to-head counts, and ties deflate win counts for
   near-identical agents, so compare means too.

4. **Mining gives hypotheses, not parameters.** A strong cohort's behaviour
   profile (livestock mix, land timing, seed and sale volumes, hiring curve)
   is cheap to extract and validated one of our choices exactly. But porting
   their volumes into a different architecture measured *worse* in every
   combination: their numbers depend on machinery we do not have. Mine for the
   mechanism, then test it.

5. **Verify the submission state by submitting.** A competition can disable
   submissions while still showing a later deadline; the CLI reports a bare
   400, and the real message is in `e.response.text`.
