#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

PROJECT="${PROJECT:-horoscope.xcodeproj}"
SCHEME="${SCHEME:-horoscope}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 15}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=${SIMULATOR_NAME}}"
RUN_ARCHIVE="${RUN_ARCHIVE:-0}"
SINGLE_SIMULATOR_MODE="${SINGLE_SIMULATOR_MODE:-1}"
MAX_CONCURRENT_TEST_SIMULATORS="${MAX_CONCURRENT_TEST_SIMULATORS:-1}"

PREFLIGHT_ENABLED="${PREFLIGHT_ENABLED:-1}"
XCODE_APP_PATH="${XCODE_APP_PATH:-/Applications/Xcode.app}"
EXPECTED_DEVELOPER_DIR="${EXPECTED_DEVELOPER_DIR:-${XCODE_APP_PATH}/Contents/Developer}"
AUTO_SWITCH_XCODE="${AUTO_SWITCH_XCODE:-0}"
CLEAN_DERIVED_DATA="${CLEAN_DERIVED_DATA:-0}"
DERIVED_DATA_GLOB="${DERIVED_DATA_GLOB:-horoscope-*}"
CLEAN_SWIFTPM_CACHE="${CLEAN_SWIFTPM_CACHE:-0}"
SWIFTPM_CACHE_PATH="${SWIFTPM_CACHE_PATH:-${HOME}/Library/Caches/org.swift.swiftpm}"

ARTIFACT_ROOT="${ARTIFACT_ROOT:-/tmp/horoscope_rc_release}"
RUN_ID="${RUN_ID:-$(date -u '+%Y%m%dT%H%M%SZ')}"
ARTIFACT_DIR="${ARTIFACT_DIR:-${ARTIFACT_ROOT}/${RUN_ID}}"

PREFLIGHT_LOG_PATH="${PREFLIGHT_LOG_PATH:-${ARTIFACT_DIR}/00_preflight.log}"
RELEASE_PREP_ARTIFACT_PATH="${RELEASE_PREP_ARTIFACT_PATH:-${ARTIFACT_DIR}/01_release_prep_checks.log}"
LIST_LOG_PATH="${LIST_LOG_PATH:-${ARTIFACT_DIR}/02_xcodebuild_list.log}"
RESOLVE_LOG_PATH="${RESOLVE_LOG_PATH:-${ARTIFACT_DIR}/03_resolve_packages.log}"
TEST_LOG_PATH="${TEST_LOG_PATH:-${ARTIFACT_DIR}/04_tests.log}"
TEST_RESULT_BUNDLE_PATH="${TEST_RESULT_BUNDLE_PATH:-${ARTIFACT_DIR}/horoscope-tests.xcresult}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${ARTIFACT_DIR}/horoscope.xcarchive}"
ARCHIVE_LOG_PATH="${ARCHIVE_LOG_PATH:-${ARTIFACT_DIR}/05_archive.log}"
SUMMARY_PATH="${SUMMARY_PATH:-${ARTIFACT_DIR}/rc_handoff_summary.txt}"
CLONED_SOURCE_PACKAGES_DIR_PATH="${CLONED_SOURCE_PACKAGES_DIR_PATH:-${ARTIFACT_DIR}/SourcePackages}"

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required command: ${command_name}" >&2
    exit 1
  fi
}

require_bool() {
  local variable_name="$1"
  local value="$2"

  if [[ "${value}" != "0" && "${value}" != "1" ]]; then
    echo "${variable_name} must be 0 or 1 (current: ${value})" >&2
    exit 1
  fi
}

