#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "$#" -ne 1 ]]; then
  cat <<'EOF'
Usage:
  ./scripts/kaggle_status.sh owner/kernel-slug
EOF
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/kaggle_env.sh
source "${SCRIPT_DIR}/kaggle_env.sh"

kaggle kernels status "$1"

