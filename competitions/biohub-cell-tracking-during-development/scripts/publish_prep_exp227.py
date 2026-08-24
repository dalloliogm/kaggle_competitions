#!/usr/bin/env python3
"""Retitle the 0.918 notebook and clear inherited internal wording from its code.

The markdown was already polished for publication. What remained were code-level
leftovers from the upstream lineage: comments and printed strings naming
"Biohub 159B", a strategy-guard message describing a change this notebook does
not make, and audit artefacts called `biohub_162_gpt_feedback.txt`.

These are STRING AND COMMENT edits only. Nothing executable changes - no
threshold, no gate, no control flow - so the run must reproduce the scored
submission exactly. That is the point of re-running it: if the new output's
sha256 matches submission 55724576, the published notebook demonstrably
produces the 0.918 result and the claim is earned rather than asserted.

Retitling changes the Kaggle slug (Kaggle derives it from the title, not the
metadata id), so this publishes as a new kernel rather than a new version of
the internal one. The internal exp227 kernel is left untouched as the record of
the scored run.
"""

from __future__ import annotations

import ast
import json
import re
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
SOURCE = WORKSPACE / "notebooks" / "biohub-exp227-divergence-mutualnn-wide.ipynb"
OUT_DIR = WORKSPACE / "notebooks" / "safe-divisions-lb-0918"
TITLE = "Biohub Safe Divisions Without False Forks LB 0.918"
# Kaggle derives the kernel slug from the TITLE, not from the metadata id, so
# derive it the same way. A hand-written id that disagrees with the title is
# rejected with a bare 400 on push.
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")

# (old, new, minimum expected occurrences). Comments and message strings only.
TEXT_EDITS = (
    (
        "# Freeze Biohub 159B and permit exactly one longer-context association integration.",
        "# Freeze the association stack so the only change under test is the\n"
        "# safe-division admission logic.",
        1,
    ),
    (
        'raise RuntimeError("Biohub 159B contains an unintended extra change. '
        'Do not use this run for model selection.")',
        'raise RuntimeError("The frozen association stack drifted. '
        'Do not use this run for model selection.")',
        1,
    ),
    (
        'print("Strategy guard: PASS — Biohub 159B plus exactly one three-frame '
        'forward acceleration lookahead integration is active.")',
        'print("Strategy guard: PASS — the association stack is frozen and only the '
        'safe-division admission logic differs.")',
        1,
    ),
    (
        "# Full clean-graph audit, SHA256, provenance summary, and GPT feedback block.",
        "# Full clean-graph audit, SHA256, and provenance summary.",
        1,
    ),
    ('print(f"GPT feedback: {GPT_FEEDBACK_PATH}")',
     'print(f"Audit summary: {GPT_FEEDBACK_PATH}")', 1),
    ('GPT_FEEDBACK_PATH', 'AUDIT_SUMMARY_PATH', 3),
    ('"biohub_162_gpt_feedback.txt"', '"submission_audit_summary.txt"', 1),
    ('"biohub_162_audit.json"', '"submission_audit.json"', 1),
    ('EXPERIMENT_TAG = "biohub_162_forward_acceleration_lookahead_target0916_nohack"',
     'EXPERIMENT_TAG = "divergence_mutual_nn_safe_divisions"', 1),
    ('"notebook": "biohub_162_forward_acceleration_lookahead_target0916_nohack.ipynb",',
     '"notebook": "safe-divisions-without-false-forks-lb-0-918.ipynb",', 1),
    ("***** GPT FEEDBACK END *****", "***** AUDIT SUMMARY END *****", 1),
    ("***** GPT FEEDBACK START *****", "***** AUDIT SUMMARY START *****", 1),
    ("Biohub 159B with a three-frame continuation bonus inside motion assignment",
     "Frozen association stack with divergence and mutual-NN safe-division admission", 1),
    ("# This refines the clean 0.915 Biohub 159B association graph.",
     "# This refines the frozen association graph.", 1),
    ('"DO NOT SUBMIT: the three-frame forward acceleration lookahead mechanism '
     'produced the exact Biohub 159B submission. The hypothesis was inactive."',
     '"DO NOT SUBMIT: the output is identical to the frozen baseline. '
     'The change under test was inactive."', 1),
    ("'CLEAN FORWARD-ACCELERATION LOOKAHEAD 0.916 CANDIDATE. "
     "Submit once against Biohub 159B=0.915. '",
     "'CLEAN CANDIDATE: the graph audit passed and the output differs from the "
     "frozen baseline. '", 1),
)


