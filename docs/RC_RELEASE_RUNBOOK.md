# RC Release Runbook (Deterministic)

Last updated: 2026-02-28

## 1) Goal
Deterministic, repeatable local RC validation + archive flow for fast TestFlight/App Store handoff.

## 2) Deterministic artifact paths
Every run writes to:

- `RC_ROOT=/tmp/horoscope_rc_release`
- `RC_DIR=${RC_ROOT}/${RUN_ID}`

Expected artifacts:
- `${RC_DIR}/01_release_prep_checks.log`
- `${RC_DIR}/02_xcodebuild_list.log`
- `${RC_DIR}/03_resolve_packages.log`
- `${RC_DIR}/04_tests.log`
- `${RC_DIR}/horoscope-tests.xcresult`
- `${RC_DIR}/05_archive.log` (archive enabled)
- `${RC_DIR}/horoscope.xcarchive` (archive enabled)
- `${RC_DIR}/rc_handoff_summary.txt`

## 3) Primary flow (copy-paste, recommended)
Run from local Xcode machine:

```bash
set -euo pipefail

cd /Users/malware/.openclaw/workspace-release-ops/project

export RC_ROOT=/tmp/horoscope_rc_release
export RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"

RUN_ARCHIVE=1 \
ARTIFACT_ROOT="${RC_ROOT}" \
RUN_ID="${RUN_ID}" \
PROJECT=horoscope.xcodeproj \
SCHEME=horoscope \
SIMULATOR_NAME='iPhone 15' \
./scripts/local_xcode_validation.sh

echo "RC artifacts: ${RC_ROOT}/${RUN_ID}"
```

## 4) Manual fallback flow (if wrapper script is not usable)

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

RELEASE_PREP_ARTIFACT_PATH="${RC_DIR}/01_release_prep_checks.log" ./scripts/release_prep_checks.sh
xcodebuild -list -project "${PROJECT}" 2>&1 | tee "${RC_DIR}/02_xcodebuild_list.log"
xcodebuild -resolvePackageDependencies -project "${PROJECT}" 2>&1 | tee "${RC_DIR}/03_resolve_packages.log"
xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -destination "${DESTINATION}" -resultBundlePath "${RC_DIR}/horoscope-tests.xcresult" test 2>&1 | tee "${RC_DIR}/04_tests.log"
xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -configuration Release -destination 'generic/platform=iOS' -archivePath "${RC_DIR}/horoscope.xcarchive" archive 2>&1 | tee "${RC_DIR}/05_archive.log"

echo "RC artifacts: ${RC_DIR}"
```

## 5) Go / No-Go gates

1. **Gate A — Release prep checks**
   - **GO:** `release_prep_checks.sh` exits `0`.
   - **NO-GO:** plist/localization/secret/whitespace check fails.

2. **Gate B — Xcode project + package resolve**
   - **GO:** `xcodebuild -list` and `-resolvePackageDependencies` exit `0`.
   - **NO-GO:** project metadata, toolchain, or package resolution failure.

3. **Gate C — Simulator tests**
   - **GO:** `xcodebuild ... test` exits `0` and writes `.xcresult`.
   - **NO-GO:** test failures, simulator boot/destination failures.

4. **Gate D — Release archive**
   - **GO:** `xcodebuild ... archive` exits `0` and `${RC_DIR}/horoscope.xcarchive` exists.
   - **NO-GO:** signing/profile/capability/archive errors.

5. **Gate E — Handoff completeness**
   - **GO:** artifacts + smoke notes + build number are ready for TestFlight handoff.
   - **NO-GO:** missing logs, unclear failure cause, missing manual smoke notes.

## 6) Recovery steps (copy-paste)

### A) Xcode toolchain not ready
```bash
sudo xcode-select -switch /Applications/Xcode.app
xcodebuild -runFirstLaunch
```

### B) Simulator destination not found
```bash
xcrun simctl list devices available | grep -E 'iPhone'
```
Pick an available device and rerun with:
```bash
SIMULATOR_NAME='iPhone 16' RUN_ARCHIVE=1 ARTIFACT_ROOT=/tmp/horoscope_rc_release RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)" ./scripts/local_xcode_validation.sh
```

### C) Swift package / DerivedData corruption
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/horoscope-*
rm -rf ~/Library/Caches/org.swift.swiftpm
xcodebuild -resolvePackageDependencies -project horoscope.xcodeproj
```

### D) Signing/archive failures
1. Open Xcode → target `horoscope` → Signing & Capabilities.
2. Verify Team, bundle id, provisioning profile, push/in-app-purchase capabilities.
3. Re-run archive command only:
```bash
xcodebuild -project horoscope.xcodeproj -scheme horoscope -configuration Release -destination 'generic/platform=iOS' -archivePath "${RC_DIR}/horoscope.xcarchive" archive 2>&1 | tee "${RC_DIR}/05_archive.log"
```

### E) Secret scan failure
Use the reported file/line from `01_release_prep_checks.log`, remove hardcoded credentials, rotate any leaked key, rerun from Gate A.

## 7) TestFlight handoff package
Share these items from `${RC_DIR}`:
- `01_release_prep_checks.log`
- `04_tests.log`
- `horoscope-tests.xcresult`
- `05_archive.log` (if archive enabled)
- `rc_handoff_summary.txt`

Minimum handoff note template:

```text
RC run: <RUN_ID>
Branch/commit: <branch>@<commit>
Gates: A/B/C/D = PASS
Archive: <path to horoscope.xcarchive>
Open items: <none or explicit blocker>
```
