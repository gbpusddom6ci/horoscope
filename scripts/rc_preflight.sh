#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

ARTIFACT_PATH="${RC_PREFLIGHT_ARTIFACT_PATH:-}"

XCODE_APP_PATH="${XCODE_APP_PATH:-/Applications/Xcode.app}"
EXPECTED_DEVELOPER_DIR="${EXPECTED_DEVELOPER_DIR:-${XCODE_APP_PATH}/Contents/Developer}"
AUTO_SWITCH_XCODE="${AUTO_SWITCH_XCODE:-0}"
CLEAN_DERIVED_DATA="${CLEAN_DERIVED_DATA:-0}"
DERIVED_DATA_GLOB="${DERIVED_DATA_GLOB:-horoscope-*}"
CLEAN_SWIFTPM_CACHE="${CLEAN_SWIFTPM_CACHE:-0}"
SWIFTPM_CACHE_PATH="${SWIFTPM_CACHE_PATH:-${HOME}/Library/Caches/org.swift.swiftpm}"
CLONED_SOURCE_PACKAGES_DIR_PATH="${CLONED_SOURCE_PACKAGES_DIR_PATH:-}"

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required command: ${command_name}"
    exit 1
  fi
}

require_bool() {
  local variable_name="$1"
  local value="$2"
  if [[ "${value}" != "0" && "${value}" != "1" ]]; then
    echo "${variable_name} must be 0 or 1 (current: ${value})"
    exit 1
  fi
}

for required_command in xcode-select xcodebuild mkdir rm date; do
  require_command "${required_command}"
done

require_bool "AUTO_SWITCH_XCODE" "${AUTO_SWITCH_XCODE}"
require_bool "CLEAN_DERIVED_DATA" "${CLEAN_DERIVED_DATA}"
require_bool "CLEAN_SWIFTPM_CACHE" "${CLEAN_SWIFTPM_CACHE}"

run_preflight() {
  echo "RC preflight started at $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "Expected developer dir: ${EXPECTED_DEVELOPER_DIR}"

  if [[ ! -d "${EXPECTED_DEVELOPER_DIR}" ]]; then
    echo "Expected developer directory not found: ${EXPECTED_DEVELOPER_DIR}"
    echo "Install Xcode or set XCODE_APP_PATH/EXPECTED_DEVELOPER_DIR before retrying."
    exit 1
  fi

  local active_developer_dir
  active_developer_dir="$(xcode-select -p 2>/dev/null || true)"
  if [[ -z "${active_developer_dir}" ]]; then
    echo "Unable to determine active developer directory (xcode-select -p)."
    exit 1
  fi

  echo "Active developer dir: ${active_developer_dir}"

  if [[ "${active_developer_dir}" == "/Library/Developer/CommandLineTools" ]]; then
    echo "Active developer directory points to CommandLineTools; full Xcode is required for archive/test flows."

    if [[ "${AUTO_SWITCH_XCODE}" == "1" ]]; then
      echo "AUTO_SWITCH_XCODE=1 set; attempting xcode-select -switch ${EXPECTED_DEVELOPER_DIR}"
      if xcode-select -switch "${EXPECTED_DEVELOPER_DIR}" >/dev/null 2>&1; then
        active_developer_dir="$(xcode-select -p)"
        echo "xcode-select switched successfully. Active developer dir: ${active_developer_dir}"
      else
        echo "Automatic switch failed (likely permission issue)."
        echo "Run manually: sudo xcode-select -switch ${EXPECTED_DEVELOPER_DIR}"
        exit 1
      fi
    else
      echo "Fix with: sudo xcode-select -switch ${EXPECTED_DEVELOPER_DIR}"
      exit 1
    fi
  fi

  if ! xcodebuild -version >/dev/null 2>&1; then
    echo "xcodebuild is not functional with active developer directory: ${active_developer_dir}"
    echo "Try: sudo xcode-select -switch ${EXPECTED_DEVELOPER_DIR}"
    exit 1
  fi

  echo "xcodebuild is functional for the active developer directory."

  if [[ "${CLEAN_DERIVED_DATA}" == "1" ]]; then
    local derived_data_root pattern
    derived_data_root="${HOME}/Library/Developer/Xcode/DerivedData"
    pattern="${derived_data_root}/${DERIVED_DATA_GLOB}"

    shopt -s nullglob
    local matches=(${pattern})
    shopt -u nullglob

    if [[ "${#matches[@]}" -gt 0 ]]; then
      echo "Removing ${#matches[@]} derived data path(s) matching ${pattern}"
      rm -rf "${matches[@]}"
    else
      echo "No derived data path matched: ${pattern}"
    fi
  else
    echo "DerivedData cleanup skipped (CLEAN_DERIVED_DATA=0)."
  fi

  if [[ "${CLEAN_SWIFTPM_CACHE}" == "1" ]]; then
    if [[ -d "${SWIFTPM_CACHE_PATH}" ]]; then
      echo "Removing SwiftPM cache path: ${SWIFTPM_CACHE_PATH}"
      rm -rf "${SWIFTPM_CACHE_PATH}"
    else
      echo "SwiftPM cache path not found: ${SWIFTPM_CACHE_PATH}"
    fi
  else
    echo "SwiftPM cache cleanup skipped (CLEAN_SWIFTPM_CACHE=0)."
  fi

  if [[ -n "${CLONED_SOURCE_PACKAGES_DIR_PATH}" ]]; then
    mkdir -p "${CLONED_SOURCE_PACKAGES_DIR_PATH}"
    echo "Prepared cloned source packages path: ${CLONED_SOURCE_PACKAGES_DIR_PATH}"
  fi

  echo "RC preflight completed successfully."
}

if [[ -n "${ARTIFACT_PATH}" ]]; then
  require_command tee
  mkdir -p "$(dirname "${ARTIFACT_PATH}")"
  echo "Writing preflight log to ${ARTIFACT_PATH}"

  if run_preflight 2>&1 | tee "${ARTIFACT_PATH}"; then
    :
  else
    pipeline_statuses=("${PIPESTATUS[@]}")
    if [[ "${pipeline_statuses[0]}" -ne 0 ]]; then
      exit "${pipeline_statuses[0]}"
    fi
    exit "${pipeline_statuses[1]}"
  fi
else
  run_preflight
fi
