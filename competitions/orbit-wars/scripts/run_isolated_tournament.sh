#!/usr/bin/env bash
# Run each candidate in a SEPARATE process to avoid the sys.modules collision
# (every agent ships its own orbit_lite/producer_anchor_agent; in one process the
# first-loaded wins). One fresh `uv run` per candidate => correct per-candidate
# loading. Opponents are held constant across candidates, so relative ranking is
# valid even though opponent orbit_lite may still share the candidate's in-process.
set -euo pipefail
cd /Users/giovannidallolio/workspace/kaggle_competitions/competitions/orbit-wars

SEEDS_JSON="$1"          # e.g. "[911,1012]"
shift
# remaining args: name=relpath pairs for candidates
OPP='{"i-m-stronger":"submissions/candidates/i-m-stronger/main.py","current-anchor":"submissions/candidates/meta0622-anchor-producer-wave-control/unpacked/main.py","apex":"submissions/candidates/apex-hybrid/main.py"}'

for pair in "$@"; do
  name="${pair%%=*}"
  path="${pair#*=}"
  cfg="/tmp/iso_${name}.json"
  out="submissions/iso-${name}.json"
  cat > "$cfg" <<JSON
{
  "candidates": {"${name}": "${path}"},
  "opponents": ${OPP},
  "seeds": ${SEEDS_JSON},
  "modes": [4],
  "mixed": true,
  "output": "${out}"
}
JSON
  echo "### Running candidate ${name} in fresh process ###"
  OMP_NUM_THREADS=2 OPENBLAS_NUM_THREADS=2 MKL_NUM_THREADS=2 \
    uv run scripts/tournament.py "$cfg" 2>&1 | grep -E "AGGREGATE|${name}" | tail -4
done

echo "=== MERGED RANKING ==="
python3 - "$@" <<'PY'
import json, sys, glob
rows=[]
for pair in sys.argv[1:]:
    name=pair.split('=')[0]
    f=f"submissions/iso-{name}.json"
    try:
        d=json.load(open(f))
        a=d['aggregate'][name]
        rows.append((name,a))
    except Exception as e:
        print("missing",name,e)
rows.sort(key=lambda r:(-r[1]['win_rate'], -r[1]['avg_survival_frac'], -r[1]['avg_final_share']))
print(f"{'candidate':<14}{'win':>6}{'survive':>9}{'surv_frac':>11}{'share':>8}{'err':>5}")
for name,a in rows:
    print(f"{name:<14}{a['win_rate']:>6.2f}{a['survival_rate']:>9.2f}{a['avg_survival_frac']:>11.2f}{a['avg_final_share']:>8.3f}{a['errors']:>5}")
PY
