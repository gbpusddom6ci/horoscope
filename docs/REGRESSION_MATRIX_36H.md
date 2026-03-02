# REGRESSION_MATRIX_36H

Date: 2026-02-28  
Branch: `war36/tester-regression`  
Scope: 36-hour RC (H+0 kickoff)  
Owner: Tester Regression Lane

## 1) Release Gate (Strict)

### Blocking policy
- **P0 fail**: immediate **NO-GO**.
- **P1 fail**: **NO-GO** unless explicit Product + Engineering waiver is documented in release notes.
- **P2 fail**: can ship only with owner + ETA + rollback note.

### Pass criteria for RC promotion
1. `CMD-00` passes.
2. `CMD-04` (UI suite) passes.
3. `CMD-03` (unit suite) passes.
4. Monetization path (`MON-01..MON-04`) passes in sandbox account flow.
5. EN/TR localization checks (`LOC-01..LOC-04`) pass.

### Rerun policy
- On failure: rerun listed command **once**.
- If reproduced 2/2: mark as confirmed regression.
- If not reproduced: run `CMD-02` full test command once before downgrading to flaky.

## 2) Severity Scale

- **P0 (Blocker):** login, onboarding completion, crash, purchase/restore break, data-loss/corruption, app unusable.
- **P1 (Major):** core feature broken/degraded without workaround, major localization issue, repeated API failure with poor recovery.
- **P2 (Minor):** cosmetic/edge issue with workaround.

## 3) Rerun Command Catalog

Run from repo root:

| ID | Command |
|---|---|
| CMD-00 | `RELEASE_PREP_ARTIFACT_PATH=/tmp/release_prep_checks_latest.log ./scripts/release_prep_checks.sh` |
| CMD-01 | `./scripts/local_xcode_validation.sh` |
| CMD-02 | `xcodebuild -project horoscope.xcodeproj -scheme horoscope -destination 'platform=iOS Simulator,name=iPhone 15' test` |
| CMD-03 | `xcodebuild -project horoscope.xcodeproj -scheme horoscope -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:horoscopeTests test` |
| CMD-04 | `xcodebuild -project horoscope.xcodeproj -scheme horoscope -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:horoscopeUITests test` |
| CMD-05 | `xcodebuild -project horoscope.xcodeproj -scheme horoscope -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:horoscopeUITests/testQuickActionsButtonNavigatesToChat -only-testing:horoscopeUITests/testChatMoreContextsSheetOpens -only-testing:horoscopeUITests/testChatComposerKeyboardAdaptiveChrome test` |
| CMD-06 | `xcodebuild -project horoscope.xcodeproj -scheme horoscope -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:horoscopeUITests/testHomeGridShowsCompactTiles -only-testing:horoscopeUITests/testQuickActionDreamOpensComposer -only-testing:horoscopeUITests/testDreamPrimaryCtaIsReachable -only-testing:horoscopeUITests/testSettingsCoreSectionsVisible test` |
| CMD-07 | `xcodebuild -list -project horoscope.xcodeproj && xcodebuild -resolvePackageDependencies -project horoscope.xcodeproj` |
| CMD-08 | `xcodebuild -project horoscope.xcodeproj -scheme horoscope -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/horoscope_release_validation.xcarchive archive` |
| CMD-09 | `plutil -lint horoscope/en.lproj/Localizable.strings` |

---

## 4) Regression Matrix

### A) Auth

| ID | Test case | Expected result | Severity if fail | Rerun command(s) |
|---|---|---|---|---|
| AUTH-01 | Email login with existing account | User signs in successfully and lands on Home; no crash/loop | P0 | CMD-04 + manual auth repro |
| AUTH-02 | Apple Sign-In first login route | Successful auth routes to onboarding when profile incomplete | P0 | CMD-04 + manual auth repro |
| AUTH-03 | Sign out confirmation + post-logout route | Sign-out requires confirmation; app returns to auth entry and session is cleared | P0 | CMD-06 + manual sign-out repro |

### B) Onboarding

| ID | Test case | Expected result | Severity if fail | Rerun command(s) |
|---|---|---|---|---|
| ONB-01 | Required onboarding fields validation | Continue button blocked until mandatory birth data/location is valid | P0 | CMD-04 + manual onboarding repro |
| ONB-02 | Birth time unknown path | User can continue without birth time and complete onboarding | P1 | CMD-04 + manual onboarding repro |
| ONB-03 | Location autocomplete + resolve | Selected location resolves consistently; stale callback does not overwrite new choice | P1 | CMD-03 + manual onboarding repro |
| ONB-04 | Onboarding completion persistence | After relaunch, completed users skip onboarding and land on main tabs | P0 | CMD-02 |

### C) Home

| ID | Test case | Expected result | Severity if fail | Rerun command(s) |
|---|---|---|---|---|
| HOME-01 | Quick action button navigates to chat | Floating quick action opens Chat composer reliably | P1 | CMD-05 |
| HOME-02 | Feature grid tiles visibility/navigation | Chat/Dream/Palm/Tarot tiles appear and navigate correctly | P1 | CMD-06 |
| HOME-03 | Personalized content loading state | Loading card shows while fetching; chart/transits appear when available; no stale data flash | P1 | CMD-03 + manual home repro |
| HOME-04 | Selected tab persists after relaunch | Previously selected tab is restored after terminate/launch | P1 | CMD-04 |

### D) Chat

