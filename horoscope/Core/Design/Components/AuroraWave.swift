import SwiftUI

/// Animated flowing aurora wave visualization — 3 sine wave layers
/// with glow effects (green, cyan, pink).
struct AuroraWave: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var height: CGFloat = 120
    var lineWidth: CGFloat = 2.5
    var glowRadius: CGFloat = 10

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

                drawWave(
                    context: &context, size: size, time: time,
                    color: MysticColors.auroraGreen,
                    amplitude: 0.25, frequency: 1.2, speed: 0.8, phaseOffset: 0,
                    lineWidth: lineWidth, glowRadius: glowRadius
                )

                drawWave(
                    context: &context, size: size, time: time,
                    color: MysticColors.neonLavender,
                    amplitude: 0.2, frequency: 1.6, speed: 1.1, phaseOffset: 1.2,
                    lineWidth: lineWidth * 0.85, glowRadius: glowRadius * 0.8
                )

                drawWave(
                    context: &context, size: size, time: time,
                    color: MysticColors.celestialPink,
                    amplitude: 0.15, frequency: 2.0, speed: 0.6, phaseOffset: 2.5,
                    lineWidth: lineWidth * 0.7, glowRadius: glowRadius * 0.6
                )
            }
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }

    private func drawWave(
        context: inout GraphicsContext,
        size: CGSize,
        time: Double,
        color: Color,
        amplitude: CGFloat,
        frequency: CGFloat,
        speed: Double,
        phaseOffset: Double,
        lineWidth: CGFloat,
        glowRadius: CGFloat
    ) {
        var path = Path()
        let midY = size.height / 2
        let amp = size.height * amplitude
        let steps = Int(size.width / 2)

        for i in 0...steps {
            let x = CGFloat(i) / CGFloat(steps) * size.width
            let normalizedX = x / size.width
            let angle = normalizedX * .pi * 2 * frequency + time * speed + phaseOffset
            let y = midY + sin(angle) * amp * (0.6 + 0.4 * sin(normalizedX * .pi))

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        // Glow layer
        var glowContext = context
        glowContext.addFilter(.blur(radius: glowRadius))
        glowContext.stroke(path, with: .color(color.opacity(0.6)), lineWidth: lineWidth * 2.5)

        // Mid glow
        var midGlow = context
        midGlow.addFilter(.blur(radius: glowRadius * 0.4))
        midGlow.stroke(path, with: .color(color.opacity(0.8)), lineWidth: lineWidth * 1.5)

        // Core line
        context.stroke(path, with: .color(color), lineWidth: lineWidth)
    }
}

#Preview {
    ZStack {
        MysticColors.voidBlack.ignoresSafeArea()
        AuroraWave()
            .padding()
    }
}
