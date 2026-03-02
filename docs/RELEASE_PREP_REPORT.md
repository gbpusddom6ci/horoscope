# RELEASE_PREP_REPORT

Date: February 27, 2026

## 1) Audit Scope

I performed a release-prep audit across architecture, navigation, feature screens, services, localization, CI, and tests.

Reviewed areas:
- App/root flow: `horoscopeApp.swift`, `Navigation/AppRouter.swift`, `Navigation/MainTabView.swift`
- Core design/layout/components: `Core/Design/*`, `Core/Extensions/ViewExtensions.swift`
- Models/services: `Core/Models/*`, `Core/Services/*`
- Major features:
  - `Features/Auth/AuthView.swift`
  - `Features/Onboarding/OnboardingView.swift`
  - `Features/Home/HomeView.swift`
  - `Features/Chat/ChatView.swift`
  - `Features/Dreams/DreamJournalView.swift`
  - `Features/NatalChart/*`
  - `Features/PalmReading/PalmReadingView.swift`
  - `Features/Tarot/TarotView.swift`
  - `Features/Settings/*`
- Localization: `horoscope/en.lproj/Localizable.strings`
- Tests: `horoscopeTests/horoscopeTests.swift`, `horoscopeUITests/horoscopeUITests.swift`
- CI/workflow: `.github/workflows/ios-ci.yml`
- Firebase ops/security files: `firebase/firestore.rules`, `firebase/firestore.indexes.json`, `docs/OPERATIONS.md`

## 2) Issues Found (Severity)

### High
- Chat session auto-title logic bug in `ChatService.addMessage`: first user message could never rename an untitled session.
- Chat history selection bug in `ChatView`: selecting a historical session could be overridden by context change auto-selection.

### Medium
- Floating center chat button accessibility hint did not match real behavior after UX changes.
- Re-tap tab behavior was inconsistent (only some screens handled scroll-to-top semantics).
- Onboarding location async updates had off-main-thread mutation risk.
- Palm reading sent full-size images, increasing timeout/failure risk on multimodal requests.
- CI workflow still referenced removed/renamed UI smoke test (`testQuickActionsSheetShowsItems`).

### Low / Operational
- Could not run full `xcodebuild`/simulator validation in this sandbox due CoreSimulator and permission constraints.

## 3) What Was Changed

### Release blockers + logic correctness
- `Core/Services/ChatService.swift`
  - Fixed first-user-message session-title generation logic.
  - Added pure helper logic (`updatedTitle`, `isUntitledTitle`) for deterministic behavior.

- `Features/Chat/ChatView.swift`
  - Fixed session-history selection flow so selected session is preserved across context switch.
  - Added guard to prevent send while already loading.

- `.github/workflows/ios-ci.yml`
  - Updated UI smoke test target from removed name to current test method:
    - `testQuickActionsButtonNavigatesToChat`

### UI/UX + navigation consistency
- `Navigation/MainTabView.swift`
  - Floating center chat button now:
    - re-tap triggers chat scroll event
    - shows selected visual state when chat tab is active
    - provides accurate accessibility value/hint

- Added tab re-tap scroll handling to major tab screens:
  - `Features/Chat/ChatView.swift` (`.chat` -> scroll to latest message)
  - `Features/Dreams/DreamJournalView.swift` (`.dream` -> scroll to top)
  - `Features/NatalChart/NatalChartView.swift` (`.chart` -> scroll to top)
  - `Features/Settings/SettingsView.swift` (`.profile` -> scroll to top)

### Stability / resilience
- `Features/Onboarding/OnboardingView.swift`
  - Wrapped async location resolution state writes on `MainActor`.
  - Ensured completer delegate UI state updates are main-actor safe.

- `Features/PalmReading/PalmReadingView.swift`
  - Added image optimization/downscaling + JPEG recompression before AI upload.
  - Reduced payload risk for multimodal calls.

### Localization + tests
- Added new localization key in both languages:
  - `tab.chat.fab.hint`
- Updated tests in `horoscopeTests/horoscopeTests.swift`:
  - Added unit tests for chat title generation/preservation.
  - Extended core localization parity required keys with new accessibility key.

## 4) Validation Run

