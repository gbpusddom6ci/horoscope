import SwiftUI

/// Circular progress ring with neon glow and optional animated light trail.
struct GlowingRing: View {
    let progress: CGFloat
    let color: Color
    var size: CGFloat = 70
    var lineWidth: CGFloat = 6
    var label: String? = nil
    var showTrail: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var trailRotation: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Track ring
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: lineWidth)
                    .frame(width: size, height: size)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                color.opacity(0.3),
                                color,
                                color,
                                color.opacity(0.3)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * progress)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    // Glow layers
                    .shadow(color: color.opacity(0.8), radius: 4)
                    .shadow(color: color.opacity(0.4), radius: 10)
                    .shadow(color: color.opacity(0.15), radius: 20)

                // Light trail dot
                if showTrail && !reduceMotion {
                    Circle()
                        .fill(Color.white)
                        .frame(width: lineWidth * 1.5, height: lineWidth * 1.5)
                        .shadow(color: color, radius: 8)
                        .shadow(color: color.opacity(0.6), radius: 16)
                        .offset(y: -size / 2)
                        .rotationEffect(.degrees(trailRotation - 90))
                }

                // Value text
                Text(verbatim: "\(Int(progress * 100))%")
                    .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            if let label {
                Text(label)
                    .font(MysticFonts.caption(11))
                    .foregroundColor(MysticColors.textSecondary)
            }
        }
        .onAppear {
            guard showTrail && !reduceMotion else { return }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                trailRotation = 360
            }
        }
    }
}

#Preview {
    ZStack {
        MysticColors.voidBlack.ignoresSafeArea()
        HStack(spacing: 24) {
            GlowingRing(progress: 0.7, color: MysticColors.auroraGreen, label: "Love")
            GlowingRing(progress: 0.85, color: MysticColors.celestialPink, label: "Career")
            GlowingRing(progress: 0.6, color: MysticColors.neonLavender, label: "Health")
        }
    }
}