# The one identifier this script renames. Declared explicitly so the structural
# check below stays strict about everything else - a rename it does not know
# about still fails the build.
ALLOWED_RENAMES = {"AUDIT_SUMMARY_PATH": "GPT_FEEDBACK_PATH"}


def structural_signature(source: str) -> str:
    """AST shape with string constants blanked and declared renames undone.

    Two notebooks with the same signature differ only in string literals,
    comments, and the identifier renames listed in ALLOWED_RENAMES. Any other
    difference - a changed threshold, an added branch, a reordered call - shows
    up as a signature mismatch.
    """
    tree = ast.parse(source)
    for node in ast.walk(tree):
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            node.value = ""
        elif isinstance(node, ast.Name) and node.id in ALLOWED_RENAMES:
            node.id = ALLOWED_RENAMES[node.id]
    return ast.dump(tree)


def main() -> None:
    nb = json.loads(SOURCE.read_text())
    before = [
        "".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"
    ]

    applied = 0
    for index, cell in enumerate(nb["cells"]):
        if cell["cell_type"] != "code":
            continue
        text = "".join(cell["source"])
        original = text
        for old, new, _minimum in TEXT_EDITS:
            if old in text:
                text = text.replace(old, new)
        if text != original:
            cell["source"] = text.splitlines(keepends=True)
            applied += 1

    after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    for old, _new, minimum in TEXT_EDITS:
        remaining = sum(c.count(old) for c in after)
        if remaining:
            raise RuntimeError(f"{old!r} still present {remaining}x")
        if sum(c.count(old) for c in before) < minimum:
            raise RuntimeError(f"{old!r} was expected at least {minimum}x in the source")

    # The load-bearing check: identical structure, only strings differ.
    for index, (old_code, new_code) in enumerate(zip(before, after)):
        if old_code == new_code:
            continue
        try:
            if structural_signature(old_code) != structural_signature(new_code):
                raise RuntimeError(
                    f"code cell {index} changed structurally; only strings and "
                    "comments may differ"
                )
        except SyntaxError as error:
            raise RuntimeError(f"code cell {index} no longer parses: {error}") from error

    for stale in ("159B", "GPT feedback", "biohub_162"):
        hits = sum(c.count(stale) for c in after)
        if hits:
            raise RuntimeError(f"{stale!r} still appears {hits}x in code")

    OUT_DIR.mkdir(exist_ok=True)
    out = OUT_DIR / f"{SLUG}.ipynb"
    out.write_text(json.dumps(nb, indent=1) + "\n")

    metadata = json.loads(
        (WORKSPACE / "notebooks"
         / "biohub-exp227-divergence-mutualnn-wide.kernel-metadata.json").read_text()
    )
    metadata["id"] = f"dalloliogm/{SLUG}"
    metadata["title"] = TITLE
    metadata["code_file"] = out.name
    metadata["is_private"] = True   # publication stays a separate, deliberate act
    metadata.pop("docker_image", None)
    (OUT_DIR / "kernel-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")

    print(f"wrote {out.relative_to(WORKSPACE)}")
    print(f"  {applied} code cells edited (strings/comments only, AST verified)")
    print(f"  title: {TITLE}")
    print(f"  is_private: {metadata['is_private']}")


if __name__ == "__main__":
    main()
