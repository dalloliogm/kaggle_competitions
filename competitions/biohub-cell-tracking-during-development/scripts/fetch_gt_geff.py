#!/usr/bin/env python3
"""Mirror a train/<stem>.geff from the Kaggle competition into a local tree.

The CLI writes every -f download to <p>/<basename>, so nested paths collide.
Give each file its own -p directory and the tree reconstructs correctly.
"""
import json, subprocess, sys, shutil
from pathlib import Path

COMP = "biohub-cell-tracking-during-development"
ROOT = Path("/tmp/claude-0/-home-user-kaggle-competitions/"
            "079e2126-1615-5dfd-bdeb-d1a861286f6c/scratchpad/gt")

def fetch(rel: str, dest_root: Path) -> bool:
    out = dest_root / rel
    if out.exists():
        return True
    out.parent.mkdir(parents=True, exist_ok=True)
    r = subprocess.run(
        ["uvx", "--index-url", "https://pypi.org/simple", "kaggle", "competitions",
         "download", "-c", COMP, "-f", rel, "-p", str(out.parent)],
        capture_output=True, text=True, timeout=300,
        env={**__import__("os").environ, "UV_HTTP_TIMEOUT": "300"})
    if "404" in r.stdout + r.stderr:
        return False
    got = out.parent / Path(rel).name
    if got != out and got.exists():
        got.rename(out)
    # Kaggle sometimes wraps single files in a zip.
    z = out.with_suffix(out.suffix + ".zip")
    if z.exists():
        shutil.unpack_archive(str(z), str(out.parent)); z.unlink()
    return out.exists()

def array_files(base: str, dest: Path):
    """Return the chunk paths for a zarr v3 array, reading its own metadata."""
    meta = dest / base / "zarr.json"
    if not meta.exists():
        return []
    m = json.loads(meta.read_text())
    shape = m.get("shape", [])
    chunks = (m.get("chunk_grid", {}).get("configuration", {}) or {}).get("chunk_shape", shape)
    if not shape:
        return []
    n = []
    for dim, ch in zip(shape, chunks):
        n.append(max(1, -(-dim // max(1, ch))))
    idxs = [[]]
    for count in n:
        idxs = [p + [i] for p in idxs for i in range(count)]
    sep = m.get("chunk_key_encoding", {}).get("configuration", {}).get("separator", "/")
    return [f"{base}/c" + "".join(sep + str(i) for i in ix) for ix in idxs]

def fetch_stem(stem: str) -> bool:
    g = f"train/{stem}.geff"
    dest = ROOT
    if not fetch(f"{g}/zarr.json", dest):
        print(f"  {stem}: no root zarr.json"); return False
    arrays = [f"{g}/nodes/ids"] + [f"{g}/nodes/props/{p}/values" for p in ("t", "z", "y", "x")] \
             + [f"{g}/edges/ids"]
    for grp in (f"{g}/nodes", f"{g}/edges"):
        fetch(f"{grp}/zarr.json", dest)
    ok = True
    for a in arrays:
        if not fetch(f"{a}/zarr.json", dest):
            print(f"  {stem}: missing {a}/zarr.json"); ok = False; continue
        for c in array_files(a, dest):
            if not fetch(c, dest):
                print(f"  {stem}: missing chunk {c}"); ok = False
    return ok

if __name__ == "__main__":
    stems = sys.argv[1:]
    good = 0
    for s in stems:
        if fetch_stem(s):
            good += 1
            print(f"  {s}: ok")
    print(f"{good}/{len(stems)} stems fetched into {ROOT}")
