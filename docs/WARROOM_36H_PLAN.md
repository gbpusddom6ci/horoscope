# WARROOM 36H Plan — Horoscope

## Objective
36 saat içinde **TestFlight-ready Release Candidate** çıkarmak.

## Non-Negotiables
- App derlenebilir olmalı (Debug + Release)
- Kritik akışlar çalışmalı: Auth, Onboarding, Home, Chat, Natal, Palm, Tarot, Settings
- P0 = 0, P1 mümkünse 0
- Lokalizasyon (EN/TR) bozulmamalı

## Workstreams

### 1) Stabilization Lane (coder)
- Build kırıklarını çöz
- `DesignSystem.swift` + `Theme.swift` çakışmalarını temizle
- App giriş akışı ve tab root stabil hale gelsin

### 2) Core Product Flow Lane (coder-core)
- Domain drift temizliği (yanlış feature set / yanlış nav)
- Horoscope ana ürün akışını geri oturt
- Gereksiz/yanlış ekranların etkisini izole et

### 3) UI Reform Lane (coder-ui)
- Mystic/premium tema üzerinde tutarlı component ve spacing
- Kritik ekranlarda görsel tutarlılık ve a11y polish

### 4) QA Gate (tester + tester-regression)
- Regression matrix
- Build/test komutları
- Bug listesi (P0/P1/P2)

### 5) Product/Growth (creative)
- Monetization ve retention iyileştirme backlog
- Hızlı kazanımlar (high impact, low effort)

### 6) Release Ops (release-ops)
- CI + release scripts + runbook hardening
- Submission checklist

## Timeline (Wall-clock)
- H+0 → H+4: Stabilization + scope freeze
- H+4 → H+18: Parallel implementation
- H+18 → H+28: QA + bugfix loops
- H+28 → H+34: Release prep + final polish
- H+34 → H+36: RC freeze + handoff

## Branching
- orchestrator: `war36/orchestrator`
- lanes:
  - `war36/coder`
  - `war36/coder-core`
  - `war36/coder-ui`
  - `war36/tester`
  - `war36/tester-regression`
  - `war36/creative`
  - `war36/release-ops`

## Merge Strategy
1. coder (stabilization) -> orchestrator
2. coder-core -> orchestrator
3. coder-ui -> orchestrator
4. tester fixes (if any) -> orchestrator
5. release-ops -> orchestrator

Gate: Her merge öncesi build + release_prep_checks.
