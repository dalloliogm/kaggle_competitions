#!/usr/bin/env bash
set -euo pipefail

if [[ -f "${HOME}/.env" ]]; then
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    [[ "${line}" == export\ * ]] && line="${line#export }"
    [[ "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || continue

    key="${line%%=*}"
    value="${line#*=}"
    if [[ "${value}" == \"*\" && "${value}" == *\" ]]; then
      value="${value:1:${#value}-2}"
    elif [[ "${value}" == \'*\' && "${value}" == *\' ]]; then
      value="${value:1:${#value}-2}"
    fi
    export "${key}=${value}"
  done < "${HOME}/.env"
fi

KAGGLE_ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAGGLE_REPO_ROOT="$(cd "${KAGGLE_ENV_DIR}/.." && pwd)"
export KAGGLE_CONFIG_DIR="${KAGGLE_CONFIG_DIR:-${KAGGLE_REPO_ROOT}/.kaggle_config}"
mkdir -p "${KAGGLE_CONFIG_DIR}"

if ! command -v kaggle >/dev/null 2>&1; then
  if [[ -x "${KAGGLE_REPO_ROOT}/.venv/bin/kaggle" ]]; then
    export PATH="${KAGGLE_REPO_ROOT}/.venv/bin:${PATH}"
  else
    cat >&2 <<'EOF'
The Kaggle CLI was not found.

Install it with:
  .venv/bin/python -m pip install --index-url https://pypi.org/simple kaggle
EOF
    exit 1
  fi
fi

if [[ -z "${KAGGLE_USERNAME:-}" && -n "${KAGGLE_API_USERNAME:-}" ]]; then
  export KAGGLE_USERNAME="${KAGGLE_API_USERNAME}"
fi

if [[ -z "${KAGGLE_KEY:-}" && -n "${KAGGLE_API_KEY:-}" ]]; then
  export KAGGLE_KEY="${KAGGLE_API_KEY}"
fi

if [[ -z "${KAGGLE_USERNAME:-}" || -z "${KAGGLE_KEY:-}" ]]; then
  cat >&2 <<'EOF'
Kaggle credentials were not found.

Set these in ~/.env:
  KAGGLE_USERNAME=your_username
  KAGGLE_KEY=your_api_key

If your file already has KAGGLE_API_KEY, that is accepted as an alias for KAGGLE_KEY.
EOF
  exit 1
fi
