#!/usr/bin/env python3
"""The official (post-patch) division true-positive rule, and a test against ours.

## Why this exists

`compute_division_confusion` in our production notebook is labelled
"Division-matching reflects the organizers' post-exploit patch". It does not.
It accepts a ground-truth division as a true positive when

  * the anchor (the GT division source, or its GT parent) maps to a predicted
    node, and
  * both daughter lineages reach *some* predicted node, and
  * one weakly-connected component of the predicted graph contains a hit from
    each daughter lineage and contains *any* forking node anywhere.

`metrics.md` was patched on 2026-07-17 (commit aa65e90) precisely to remove the
weakly-connected-component route. The rule is now **local**:

  * the fork must be the matched anchor itself or its immediate successor, and
  * the two daughters must land on **two distinct direct-child branches** of
    that fork.

Ours is strictly more permissive, so it over-reports division Jaccard. Anything
we tuned against it - including the 2026-09-14 arm that halved the
safe-division caps and lost 0.946 -> 0.942 - was steered by a loose instrument.

This module implements the local rule next to a faithful transcription of ours,
and `main()` demonstrates the divergence on constructed graphs, including the
hub-node exploit the patch was written against.

Run: python3 scripts/division_metric_local_rule.py
"""

from __future__ import annotations


def weakly_connected_components(node_ids, edges):
    parent = {n: n for n in node_ids}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    for s, t in edges:
        if s in parent and t in parent:
            union(s, t)
    return {n: find(n) for n in node_ids}


def _gt_maps(gt_edges):
    gt_out: dict[int, set[int]] = {}
    gt_in: dict[int, int] = {}
    for s, t in gt_edges:
        gt_out.setdefault(s, set()).add(t)
        gt_in[t] = s
    return gt_out, gt_in


def _lineage(gt_out, root_child):
    seen = {root_child}
    stack = [root_child]
    while stack:
        cur = stack.pop()
        for nxt in gt_out.get(cur, ()):
            if nxt not in seen:
                seen.add(nxt)
                stack.append(nxt)
    return seen


def division_confusion_component(pred_nodes, pred_edges, gt_nodes, gt_edges,
                                 pred_to_gt, gt_to_pred):
    """Faithful transcription of the rule our notebook currently applies."""
    gt_out, gt_in = _gt_maps(gt_edges)
    pred_out: dict[int, set[int]] = {}
    for s, t in pred_edges:
        pred_out.setdefault(s, set()).add(t)

    components = weakly_connected_components(list(pred_nodes), list(pred_edges))
    fork_components = {
        components[n] for n, outs in pred_out.items()
        if len(outs) >= 2 and n in components
    }

    tp = fn = 0
    tp_gt_sources: set[int] = set()
    for gsrc in [s for s, o in gt_out.items() if len(o) >= 2]:
        children = sorted(gt_out[gsrc])[:2]
        anchors = [gsrc] + ([gt_in[gsrc]] if gsrc in gt_in else [])
        anchor_pred = [gt_to_pred[a] for a in anchors if a in gt_to_pred]
        hit_sets = []
        ok = True
        for child in children:
            hits = {components[p] for g in _lineage(gt_out, child)
                    if (p := gt_to_pred.get(g)) is not None and p in components}
            if not hits:
                ok = False
                break
            hit_sets.append(hits)
        if not ok or not anchor_pred:
            fn += 1
            continue
        anchor_comps = {components[p] for p in anchor_pred if p in components}
        if any(c in hit_sets[0] and c in hit_sets[1] and c in fork_components
               for c in anchor_comps):
            tp += 1
            tp_gt_sources.add(gsrc)
        else:
            fn += 1

    fp = sum(1 for n, outs in pred_out.items()
             if len(outs) >= 2 and (g := pred_to_gt.get(n)) is not None
             and g in gt_out and g not in tp_gt_sources)
    return tp, fp, fn


def division_confusion_local(pred_nodes, pred_edges, gt_nodes, gt_edges,
                             pred_to_gt, gt_to_pred):
    """The official post-patch rule: a *local* fork with two distinct branches.

    A ground-truth division at `gsrc` counts as a true positive when there is a
    predicted fork F such that

      * F is the predicted match of `gsrc`, or F is an immediate successor of
        that match, and
      * F has at least two outgoing edges, and
      * the two GT daughter lineages are reached through **two different**
        direct children of F.

    Sharing a component is not enough, and a fork elsewhere in the graph does
    not count. A hub node at t = -1000 is not the immediate successor of
    anything real, which is exactly what the patch closed.
    """
    gt_out, _gt_in = _gt_maps(gt_edges)
    pred_out: dict[int, set[int]] = {}
    for s, t in pred_edges:
        pred_out.setdefault(s, set()).add(t)

    def branch_nodes(child):
        """Every predicted node reachable from one direct child of the fork."""
        seen = {child}
        stack = [child]
        while stack:
            cur = stack.pop()
            for nxt in pred_out.get(cur, ()):
                if nxt not in seen:
                    seen.add(nxt)
                    stack.append(nxt)
        return seen

    tp = fn = 0
    tp_gt_sources: set[int] = set()
    for gsrc in [s for s, o in gt_out.items() if len(o) >= 2]:
        matched = gt_to_pred.get(gsrc)
        if matched is None:
            fn += 1
            continue
        # The fork is the matched parent, or its immediate successor.
        fork_candidates = [matched] + list(pred_out.get(matched, ()))
        children = sorted(gt_out[gsrc])[:2]
        lineages = [_lineage(gt_out, c) for c in children]
        pred_hits = [
            {p for g in lin if (p := gt_to_pred.get(g)) is not None}
            for lin in lineages
        ]

        found = False
        for fork in fork_candidates:
            outs = sorted(pred_out.get(fork, ()))
            if len(outs) < 2:
                continue
            branches = {c: branch_nodes(c) for c in outs}
            # Daughter 1 and daughter 2 must be reached via *different* direct
            # children of this fork.
            reach0 = {c for c, nodes in branches.items() if nodes & pred_hits[0]}
            reach1 = {c for c, nodes in branches.items() if nodes & pred_hits[1]}
            if any(a != b for a in reach0 for b in reach1):
                found = True
                break
        if found:
            tp += 1
            tp_gt_sources.add(gsrc)
        else:
            fn += 1

    fp = sum(1 for n, outs in pred_out.items()
             if len(outs) >= 2 and (g := pred_to_gt.get(n)) is not None
             and g in gt_out and g not in tp_gt_sources)
    return tp, fp, fn


