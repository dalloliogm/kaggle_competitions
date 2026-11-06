# Team merger plan (2026-11-06) - nothing has been sent to anyone

## Facts
- Rules (rules.md 1b, foundational_rules 5c/5d/6a): max team size 5; merger is requested through the competition site by the team leader; deadline **2026-12-07 23:59 UTC**; combined submission count must not exceed (5/day x days of the competition) at the deadline (~84 days x 5 = ~420) - we have ~18 submissions, top teams ~220, so not binding; **no private sharing of code/data outside a team** (forum-public sharing only). So before a merger we can only talk about *ideas* and *results*, not exchange code.
- Prize eligibility: weights/intermediates need public generation code (hosts, threads 748882/752541/753662); merged team inherits the stricter of the two pipelines' provenance.
- Leaderboard 2026-11-06: ~4,887 teams; top 0.537; 6 teams >= 0.500; 15 >= 0.490; 725 >= 0.480; 210 teams tie at 0.477 starting at rank 1009. We (0.477) are ~rank 1009-1218: no medal on our own.

## Top of the public leaderboard
| Rank | Team | Score | Submissions | Members |
|---|---|---|---|---|
| 1 | Shehab Alshehabi | 0.537 | 219 | shehabalshehabi |
| 2 | Savko | 0.525 | 221 | savchenko |
| 3 | Oleksandr Parfionov | 0.519 | 101 | parfyon |
| 4 | democat | 0.512 | 92 | w1326627677 |
| 5 | pikachu | 0.504 | 186 | jzhpfn |
| 6 | Paweł Biernat | 0.501 | 95 | pawebiernatingenix |
| 7 | pain in the mass | 0.497 | 18 | christianherman,fraugygax |
| 8 | CHU1PC | 0.495 | 101 | lowasitgoes,tadashikato |
| 9 | grinders | 0.493 | 162 | gordeevmax,infibiss,smirnolegov |
| 10 | 剑锋所指！ | 0.493 | 39 | chronoscop |
| 11 | Shuta TAKANO | 0.492 | 165 | shutatakano |
| 12 | MY | 0.492 | 201 | mikhailyurasov |
| 13 | Amil Gentili | 0.492 | 28 | agentili |
| 14 | team051 | 0.490 | 56 | team051 |
| 15 | Day: chem. Night: Say my name. | 0.490 | 61 | heliosli |
| 16 | akmr | 0.489 | 41 | akimaru |
| 17 | JJ | 0.489 | 144 | aypyaypy,jjinho,ttyn4519 |
| 18 | S@i | 0.488 | 108 | sigmatango |
| 19 | thoughtspan | 0.488 | 96 | egotts |
| 20 | Sirui Zeng | 0.488 | 102 | siruizeng |
| 21 | James Y | 0.488 | 144 | redoctopusk |
| 22 | BMW | 0.487 | 66 | bibrocks1,mruddunijmodha |
| 23 | Johnny Lee | 0.486 | 49 | wuliaokaola |
| 24 | Tra Crew | 0.486 | 137 | tracrew |
| 25 | 無敵 | 0.486 | 53 | deveshupathak |

## What we can honestly offer
- A working, deterministic copy of the public 0.477 pipeline plus a reproducible **held-out validation harness** (300 molecules, per-candidate ICEBERG/GLACIER/fragment/neural scores; `validation_dump_2026-11-01/`, `arbiter/`) - useful for offline testing so that nobody pays 7 h per idea.
- A rank-1 arbiter framework (pairwise, clean features); it scored 0.477 (no measurable gain) so we should not oversell it.
- Compute/time: Kaggle GPU quota and agent-assisted engineering. NOT a better model than the public stack.
- Weak position for joining top-10 teams (they gain little from us). Better fits: teams at 0.480-0.495 that run an independent stack and lack an evaluation harness, or solo participants who say they are looking for teammates.

## Recommended approach (needs the user's go-ahead before anything is posted or sent)
1. Pick 5-8 candidate teams at 0.48-0.50 whose members have public notebooks/discussions showing a *different* pipeline (check their profiles; do not guess from the score).
2. Post ONE public message in the competition discussion (draft below) rather than DMs, which also fits the no-private-sharing rule.
3. Before any merge: agree in writing on prize split (default even shares, rules 4f), who is leader, which 2 finals get selected, and verify the partner's pipeline is reproducible (assets with public generation code).

## Draft public post (for the user to review/edit - not posted)
Title: Looking for a teammate: held-out validation harness for CASMI26 rank-1 / class-3 work