Executed checks available in this environment:
- `plutil -lint` on plist/entitlements/localization files: **passed**
- Core localization parity script (EN/TR for app key prefixes): **passed**
- Secret scan pattern check (workflow-equivalent): **passed**
- `git diff --check` whitespace check: **passed**

Attempted but blocked by environment sandbox constraints:
- `xcodebuild -list -project horoscope.xcodeproj`
- Full build/test via simulator

Failure cause summary:
- CoreSimulator service unavailable in sandbox.
- Permission-denied access for DerivedData/module cache paths outside writable workspace.

## 5) Remaining / Risk Notes

- Full compile + runtime validation on a real Xcode environment is still required before submission.
- Push/APNs production readiness remains operationally dependent on signing/capabilities setup outside this repo runtime.
- There are legacy non-prefixed localization entries that are asymmetrical between EN/TR, but core in-use prefixed keys are in parity and validated.

## 6) Recommended Final Pre-Submit Checks in Xcode

1. Clean build + archive (`Any iOS Device`) with Release config.
2. Run unit tests and UI smoke tests on at least one iOS 17+ simulator.
3. Manual smoke pass:
   - Auth (Apple + email), onboarding, home quick actions
   - Chat send/retry/session history/new session
   - Dream compose/save
   - Natal chart refresh + interpretation
   - Palm photo pick/camera + analyze
   - Settings sheets (premium/notifications/language/help/privacy)
4. Verify localization rendering in both `en` and `tr`.
5. Confirm App Store required privacy strings (camera/photo) are shown correctly at runtime.
6. Validate in-app purchase products and restore flow with StoreKit test account/sandbox.
7. Confirm Firebase config and Firestore rules/indexes are deployed to intended environment.
8. Run one final secret scan and ensure `Config/Secrets.xcconfig` is not committed.

## 7) Pass 2 (Release Hardening)

Date: February 27, 2026

### Findings
- **High (data consistency):** `AuthService.updateBirthData` updated local session before remote sync and did not roll back on backend failure.
- **Medium (thread safety + UX):** `EditBirthDataSheet.selectLocation` mutated view state in async callback without explicit main-thread handoff and had no user-facing error when geocoding failed.
- **Medium (localization polish):** date formatting used `Locale.autoupdatingCurrent`, which could drift from in-app language (`selected_language`) and produce mixed-language UI.
- **Medium (network feedback):** palm analysis surfaced raw error descriptions and photo-load failure from gallery could fail silently.
- **Low (interaction resilience):** natal refresh could be tapped repeatedly during load.

### Changes Implemented
- `Core/Services/AuthService.swift`
  - Hardened `updateBirthData` with optimistic update + rollback on sync failure.
  - Added `@MainActor` isolation and explicit `errorMessage` handling for success/failure.

- `Features/Settings/SettingsView.swift`
  - Made location search completion updates main-actor safe.
  - Added user-facing inline error for unresolved location selection.

- `Core/Extensions/ViewExtensions.swift`
  - Updated `Date.formatted(as:)` and `Date.relativeFormatted` to honor app-selected language.
  - Added testable locale helper `Date.appLocale(selectedLanguage:fallback:)`.

- `Features/PalmReading/PalmReadingView.swift`
  - Added friendly user-facing error mapper for palm flow (`URLError`/`AIServiceError`/config).
  - Added explicit failure feedback when selected gallery image cannot be loaded.
  - Added accessibility hints/identifiers for camera/gallery/analyze controls.

- `Features/NatalChart/NatalChartView.swift`
  - Disabled refresh during active load.
  - Added refresh accessibility hint/identifier.
  - Moved async state writes to `MainActor` and guarded repeat interpretation requests.

- Localization (`en` + `tr`)
  - Added new keys for:
    - settings location resolution failure
    - natal refresh hint
    - palm control hints and palm-specific error states

- CI/Tests
  - `.github/workflows/ios-ci.yml`: expanded localization parity prefixes to include `natal`, `palm`, and `tarot`.
  - `horoscopeTests/horoscopeTests.swift`:
    - added locale helper tests
    - added palm error mapping tests
    - extended required EN/TR key parity assertions for new keys

