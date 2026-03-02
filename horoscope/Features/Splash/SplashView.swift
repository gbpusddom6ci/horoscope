import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            MysticColors.voidBlack
                .ignoresSafeArea()
            
            StarField(starCount: 60)

            VStack(spacing: MysticSpacing.xl) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [MysticColors.stardust.opacity(0.05), MysticColors.stardust.opacity(0.3), MysticColors.stardust.opacity(0.05)],
                                center: .center,
                                startAngle: .degrees(isAnimating ? 0 : 360),
                                endAngle: .degrees(isAnimating ? 360 : 720)
                            ),
                            lineWidth: 0.5
                        )
                        .frame(width: 180, height: 180)

                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [MysticColors.mysticGold.opacity(0.08), MysticColors.mysticGold.opacity(0.9), MysticColors.mysticGold.opacity(0.08)],
                                center: .center,
                                startAngle: .degrees(isAnimating ? 0 : 360),
                                endAngle: .degrees(isAnimating ? 360 : 720)
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 160, height: 160)

                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [MysticColors.neonLavender.opacity(0.08), MysticColors.neonLavender.opacity(0.8), MysticColors.neonLavender.opacity(0.08)],
                                center: .center,
                                startAngle: .degrees(isAnimating ? 360 : 0),
                                endAngle: .degrees(isAnimating ? 720 : 360)
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 140, height: 140)

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [MysticColors.mysticGold, Color(hex: "F0D060"), MysticColors.mysticGold.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: MysticColors.mysticGold.opacity(isAnimating ? 0.6 : 0.2), radius: isAnimating ? 22 : 10)
                        .shadow(color: MysticColors.mysticGold.opacity(isAnimating ? 0.2 : 0.05), radius: isAnimating ? 40 : 20)
                        .scaleEffect(isAnimating ? 1.05 : 0.95)
                }

                GlowingText(String(localized: "app.brand"), font: MysticFonts.title(42), color: MysticColors.mysticGold, glowRadius: isAnimating ? 14 : 6)
                    .scaleEffect(isAnimating ? 1.02 : 0.98)

                Spacer()
                
                VStack(spacing: MysticSpacing.md) {
                    ProgressView()
                        .tint(MysticColors.stardust)
                        .scaleEffect(1.1)
                    
                    Text(String(localized: "splash.loading"))
                        .font(MysticFonts.caption(13))
                        .foregroundColor(MysticColors.textMuted)
                        .opacity(isAnimating ? 1 : 0.5)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
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
