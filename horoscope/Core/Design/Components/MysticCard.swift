import SwiftUI

struct MysticCard<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var glowColor: Color

    init(
        padding: CGFloat = MysticSpacing.md,
        glowColor: Color = MysticColors.neonLavender,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.glowColor = glowColor
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Glassmorphism background
                    RoundedRectangle(cornerRadius: MysticRadius.lg)
                        .fill(MysticGradients.cardGlass)

                    RoundedRectangle(cornerRadius: MysticRadius.lg)
                        .fill(MysticColors.cardBackground)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: MysticRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MysticRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: [
                                glowColor.opacity(0.3),
                                glowColor.opacity(0.05),
                                glowColor.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: glowColor.opacity(0.08),
                radius: MysticEffects.cardShadowRadius,
                x: 0,
                y: MysticEffects.cardShadowYOffset
            )
    }
}

enum MysticStateCardVariant {
    case loading(messageKey: LocalizedStringKey, detailKey: LocalizedStringKey? = nil)
    case empty(
        icon: String,
        titleKey: LocalizedStringKey,
        detailKey: LocalizedStringKey? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    )
    case error(message: String, retryTitle: String? = nil, retryAction: (() -> Void)? = nil)
    case successNotice(messageKey: LocalizedStringKey)
}

struct MysticStateCard: View {
    let variant: MysticStateCardVariant
    var accessibilityIdentifier: String?

    var body: some View {
        MysticCard(glowColor: glowColor) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }

    @ViewBuilder
    private var content: some View {
        switch variant {
        case .loading(let messageKey, let detailKey):
            HStack(spacing: MysticSpacing.sm) {
                ProgressView()
                    .tint(MysticColors.neonLavender)
                VStack(alignment: .leading, spacing: 2) {
                    Text(messageKey)
                        .font(MysticFonts.body(14))
                        .foregroundColor(MysticColors.textPrimary)
                    if let detailKey {
                        Text(detailKey)
                            .font(MysticFonts.caption(12))
                            .foregroundColor(MysticColors.textMuted)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: MysticAccessibility.minimumTapTarget)

        case .empty(let icon, let titleKey, let detailKey, let actionTitle, let action):
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                HStack(spacing: MysticSpacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(MysticColors.textMuted)
                    Text(titleKey)
                        .font(MysticFonts.heading(16))
                        .foregroundColor(MysticColors.textPrimary)
                }

                if let detailKey {
                    Text(detailKey)
                        .font(MysticFonts.body(14))
                        .foregroundColor(MysticColors.textSecondary)
                        .lineSpacing(MysticEffects.compactTextLineSpacing)
                }

                if let actionTitle, let action {
                    MysticButton(actionTitle, style: .secondary, size: .compact) {
                        action()
                    }
                    .padding(.top, MysticSpacing.xs)
                }
            }

        case .error(let message, let retryTitle, let retryAction):
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                HStack(spacing: MysticSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(MysticColors.celestialPink)
                    Text(message)
                        .font(MysticFonts.body(14))
                        .foregroundColor(MysticColors.celestialPink)
                    Spacer(minLength: 0)
                }

                if let retryAction {
                    Button(retryTitle ?? String(localized: "common.retry")) {
                        retryAction()
                    }
                    .buttonStyle(.plain)
                    .font(MysticFonts.caption(13))
                    .foregroundColor(MysticColors.neonLavender)
                    .frame(minHeight: MysticAccessibility.minimumTapTarget, alignment: .leading)
                }
            }

        case .successNotice(let messageKey):
            HStack(spacing: MysticSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(MysticColors.auroraGreen)
                Text(messageKey)
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textPrimary)
                Spacer(minLength: 0)
            }
            .frame(minHeight: MysticAccessibility.minimumTapTarget)
        }
    }

    private var glowColor: Color {
        switch variant {
        case .loading:
            return MysticColors.neonLavender.opacity(0.7)
        case .empty:
            return MysticColors.textMuted.opacity(0.5)
        case .error:
            return MysticColors.celestialPink.opacity(0.8)
        case .successNotice:
            return MysticColors.auroraGreen.opacity(0.7)
        }
    }
}

// MARK: - Feature Card (for home screen)
struct FeatureCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            MysticCard(glowColor: color) {
                HStack(spacing: MysticSpacing.md) {
                    // Icon circle
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundColor(color)
                    }

                    VStack(alignment: .leading, spacing: MysticSpacing.xs) {
                        Text(title)
                            .font(MysticFonts.body(16))
                            .fontWeight(.semibold)
                            .foregroundColor(MysticColors.textPrimary)

                        Text(subtitle)
                            .font(MysticFonts.caption(13))
                            .foregroundColor(MysticColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MysticColors.textMuted)
                }
            }
            .scaleEffect(isPressed ? MysticEffects.cardPressedScale : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if reduceMotion {
                        isPressed = true
                    } else {
                        withAnimation(.easeInOut(duration: MysticMotion.quickPressDuration)) { isPressed = true }
                    }
                }
                .onEnded { _ in
                    if reduceMotion {
                        isPressed = false
                    } else {
                        withAnimation(.easeInOut(duration: MysticMotion.quickPressDuration)) { isPressed = false }
                    }
                }
        )
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        MysticCard(glowColor: color) {
            VStack(spacing: MysticSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(value)
                    .font(MysticFonts.heading(20))
                    .foregroundColor(MysticColors.textPrimary)

                Text(label)
                    .font(MysticFonts.caption(11))
                    .foregroundColor(MysticColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ZStack {
        StarField()

        ScrollView {
            VStack(spacing: 16) {
                MysticCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: "Daily Insight")
                            .font(MysticFonts.heading())
                            .foregroundColor(MysticColors.textPrimary)
                        Text(verbatim: "Good things will happen today...")
                            .font(MysticFonts.body())
                            .foregroundColor(MysticColors.textSecondary)
                    }
                }

                FeatureCard(
                    icon: "moon.stars.fill",
                    title: "Natal Chart",
                    subtitle: "Discover your birth chart",
                    color: MysticColors.neonLavender
                ) {}

                FeatureCard(
                    icon: "sparkles",
                    title: "AI Reading",
                    subtitle: "Personal analysis with AI",
                    color: MysticColors.mysticGold
                ) {}

                HStack(spacing: 12) {
                    StatCard(label: "Sun", value: "Aries", icon: "sun.max.fill", color: MysticColors.mysticGold)
                    StatCard(label: "Moon", value: "Pisces", icon: "moon.fill", color: MysticColors.neonLavender)
                    StatCard(label: "Ascendant", value: "Leo", icon: "arrow.up.circle.fill", color: MysticColors.auroraGreen)
                }
            }
            .padding(16)
        }
    }
}
