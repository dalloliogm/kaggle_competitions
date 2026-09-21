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

# Only pin KAGGLE_CONFIG_DIR to a repo-local directory if the caller explicitly set
# it, or a repo-local config actually exists. Otherwise leave it unset so the CLI
# uses its default ~/.kaggle — which is where the access_token / kaggle.json live.
# (Forcing it to a repo dir hides ~/.kaggle/access_token and breaks auth.)
if [[ -n "${KAGGLE_CONFIG_DIR:-}" ]]; then
  mkdir -p "${KAGGLE_CONFIG_DIR}"
  export KAGGLE_CONFIG_DIR
elif [[ -f "${KAGGLE_REPO_ROOT}/.kaggle_config/access_token" || -f "${KAGGLE_REPO_ROOT}/.kaggle_config/kaggle.json" ]]; then
  export KAGGLE_CONFIG_DIR="${KAGGLE_REPO_ROOT}/.kaggle_config"
fi

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

# Legacy env aliases (username/key auth).
if [[ -z "${KAGGLE_USERNAME:-}" && -n "${KAGGLE_API_USERNAME:-}" ]]; then
  export KAGGLE_USERNAME="${KAGGLE_API_USERNAME}"
fi
if [[ -z "${KAGGLE_KEY:-}" && -n "${KAGGLE_API_KEY:-}" ]]; then
  export KAGGLE_KEY="${KAGGLE_API_KEY}"
fi

# The current CLI authenticates with an ACCESS TOKEN, so accept any of the
# supported methods rather than only the legacy username/key pair. Verify a live
# setup with: uvx --index-url https://pypi.org/simple kaggle config view
_kaggle_cfg_dir="${KAGGLE_CONFIG_DIR:-${HOME}/.kaggle}"
_kaggle_have_auth=0
[[ -n "${KAGGLE_API_TOKEN:-}" ]] && _kaggle_have_auth=1                    # access token via env
[[ -f "${_kaggle_cfg_dir}/access_token" ]] && _kaggle_have_auth=1         # access token file (preferred)
[[ -f "${_kaggle_cfg_dir}/kaggle.json" ]] && _kaggle_have_auth=1          # legacy json
[[ -n "${KAGGLE_USERNAME:-}" && -n "${KAGGLE_KEY:-}" ]] && _kaggle_have_auth=1  # legacy env pair

if [[ "${_kaggle_have_auth}" -eq 0 ]]; then
  cat >&2 <<EOF
Kaggle credentials were not found. The current CLI uses an ACCESS TOKEN.

Set one up (do NOT commit it to the repo):
  - save the KGAT... token to ${_kaggle_cfg_dir}/access_token   (then: chmod 600), or
  - export KAGGLE_API_TOKEN=KGAT...

Get the token at https://www.kaggle.com/settings/api ("Create New Token"),
or run:  uvx --index-url https://pypi.org/simple kaggle auth login

Legacy fallback still works: ${_kaggle_cfg_dir}/kaggle.json, or KAGGLE_USERNAME + KAGGLE_KEY.
EOF
  exit 1
fi
