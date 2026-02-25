import SwiftUI

// MARK: - Star Model
struct Star: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var twinkleSpeed: Double
}

// MARK: - Star Field Background
struct StarField: View {
    let starCount: Int
    @State private var stars: [Star] = []
    @State private var animate = false

    init(starCount: Int = 100) {
        self.starCount = starCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                MysticGradients.cosmicBackground
                    .ignoresSafeArea()

                // Stars layer
                Canvas { context, size in
                    for star in stars {
                        let rect = CGRect(
                            x: star.x * size.width,
                            y: star.y * size.height,
                            width: star.size,
                            height: star.size
                        )

                        let opacity = animate
                            ? star.opacity * Double.random(in: 0.3...1.0)
                            : star.opacity

                        context.opacity = opacity
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(MysticColors.starWhite)
                        )

                        // Glow for larger stars
                        if star.size > 2 {
                            let glowRect = rect.insetBy(
                                dx: -star.size * 0.5,
                                dy: -star.size * 0.5
                            )
                            context.opacity = opacity * 0.3
                            context.fill(
                                Circle().path(in: glowRect),
                                with: .color(MysticColors.neonLavender)
                            )
                        }
                    }
                }
                .ignoresSafeArea()

                // Nebula effects
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MysticColors.neonLavender.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: -80, y: -200)
                    .blur(radius: 30)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MysticColors.celestialPink.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: 120, y: 300)
                    .blur(radius: 40)
            }
            .onAppear {
                generateStars()
                withAnimation(
                    .easeInOut(duration: 3)
                    .repeatForever(autoreverses: true)
                ) {
                    animate = true
                }
            }
        }
    }

    private func generateStars() {
        stars = (0..<starCount).map { _ in
            Star(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 0.5...3.5),
                opacity: Double.random(in: 0.2...0.9),
                twinkleSpeed: Double.random(in: 1...4)
            )
        }
    }
}

// MARK: - View Modifier
struct StarFieldBackground: ViewModifier {
    let starCount: Int

    func body(content: Content) -> some View {
        content
            .background(StarField(starCount: starCount))
    }
}

extension View {
    func starFieldBackground(starCount: Int = 100) -> some View {
        modifier(StarFieldBackground(starCount: starCount))
    }
}
