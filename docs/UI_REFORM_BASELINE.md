# UI Reform Baseline (WAR36 H+0)

## Purpose
Establish a **low-risk visual consistency baseline** aligned with the mystic horoscope direction, without changing product flows.

Scope for H+0:
- Shared tokens and shared design components only
- No feature-level layout rewrites
- No behavioral product changes

---

## 1) Audit Snapshot

### Core/Design (Mystic)
**What is strong**
- Cohesive mystic palette (`MysticColors`) and gradients (`MysticGradients`)
- Tokenized spacing/radius/accessibility foundations
- Reusable shared components (`MysticButton`, `MysticCard`, `MysticTopBar`, `MysticScreenScaffold`, `StarField`)

**What needed baseline tightening**
- Repeated motion/effect literals (`0.1`, `2`, `2.5`, `12`, `4`, `0.97`, `0.98`) across shared components
- Small typography/detail spacing inconsistencies (compact text line spacing, shadow/press values)

### Core/DesignSystem (Legacy app-wide)
**What is strong**
- Broad adoption across existing screens (`AppTheme`, `AppTypography`, `GlassCard`, shared button styles)

**What needed baseline tightening**
- App-wide semantic palette not aligned with mystic direction
- Shared components used multiple hardcoded spacing/radius/interaction values
- Duplicate `Color(hex:)` implementations existed in multiple files

---

## 2) Baseline Token Rules

## Typography
Use these semantic roles:
- `AppTypography.titleExtraBold` (34, rounded) → hero screen headlines
- `AppTypography.titleBold` (28, rounded) → section/page titles
- `AppTypography.headline` (22, rounded) → key component headings, CTA emphasis
- `AppTypography.body` (17, default) → readable body content
- `AppTypography.captionMedium` (13, default) → metadata/chips/helper labels
- `AppTypography.bodyLineSpacing` (8) for long-form readability (`premiumText` default)

Mystic-specific type scale remains:
- `MysticFonts.title / heading / body / caption / mystic`

## Spacing
Primary 4-point scale:
- `xs=4`, `sm=8`, `md=16`, `lg=24` (+ extended `xl=32`, `xxl=48` in mystic layer)

Rules:
- Prefer tokenized spacing
- Avoid ad-hoc values unless truly optical/micro-alignment

## Radius
- `md=12`, `lg=16`, `xl=24` (App)
- `sm=8`, `md=12`, `lg=16`, `xl=24`, `full=100` (Mystic)

Rules:
- Pill/CTA: `lg`
- Cards: `lg` or `xl` (depending on visual hierarchy)

## Color
### App semantic baseline (aligned to mystic tone)
- `AppTheme.primary` = `#B388FF` (neon lavender)
- `AppTheme.accent` = `#C9A227` (mystic gold)
- `AppTheme.success` = `#69F0AE` (aurora green)
- `AppTheme.bgLight` = `#F6F2FF`
- `AppTheme.bgDark` = `#080510`

### Mystic palette remains source of atmospheric styles
- Cosmic bg, card glass, neon accents, text tiers (`textPrimary/Secondary/Muted`)

Rules:
- Use semantic tokens first (`primary/accent/success/background`)
- Use direct hex only when introducing a new token

## Motion & Interaction
- Shared press/micro-interaction duration: `MysticMotion.quickPressDuration` (0.1)
- Glow durations:
  - Button: `MysticMotion.buttonGlowDuration` (2.0)
  - Text: `MysticMotion.textGlowDuration` (2.5)
- Press scales:
  - Button: `MysticEffects.buttonPressedScale` (0.97)
  - Card: `MysticEffects.cardPressedScale` (0.98)

## Accessibility
- Minimum tap target: `44pt` (`AppAccessibility.minimumTapTarget` / `MysticAccessibility.minimumTapTarget`)
- Keep disabled states visibly distinct (opacity + interaction lock)

---

## 3) Shared Component Rules

### Buttons
- Use shared styles (`BigGlowingButton`, `SecondaryPillButton`, `MysticButton`)
- Keep corners and motion tokenized
- Ensure compact controls still honor `44pt` tap minimum

### Cards
- Use `GlassCard` / `MysticCard` with shared radius and subtle stroke
- Keep shadow/elevation values centralized via effect tokens

### Top Bars / Scaffolds
- Continue using `MysticTopBar` + `MysticScreenScaffold` for consistent spacing, hierarchy, and reserved chrome space

---

## 4) Do / Don’t

### Do
- ✅ Build with shared tokens first (color, spacing, radius, typography, motion)
- ✅ Keep style updates centralized in `Core/Design` and `Core/DesignSystem`
- ✅ Reuse existing shared components before creating new variants
- ✅ Preserve accessibility minimums and reduce-motion behavior

### Don’t
- ❌ Introduce new hardcoded hex/spacing/radius values in feature screens
- ❌ Duplicate utility extensions (e.g., `Color(hex:)`) across files
- ❌ Fork button/card styles per-screen when a shared variant fits
- ❌ Mix unrelated visual languages (legacy bright palette vs mystic) in the same semantic token layer

---

## 5) H+0 Change Intent
This baseline is intentionally conservative:
- Visual language alignment via tokens
- Consistency improvements in shared components
- No feature flow or business-logic change

Follow-up phases can migrate remaining feature-level literals to this baseline incrementally.
