# RC Release Runbook (Deterministic)

Last updated: 2026-02-28

## 0) Validation snapshot (current branch)
Validation run on `war36/release-ops`:

- `./scripts/release_prep_checks.sh` ✅ passes.
- `xcodebuild -list -project horoscope.xcodeproj` ❌ fails when active developer dir is `/Library/Developer/CommandLineTools`.
- Action: run `./scripts/rc_preflight.sh` (or `PREFLIGHT_ENABLED=1` in wrapper) before Gate B+.

## 1) Goal
Deterministic, repeatable local RC validation + archive flow for fast TestFlight/App Store handoff.

## 2) Deterministic artifact paths
Every run writes to:

- `RC_ROOT=/tmp/horoscope_rc_release`
- `RC_DIR=${RC_ROOT}/${RUN_ID}`

Expected artifacts:

- `${RC_DIR}/00_preflight.log`
- `${RC_DIR}/01_release_prep_checks.log`
- `${RC_DIR}/02_xcodebuild_list.log`
- `${RC_DIR}/03_resolve_packages.log`
- `${RC_DIR}/04_tests.log`
- `${RC_DIR}/horoscope-tests.xcresult`
- `${RC_DIR}/05_archive.log` (archive enabled)
- `${RC_DIR}/horoscope.xcarchive` (archive enabled)
- `${RC_DIR}/SourcePackages/` (isolated SwiftPM clones)
- `${RC_DIR}/rc_handoff_summary.txt`

## 3) Primary flow (copy-paste, recommended)
Run from local Xcode machine:

```bash
set -euo pipefail

cd /Users/malware/.openclaw/workspace-release-ops/project

export RC_ROOT=/tmp/horoscope_rc_release
export RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"

RUN_ARCHIVE=1 \
SINGLE_SIMULATOR_MODE=1 \
MAX_CONCURRENT_TEST_SIMULATORS=1 \
PREFLIGHT_ENABLED=1 \
AUTO_SWITCH_XCODE=0 \
CLEAN_DERIVED_DATA=0 \
CLEAN_SWIFTPM_CACHE=0 \
ARTIFACT_ROOT="${RC_ROOT}" \
RUN_ID="${RUN_ID}" \
PROJECT=horoscope.xcodeproj \
SCHEME=horoscope \
SIMULATOR_NAME='iPhone 15' \
CLONED_SOURCE_PACKAGES_DIR_PATH="${RC_ROOT}/${RUN_ID}/SourcePackages" \
./scripts/local_xcode_validation.sh

echo "RC artifacts: ${RC_ROOT}/${RUN_ID}"
```

## 4) Preflight helper (deterministic + safe)
`./scripts/rc_preflight.sh` does:

- Xcode path sanity check (`xcode-select -p`, `xcodebuild -version`)
- Optional DerivedData cleanup (`CLEAN_DERIVED_DATA=1`)
- Optional global SwiftPM cache cleanup (`CLEAN_SWIFTPM_CACHE=1`)
- Creates deterministic `CLONED_SOURCE_PACKAGES_DIR_PATH`

Quick commands:

```bash
# Check only (no destructive cleanup)
RC_PREFLIGHT_ARTIFACT_PATH="/tmp/horoscope_rc_release/preflight.log" \
CLONED_SOURCE_PACKAGES_DIR_PATH="/tmp/horoscope_rc_release/source-packages" \
./scripts/rc_preflight.sh
```

```bash
# Attempt auto-switch if CommandLineTools is active (may still require sudo)
AUTO_SWITCH_XCODE=1 \
RC_PREFLIGHT_ARTIFACT_PATH="/tmp/horoscope_rc_release/preflight.log" \
./scripts/rc_preflight.sh
```

```bash
# Clean stale build caches intentionally
CLEAN_DERIVED_DATA=1 \
CLEAN_SWIFTPM_CACHE=1 \
RC_PREFLIGHT_ARTIFACT_PATH="/tmp/horoscope_rc_release/preflight.log" \
./scripts/rc_preflight.sh
```

## 5) Manual fallback flow (if wrapper script is not usable)

