# MONETIZATION_IMPLEMENTATION_TICKETS

Date: 2026-02-28  
Source: `docs/MONETIZATION_36H_BACKLOG.md`  
Scope: Top 8 execution-ready tickets for WAR36 (monetization + retention)

---

## Prioritized Ticket List (Top 8)

1. **T01 (I01)** Aha-moment contextual paywall trigger  
2. **T02 (I03)** Persistent premium CTA on Home + Settings  
3. **T03 (I04)** Paywall merchandising polish (annual highlight + trust copy)  
4. **T04 (I02)** Soft free limits + daily credit meter  
5. **T05 (I08)** Limit-hit contextual paywall copy  
6. **T06 (I09)** Inline upgrade CTA in result surfaces  
7. **T07 (I05)** Daily reminder deep-link to last-used feature  
8. **T08 (I12)** Continue-where-you-left-off module on Home

---

## T01 — Aha-moment contextual paywall trigger (I01)

**Objective + KPI**
- Objective: Present premium offer immediately after first proven value moment for non-premium users.
- KPI(s):
  - Increase `paywall_view_rate_after_first_success`
  - Increase `paywall_view -> purchase_success` conversion (P2P)

**UI touchpoints**
- `ChatView`
- `NewDreamSheet` (or active dream interpretation sheet)
- `PalmReadingView`
- `PaywallView` (sheet presentation)

**Implementation steps for coder**
1. Add a lightweight trigger coordinator (e.g., `PaywallTriggerService`) with local state:
   - key: `hasShownFirstValuePaywall:<userId>`
   - skip if user is premium.
2. Hook into success callbacks in chat, dream interpretation, and palm interpretation flows.
3. On first successful result, present `PaywallView` with context payload (`chat`, `dream`, `palm`).
4. Track telemetry events:
   - `first_value_success`
   - `paywall_view` with `trigger=first_value` and `context`.
5. Ensure trigger is idempotent across app relaunches for the same user.

**Acceptance criteria (testable)**
- Given a non-premium user, when first successful chat result is produced, then `PaywallView` appears once.
- Given a non-premium user, when first successful dream interpretation is produced, then `PaywallView` appears once.
- Given a premium user, first-value success never shows paywall.
- Repeating successful actions after first trigger does not re-show this specific trigger.

**Risk + rollback note**
- Risk: perceived interruption right after value moment.
- Rollback: disable with a single feature flag (`paywall_first_value_enabled=false`) and keep flow unchanged.

---

## T02 — Persistent premium CTA on Home + Settings (I03)

**Objective + KPI**
- Objective: Increase premium path discoverability from highest-traffic surfaces.
- KPI(s):
  - Increase `paywall_open_rate_per_session`
  - Increase `premium_attach_rate`

**UI touchpoints**
- `HomeView` (compact premium card/button)
- `SettingsView` / account settings area
- `PaywallView`

**Implementation steps for coder**
1. Add reusable `PremiumCTACompactCard` component with icon, 1-line value prop, and CTA button.
2. Render card in `HomeView` above/between high-engagement modules for non-premium users.
3. Render card in `SettingsView` near subscription/account section.
4. Wire card tap to present `PaywallView`.
5. For premium users, hide CTA or replace with `Premium active` status chip.
6. Emit event `premium_cta_tap` with `surface=home|settings`.

**Acceptance criteria (testable)**
- Non-premium user sees CTA on both Home and Settings.
- CTA tap from either surface opens `PaywallView`.
- Premium user does not see upsell CTA card; sees active premium state.
- `premium_cta_tap` event includes correct surface attribute.

**Risk + rollback note**
- Risk: UI clutter reducing trust.
- Rollback: remove Home placement first (keep Settings only) via per-surface flags.

---

## T03 — Paywall merchandising polish (I04)

**Objective + KPI**
- Objective: Improve purchase completion by clearer packaging hierarchy and trust signals.
- KPI(s):
  - Increase `purchase_success / paywall_view`
  - Increase annual plan mix share