def _case_real_division():
    """A correctly predicted division: parent 1 forks into 2 and 3."""
    gt_edges = [(1, 2), (1, 3), (2, 4), (3, 5)]
    pred_edges = [(11, 12), (11, 13), (12, 14), (13, 15)]
    nodes = lambda ids: {i: (0,) for i in ids}
    m = {1: 11, 2: 12, 3: 13, 4: 14, 5: 15}
    return dict(pred_nodes=nodes(range(11, 16)), pred_edges=pred_edges,
                gt_nodes=nodes(range(1, 6)), gt_edges=gt_edges,
                gt_to_pred=m, pred_to_gt={v: k for k, v in m.items()})


def _case_hub_exploit():
    """The exploit: no real fork, but a hub merges everything into one
    component and a fake fork sits somewhere inside it."""
    gt_edges = [(1, 2), (1, 3), (2, 4), (3, 5)]
    # The tracker missed the division: the parent just continues into daughter 1,
    # and daughter 2's lineage is an unconnected second track. No fork anywhere
    # near the real cell.
    pred_edges = [(11, 12), (12, 14), (13, 15)]
    # The exploit: a hub outside the volume wired to the root of every track -
    # including the anchor's own track - plus a chain of fake forks hanging off
    # it. This is what merges the whole graph into one weakly-connected
    # component.
    pred_edges += [(99, 11), (99, 13), (99, 90), (90, 91), (90, 92)]
    nodes = lambda ids: {i: (0,) for i in ids}
    m = {1: 11, 2: 12, 3: 13, 4: 14, 5: 15}
    return dict(pred_nodes=nodes([11, 12, 13, 14, 15, 90, 91, 92, 99]),
                pred_edges=pred_edges, gt_nodes=nodes(range(1, 6)),
                gt_edges=gt_edges, gt_to_pred=m,
                pred_to_gt={v: k for k, v in m.items()})


def _case_same_branch():
    """Both daughters land on the SAME branch of a real fork - the local rule
    requires two distinct branches, component reachability does not."""
    gt_edges = [(1, 2), (1, 3), (2, 4), (3, 5)]
    # 11 forks to 12 and 20, but both GT daughters match nodes under 12.
    pred_edges = [(11, 12), (11, 20), (12, 13), (13, 14), (14, 15)]
    nodes = lambda ids: {i: (0,) for i in ids}
    m = {1: 11, 2: 13, 3: 14, 4: 15, 5: 15}
    return dict(pred_nodes=nodes([11, 12, 13, 14, 15, 20]),
                pred_edges=pred_edges, gt_nodes=nodes(range(1, 6)),
                gt_edges=gt_edges, gt_to_pred=m,
                pred_to_gt={v: k for k, v in m.items()})


def main() -> None:
    cases = [
        ("real division, fork at the matched parent", _case_real_division()),
        ("hub exploit: no local fork, one shared component", _case_hub_exploit()),
        ("real fork, both daughters on one branch", _case_same_branch()),
    ]
    print(f"{'case':48s} {'ours (component)':>18s} {'official (local)':>18s}")
    print("-" * 88)
    disagreements = 0
    for name, kw in cases:
        a = division_confusion_component(**kw)
        b = division_confusion_local(**kw)
        flag = "" if a == b else "   <-- DIVERGES"
        if a != b:
            disagreements += 1
        print(f"{name:48s} {str(a):>18s} {str(b):>18s}{flag}")
    print("\n(tp, fp, fn)")
    print(f"{disagreements} of {len(cases)} cases diverge.")
    print("\nOurs credits a division whenever any fork shares a weakly-connected")
    print("component with both daughter lineages. The official rule requires the")
    print("fork to be the matched parent or its immediate successor, with the")
    print("daughters on two distinct direct-child branches. Ours is strictly more")
    print("permissive, so every division Jaccard we have measured locally is an")
    print("upper bound, not an estimate.")


if __name__ == "__main__":
    main()