| ID | Test case | Expected result | Severity if fail | Rerun command(s) |
|---|---|---|---|---|
| CHAT-01 | Send message + response generation | User message sends, assistant response appears, composer stays usable | P0 | CMD-05 + manual chat send repro |
| CHAT-02 | First-message session auto-title | New untitled session title generated from first user message only | P1 | CMD-03 |
| CHAT-03 | Session history selection stability | Selecting historical session remains stable across context switching | P1 | CMD-05 + manual session-switch repro |
| CHAT-04 | More Contexts sheet behavior | More Contexts opens and includes Tarot entry; selecting context is applied | P1 | CMD-05 |
| CHAT-05 | Retry and error banner behavior | Failures show retry UI; retry clears stale banner on success/new send | P1 | CMD-03 + manual forced-failure repro |

### E) Dreams

| ID | Test case | Expected result | Severity if fail | Rerun command(s) |
|---|---|---|---|---|
| DRM-01 | Open dream composer from top bar | `dream.new_topbar` opens New Dream composer | P1 | CMD-06 |
| DRM-02 | Save dream entry | New entry persists and appears in list after refresh/relaunch | P1 | CMD-04 + manual dream save repro |
| DRM-03 | Initial loading vs empty state | Initial sync shows loading placeholder, not empty state flicker | P1 | CMD-03 + manual dream refresh repro |
| DRM-04 | Retry flow on sync error | Error banner shows retry action; retry refreshes list | P1 | CMD-03 + manual offline repro |

### F) Natal

| ID | Test case | Expected result | Severity if fail | Rerun command(s) |
|---|---|---|---|---|
| NAT-01 | No birth data fallback | Empty-state guidance shown without crash when birth data missing | P1 | CMD-04 + manual no-birth-data repro |
| NAT-02 | Chart refresh + interpretation | Refresh loads chart and interpretation for valid profile | P1 | CMD-02 + manual natal repro |
| NAT-03 | Interpretation retry visibility | Retry appears only on interpretation failure and works when tapped | P1 | CMD-03 + manual forced-error repro |
| NAT-04 | Refresh disabled while loading | Multiple rapid taps do not trigger duplicate refresh requests | P1 | CMD-03 + manual tap-spam repro |

### G) Palm

| ID | Test case | Expected result | Severity if fail | Rerun command(s) |
|---|---|---|---|---|
| PALM-01 | Camera/gallery media selection | Selected photo appears in preview; no silent fail | P1 | CMD-04 + manual media pick repro |
| PALM-02 | Analyze success path | Analysis runs with optimized image payload and returns result card | P1 | CMD-02 + manual palm analyze repro |
| PALM-03 | Network/timeout error mapping | Offline/timeout/API errors show user-friendly localized messages | P1 | CMD-03 + manual offline/timeout repro |
| PALM-04 | Retry action gating | Retry button visible only when image exists and analysis is idle | P1 | CMD-03 |

### H) Tarot

| ID | Test case | Expected result | Severity if fail | Rerun command(s) |
|---|---|---|---|---|
| TAROT-01 | Entry from chat context picker | Tarot context is selectable from More Contexts | P1 | CMD-05 |
| TAROT-02 | Card draw/render flow | Draw returns card payload and displays readable card content | P1 | CMD-02 + manual tarot draw repro |
| TAROT-03 | Reversed card string format | Reversed card formatting is correct and localized | P1 | CMD-03 + manual tarot locale repro |

### I) Settings

| ID | Test case | Expected result | Severity if fail | Rerun command(s) |
|---|---|---|---|---|
| SET-01 | Core sections visibility | Quick Settings / Account / Support sections are visible | P1 | CMD-06 |
| SET-02 | Language switch persistence | EN/TR selection updates UI and persists after relaunch | P1 | CMD-04 + manual language toggle repro |
| SET-03 | Edit birth data + location error UX | Invalid location resolve shows inline localized error, no crash | P1 | CMD-03 + manual settings edit repro |
| SET-04 | Sign-out confirmation safety | Sign out requires explicit confirmation before session clears | P1 | CMD-06 + manual sign-out repro |

### J) Localization (EN/TR)

| ID | Test case | Expected result | Severity if fail | Rerun command(s) |
|---|---|---|---|---|
| LOC-01 | EN/TR key parity (core keys) | Required keys exist in both files; parity check passes | P0 | CMD-00 + CMD-09 |
| LOC-02 | EN rendering across main modules | Auth/Home/Chat/Dream/Natal/Palm/Tarot/Settings strings are English and consistent | P1 | CMD-04 + manual EN walk-through |
| LOC-03 | TR rendering across main modules | Same surfaces render Turkish text and remain layout-safe | P1 | CMD-04 + manual TR walk-through |
| LOC-04 | Date/relative language adherence | Date formatting follows selected language, not mixed locale | P1 | CMD-03 + manual locale toggle repro |

### K) Monetization Path

| ID | Test case | Expected result | Severity if fail | Rerun command(s) |
|---|---|---|---|---|
| MON-01 | Open premium surface from settings | Premium/paywall sheet opens without UI break or blank state | P0 | CMD-06 + manual premium open repro |
| MON-02 | Sandbox purchase success | Successful purchase unlocks premium state and persists | P0 | CMD-08 + manual StoreKit sandbox purchase |
| MON-03 | Restore purchases | Restore flow reactivates entitlement after reinstall/sign-in | P0 | CMD-08 + manual StoreKit restore |
| MON-04 | Product fetch failure handling | Store/product fetch errors are surfaced with recoverable UX | P1 | CMD-02 + manual network-failure repro |

---

## 5) RC Decision Checklist (for H+36 sign-off)

- [ ] All P0 cases passed.
- [ ] No unwaived P1 failures.
- [ ] `CMD-00`, `CMD-03`, `CMD-04` green.
- [ ] Monetization sandbox purchase + restore verified.
- [ ] EN/TR walkthrough completed and recorded.
- [ ] Any accepted P2 risk documented with owner and ETA.

If any unchecked item remains at H+36: **NO-GO**.