Body: We're at 0.477 on the public board with the shared pipeline and have built an offline validation harness (300 held-out molecules, structures purged from the library, per-candidate ICEBERG/GLACIER/fragment-coverage/neural scores, grouped-CV tooling for a leader-vs-challenger arbiter). It lets us test rank-1 and tail-slot ideas without paying ~7 h per rerun. Our arbiter experiment (LightGBM, swap only at P>0.8) scored 0.477 - i.e. no measurable gain - so we are looking for a partner with an independent pipeline (different encoder/candidate generation/class-3 handling) rather than another copy of the shared one. Happy to share validation results and methodology publicly in this thread. We have open team places and the merger deadline is Dec 7. Please reply here with: your public score, what is different about your pipeline, and one check you'd run to see whether a combination helps beyond the public LB.

## Shortlist from public footprints (2026-11-07)
Method: took the 25 teams >= 0.486 on the public board, listed each member's public competition notebooks (`kaggle kernels list --competition ... --user ...`) and searched the ~27 saved forum threads for their names. **20 of the 25 have no public competition notebook at all**, and only 3 appear in the forum, so a pipeline cannot be judged for most of them; "no footprint" is not evidence either way.

| Priority | Team (rank, score, submissions, members) | Evidence from public footprint | Why a fit | Caveat |
|---|---|---|---|---|
| 1 | **Tra Crew** (24, 0.486, 137, solo `tracrew`) | Forum thread 751300 (Oct 23): found "a class 3 lever" worth +0.003-0.004 LB, expects another +0.007-0.010, but "ran out of GPU" | Complementary: class-3 idea + we have a held-out validation harness and Kaggle GPU quota | Their lever is unverified by us; solo, may not want to share before merging (private sharing rule) |
| 2 | **Aryan Awasthi** (221, 0.481, 62, `aryanawasthiteykik` + `kinolutor`) | Public series of notebooks with an independent stack: own spectrum->fingerprint MLP (GPU-trained), LambdaRank ranker with 1-2 bond fragmentation + analog features; S1/S2 held-out validation identical in spirit to ours (S2 = enveda-180 with no public spectra); forum thread 748524 | Independent engine, rigorous validation, 2-person team with 3 open places; their S2 numbers: ranker 0.502 -> 0.627 (+frag) -> 0.660 (+analogs), LB gain ~+0.03-0.04 | Their standalone engine scored only 0.272 and RRF-merging it into a 0.437 pipeline gave +0.001; we have ourselves seen fragment signal give only ~+0.005 on top of 0.477 |
| 3 | **MarvinTMB** (42, 0.484, 16 subs, solo, last submission 2026-10-08) | Forum 744470: "You do not need NIST or any additional data for a better score"; reached 0.484 on 10-08 with 16 submissions | Likely an independent stack ahead of the public one at that date | No public notebooks; inactive since Oct 8 (may be waiting for the final, or gone) |
| 4 | **pain in the mass** (7, 0.497, 18 subs, `christianherman` + `fraugygax`) | None public; 0.497 with only 18 submissions | High score per submission suggests their own approach, not knob-sweeping | Zero evidence about method; 2 members, 3 open places |
| 5 | Low-submission strong teams: **Amil Gentili** (13, 0.492, 28), **剑锋所指！** (10, 0.493, 39), **team051** (14, 0.490, 56), **akmr** (16, 0.489, 41), **BMW** (22, 0.487, 66) | None public | Few submissions at high score = less public-board tuning | Nothing known about methods |
| not recommended | **heliosli** (15, 0.490, 61) | Public notebook `casmi26-0-482` = fork of the shared 0.465 + neural consensus (same lineage as ours) | Active, publishes openly | Same pipeline as ours, so a merger adds little diversity |

Notes:
- Team ranks/scores are from the 2026-11-06 snapshot (top 0.537, 6 teams >= 0.500). Scores move daily.
- Aryan Awasthi's validation design matches ours (S1/S2 splits), including the finding that popularity helps S1 but not S2 - a strong sign they would use our dump properly.
- Best first move is the **public post** (draft above), plus one reply under thread 751300 addressed to Tra Crew and thread 748524 addressed to Aryan Awasthi, rather than any private message (rules: no private code sharing; talking about ideas publicly is fine). Nothing has been posted.
- Before any merge: check the partner's assets for public generation code (hosts: weights/intermediates need it for prize eligibility), agree prize split (default even shares), leader, and the two final selections.