```bash
set -euo pipefail

cd /Users/malware/.openclaw/workspace-release-ops/project

export RC_ROOT=/tmp/horoscope_rc_release
export RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
export RC_DIR="${RC_ROOT}/${RUN_ID}"
mkdir -p "${RC_DIR}"

export PROJECT=horoscope.xcodeproj
export SCHEME=horoscope
export DESTINATION='platform=iOS Simulator,name=iPhone 15'
export CLONED_SOURCE_PACKAGES_DIR_PATH="${RC_DIR}/SourcePackages"

RC_PREFLIGHT_ARTIFACT_PATH="${RC_DIR}/00_preflight.log" \
CLONED_SOURCE_PACKAGES_DIR_PATH="${CLONED_SOURCE_PACKAGES_DIR_PATH}" \
./scripts/rc_preflight.sh

RELEASE_PREP_ARTIFACT_PATH="${RC_DIR}/01_release_prep_checks.log" ./scripts/release_prep_checks.sh
xcodebuild -list -project "${PROJECT}" 2>&1 | tee "${RC_DIR}/02_xcodebuild_list.log"
xcodebuild -resolvePackageDependencies -project "${PROJECT}" -clonedSourcePackagesDirPath "${CLONED_SOURCE_PACKAGES_DIR_PATH}" 2>&1 | tee "${RC_DIR}/03_resolve_packages.log"
xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -destination "${DESTINATION}" -clonedSourcePackagesDirPath "${CLONED_SOURCE_PACKAGES_DIR_PATH}" -resultBundlePath "${RC_DIR}/horoscope-tests.xcresult" -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 -maximum-concurrent-test-device-destinations 1 test 2>&1 | tee "${RC_DIR}/04_tests.log"
xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -configuration Release -destination 'generic/platform=iOS' -clonedSourcePackagesDirPath "${CLONED_SOURCE_PACKAGES_DIR_PATH}" -archivePath "${RC_DIR}/horoscope.xcarchive" archive 2>&1 | tee "${RC_DIR}/05_archive.log"

echo "RC artifacts: ${RC_DIR}"
```

## 6) Go / No-Go gates

1. **Gate 0 — Preflight**
   - **GO:** `rc_preflight.sh` exits `0`.
   - **NO-GO:** Xcode path/toolchain invalid or preflight cleanup/sanity fails.

2. **Gate A — Release prep checks**
   - **GO:** `release_prep_checks.sh` exits `0`.
   - **NO-GO:** plist/localization/secret/whitespace check fails.

3. **Gate B — Xcode project + package resolve**
   - **GO:** `xcodebuild -list` and `-resolvePackageDependencies` exit `0`.
   - **NO-GO:** project metadata, toolchain, or package resolution failure.

4. **Gate C — Simulator tests**
   - **GO:** `xcodebuild ... test` exits `0` and writes `.xcresult`.
   - **NO-GO:** test failures, simulator boot/destination failures.

5. **Gate D — Release archive**
   - **GO:** `xcodebuild ... archive` exits `0` and `${RC_DIR}/horoscope.xcarchive` exists.
   - **NO-GO:** signing/profile/capability/archive errors.

6. **Gate E — Handoff completeness**
   - **GO:** artifacts + smoke notes + build number are ready for TestFlight handoff.
   - **NO-GO:** missing logs, unclear failure cause, missing manual smoke notes.

## 7) Failure recovery snippets (copy-paste)

### A) Xcode toolchain points to CommandLineTools
```bash
# Try helper first
RC_PREFLIGHT_ARTIFACT_PATH="${RC_DIR}/00_preflight.log" AUTO_SWITCH_XCODE=1 ./scripts/rc_preflight.sh || true

# If still failing, force switch with sudo then validate
sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

### B) Simulator destination not found
```bash
xcrun simctl list devices available | grep -E 'iPhone'
```
Pick an available device and rerun with:
```bash
SIMULATOR_NAME='iPhone 16' RUN_ARCHIVE=1 ARTIFACT_ROOT=/tmp/horoscope_rc_release RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)" ./scripts/local_xcode_validation.sh
```

### C) DerivedData/package cache corruption
```bash
RUN_ARCHIVE=0 \
PREFLIGHT_ENABLED=1 \
CLEAN_DERIVED_DATA=1 \
CLEAN_SWIFTPM_CACHE=1 \
ARTIFACT_ROOT=/tmp/horoscope_rc_release \
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)" \
./scripts/local_xcode_validation.sh
```

### D) SwiftPM still conflicts after cleanup
```bash
export RC_DIR="/tmp/horoscope_rc_release/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "${RC_DIR}"
rm -rf "${RC_DIR}/SourcePackages"
xcodebuild -resolvePackageDependencies -project horoscope.xcodeproj -clonedSourcePackagesDirPath "${RC_DIR}/SourcePackages"
```

### E) Signing/archive failures
1. Open Xcode → target `horoscope` → Signing & Capabilities.
2. Verify Team, bundle id, provisioning profile, push/in-app-purchase capabilities.
3. Re-run archive command only:
```bash
xcodebuild -project horoscope.xcodeproj -scheme horoscope -configuration Release -destination 'generic/platform=iOS' -clonedSourcePackagesDirPath "${RC_DIR}/SourcePackages" -archivePath "${RC_DIR}/horoscope.xcarchive" archive 2>&1 | tee "${RC_DIR}/05_archive.log"
```

### F) Secret scan failure
Use the reported file/line from `01_release_prep_checks.log`, remove hardcoded credentials, rotate any leaked key, rerun from Gate A.

## 8) TestFlight handoff package
Share these items from `${RC_DIR}`:

- `00_preflight.log`
- `01_release_prep_checks.log`
- `04_tests.log`
- `horoscope-tests.xcresult`
- `05_archive.log` (if archive enabled)
- `rc_handoff_summary.txt`

Minimum handoff note template:

```text
RC run: <RUN_ID>
Branch/commit: <branch>@<commit>
Gates: 0/A/B/C/D = PASS
Archive: <path to horoscope.xcarchive>
Open items: <none or explicit blocker>
```
