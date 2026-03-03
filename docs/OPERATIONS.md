# Operations Checklist

## Firestore Rules / Indexes
- Update rules and indexes from:
  - `firebase/firestore.rules`
  - `firebase/firestore.indexes.json`
- Deploy with Firebase CLI:
  - `firebase deploy --only firestore:rules,firestore:indexes`

## Push Notifications (FCM + APNs)
- Enable Push Notifications capability in Apple Developer for the app id.
- Upload APNs key/cert in Firebase Console -> Project Settings -> Cloud Messaging.
- Verify device receives `fcmToken` in `users/{uid}.fcmToken`.

## StoreKit Production
- Create products in App Store Connect:
  - `rk.horoscope.premium.monthly`
  - `rk.horoscope.premium.yearly`
- If product ids change, update Build Setting `PREMIUM_PRODUCT_IDS`.

## Monitoring
- CI workflow exists at `.github/workflows/ios-ci.yml`.
- Keep unit tests green before release.
- Optional next step: add Firebase Crashlytics and Analytics package products for runtime dashboards.

## Release Prep Checks
- Run local release-prep sanity checks with:
  - `./scripts/release_prep_checks.sh`
- Optional: capture a shareable log artifact while running checks:
  - `RELEASE_PREP_ARTIFACT_PATH=/tmp/release_prep_checks_latest.log ./scripts/release_prep_checks.sh`
- The script validates:
  - plist/string syntax (`plutil`)
  - EN/TR core localization parity
  - hardcoded secret patterns
  - `git diff --check` whitespace issues (current working tree)

## RC Release Runbook (Deterministic)
- Primary handoff runbook: `docs/RC_RELEASE_RUNBOOK.md`
- Recommended one-command flow:
  - `RUN_ARCHIVE=1 ARTIFACT_ROOT=/tmp/horoscope_rc_release RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)" ./scripts/local_xcode_validation.sh`

## Final Manual Submission Workflow
1. Run local sanity checks:
   - `./scripts/release_prep_checks.sh`
2. In local Xcode environment (outside sandbox), run:
   - `xcodebuild -list -project horoscope.xcodeproj`
   - `xcodebuild -resolvePackageDependencies -project horoscope.xcodeproj`
   - `SIMULATOR_NAME=$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ {gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1; exit}')`
   - `xcodebuild -project horoscope.xcodeproj -scheme horoscope -destination "platform=iOS Simulator,name=${SIMULATOR_NAME}" test`
3. In Xcode, create a Release archive (`Any iOS Device`) and validate organizer checks.
4. Perform manual smoke pass in both EN and TR:
   - Auth/onboarding
   - Home quick actions
   - Chat send/retry/history
   - Dream create/save/retry-load
   - Natal refresh/interpretation retry
   - Palm camera/gallery/analyze/retry
   - Settings sheets (premium/notifications/language/help/privacy)
5. Cross-check with `docs/RELEASE_PREP_REPORT.md` before App Store upload.

## External Xcode Machine Runbook (Handoff)
1. Open Xcode once and wait for "Installing additional components" to finish (if prompted).
2. From repo root, run:
   - `RELEASE_PREP_ARTIFACT_PATH=/tmp/release_prep_checks_latest.log ./scripts/release_prep_checks.sh`
   - `xcodebuild -list -project horoscope.xcodeproj`
   - `xcodebuild -resolvePackageDependencies -project horoscope.xcodeproj`
   - `SIMULATOR_NAME=$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ {gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1; exit}')`
   - `xcodebuild -project horoscope.xcodeproj -scheme horoscope -destination "platform=iOS Simulator,name=${SIMULATOR_NAME}" test`
3. Share the saved `release_prep_checks_latest.log` with handoff notes for quick verification context.
4. In Xcode Organizer:
   - Archive with Release config.
   - Validate.
   - Upload to App Store Connect.
5. If package/cache state is corrupted on that machine, run cleanup once:
   - `rm -rf ~/Library/Developer/Xcode/DerivedData/horoscope-*`
   - `rm -rf ~/Library/Caches/org.swift.swiftpm`
   - rerun dependency resolution and tests.

## Legacy Data Migration
- First login after upgrade automatically migrates legacy UserDefaults data to Firestore.
- Migration marker key: `legacy_migrated_{uid}` in UserDefaults.
