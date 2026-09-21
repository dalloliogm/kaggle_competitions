#!/usr/bin/env python3
"""Execute the code cells of the ROGII self-alignment validation notebook."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NOTEBOOK = (
    ROOT
    / "competitions"
    / "rogii-wellbore-geology-prediction"
    / "notebooks"
    / "rogii-lateral-self-alignment-masked-prefix.ipynb"
)


def display(value):
    print(value)


namespace = {"display": display}
notebook = json.loads(NOTEBOOK.read_text())
for index, cell in enumerate(notebook["cells"]):
    if cell["cell_type"] != "code":
        continue
    print(f"running code cell {index}", flush=True)
    exec(compile(cell["source"], f"{NOTEBOOK.name}:cell-{index}", "exec"), namespace)
