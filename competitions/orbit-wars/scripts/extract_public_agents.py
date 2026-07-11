#!/usr/bin/env python3
"""Materialize selected public Orbit Wars agents from downloaded notebooks."""

from __future__ import annotations

import base64
import hashlib
import json
import tarfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PUBLIC = ROOT / "references" / "public-kernels"
OUTPUT = ROOT / "submissions" / "candidates"


def code_cells(path: Path) -> list[str]:
    notebook = json.loads(path.read_text())
    cells = []
    for cell in notebook["cells"]:
        if cell.get("cell_type") != "code":
            continue
        source = cell.get("source", "")
        cells.append("".join(source) if isinstance(source, list) else source)
    return cells


def extract_writefile_agent(notebook: Path, destination: Path) -> None:
    for source in code_cells(notebook):
        lines = source.splitlines()
        if lines and lines[0].strip() == "%%writefile main.py":
            destination.mkdir(parents=True, exist_ok=True)
            (destination / "main.py").write_text("\n".join(lines[1:]) + "\n")
            return
    raise RuntimeError(f"No %%writefile main.py cell found in {notebook}")


def extract_meta_archives(notebook: Path, prefix: str = "meta") -> None:
    source = next(source for source in code_cells(notebook) if "ARCHIVES = {" in source)
    namespace: dict[str, object] = {}
    executable = source.split("if SUBMISSION_VARIANT not in ARCHIVES:", 1)[0]
    exec(executable, namespace)
    archives = namespace["ARCHIVES"]

    for variant, info in archives.items():
        destination = OUTPUT / f"{prefix}-{variant.lower().replace('_', '-')}"
        destination.mkdir(parents=True, exist_ok=True)
        payload = base64.b64decode(info["b64"])
        digest = hashlib.sha256(payload).hexdigest()
        if digest != info["sha256"]:
            raise RuntimeError(f"Checksum mismatch for {variant}")
        archive = destination / "submission.tar.gz"
        archive.write_bytes(payload)
        with tarfile.open(archive, "r:gz") as handle:
            handle.extractall(destination / "unpacked")
        (destination / "metadata.json").write_text(
            json.dumps(
                {
                    "variant": variant,
                    "role": info["role"],
                    "recommended_slot": info["recommended_slot"],
                    "strategy": info["strategy"],
                    "sha256": digest,
                    "size": len(payload),
                },
                indent=2,
            )
            + "\n"
        )


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    extract_meta_archives(
        PUBLIC / "meta-0621" / "orbit-wars-meta-snapshot-0621.ipynb",
        "meta",
    )
    extract_meta_archives(
        PUBLIC / "meta-0622" / "orbit-wars-meta-snapshot-0622.ipynb",
        "meta0622",
    )
    extract_writefile_agent(
        PUBLIC / "v8-1250" / "orbit-wars-v8-max-1250-score.ipynb",
        OUTPUT / "v8-1250",
    )
    extract_writefile_agent(
        PUBLIC / "i-the-orbit" / "i-the-orbit.ipynb",
        OUTPUT / "i-the-orbit",
    )
    for folder, notebook in (
        ("i-m-stronger", "orbit-wars-i-m-stronger.ipynb"),
        ("exp50", "orbit-wars-exp50.ipynb"),
        ("light-1200", "light-ver-1200-simple-orbit-intruder.ipynb"),
        ("v2-gru", "v2-gru.ipynb"),
        ("apex-hybrid", "apex-hybrid-dynamic-ring-control-border-defense.ipynb"),
    ):
        destination = OUTPUT / folder
        extract_writefile_agent(PUBLIC / folder / notebook, destination)
        support = (
            ROOT
            / "references"
            / "datasets"
            / "producer-orbit-wars-utils"
            / "orbit_lite"
        )
        target = destination / "orbit_lite"
        if not target.exists():
            import shutil

            shutil.copytree(support, target)
    print(f"Extracted candidates under {OUTPUT}")


if __name__ == "__main__":
    main()
