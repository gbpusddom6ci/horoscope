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
            .shadow(color: glowColor.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Feature Card (for home screen)
struct FeatureCard: View {
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
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = true } }
                .onEnded { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = false } }
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
                        Text("Günlük Yorum")
                            .font(MysticFonts.heading())
                            .foregroundColor(MysticColors.textPrimary)
                        Text("Bugün güzel şeyler olacak...")
                            .font(MysticFonts.body())
                            .foregroundColor(MysticColors.textSecondary)
                    }
                }

                FeatureCard(
                    icon: "moon.stars.fill",
                    title: "Natal Chart",
                    subtitle: "Doğum haritanızı keşfedin",
                    color: MysticColors.neonLavender
                ) {}

                FeatureCard(
                    icon: "sparkles",
                    title: "AI Yorum",
                    subtitle: "Yapay zeka ile kişisel analiz",
                    color: MysticColors.mysticGold
                ) {}

                HStack(spacing: 12) {
                    StatCard(label: "Güneş", value: "Koç", icon: "sun.max.fill", color: MysticColors.mysticGold)
                    StatCard(label: "Ay", value: "Balık", icon: "moon.fill", color: MysticColors.neonLavender)
                    StatCard(label: "Yükselen", value: "Aslan", icon: "arrow.up.circle.fill", color: MysticColors.auroraGreen)
                }
            }
            .padding(16)
        }
    }
}