### Pass 2 Validation (Environment-available)
- `plutil -lint` on localization/plists: **passed**
- Localization parity diff (expanded prefixes: `tab/common/auth/onboarding/home/chat/dream/settings/quick_actions/config/ai/notifications/astro/transit/natal/palm/tarot`): **passed**
- Secret scan pattern check (workflow-equivalent): **passed**
- `git diff --check`: **passed**
- `xcodebuild -list -project horoscope.xcodeproj`: **blocked in sandbox** (CoreSimulator connection invalid + permission denied on DerivedData/module cache paths outside writable workspace).

### Remaining Risks After Pass 2
- Simulator/runtime integration tests and archive validation still required outside sandbox.
- Firebase/StoreKit environment-specific behavior (real auth/purchase flows) requires device/simulator validation with production-like credentials.

## 8) Pass 3 (App Store Readiness)

Date: February 27, 2026

### Findings
- **Medium (async/state safety):** `HomeView.loadData` could write `@State` from async context and could re-apply stale chart/transit results after user/birth-data changes.
- **Medium (edge-state UX):** `DreamJournalView` did not distinguish initial loading from empty state and had no inline retry action for sync-load failures.
- **Medium (error recovery):** `NatalChartView` interpretation failures could leave users without a clear retry flow.
- **Low (release ops):** release sanity checks required running multiple manual commands instead of one repeatable script.

### Changes
- `horoscope/Features/Home/HomeView.swift`
  - Hardened personalized data loading with load-token guarding and main-actor state application.
  - Reset stale personalized state when birth data is absent.
  - Added explicit personalized loading card (`home.personalized.loading`).
  - Reloads personalized data on birth-data changes (`.onChange(of: birthData)`).
  - Added testable helper: `shouldShowPersonalizedLoading(...)`.

- `horoscope/Features/Dreams/DreamJournalView.swift`
  - Added initial loading state with progress UI (`dream.loading.entries`) to avoid false empty-state impression.
  - Added pull-to-refresh and inline retry action for sync error banner (`dream.retry.action`).
  - Added retry accessibility hint/identifier.
  - Added testable helper: `shouldShowInitialLoadingState(...)`.

- `horoscope/Features/NatalChart/NatalChartView.swift`
  - Split interpretation error from successful interpretation content using `interpretationErrorMessage`.
  - Added explicit retry UX for interpretation failures (`natal.interpretation.retry`) with accessibility hint/identifiers.
  - Kept interpretation requests guarded against duplicate in-flight calls.
  - Added testable helper: `shouldShowInterpretationRetry(...)`.

- Localization updates
  - Added new EN/TR keys:
    - `home.personalized.loading`
    - `dream.loading.entries`
    - `dream.retry.action`
    - `dream.retry.hint`
    - `natal.interpretation.retry`
    - `natal.interpretation.hint`
    - `natal.interpretation.retry.hint`

- Tests
  - `horoscopeTests/horoscopeTests.swift`:
    - added helper-logic tests for home loading state, dream initial-loading state, natal retry visibility
    - extended localization parity required keys with new Pass 3 keys

- Release automation/docs
  - Added `scripts/release_prep_checks.sh` for one-command local sanity validation.
  - Updated `docs/OPERATIONS.md` with usage of the new release-prep script.

### Validations
- `./scripts/release_prep_checks.sh`: **passed**
  - `plutil -lint` on plist/entitlements/localization files: passed
  - EN/TR core localization parity diff: passed
  - hardcoded secret pattern scan: passed
  - `git diff --check`: passed
- `xcodebuild -list -project horoscope.xcodeproj`: **blocked in sandbox**
  - CoreSimulator service connection invalid in this environment
  - permission denied for DerivedData/module cache paths outside workspace

### Remaining Risks
- Full compile/unit/UI test and archive validation still required in a normal Xcode environment (outside this sandbox).
- Runtime behavior for network-dependent AI calls still needs final device/simulator smoke verification under production-like connectivity.

## 9) Pass 4 (Final Polish Before External Xcode Validation)

Date: February 27, 2026

### Findings
- **Low (accessibility coverage):** several state surfaces (loading/empty/error/retry) still lacked stable accessibility identifiers and hints, reducing VoiceOver clarity and making UI smoke selectors less consistent.
- **Low (state feedback):** palm analysis showed loading only inside button chrome and did not provide an inline retry action when an analysis failed with a selected image.
- **Low (release workflow clarity):** ops documentation and release-check script messaging were close, but final manual submission flow could be clearer.