validate_inputs() {
  if [[ ! -d "${ROOT_DIR}" ]]; then
    echo "Repository root is not accessible: ${ROOT_DIR}" >&2
    exit 1
  fi

  if [[ ! -e "${PROJECT}" ]]; then
    echo "Project file does not exist: ${PROJECT}" >&2
    exit 1
  fi

  require_bool "RUN_ARCHIVE" "${RUN_ARCHIVE}"
  require_bool "SINGLE_SIMULATOR_MODE" "${SINGLE_SIMULATOR_MODE}"
  require_bool "PREFLIGHT_ENABLED" "${PREFLIGHT_ENABLED}"
  require_bool "AUTO_SWITCH_XCODE" "${AUTO_SWITCH_XCODE}"
  require_bool "CLEAN_DERIVED_DATA" "${CLEAN_DERIVED_DATA}"
  require_bool "CLEAN_SWIFTPM_CACHE" "${CLEAN_SWIFTPM_CACHE}"

  if [[ "${PREFLIGHT_ENABLED}" == "1" && ! -x ./scripts/rc_preflight.sh ]]; then
    echo "Missing executable preflight helper: ./scripts/rc_preflight.sh" >&2
    exit 1
  fi

  if [[ -e "${TEST_RESULT_BUNDLE_PATH}" ]]; then
    echo "Test result bundle path already exists: ${TEST_RESULT_BUNDLE_PATH}" >&2
    echo "Use a new RUN_ID/ARTIFACT_DIR or remove it before re-running." >&2
    exit 1
  fi

  if [[ "${RUN_ARCHIVE}" == "1" && -e "${ARCHIVE_PATH}" ]]; then
    echo "Archive path already exists: ${ARCHIVE_PATH}" >&2
    echo "Use a new RUN_ID/ARTIFACT_DIR or remove it before re-running." >&2
    exit 1
  fi
}

run_step() {
  echo
  echo "==> $*"
  "$@"
}

run_step_with_log() {
  local log_path="$1"
  shift

  mkdir -p "$(dirname "${log_path}")"

  echo
  echo "==> $*"
  if "$@" 2>&1 | tee "${log_path}"; then
    return 0
  fi

  local status="${PIPESTATUS[0]}"
  echo "Command failed with exit code ${status}. See log: ${log_path}" >&2
  return "${status}"
}

for required_command in xcodebuild tee mkdir date; do
  require_command "${required_command}"
done

resolve_simulator_destination() {
  local simulator_prefix="platform=iOS Simulator,name="
  if [[ "${DESTINATION}" != "${simulator_prefix}"* ]]; then
    return 0
  fi

  if ! command -v xcrun >/dev/null 2>&1; then
    return 0
  fi

  local requested_name="${DESTINATION#${simulator_prefix}}"
  local available_names
  available_names="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ {gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}')"

  if [[ -z "${available_names}" ]]; then
    return 0
  fi

  if printf '%s\n' "${available_names}" | grep -Fxq "${requested_name}"; then
    return 0
  fi

  local fallback_name
  fallback_name="$(printf '%s\n' "${available_names}" | head -n 1)"
  echo "Requested simulator '${requested_name}' is not available; falling back to '${fallback_name}'."
  DESTINATION="${simulator_prefix}${fallback_name}"
}

validate_inputs
resolve_simulator_destination
mkdir -p "${ARTIFACT_DIR}"
mkdir -p "${CLONED_SOURCE_PACKAGES_DIR_PATH}"

echo "Local Xcode validation started at $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Project: ${PROJECT}"
echo "Scheme: ${SCHEME}"
echo "Destination: ${DESTINATION}"
echo "Run archive: ${RUN_ARCHIVE}"
echo "Single simulator mode: ${SINGLE_SIMULATOR_MODE}"
echo "Max concurrent test simulators: ${MAX_CONCURRENT_TEST_SIMULATORS}"
echo "Preflight enabled: ${PREFLIGHT_ENABLED}"
echo "Artifact directory: ${ARTIFACT_DIR}"
echo "Source packages directory: ${CLONED_SOURCE_PACKAGES_DIR_PATH}"
echo "Release-prep log: ${RELEASE_PREP_ARTIFACT_PATH}"

