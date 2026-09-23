#!/usr/bin/env python3
"""Build the public 'metric anatomy' notebook.

Shares what the scoring formula actually rewards, measured rather than
asserted. The headline is a NEGATIVE result - the most tempting-looking lever
in the metric does not pay - so this helps people avoid a trap rather than
handing over a solution. CPU-only, so it costs no GPU quota.
"""
import json, re
from pathlib import Path

WS = Path(__file__).resolve().parent.parent
OUT = WS / "notebooks" / "public-metric-anatomy"
# Kaggle rejects titles over 50 characters with a bare 400.
TITLE = "Biohub Metric Anatomy: Where The Score Comes From"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")

def md(t): return {"cell_type": "markdown", "metadata": {}, "source": t.strip().splitlines(keepends=True)}
def code(t): return {"cell_type": "code", "execution_count": None, "metadata": {},
                     "outputs": [], "source": t.strip().splitlines(keepends=True)}

CELLS = [
md(r"""
# Where your score actually comes from

`score = adjusted_edge_jaccard + 0.1 x division_jaccard`

Three things about this metric are easy to miss, and all three change what is
worth optimising. This notebook measures them on the competition data rather
than asserting them.

1. **The ground truth is sparsely annotated.** On our runs only about **3% of
   predicted nodes** ever match a GT node. The other 97% are invisible to the
   edge Jaccard.
2. **Unmatched predictions are not false positives** - but every predicted node
   still counts in the node-count penalty, which multiplies the whole edge term.
3. **That penalty is worth far more than most post-processing knobs** - and it
   is still a trap. We measured the exchange rate and it does not pay.

Point 3 is the useful one, and it is a negative result: the obvious way to
exploit point 2 loses score. The arithmetic for why is below, so you can skip
the week we spent on it.
"""),

md(r"""
## 1. The formula

From the competition's own evaluation page and reference implementation:

- Predicted nodes are matched to GT nodes **per timepoint**, by optimal
  bipartite assignment on physical distance, capped at **7 um**
  (scale z=1.625, y=x=0.40625 um/voxel).
- A predicted edge is a **TP** when both endpoints match GT nodes joined by a
  GT edge. `J = TP / (TP + FP + FN)`.
- The reported number is **adjusted**:

      J_adj = max(0, J * (1 - alpha * node_ratio))
      node_ratio = (N_pred - N_target) / N_target,   alpha = 0.1

`N_target` is `estimated_number_of_nodes`, stored in each GT `.geff`. Note
carefully: `max(0, ...)` clamps the **result**, not the ratio. Predict fewer
nodes than `N_target` and `node_ratio` goes negative, so the factor goes
**above 1** and scales your Jaccard **up**.
"""),

code(r"""
import json, math
from pathlib import Path

COMPETITION = "biohub-cell-tracking-during-development"
# Kaggle mounts competition data under /kaggle/input/competitions/<slug> for
# some kernels and /kaggle/input/<slug> for others, so check both and then
# fall back to scanning for any directory that has a train/ beside it.
CANDIDATES = [Path(f"/kaggle/input/competitions/{COMPETITION}"),
              Path(f"/kaggle/input/{COMPETITION}")]
CANDIDATES += sorted(Path("/kaggle/input").glob("*")) if Path("/kaggle/input").exists() else []
CANDIDATES += sorted(Path("/kaggle/input/competitions").glob("*")) if Path("/kaggle/input/competitions").exists() else []
ROOT = next((c for c in CANDIDATES if (c / "train").is_dir()), None)
if ROOT is None:
    raise SystemExit(
        "Could not find the competition data. Attach it to this notebook "
        f"(Add Data -> {COMPETITION}). Looked in: "
        + ", ".join(str(c) for c in CANDIDATES[:4]))
print("competition data:", ROOT)

def estimated_nodes(geff: Path):
    # estimated_number_of_nodes lives in the geff root metadata.
    for name in ("zarr.json", ".zattrs"):
        p = geff / name
        if not p.exists():
            continue
        payload = json.loads(p.read_text())
        stack = [payload]
        while stack:
            cur = stack.pop()
            if isinstance(cur, dict):
                if "estimated_number_of_nodes" in cur:
                    return float(cur["estimated_number_of_nodes"])
                stack.extend(cur.values())
            elif isinstance(cur, list):
                stack.extend(cur)
    return None

geffs = sorted((ROOT / "train").glob("*.geff"))
print(f"{len(geffs)} training videos")
"""),

md(r"""
## 2. How sparse is the annotation?

`estimated_number_of_nodes` is an estimate of **every cell in the video**, not
the number that were labelled. Comparing it with the labelled node count shows
how much of each video is actually scored. Across all 199 training
videos this comes to **133,318 labelled nodes out of ~4.7M estimated cells -
2.82%** - and the per-video fraction spans **0.13% to 20.21%**, a 155x range.
"""),

code(r"""
# No zarr needed: a zarr array records its own length in its metadata, so the
# labelled node count is just the shape. Pure JSON keeps this notebook
# dependency-free (Kaggle CPU images have no zarr, and internet is off).
def labelled_nodes(geff):
    meta = geff / "nodes/ids/zarr.json"
    if not meta.exists():
        meta = geff / "nodes/ids/.zarray"
    if not meta.exists():
        return None
    shape = json.loads(meta.read_text()).get("shape")
    return int(shape[0]) if shape else None

rows = []
for g in geffs:
    n_target, labelled = estimated_nodes(g), labelled_nodes(g)
    if n_target and labelled:
        rows.append((g.stem, labelled, n_target, labelled / n_target))

rows.sort(key=lambda r: r[3])
print(f"{len(rows)} videos with both counts\n")
print(f"{'video':<20}{'labelled':>10}{'estimated total':>18}{'labelled %':>12}")
for stem, lab, tot, frac in rows[:5]:
    print(f"{stem:<20}{lab:>10,}{tot:>18,.0f}{frac*100:>11.2f}%")
print(f"{'...':<20}")
for stem, lab, tot, frac in rows[-5:]:
    print(f"{stem:<20}{lab:>10,}{tot:>18,.0f}{frac*100:>11.2f}%")

fr = sorted(r[3] for r in rows)
print(f"\nlabelled fraction: min {fr[0]*100:.2f}%  median {fr[len(fr)//2]*100:.2f}%  max {fr[-1]*100:.2f}%")
print(f"total labelled {sum(r[1] for r in rows):,} of {sum(r[2] for r in rows):,.0f} estimated cells "
      f"({sum(r[1] for r in rows)/sum(r[2] for r in rows)*100:.2f}%)")
print(f"\n=> the scored subset is tiny, and its size varies {fr[-1]/fr[0]:.0f}x between videos.")
"""),

md(r"""
## 3. Unmatched predictions are invisible - but not free

The reference implementation counts a predicted edge as a **FP only if at least
one endpoint matches a GT node that participates in GT edges**. An edge between
two *unmatched* nodes is neither TP nor FP. It never touches `J`.

The competition tutorial says this outright: *"unmatched predictions are not
punished as FPs, but the node-count penalty discourages mass over-detection."*

So a node you predict in an unannotated region cannot hurt your Jaccard - but
it does increase `N_pred`, and therefore scales your whole edge term.

On our own 24-video held-out set:

| | |
| --- | --- |
| predicted nodes | 468,572 |
| matching any GT node | 14,912 (**3.18%**) |
| GT edges (tp + fn) | 14,651 |

If we kept **only** the nodes that match GT, dropping the other 453,660, the
adjusted edge Jaccard would go from **0.9159 to 1.0387** - and true positives
would not change at all (13,967 either way); only false positives fall,
655 -> 15.

That is **+0.12** sitting in the node-count factor. It looks like the whole
competition.
"""),

md(r"""
## 4. The trap: why you cannot just predict fewer nodes

You cannot know at inference which cells were annotated. So any real rule prunes
a mix of matched and unmatched nodes, and every matched node you drop turns its
TP edges into FN.

The exchange rate decides it. With `alpha = 0.1`:

- removing one node is worth `0.1 * J / N_target`
- losing one TP edge costs `1 / (TP + FP + FN)`

Plug in our numbers and you need to remove **422 nodes for every TP edge you
lose** just to break even.
"""),

code(r"""
J, N_target, TP, FP, FN = 0.91252, 589_730, 13_967, 655, 684

gain_per_node = 0.1 * J / N_target
cost_per_tp   = 1.0 / (TP + FP + FN)
print(f"value of removing 1 node  = {gain_per_node:.3e}")
print(f"cost of losing 1 TP edge  = {cost_per_tp:.3e}")
print(f"BREAK-EVEN                = {cost_per_tp / gain_per_node:.0f} nodes per TP edge\n")

# What we actually measured, pruning whole short tracks (min track length).
measured = [("min_track_len 8", 14_051, 50), ("min_track_len 10", 26_903, 112),
            ("min_track_len 14", 57_596, 461), ("min_track_len 20", 104_343, 1_185),
            ("min_track_len 30", 184_504, 2_661)]
need = cost_per_tp / gain_per_node
print(f"{'rule':<20}{'nodes removed':>15}{'TP lost':>9}{'nodes/TP':>10}")
for name, dn, dtp in measured:
    print(f"{name:<20}{dn:>15,}{dtp:>9,}{dn/dtp:>10,.0f}{'   PAYS' if dn/dtp > need else ''}")
print(f"\nnone of them reach {need:.0f}.")
"""),

md(r"""
### We also tried learning it

Since simple rules top out around 280-360 nodes per TP edge, we trained a
gradient-boosting classifier to predict "will this node match a GT node", using
only features available at inference: track length, node degree, time, local
crowding, nearest-neighbour distance and position. Grouped cross-validation by
video.

**AUC 0.717** - so which cells get annotated is genuinely *not* random. It is
just not predictable enough:

    drop the lowest-scoring 5% of nodes
      +0.00370   node-count factor gain
      -0.00395   lost true positives
      -0.00025   net

Best learned exchange rate: **396** against a break-even of **422**. A 6%
shortfall - close enough to be tempting, still a loss.

Two further reasons it does not rescue: annotation density varies ~50x between
videos (section 2), so the rule would need to be per-video; and to target it
per-video you would need `N_target`, which lives in the GT `.geff` and **does
not exist for test videos**. The one targeting signal that would help is missing
exactly where you would use it.

**Conclusion: the +0.12 ceiling is real and, as far as we could find,
unreachable.** Raising the detector threshold globally is the naive version of
this and it scored 0.943 for us against 0.947 - worse, for exactly this reason.
"""),

md(r"""
## 5. A validation lesson that cost us more than any model change

Unrelated to the metric's structure, but it cost us a leaderboard place, so it
is worth passing on.

We compared post-processing candidates by their **aggregate** delta over a
24-video held-out set. One candidate looked validated: `+0.0017`, with a
bootstrap CI excluding zero. It **lost** on the leaderboard.

The reason: only 9 of the 24 videos were affected by the change at all. The
other 15 were exact ties - structural zeros - and including them tightened the
confidence interval without adding any evidence.

Restricting the paired test to the **affected** samples fixed it. The same
candidate then showed 3 wins against 6 losses and was correctly rejected. After
the fix, the harness agreed with the public board on every comparison we could
check, including one case where the aggregate had inverted the answer.

**If a change only moves a subset of your samples, measure it on that subset.**
Ties do not carry information, but they do shrink your error bars.
"""),

md(r"""
## Takeaways

1. **~97% of your predicted nodes are never scored directly.** They are
   invisible to the edge Jaccard because the GT is sparsely annotated.
2. **They are not free**: every node counts in `N_pred`, and the node-count
   factor multiplies your whole edge term. Under-predicting scales it *up*.
3. **Do not chase that.** Break-even is ~422 nodes removed per TP edge lost.
   Track-length pruning reaches ~280-360, a learned classifier ~396. We could
   not find a rule that pays, and the naive version (higher detector threshold)
   measurably loses.
4. **Detection quality beats detection quantity.** An edge is a TP only if
   *both* endpoints land within 7 um. Because z is 4x coarser than x/y, the
   same voxel error costs ~4x more in z.
5. **Measure changes on the samples they actually move.**

If you find a node filter that clears 422, please say so in the comments - we
would genuinely like to know we were wrong about this one.
""")]

nb = {"cells": CELLS, "metadata": {
        "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
        "language_info": {"name": "python"}},
      "nbformat": 4, "nbformat_minor": 5}

OUT.mkdir(parents=True, exist_ok=True)
(OUT / f"{SLUG}.ipynb").write_text(json.dumps(nb, indent=1) + "\n")
(OUT / "kernel-metadata.json").write_text(json.dumps({
    "id": f"dalloliogm/{SLUG}", "title": TITLE, "code_file": f"{SLUG}.ipynb",
    "language": "python", "kernel_type": "notebook",
    "is_private": True,          # flipped to public deliberately, after review
    "enable_gpu": False, "enable_tpu": False, "enable_internet": False,
    "dataset_sources": [], "kernel_sources": [],
    "competition_sources": ["biohub-cell-tracking-during-development"],
    "model_sources": [],
}, indent=2) + "\n")
print(f"wrote {(OUT / f'{SLUG}.ipynb').relative_to(WS)}")
print(f"  {len(CELLS)} cells, CPU-only (no GPU quota), is_private=True for now")