### Changes
- `horoscope/Features/Chat/ChatView.swift`
  - Added state-focused accessibility identifiers/hints for:
    - top-bar new chat action (`chat.new_topbar`)
    - empty state (`chat.empty.state`)
    - typing/loading indicator (`chat.loading.reply`)
    - retry/error banners (`chat.retry.banner`, `chat.retry.action`, `chat.error.banner`)
    - session history empty/list items (`chat.session.empty`, `chat.session.{id}`)

- `horoscope/Features/Dreams/DreamJournalView.swift`
  - Added accessibility identifiers/hints for state UI:
    - empty state + CTA (`dream.empty.state`, `dream.empty.cta`)
    - initial loading state (`dream.loading.state`)
    - sync error banner (`dream.error.banner`)

- `horoscope/Features/Home/HomeView.swift`
  - Added identifier for personalized loading state (`home.personalized.loading.state`).

- `horoscope/Features/NatalChart/NatalChartView.swift`
  - Added accessibility identifiers/labels for:
    - chart loading state (`natal.loading.state`)
    - no-birth-data empty state (`natal.empty.state`)
    - interpretation error card (`natal.interpretation.error`)

- `horoscope/Features/PalmReading/PalmReadingView.swift`
  - Added explicit inline analyzing feedback (`palm.analyzing.state`).
  - Added retry action in error card when a photo is available and analysis is idle (`palm.retry.button`).
  - Added state/helper identifiers for preview/error/result cards.
  - Added helper `shouldShowRetryAction(...)` for deterministic state logic.

- Localization (`en` + `tr`)
  - Added Pass 4 keys with EN/TR parity:
    - `chat.retry.hint`
    - `chat.loading.reply`
    - `common.retry`
    - `palm.analyzing`
    - `palm.retry.hint`

- Ops/script alignment
  - `docs/OPERATIONS.md`: added explicit final manual submission workflow steps.
  - `scripts/release_prep_checks.sh`: clarified step label to match behavior (`working tree diff`).

- Tests
  - `horoscopeTests/horoscopeTests.swift`
    - Added palm retry-visibility test for `shouldShowRetryAction(...)`.
    - Extended required localization parity keys with new Pass 4 keys.

### Validation
- `./scripts/release_prep_checks.sh`: **passed**
  - `plutil -lint`: passed
  - EN/TR core localization parity: passed
  - hardcoded secret scan: passed
  - `git diff --check`: passed
- `xcodebuild -list -project horoscope.xcodeproj`: **blocked in sandbox**
  - CoreSimulator service unavailable in this environment
  - permission-denied access to DerivedData/module cache paths outside workspace

### Remaining Risks
- Full compile, unit/UI execution, and archive/upload validation must still run on an external local Xcode environment (outside sandbox restrictions).

## 10) Pass 5 (Continuous Improvement Until Handoff)

Date: February 27, 2026

### Focus
- Added low-risk, user-visible polish in `chat`, `dream`, and `settings` flows with emphasis on long-running feedback and safer actions.

### Changes
- `horoscope/Features/Chat/ChatView.swift`
  - Added delayed slow-response hint while waiting on AI generation (`chat.loading.slow`) after extended loading.
  - Added deterministic helper `shouldShowSlowResponseNotice(...)` to keep UI-state behavior testable.

- `horoscope/Features/Dreams/DreamJournalView.swift`
  - Added inline refresh-status notice for non-empty lists during reload (`dream.loading.refresh`) to reduce ambiguity during pull-to-refresh.
  - Added deterministic helper `shouldShowRefreshNotice(...)`.

- `horoscope/Features/Settings/SettingsView.swift`
  - Added sign-out confirmation dialog to prevent accidental logout during demos/review flow.
  - Added localization keys for title/body/action of confirmation.

- Localization (`en` + `tr`)
  - Added new keys with parity:
    - `chat.loading.slow`
    - `dream.loading.refresh`
    - `settings.signout.confirm.title`
    - `settings.signout.confirm.message`
    - `settings.signout.confirm.action`

- Tests (`horoscopeTests/horoscopeTests.swift`)
  - Added helper-state unit tests for:
    - chat slow-response notice visibility
    - dream refresh notice visibility
  - Extended required EN/TR localization parity key list with Pass 5 keys.