**UI touchpoints**
- `PaywallView`
- StoreKit product selection controls

**Implementation steps for coder**
1. Sort products to show annual plan first.
2. Add visual emphasis for annual SKU:
   - “Best Value” badge
   - savings text if price metadata allows (e.g., vs monthly equivalent).
3. Keep monthly option visible and selectable.
4. Ensure Restore Purchases is always visible.
5. Add trust copy section: “Cancel anytime”, “Secure billing via Apple”.
6. Track `paywall_plan_selected` + `purchase_tap` with `plan_id`.

**Acceptance criteria (testable)**
- Annual plan is preselected on first paywall load (unless prior manual selection exists in same session).
- Best value badge is visible on annual plan card.
- Restore button is accessible without scrolling traps.
- Trust copy is visible on all paywall states.
- Purchase events include selected plan id.

**Risk + rollback note**
- Risk: overemphasis may feel manipulative.
- Rollback: remove preselection while keeping badge/copy improvements.

---

## T04 — Soft free limits + daily credit meter (I02)

**Objective + KPI**
- Objective: Establish monetization boundary without hard blocking first value.
- KPI(s):
  - Increase `limit_hit_rate` (controlled)
  - Increase paywall opens from usage exhaustion
  - Reduce compute cost per non-premium active user

**UI touchpoints**
- `ChatView` send action
- Dream interpretation action
- `PalmReadingView` analyze action
- `NatalChartView` interpretation action
- Shared “credits left today” label/badge in relevant screens

**Implementation steps for coder**
1. Create `UsageLimitService`:
   - per-user per-day counters in UserDefaults (key includes `userId` + date)
   - configurable free quota by feature (start with global quota if faster).
2. Expose `remainingCredits` and `consumeCreditIfAvailable()`.
3. Integrate checks before AI actions across chat/dream/palm/natal flows.
4. Add UI meter text: “X free insights left today”.
5. Reset counters on local day change.
6. Emit telemetry: `credit_consumed`, `limit_hit` with feature context.

**Acceptance criteria (testable)**
- With fresh day and non-premium user, first N actions succeed and decrement visible count.
- At quota exhaustion, next action does not call AI request path and triggers limit state.
- On date change (or mocked day rollover), quota resets automatically.
- Premium users bypass limit checks.

**Risk + rollback note**
- Risk: aggressive quota can hurt retention.
- Rollback: raise quota remotely/config constant or disable gate with `usage_limits_enabled=false`.

---

## T05 — Limit-hit contextual paywall copy (I08)

**Objective + KPI**
- Objective: Improve conversion at highest-intent monetization moment (limit reached).
- KPI(s):
  - Increase `paywall_view -> purchase_success` for `trigger=limit_hit`
  - Reduce paywall dismiss rate at limit-hit entrypoint

**UI touchpoints**
- Limit-hit entry states in:
  - `ChatView`
  - Dream interpretation flow
  - `PalmReadingView`
  - `NatalChartView`
- `PaywallView` headline/subheadline area

**Implementation steps for coder**
1. Add trigger context parameter to paywall presenter (`trigger=limit_hit`, `context=chat|dream|palm|natal`).
2. Define copy map per context:
   - chat: “Continue your guidance conversation”
   - dream: “Unlock full dream interpretations”
   - palm: “Get complete palm reading insights”
   - natal: “Unlock deeper natal chart analysis”.
3. Reuse same paywall component; only inject contextual strings.
4. Track `paywall_view` and `purchase_success` with context tags.

**Acceptance criteria (testable)**
- Hitting limit in each supported surface opens paywall with correct context-specific headline.
- Event payload always includes `trigger=limit_hit` and correct `context`.
- Fallback generic copy is used if unknown context is passed.

**Risk + rollback note**
- Risk: inconsistent copy quality across contexts.
- Rollback: switch to single generic copy via config map fallback.

---

## T06 — Inline upgrade CTA in result surfaces (I09)

