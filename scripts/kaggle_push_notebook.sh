#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/kaggle_push_notebook.sh NOTEBOOK.ipynb owner/kernel-slug [title]

Example:
  ./scripts/kaggle_push_notebook.sh ps-s5e11-blend-0-92768.ipynb dalloliogm/ps-s5e11-blend-0-92768

The notebook stays in the repository root. A temporary Kaggle push folder is created under .kaggle_work/.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "$#" -lt 2 ]]; then
  usage
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/kaggle_env.sh
source "${SCRIPT_DIR}/kaggle_env.sh"

NOTEBOOK_ARG="$1"
KERNEL_ID="$2"
TITLE="${3:-}"

if [[ "${KERNEL_ID}" != */* ]]; then
  echo "Kernel id must look like owner/kernel-slug, got: ${KERNEL_ID}" >&2
  exit 1
fi

if [[ "${NOTEBOOK_ARG}" = /* ]]; then
  NOTEBOOK_PATH="${NOTEBOOK_ARG}"
else
  NOTEBOOK_PATH="${REPO_ROOT}/${NOTEBOOK_ARG}"
fi

if [[ ! -f "${NOTEBOOK_PATH}" ]]; then
  echo "Notebook not found: ${NOTEBOOK_PATH}" >&2
  exit 1
fi

if [[ "${NOTEBOOK_PATH}" != *.ipynb ]]; then
  echo "Expected a .ipynb notebook, got: ${NOTEBOOK_PATH}" >&2
  exit 1
fi

KERNEL_SLUG="${KERNEL_ID##*/}"
WORK_DIR="${REPO_ROOT}/.kaggle_work/${KERNEL_SLUG}"
CODE_FILE="$(basename "${NOTEBOOK_PATH}")"

if [[ -z "${TITLE}" ]]; then
  TITLE="${KERNEL_SLUG//-/ }"
fi

mkdir -p "${WORK_DIR}"
cp "${NOTEBOOK_PATH}" "${WORK_DIR}/${CODE_FILE}"

METADATA="${WORK_DIR}/kernel-metadata.json"
if [[ ! -f "${METADATA}" ]]; then
  cat > "${METADATA}" <<EOF
{
  "id": "${KERNEL_ID}",
  "title": "${TITLE}",
  "code_file": "${CODE_FILE}",
  "language": "python",
  "kernel_type": "notebook",
  "is_private": true,
  "enable_gpu": false,
  "enable_tpu": false,
  "enable_internet": false,
  "dataset_sources": [],
  "competition_sources": [],
  "kernel_sources": []
}
EOF
else
  echo "Using existing metadata: ${METADATA}"
fi

echo "Pushing ${CODE_FILE} to Kaggle kernel ${KERNEL_ID}"
echo "Working folder: ${WORK_DIR}"
kaggle kernels push -p "${WORK_DIR}"