### Validation
- `./scripts/release_prep_checks.sh`: **passed**
  - `plutil -lint`: passed
  - EN/TR core localization parity: passed
  - hardcoded secret scan: passed
  - `git diff --check`: passed
- `xcodebuild -list -project horoscope.xcodeproj`: **blocked in sandbox**
  - CoreSimulator service unavailable in this environment
  - permission-denied access to DerivedData/module cache paths outside workspace

### Remaining Risks
- Full compile, simulator runtime tests, and archive/upload validation still require an external local Xcode environment.

## 11) Pass 6 (Pre-Handoff Finalization)

Date: February 27, 2026

### Focus
- Final low-risk reliability polish for async loading/error states in key flows (`chat`, `natal`, `palm`).
- Handoff clarity for immediate external Xcode validation + App Store submission.

### Findings
- **Low (chat state consistency):** retry/error banners could remain visible after session/context switches, even when unrelated to the active thread.
- **Low (natal async consistency):** interpretation response could arrive after a chart reload and overwrite current state.
- **Low (palm async consistency):** media selection during/after an in-flight analysis could allow stale callback state to update UI.

### Changes
- `horoscope/Features/Chat/ChatView.swift`
  - Scoped retry/error banner visibility to the active session/context only.
  - Cleared transient retry/error state when starting a new send/retry request.

- `horoscope/Features/NatalChart/NatalChartView.swift`
  - Added request-id guarding for interpretation async completion to ignore stale callbacks.
  - Disabled chart refresh while interpretation is in progress to keep chart/result state coherent.
  - Explicitly reset interpretation in-flight state when chart reload starts or when birth data is absent.

- `horoscope/Features/PalmReading/PalmReadingView.swift`
  - Disabled camera/gallery selection while analysis is in progress.
  - Added request-id guarding for analysis completion to ignore stale callbacks.
  - Invalidated in-flight analysis state when a new image is loaded/selected.

- `docs/OPERATIONS.md`
  - Expanded external-machine handoff runbook with explicit dependency resolution and one-time cache cleanup fallback commands.

### Localization / Tests
- No new localization keys introduced; EN/TR parity remains unchanged.
- Existing tests/localization parity checks remained aligned; no test key updates required for this pass.

### Validation
- `./scripts/release_prep_checks.sh`: **passed**
  - `plutil -lint`: passed
  - EN/TR core localization parity: passed
  - hardcoded secret scan: passed
  - `git diff --check`: passed
- `xcodebuild -list -project horoscope.xcodeproj`: **blocked in sandbox**
  - CoreSimulator service unavailable/invalid in this environment
  - permission denied for DerivedData/module cache paths outside writable workspace

### Handoff Status
- Pass 6 completed with low-risk polish only; ready for external local Xcode build/test/archive validation and App Store submission workflow.

## 12) Pass 7 (Final Pre-17:00 Hardening)

Date: February 27, 2026

### Focus
- Final sweep for tiny, high-confidence UX reliability/clarity improvements.
- Keep churn minimal and preserve localization/test parity.

### Findings
- **Low (onboarding async reliability):** rapid location reselection could allow an older geocoding response to overwrite a newer selection.
- **Low (onboarding clarity):** selected location label could render with a trailing separator when subtitle was empty.

### Changes
- `horoscope/Features/Onboarding/OnboardingView.swift`
  - Added request-id guarding (`activeLocationResolveRequestID`) in `selectLocation(_:)` to ignore stale location-resolution callbacks.
  - Added deterministic helper `composedLocationName(title:subtitle:)` and switched selection display/build logic to use safe joining (no trailing comma).
  - Kept all geocoding completion mutations on `MainActor`.

- `horoscopeTests/horoscopeTests.swift`
  - Added unit test coverage for onboarding location-name formatting helper:
    - combined title+subtitle
    - title-only
    - subtitle-only/trimmed input

### Localization / Tests
- No new localization keys added.
- EN/TR parity remains unchanged.
- Added lightweight deterministic unit coverage for new helper behavior.

### Validation
- `./scripts/release_prep_checks.sh`: **passed**
  - `plutil -lint`: passed
  - EN/TR core localization parity: passed
  - hardcoded secret scan: passed
  - `git diff --check`: passed
