#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "$#" -ne 1 ]]; then
  cat <<'EOF'
Usage:
  ./scripts/kaggle_output.sh owner/kernel-slug
EOF
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/kaggle_env.sh
source "${SCRIPT_DIR}/kaggle_env.sh"

KERNEL_ID="$1"
KERNEL_SLUG="${KERNEL_ID##*/}"
OUTPUT_DIR="${REPO_ROOT}/kaggle_outputs/${KERNEL_SLUG}"

mkdir -p "${OUTPUT_DIR}"
kaggle kernels output "${KERNEL_ID}" -p "${OUTPUT_DIR}" -o
echo "Downloaded outputs to ${OUTPUT_DIR}"

