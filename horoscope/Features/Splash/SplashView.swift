import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            AuroraBackdrop(style: .sanctumGlow)

            VStack(spacing: AuroraSpacing.xl) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AuroraColors.auroraMint.opacity(0.28),
                                    AuroraColors.auroraViolet.opacity(0.16),
                                    AuroraColors.auroraRose.opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 18,
                                endRadius: 120
                            )
                        )
                        .frame(width: 220, height: 220)

                    Capsule(style: .continuous)
                        .fill(AuroraGradients.auroraVeil)
                        .frame(width: 240, height: 76)
                        .rotationEffect(.degrees(isAnimating ? -14 : -22))
                        .blur(radius: 28)
                        .opacity(0.5)

                    Capsule(style: .continuous)
                        .fill(AuroraGradients.oracle)
                        .frame(width: 200, height: 60)
                        .rotationEffect(.degrees(isAnimating ? 16 : 8))
                        .blur(radius: 22)
                        .opacity(0.34)

                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        .frame(width: 148, height: 148)

                    AuroraGlyph(kind: .saturn, color: AuroraColors.polarWhite, lineWidth: 2.4)
                        .frame(width: 72, height: 72)
                        .foregroundStyle(AuroraGradients.primaryCTA)
                        .shadow(color: AuroraColors.auroraMint.opacity(isAnimating ? 0.8 : 0.3), radius: isAnimating ? 28 : 12)
                        .shadow(color: AuroraColors.auroraViolet.opacity(isAnimating ? 0.26 : 0.08), radius: isAnimating ? 44 : 20)
                        .scaleEffect(isAnimating ? 1.04 : 0.96)
                }

                VStack(spacing: AuroraSpacing.sm) {
                    Text(String(localized: "app.brand"))
                        .font(AuroraTypography.hero(42))
                        .foregroundColor(AuroraColors.textPrimary)
                        .scaleEffect(isAnimating ? 1.01 : 0.99)

                    Text("splash.subtitle")
                        .font(AuroraTypography.body(14))
                        .foregroundColor(AuroraColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AuroraSpacing.lg)
                }

                Spacer()

                VStack(spacing: AuroraSpacing.md) {
                    ProgressView()
                        .tint(AuroraColors.polarWhite)
                        .scaleEffect(1.1)

                    Text(String(localized: "splash.loading"))
                        .font(AuroraTypography.body(13))
                        .foregroundColor(AuroraColors.textMuted)
                        .opacity(isAnimating ? 1 : 0.5)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            } else {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}
