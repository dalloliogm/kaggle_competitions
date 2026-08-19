---
name: competition-approach-map
description: Create reusable, evidence-grounded HTML flow maps and timelines for Kaggle or other competition histories. Use when Codex needs to visualize experiment relationships, model-component focus, public/local scores, pending results, deliberate non-submissions, rejected directions, untried paths, or external notebook/data/discussion provenance from workspace records.
---

# Competition Approach Map

Create a compact interactive HTML map and, when chronology clarifies the decisions, a companion timeline. Show experiment lineage, model-component focus, decisions, and evidence without replacing the primary experiment record.

## Shared record and parity

Treat the competition workspace's Markdown records as the evidence-bearing source of truth and the HTML map/timeline as a rendered, navigable view of that same record. Do not maintain competing hand-written versions of scores, dates, statuses, motivations, architecture targets, provenance, or decisions. If the existing page is hand-curated, update the Markdown and HTML in the same change until a renderer or sync tool is available, and make any HTML-only explanatory prose clearly non-record content.

For each approach, maintain one stable record with, at minimum: `id`, date, what changed, why it was tested, architecture stage(s), local result, public result, private-result state, submission status, provenance, and follow-up/decision. Keep durable cross-experiment conclusions in `LEARNINGS.md`, linked to the relevant approach IDs rather than duplicating their full result. `TASKS.md` may hold operational state and pending work, but it must not become a second experiment ledger.

Prefer a structured registry when the Markdown tables cannot carry these fields cleanly. The registry may be JSON/YAML or a deliberately structured Markdown table, but it must be the single input from which the HTML inventory and timeline are rendered. The flow-map data should reference the same stable IDs and should not introduce a different score or status for an existing approach. If full generation is not yet implemented, perform a parity audit before handoff: compare approach IDs, dates, architecture targets, statuses, local/public/private result text, provenance links, and current-decision wording across Markdown and HTML.

## Gather evidence

1. Read the competition's `APPROACHES.md`, `LEARNINGS.md`, and current task/status file before mapping it.
2. Treat a public score, submission state, and local-validation result as distinct facts. Preserve uncertainty and date-stamp the map.
3. Include only approaches supported by source records. Collapse repetitive one-factor probes into one node only when the node names every included experiment and reports the full score range.
4. Explicitly label `not submitted because local evidence did not improve`, `invalid/rejected by platform`, `pending`, `held`, and `untried` separately.
5. Search the records for external provenance: public notebooks, public datasets/model assets, official discussions, and copied code. Record only a source and role that are explicit in the workspace; absence of a record is not proof of no use.

## Build the map

1. Create a JSON file following `assets/approach-map-data.example.json`.
2. Run `python3 scripts/generate_approach_map.py INPUT.json OUTPUT.html` to produce a standalone page. It needs no network access or build tooling.
3. Put the generated page in the repository's `docs/` directory when it should be publishable through GitHub Pages. Add a concise link from the competition's `APPROACHES.md`.
4. Use status colors consistently: submitted, best, rejected, not-submitted, pending, and untried. Do not call a result rejected merely because its score is pending.
5. Make relationships explicit with each node's `parents` field. Use a small number of lanes that reflect the real backbone and major branches.

## Timeline and system view

When the user needs to understand decision order, provide a linked timeline alongside the flow map. Each timeline node must state:

- **What** changed;
- **Why** it was tested;
- **Result**, keeping local validation, submission state, and public score distinct;
- **Public base** only when a public notebook or asset is explicitly recorded.

Add a compact plain-language model/system diagram when the submission is multi-stage. Do not assume the Biohub-style detection → association → global selection → repair pipeline is universal. Discover the stages from the competition records and code. For a typical tabular competition, a suitable diagram may be exploration/data audit → feature engineering → modelling → validation/evaluation → ensembling/post-processing/submission; omit stages that are not materially part of the work and split or merge stages when the actual workflow requires it. Place each experiment group under every component it changed. Give each timeline node a compact version of that pipeline with its changed stages highlighted; mark audits and controls separately rather than pretending they changed a component.

Treat the architecture as versioned and evidence-derived. If the initial system is not yet understood, use provisional stage names and label uncertain component assignments rather than inventing model details. When an experiment adds, removes, or reorganizes a component, preserve the earlier architecture in the dated timeline, update the current system view to the latest confirmed version, and record the transition in the experiment's What/Why/Result fields. Stage names should describe the decision system at the level useful for experiment planning, not necessarily the exact neural-network class or every implementation function.