if [[ "${PREFLIGHT_ENABLED}" == "1" ]]; then
  run_step env \
    RC_PREFLIGHT_ARTIFACT_PATH="${PREFLIGHT_LOG_PATH}" \
    XCODE_APP_PATH="${XCODE_APP_PATH}" \
    EXPECTED_DEVELOPER_DIR="${EXPECTED_DEVELOPER_DIR}" \
    AUTO_SWITCH_XCODE="${AUTO_SWITCH_XCODE}" \
    CLEAN_DERIVED_DATA="${CLEAN_DERIVED_DATA}" \
    DERIVED_DATA_GLOB="${DERIVED_DATA_GLOB}" \
    CLEAN_SWIFTPM_CACHE="${CLEAN_SWIFTPM_CACHE}" \
    SWIFTPM_CACHE_PATH="${SWIFTPM_CACHE_PATH}" \
    CLONED_SOURCE_PACKAGES_DIR_PATH="${CLONED_SOURCE_PACKAGES_DIR_PATH}" \
    ./scripts/rc_preflight.sh
fi

run_step env RELEASE_PREP_ARTIFACT_PATH="${RELEASE_PREP_ARTIFACT_PATH}" ./scripts/release_prep_checks.sh
run_step_with_log "${LIST_LOG_PATH}" xcodebuild -list -project "${PROJECT}"
run_step_with_log "${RESOLVE_LOG_PATH}" xcodebuild -resolvePackageDependencies -project "${PROJECT}" -clonedSourcePackagesDirPath "${CLONED_SOURCE_PACKAGES_DIR_PATH}"
TEST_COMMAND=(xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -destination "${DESTINATION}" -clonedSourcePackagesDirPath "${CLONED_SOURCE_PACKAGES_DIR_PATH}" -resultBundlePath "${TEST_RESULT_BUNDLE_PATH}")
if [[ "${SINGLE_SIMULATOR_MODE}" == "1" ]]; then
  TEST_COMMAND+=(
    -parallel-testing-enabled NO
    -maximum-concurrent-test-simulator-destinations "${MAX_CONCURRENT_TEST_SIMULATORS}"
    -maximum-concurrent-test-device-destinations 1
  )
fi
TEST_COMMAND+=(test)
run_step_with_log "${TEST_LOG_PATH}" "${TEST_COMMAND[@]}"

if [[ "${RUN_ARCHIVE}" == "1" ]]; then
  run_step_with_log "${ARCHIVE_LOG_PATH}" xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -configuration Release -destination "generic/platform=iOS" -clonedSourcePackagesDirPath "${CLONED_SOURCE_PACKAGES_DIR_PATH}" -archivePath "${ARCHIVE_PATH}" archive
  ARCHIVE_STATUS="enabled"
else
  ARCHIVE_STATUS="skipped"
fi

cat > "${SUMMARY_PATH}" <<EOF
rc_run_id=${RUN_ID}
started_at_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
project=${PROJECT}
scheme=${SCHEME}
destination=${DESTINATION}
artifact_dir=${ARTIFACT_DIR}
preflight_enabled=${PREFLIGHT_ENABLED}
preflight_log=${PREFLIGHT_LOG_PATH}
release_prep_log=${RELEASE_PREP_ARTIFACT_PATH}
cloned_source_packages_dir=${CLONED_SOURCE_PACKAGES_DIR_PATH}
xcode_list_log=${LIST_LOG_PATH}
resolve_log=${RESOLVE_LOG_PATH}
test_log=${TEST_LOG_PATH}
test_result_bundle=${TEST_RESULT_BUNDLE_PATH}
archive_status=${ARCHIVE_STATUS}
archive_log=${ARCHIVE_LOG_PATH}
archive_path=${ARCHIVE_PATH}
EOF

echo
echo "Local Xcode validation completed successfully."
echo "Summary: ${SUMMARY_PATH}"
