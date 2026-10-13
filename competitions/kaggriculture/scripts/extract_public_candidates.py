#!/usr/bin/env python3
"""Extract standalone agents from downloaded public notebooks without executing them."""

from __future__ import annotations

import ast
import base64
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NOTEBOOK_ROOT = ROOT / "references" / "public-notebooks"
OUTPUT_ROOT = ROOT / "submissions" / "public-notebook-candidates"

SPECS = {
    "salemali7-kaggriculture-2900": {
        "folder": "salemali7__kaggriculture-2900",
        "notebook": "kaggriculture-2900.ipynb",
        "cell": 13,
        "mode": "writefile",
        "url": "https://www.kaggle.com/code/salemali7/kaggriculture-2900",
        "votes_at_ingest": 76,
    },
    "tetsutani-shape-shop-pasture": {
        "folder": "tetsutani__shape-the-shop-work-the-pasture-kaggriculture",
        "notebook": "shape-the-shop-work-the-pasture-kaggriculture.ipynb",
        "cell": 9,
        "mode": "base64",
        "url": "https://www.kaggle.com/code/tetsutani/shape-the-shop-work-the-pasture-kaggriculture",
        "votes_at_ingest": 118,
    },
    "thomastschinkel-public-state-router": {
        "folder": "thomastschinkel__public-state-router",
        "notebook": "kaggriculture-public-state-router-74-5-win-rate.ipynb",
        "cell": 5,
        "mode": "writefile",
        "url": "https://www.kaggle.com/code/thomastschinkel/kaggriculture-public-state-router-74-5-win-rate",
        "votes_at_ingest": 98,
    },
    "lynnsakurai-farming-score-mathematical": {
        "folder": "lynnsakurai__farming-score-mathematical",
        "notebook": "farming-score-a-mathematical-approach.ipynb",
        "cell": 4,
        "mode": "base64",
        "url": "https://www.kaggle.com/code/lynnsakurai/farming-score-a-mathematical-approach",
        "votes_at_ingest": 43,
    },
}


def assignments(source: str) -> dict[str, object]:
    """Return literal top-level assignments; never execute notebook code."""
    values = {}
    for node in ast.parse(source).body:
        if not isinstance(node, ast.Assign) or len(node.targets) != 1:
            continue
        target = node.targets[0]
        if isinstance(target, ast.Name):
            try:
                values[target.id] = ast.literal_eval(node.value)
            except (ValueError, TypeError):
                pass
    return values


def extract(spec: dict) -> tuple[bytes, str | None]:
    path = NOTEBOOK_ROOT / spec["folder"] / spec["notebook"]
    notebook = json.loads(path.read_text(encoding="utf-8"))
    source = "".join(notebook["cells"][spec["cell"]]["source"])
    if spec["mode"] == "writefile":
        first, body = source.split("\n", 1)
        if first.strip() != "%%writefile main.py":
            raise ValueError(f"unexpected writefile header in {path}")
        return body.encode("utf-8"), None

    values = assignments(source)
    encoded = values.get("MAIN_B64")
    if not isinstance(encoded, str):
        raise ValueError(f"MAIN_B64 not found in {path}")
    expected = values.get("EXPECTED_MAIN_SHA256") or values.get("EXPECTED_SOURCE_SHA256")
    return base64.b64decode(encoded), str(expected) if expected else None


def main() -> None:
    for name, spec in SPECS.items():
        source, expected_hash = extract(spec)
        actual_hash = hashlib.sha256(source).hexdigest()
        if expected_hash and actual_hash != expected_hash:
            raise ValueError(f"hash mismatch for {name}: {actual_hash} != {expected_hash}")
        compile(source, "main.py", "exec")

        destination = OUTPUT_ROOT / name
        destination.mkdir(parents=True, exist_ok=True)
        (destination / "main.py").write_bytes(source)
        provenance = {
            "candidate": name,
            "source_url": spec["url"],
            "downloaded_latest_on": "2026-09-07",
            "source_notebook": str(
                (NOTEBOOK_ROOT / spec["folder"] / spec["notebook"]).relative_to(ROOT)
            ),
            "source_cell_index": spec["cell"],
            "votes_at_ingest": spec["votes_at_ingest"],
            "sha256": actual_hash,
            "expected_notebook_hash": expected_hash,
            "extraction": "literal decode only; notebook code was not executed",
            "score_status": "not independently verified; title/author claims are secondary evidence",
        }
        (destination / "provenance.json").write_text(
            json.dumps(provenance, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        print(json.dumps({"candidate": name, "bytes": len(source), "sha256": actual_hash}))


if __name__ == "__main__":
    main()
