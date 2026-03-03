# WAKEUP_HANDOFF

Date: February 27, 2026

## Purpose
- Single runbook for immediate local Xcode validation before App Store submission.
- Keep behavior unchanged; focus on verification confidence and handoff clarity.
- Canonical deterministic RC flow now lives in `docs/RC_RELEASE_RUNBOOK.md`.

## Exact Command Sequence (Local Xcode Machine)
Run from repo root (`/Users/malware/horoscope/horoscope`):

```bash
RELEASE_PREP_ARTIFACT_PATH=/tmp/release_prep_checks_latest.log ./scripts/release_prep_checks.sh
xcodebuild -list -project horoscope.xcodeproj
xcodebuild -resolvePackageDependencies -project horoscope.xcodeproj
SIMULATOR_NAME=$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ {gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1; exit}')
xcodebuild -project horoscope.xcodeproj -scheme horoscope -destination "platform=iOS Simulator,name=${SIMULATOR_NAME}" test
xcodebuild -project horoscope.xcodeproj -scheme horoscope -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/horoscope_release_validation.xcarchive archive
```

Optional wrapper (same flow, archive disabled by default):

```bash
./scripts/local_xcode_validation.sh
RUN_ARCHIVE=1 ./scripts/local_xcode_validation.sh
```

## Decision Gates (If Fail -> What To Check)
1. `release_prep_checks.sh` fails
   - Open `/tmp/release_prep_checks_latest.log`.
   - Fix the failing class only: plist syntax, EN/TR key parity, secret pattern, or `git diff --check` whitespace.
   - Re-run from step 1.
2. `xcodebuild -list` fails
   - Open Xcode once and finish "Installing additional components" if prompted.
   - Ensure command line tools are selected (`xcode-select -p`).
   - Re-run step 2.
3. `-resolvePackageDependencies` fails
   - Check network/proxy/Apple service access.
   - If cache corruption is suspected, clear once:
     - `rm -rf ~/Library/Developer/Xcode/DerivedData/horoscope-*`
     - `rm -rf ~/Library/Caches/org.swift.swiftpm`
   - Re-run step 3.
4. Simulator `test` fails before tests start
   - Ensure an available iPhone simulator exists/boots (`xcrun simctl list devices available`).
   - Re-run step 4 with an available simulator name if needed.
5. Tests run but fail
   - Triage regression vs flaky infra using `.xcresult`.
   - Fix only high-confidence release blockers, then re-run step 4.
6. Release `archive` fails
   - Verify signing team/profile/capabilities/bundle id and Release build settings.
   - Re-run step 5 after signing corrections.

## Final App Store Submission Checklist
1. `./scripts/release_prep_checks.sh` passes and log is saved.
2. `xcodebuild` list/resolve/test all pass on local machine.
3. Release archive succeeds and Organizer validation passes.
4. Manual smoke pass completed in EN + TR:
   - Auth/onboarding, home quick actions, chat, dreams, natal, palm, settings sheets.
5. Privacy prompts/strings verified (camera + photo library).
6. StoreKit products and restore flow verified with sandbox/test account.
7. Firebase rules/indexes and environment config confirmed for production target.
8. Final secret sanity check done; no credentials in git-tracked files.
9. Upload to App Store Connect from Organizer, then document build number and handoff notes.
