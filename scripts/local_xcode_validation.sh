#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

PROJECT="${PROJECT:-horoscope.xcodeproj}"
SCHEME="${SCHEME:-horoscope}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 15}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=${SIMULATOR_NAME}}"
RUN_ARCHIVE="${RUN_ARCHIVE:-0}"

ARTIFACT_ROOT="${ARTIFACT_ROOT:-/tmp/horoscope_rc_release}"
RUN_ID="${RUN_ID:-$(date -u '+%Y%m%dT%H%M%SZ')}"
ARTIFACT_DIR="${ARTIFACT_DIR:-${ARTIFACT_ROOT}/${RUN_ID}}"

RELEASE_PREP_ARTIFACT_PATH="${RELEASE_PREP_ARTIFACT_PATH:-${ARTIFACT_DIR}/01_release_prep_checks.log}"
LIST_LOG_PATH="${LIST_LOG_PATH:-${ARTIFACT_DIR}/02_xcodebuild_list.log}"
RESOLVE_LOG_PATH="${RESOLVE_LOG_PATH:-${ARTIFACT_DIR}/03_resolve_packages.log}"
TEST_LOG_PATH="${TEST_LOG_PATH:-${ARTIFACT_DIR}/04_tests.log}"
TEST_RESULT_BUNDLE_PATH="${TEST_RESULT_BUNDLE_PATH:-${ARTIFACT_DIR}/horoscope-tests.xcresult}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${ARTIFACT_DIR}/horoscope.xcarchive}"
ARCHIVE_LOG_PATH="${ARCHIVE_LOG_PATH:-${ARTIFACT_DIR}/05_archive.log}"
SUMMARY_PATH="${SUMMARY_PATH:-${ARTIFACT_DIR}/rc_handoff_summary.txt}"

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required command: ${command_name}" >&2
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

  if [[ "${RUN_ARCHIVE}" != "0" && "${RUN_ARCHIVE}" != "1" ]]; then
    echo "RUN_ARCHIVE must be 0 or 1 (current: ${RUN_ARCHIVE})" >&2
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

validate_inputs
mkdir -p "${ARTIFACT_DIR}"

echo "Local Xcode validation started at $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Project: ${PROJECT}"
echo "Scheme: ${SCHEME}"
echo "Destination: ${DESTINATION}"
echo "Run archive: ${RUN_ARCHIVE}"
echo "Artifact directory: ${ARTIFACT_DIR}"
echo "Release-prep log: ${RELEASE_PREP_ARTIFACT_PATH}"

run_step env RELEASE_PREP_ARTIFACT_PATH="${RELEASE_PREP_ARTIFACT_PATH}" ./scripts/release_prep_checks.sh
run_step_with_log "${LIST_LOG_PATH}" xcodebuild -list -project "${PROJECT}"
run_step_with_log "${RESOLVE_LOG_PATH}" xcodebuild -resolvePackageDependencies -project "${PROJECT}"
run_step_with_log "${TEST_LOG_PATH}" xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -destination "${DESTINATION}" -resultBundlePath "${TEST_RESULT_BUNDLE_PATH}" test

if [[ "${RUN_ARCHIVE}" == "1" ]]; then
  run_step_with_log "${ARCHIVE_LOG_PATH}" xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -configuration Release -destination "generic/platform=iOS" -archivePath "${ARCHIVE_PATH}" archive
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
release_prep_log=${RELEASE_PREP_ARTIFACT_PATH}
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
