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
                    // Outer spinning halo
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [MysticColors.mysticGold.opacity(0.1), MysticColors.mysticGold, MysticColors.mysticGold.opacity(0.1)],
                                center: .center,
                                startAngle: .degrees(isAnimating ? 0 : 360),
                                endAngle: .degrees(isAnimating ? 360 : 720)
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 160, height: 160)
                        
                    // Inner spinning halo counter-clockwise
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [MysticColors.neonLavender.opacity(0.1), MysticColors.neonLavender, MysticColors.neonLavender.opacity(0.1)],
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
                                colors: [MysticColors.mysticGold, MysticColors.mysticGold.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: MysticColors.mysticGold.opacity(isAnimating ? 0.6 : 0.2), radius: isAnimating ? 20 : 10)
                        .scaleEffect(isAnimating ? 1.05 : 0.95)
                }

                GlowingText("Mystic", font: MysticFonts.title(40), color: MysticColors.mysticGold, glowRadius: isAnimating ? 12 : 6)
                    .scaleEffect(isAnimating ? 1.02 : 0.98)

                Spacer()
                
                VStack(spacing: MysticSpacing.md) {
                    ProgressView()
                        .tint(MysticColors.neonLavender)
                        .scaleEffect(1.2)
                    
                    Text("Awakening the stars...")
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
