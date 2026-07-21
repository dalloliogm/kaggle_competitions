#!/usr/bin/env bash
# Push and submit the exp129-132 batch that a prior session built but never
# landed on Kaggle. RUN THIS LOCALLY (or in an environment whose network policy
# allows api.kaggle.com) - it will not work anywhere the Kaggle API host is
# blocked by the egress proxy.
#
# What it does, per experiment:
#   1. stage the notebook + its sidecar *.kernel-metadata.json into a clean push
#      folder with a canonically named kernel-metadata.json
#   2. kaggle kernels push   (Kaggle auto-increments the version; queues behind
#      the 2-concurrent-GPU-session cap on its own)
#   3. launch scripts/await_validate_submit.py in the background, which waits for
#      the kernel to COMPLETE, downloads submission.csv, re-validates the full
#      invariant set, refuses duplicates, and only then submits.
#
# Daily budget note: exp128 already used 1 of today's 5 slots, so these 4 exactly
# fill the day. If a kernel from a previous push already ran to COMPLETE, you can
# skip its push line to avoid burning GPU hours re-running it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
COMP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NB_DIR="${COMP_DIR}/notebooks"
STAGE_ROOT="${COMP_DIR}/.push_work"
AWAIT="${COMP_DIR}/scripts/await_validate_submit.py"
KG=(uvx --index-url https://pypi.org/simple kaggle)

# experiment : kernel-slug : notebook-basename : submit message
EXPERIMENTS=(
  "dalloliogm/biohub-exp129-finetuned-model|biohub-exp129-finetuned-model|exp129 fold-1 fine-tuned model, Exp126 graph recipe frozen (TIGHT_UM 7.0); first submission from a self-trained model"
  "dalloliogm/biohub-exp130-min-track-10|biohub-exp130-min-track-10|exp130 node-count: OUTPUT_MIN_TRACK_LEN 6->10 on Exp126 recipe"
  "dalloliogm/biohub-exp131-min-track-4|biohub-exp131-min-track-4|exp131 node-count: OUTPUT_MIN_TRACK_LEN 6->4 on Exp126 recipe"
  "dalloliogm/biohub-exp132-det-098|biohub-exp132-det-098|exp132 node-count: DET_THRESHOLD 0.96875->0.98 on Exp126 recipe"
)

echo "Preflight: confirm the Kaggle API is reachable..."
if ! "${KG[@]}" competitions submissions -c biohub-cell-tracking-during-development >/dev/null 2>&1; then
  echo "ERROR: cannot reach the Kaggle API (auth or egress). Fix that first." >&2
  echo "       This box's proxy blocks api.kaggle.com; run this on your local machine." >&2
  exit 1
fi

mkdir -p "${STAGE_ROOT}"
declare -a WATCHERS=()

for spec in "${EXPERIMENTS[@]}"; do
  IFS='|' read -r slug base msg <<<"${spec}"
  stage="${STAGE_ROOT}/${slug##*/}"
  rm -rf "${stage}"; mkdir -p "${stage}"
  cp "${NB_DIR}/${base}.ipynb" "${stage}/${base}.ipynb"
  cp "${NB_DIR}/${base}.kernel-metadata.json" "${stage}/kernel-metadata.json"

  echo "=== pushing ${slug} ==="
  push_out="$("${KG[@]}" kernels push -p "${stage}" 2>&1)"
  echo "${push_out}"
  # Kaggle prints "... version <N> successfully pushed"; fall back to 1.
  ver="$(printf '%s\n' "${push_out}" | grep -oiE 'version [0-9]+' | grep -oE '[0-9]+' | tail -1)"
  ver="${ver:-1}"

  echo "=== arming submit watcher for ${slug} v${ver} ==="
  logf="${STAGE_ROOT}/${slug##*/}.watch.log"
  nohup python3 "${AWAIT}" "${slug}" "${ver}" "${msg}" >"${logf}" 2>&1 &
  WATCHERS+=("$!:${slug}:${logf}")
  sleep 5   # small stagger so pushes don't race the 2-session GPU cap
done

echo
echo "All four pushed and watchers armed. They poll for up to 10h each."
echo "Watcher PIDs / logs:"
for w in "${WATCHERS[@]}"; do
  IFS=':' read -r pid slug logf <<<"${w}"
  echo "  pid ${pid}  ${slug}  ->  ${logf}"
done
echo
echo "Follow progress with:  tail -f ${STAGE_ROOT}/*.watch.log"
echo "Do NOT close this shell until the watchers exit (they die with the session)."
wait
echo "All watchers exited. Check the logs above and 'kaggle competitions submissions' for results."
