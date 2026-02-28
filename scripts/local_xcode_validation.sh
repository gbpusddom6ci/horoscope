#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

PROJECT="${PROJECT:-horoscope.xcodeproj}"
SCHEME="${SCHEME:-horoscope}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 15}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=${SIMULATOR_NAME}}"
RUN_ARCHIVE="${RUN_ARCHIVE:-0}"
ARCHIVE_PATH="${ARCHIVE_PATH:-/tmp/horoscope_release_validation.xcarchive}"
RELEASE_PREP_ARTIFACT_PATH="${RELEASE_PREP_ARTIFACT_PATH:-/tmp/release_prep_checks_latest.log}"

run_step() {
  echo
  echo "==> $*"
  "$@"
}

echo "Local Xcode validation started at $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Project: ${PROJECT}"
echo "Scheme: ${SCHEME}"
echo "Destination: ${DESTINATION}"

if [[ -n "${RELEASE_PREP_ARTIFACT_PATH}" ]]; then
  run_step env RELEASE_PREP_ARTIFACT_PATH="${RELEASE_PREP_ARTIFACT_PATH}" ./scripts/release_prep_checks.sh
else
  run_step ./scripts/release_prep_checks.sh
fi

run_step xcodebuild -list -project "${PROJECT}"
run_step xcodebuild -resolvePackageDependencies -project "${PROJECT}"
run_step xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -destination "${DESTINATION}" test

if [[ "${RUN_ARCHIVE}" == "1" ]]; then
  run_step xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -configuration Release -destination "generic/platform=iOS" -archivePath "${ARCHIVE_PATH}" archive
  echo
  echo "Archive generated at: ${ARCHIVE_PATH}"
else
  echo
  echo "Archive skipped (set RUN_ARCHIVE=1 to enable)."
fi

echo
echo "Local Xcode validation completed successfully."