**Objective + KPI**
- Objective: Monetize high intent directly at result-consumption point.
- KPI(s):
  - Increase `inline_upgrade_tap_rate`
  - Increase paywall opens from result screens

**UI touchpoints**
- Result cards/sections in:
  - `ChatView`
  - Dream interpretation result UI
  - `PalmReadingView` result UI
- `PaywallView`

**Implementation steps for coder**
1. Add reusable inline component (`UnlockDeeperInsightsRow`) below successful result content for non-premium users.
2. Component copy: short value statement + “Unlock Premium” CTA.
3. Tap opens `PaywallView` with `trigger=inline_result_cta` and context.
4. Hide component for premium users.
5. Add telemetry: `inline_upgrade_impression`, `inline_upgrade_tap`.

**Acceptance criteria (testable)**
- Non-premium users see inline CTA after successful result in all targeted surfaces.
- Tapping inline CTA opens paywall and logs `trigger=inline_result_cta`.
- Premium users never see inline upsell.

**Risk + rollback note**
- Risk: repetitive upsell feeling after every result.
- Rollback: throttle impressions (e.g., once per session per context) or disable per surface.

---

## T07 — Daily reminder deep-link to last-used feature (I05)

**Objective + KPI**
- Objective: Create reliable daily return loop and reduce re-entry friction.
- KPI(s):
  - Increase D1/D7 retention
  - Increase notification open rate
  - Increase sessions per active user/day

**UI touchpoints**
- Notification permission/settings UI
- `NotificationService`
- App routing layer (`AppRouter` / `MainTabView` navigation handlers)
- Target feature screens (chat/dream/palm/natal/tarot)

**Implementation steps for coder**
1. Persist `lastUsedFeature` whenever a feature action completes successfully.
2. Schedule one daily local notification (user-configurable time, default evening).
3. Notification payload includes deep-link route to `lastUsedFeature`.
4. On notification open, route directly to target feature and surface quick action CTA.
5. Log events: `notification_scheduled`, `notification_open`, `notification_deeplink_routed`.

**Acceptance criteria (testable)**
- After user interacts with a feature, `lastUsedFeature` is updated.
- Scheduled local notification appears at configured time.
- Tapping notification opens app and routes to matching feature screen.
- If feature value is missing/invalid, app falls back to Home safely.

**Risk + rollback note**
- Risk: over-notification causing opt-out/churn.
- Rollback: reduce frequency or disable deep-link payload while keeping generic reminder.

---

## T08 — Continue-where-you-left-off Home module (I12)

**Objective + KPI**
- Objective: Shorten time-to-value on app re-entry by resuming active context.
- KPI(s):
  - Increase `session_start -> meaningful_action` conversion
  - Increase D1 retention

**UI touchpoints**
- `HomeView` (resume module/card)
- Per-feature resume destinations (chat thread, draft dream note, last reading context)
- Navigation/router

**Implementation steps for coder**
1. Store resumable context on feature exit or completion:
   - `lastContextType`
   - `lastContextId` (if applicable)
   - `lastContextTimestamp`.
2. Add Home card: “Continue where you left off” with dynamic label/icon.
3. Tap routes to exact context when still available; otherwise open feature root.
4. Hide module when no context exists or context is stale beyond threshold (e.g., >7 days).
5. Emit events: `resume_module_impression`, `resume_module_tap`, `resume_route_success`.

**Acceptance criteria (testable)**
- After completing a supported feature action, Home shows resume module on next launch.
- Tapping module routes to correct destination (or graceful feature root fallback).
- Module is not shown when there is no saved context.
- Stale context is automatically pruned and module disappears.

**Risk + rollback note**
- Risk: broken deep links if context objects are deleted.
- Rollback: route all resume taps to feature root until deep-link stability is fixed.

---

## Notes for implementation sequencing

- **Batch 1 (fast conversion wins):** T01, T02, T03  
- **Batch 2 (monetization boundary):** T04, T05, T06  
- **Batch 3 (retention loop):** T07, T08  

Recommended rollout: ship behind flags, enable for 10% internal/test cohort first, then ramp.