For a page that combines a system view with a timeline, keep the document sections in this order unless the user explicitly requests otherwise: competition context and primer, model architecture and experiment focus, all-attempted-approaches inventory, chronological timeline, external-provenance ledger, and current decision. The inventory is a compact index; it must not replace or absorb the detailed timeline.

Before finalizing the architecture section, reconcile its focus chips against the newest dated records in `APPROACHES.md`, `LEARNINGS.md`, and the task/status file. Add recent experiments to every stage they actually changed, including independent detector/linker branches, controls, diagnostics, and held paths. Update the stage prose when the evidence changes the strategic conclusion, such as a linker bottleneck or a post-processing axis being closed. Do not label an experiment as a control merely because it tied the public frontier: distinguish controls, diagnostics, candidate submissions, and held work.

When adding an inventory table, include at least date, approach ID, descriptive change, motivation, architecture target, and result. Sort dated rows oldest to newest. Derive the description and motivation from the recorded changes, notes, follow-ups, and learnings rather than repeating generic category text. Keep public score, local validation, submission state, and private-score uncertainty separate. Use the same stage colours as the architecture diagram for target chips, and preserve the compact layout or responsive wrapping needed to avoid desktop horizontal scrolling.

Add an external-provenance ledger to the page and an `## External provenance log` to `APPROACHES.md`. For every recorded input, include: when it was used or reviewed, source name/link if known, source type (notebook, public model/data asset, or discussion), material used, affected experiments, and whether it was copied, adapted, inspiration-only, or evaluation context only. Explicitly state whether external raw competition data use is recorded. Never attribute a source author's leaderboard result to the user's submission.

## Required competition context

Put a compact context panel above the map with the following fields:

- short competition description and metric;
- a plain-language statement of what is predicted or submitted;
- the principal model families or decision-system approaches actually used;
- official Kaggle link;
- official start date, user entry date, and official finish date;
- final rank, final public score, and final private score after completion; or clearly state that they are not applicable while ongoing;
- one or more evidence-grounded lessons for finished competitions.

Do not infer missing dates, ranks, or private scores. State `Not recorded` and add the field when authoritative evidence becomes available.

For model families and lessons, prefer explicit evidence from `APPROACHES.md` or `LEARNINGS.md`. Use a short, specific summary such as `LightGBM + CatBoost residuals on a particle-filter anchor`, rather than a generic label like `machine learning`. If no conclusion has been earned, state `No completed postmortem yet`.

## Portfolio index

Maintain `docs/index.html` as the GitHub Pages entry point. Include the Kaggle link and map link (or `Map planned`) in the competition-name cell. Keep the remaining columns compact: prediction target, main models/approach family, main learning, status/period, and one combined leaderboard-outcome column for best public score, final public/private score, and final rank. Link an active map from the index as soon as it exists; add the remaining pages incrementally.

## Verify and hand off

1. Run the generator for the flow map when its JSON schema fits; extend the standalone page or generator for timeline, component, and provenance fields rather than silently dropping them.
2. Inspect HTML for escaped text, every input node, the component assignments, each provenance entry, and the architecture/inventory/timeline section boundaries. Confirm that the inventory and chronological timeline are both present and that the inventory precedes the timeline, with provenance and current decision after it.
3. Run `git diff --check`; stage only the map and narrowly related documentation.
4. For GitHub Pages, explain that a maintainer must select the `main` branch and `/docs` as publishing source, or enable an existing Pages workflow. Do not claim the page is deployed unless it actually is.

If a scripted replacement is used to refresh an inventory section, replace only the bounded inventory section (from its opening section tag through its closing tag). Re-parse the finished HTML and count/locate the `system`, `approach-inventory`, `timeline`, `provenance`, and `outcome` markers before committing; a successful HTML parse alone does not prove that a major section was not accidentally removed.

## Data rules

- `status` must be one of `submitted`, `best`, `rejected`, `not-submitted`, `pending`, or `untried`.
- `score` is display text; use `Not submitted`, `Pending`, or a precise local/public value rather than inventing a number.
- `parents` contains node IDs and supplies relationship labels. Use empty parents only for roots.
