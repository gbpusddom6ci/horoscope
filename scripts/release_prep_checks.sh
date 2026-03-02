#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

ARTIFACT_PATH="${RELEASE_PREP_ARTIFACT_PATH:-}"

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required command: ${command_name}"
    exit 1
  fi
}

for required_command in plutil awk grep diff mktemp rg git; do
  require_command "${required_command}"
done

run_checks() {
  echo "Release-prep checks started at $(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  echo "[1/3] Linting plist and localization files with plutil..."
  plutil -lint \
    Config/AppInfo.plist \
    horoscope/horoscope.entitlements \
    horoscope/en.lproj/Localizable.strings >/dev/null

  echo "[2/3] Scanning for potential hardcoded secrets..."
  if rg -n \
    -g '!.git' \
    -g '!DerivedData/**' \
    -g '!Config/Secrets.template.xcconfig' \
    -g '!Config/Secrets.xcconfig' \
    -g '!README.md' \
    -e 'sk-or-[A-Za-z0-9._-]{20,}|Authorization:[[:space:]]*Bearer[[:space:]]+sk-or-[A-Za-z0-9._-]{20,}|OPENROUTER_API_KEY[[:space:]]*=[[:space:]]*sk-or-[A-Za-z0-9._-]{20,}|FREE_ASTRO_API_KEY[[:space:]]*=[[:space:]]*[A-Za-z0-9._-]{12,}' \
    .; then
    echo "Potential hardcoded secret found."
    exit 1
  fi

  echo "[3/3] Checking whitespace/errors in working tree diff..."
  git diff --check

  echo "Release-prep checks passed."
}

if [[ -n "${ARTIFACT_PATH}" ]]; then
  require_command tee
  mkdir -p "$(dirname "${ARTIFACT_PATH}")"
  echo "Writing release-prep check log to ${ARTIFACT_PATH}"
  if run_checks 2>&1 | tee "${ARTIFACT_PATH}"; then
    :
  else
    pipeline_statuses=("${PIPESTATUS[@]}")
    if [[ "${pipeline_statuses[0]}" -ne 0 ]]; then
      exit "${pipeline_statuses[0]}"
    fi
    exit "${pipeline_statuses[1]}"
  fi
else
  run_checks
fi