- `xcodebuild -list -project horoscope.xcodeproj`: **blocked in sandbox**
  - CoreSimulatorService connection invalid/unavailable in sandbox
  - permission-denied access to DerivedData/module cache and SwiftPM cache paths outside writable workspace

### Handoff Status
- Pass 7 completed with low-risk polish only; branch remains ready for external local Xcode build/test/archive validation before submission.

## 13) Pass 8 (Wake-Up Handoff Finalization)

Date: February 27, 2026

### Focus
- Final low-risk scan for meaningful UX/reliability polish.
- Prioritize release runbook/checklist clarity and verification artifact quality for handoff.

### Findings
- No additional high-confidence product-code bug was identified that justified late-cycle behavior changes.
- Highest value opportunity was operational reliability: make release-check output easier to capture/share during wake-up handoff and external Xcode validation.

### Changes
- `scripts/release_prep_checks.sh`
  - Added preflight command checks with clear failure messages for required tooling (`plutil`, `awk`, `grep`, `diff`, `mktemp`, `rg`, `git`).
  - Added optional log artifact capture via `RELEASE_PREP_ARTIFACT_PATH` (no behavior change unless set).
  - Added UTC start timestamp line to improve traceability in shared logs.

- `docs/OPERATIONS.md`
  - Documented optional artifact command:
    - `RELEASE_PREP_ARTIFACT_PATH=/tmp/release_prep_checks_latest.log ./scripts/release_prep_checks.sh`
  - Updated external-machine runbook to use artifact capture and explicitly share the generated log in handoff notes.

### Localization / Tests
- No localization keys changed.
- No test behavior changed.
- Existing localization/test parity remains aligned.

### Validation
- `./scripts/release_prep_checks.sh`: **passed**
- `RELEASE_PREP_ARTIFACT_PATH=/tmp/release_prep_checks_latest.log ./scripts/release_prep_checks.sh`: **passed** (artifact successfully written)
- `xcodebuild -list -project horoscope.xcodeproj`: **blocked in sandbox**
  - CoreSimulator service unavailable/invalid in this environment
  - permission-denied access to DerivedData/module cache paths outside writable workspace

### Handoff Status
- Pass 8 completed with low-risk release-ops hardening and improved verification artifact flow; branch is prepared for wake-up handoff and external Xcode build/test/archive execution.

## 14) Pass 9 (Final Pre-Wake Handoff Packaging)

Date: February 27, 2026

### Focus
- Final high-value, low-risk packaging for immediate local Xcode validation and App Store submission.
- Improve handoff clarity with explicit gates/checklists, avoiding risky product-code changes.

### Findings
- No additional tiny/high-confidence product-code fix was identified that justified a late-cycle behavior change.
- Highest value remaining work was a concise, deterministic wake-up runbook and optional command wrapper for local machines.

### Changes
- `docs/WAKEUP_HANDOFF.md`
  - Added a concise wake-up artifact with:
    - exact local command sequence (checks, list, resolve, test, archive)
    - decision gates (`if fail -> what to verify -> rerun point`)
    - final App Store submission checklist

- `scripts/local_xcode_validation.sh`
  - Added optional helper script that executes the same local validation sequence safely.
  - Defaults to test flow; archive is opt-in via `RUN_ARCHIVE=1`.
  - Supports non-invasive environment overrides (`PROJECT`, `SCHEME`, `SIMULATOR_NAME`, `DESTINATION`, `ARCHIVE_PATH`, `RELEASE_PREP_ARTIFACT_PATH`).

### Localization / Tests
- No localization keys changed.
- No test logic changed.
- Existing localization/test parity remains preserved.

### Validation
- `./scripts/release_prep_checks.sh`: **passed**
- `bash -n scripts/local_xcode_validation.sh`: **passed**
- `shellcheck scripts/local_xcode_validation.sh`: **not run** (`shellcheck` unavailable in this environment)
- `xcodebuild -list -project horoscope.xcodeproj`: **still blocked in sandbox** (CoreSimulator unavailable + permission-denied access to DerivedData/module cache outside writable workspace)

### Handoff Status
- Pass 9 completed with docs/script release-ops packaging only; branch is ready for external local Xcode machine validation, archive, and App Store submission flow.
