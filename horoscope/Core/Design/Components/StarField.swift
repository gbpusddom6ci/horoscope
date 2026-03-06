import SwiftUI

// MARK: - Star Field Configuration

enum StarFieldMode {
    case screen
    case modal
    case staticBackdrop

    var densityMultiplier: CGFloat {
        switch self {
        case .screen:
            return 1
        case .modal:
            return 0.7
        case .staticBackdrop:
            return 0.45
        }
    }

    var nebulaOpacity: Double {
        switch self {
        case .screen:
            return 1
        case .modal:
            return 0.7
        case .staticBackdrop:
            return 0.5
        }
    }

    var twinkleStrength: Double {
        switch self {
        case .screen:
            return 0.35
        case .modal:
            return 0.22
        case .staticBackdrop:
            return 0.0
        }
    }

    var minFrameInterval: TimeInterval {
        switch self {
        case .screen:
            return 1.0 / 24.0
        case .modal:
            return 1.0 / 20.0
        case .staticBackdrop:
            return 1.0 / 12.0
        }
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid all-zero state.
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2685821657736338717
    }
}

private struct Star: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let baseOpacity: Double
    let twinkleSpeed: Double
    let phase: Double
}

// MARK: - Star Field Background
struct StarField: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    let starCount: Int
    let mode: StarFieldMode
    let isAnimated: Bool
    let seed: UInt64?

    @State private var stars: [Star] = []

    init(
        starCount: Int = 100,
        mode: StarFieldMode = .screen,
        isAnimated: Bool = true,
        seed: UInt64? = nil
    ) {
        self.starCount = starCount
        self.mode = mode
        self.isAnimated = isAnimated
        self.seed = seed
    }

    private var shouldAnimate: Bool {
        isAnimated && !reduceMotion && scenePhase == .active && mode.twinkleStrength > 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MysticGradients.cosmicBackground
                    .ignoresSafeArea()

                TimelineView(.periodic(from: .now, by: mode.minFrameInterval)) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        let twinkleAmplitude = mode.twinkleStrength

                        for star in stars {
                            let rect = CGRect(
                                x: star.x * size.width,
                                y: star.y * size.height,
                                width: star.size,
                                height: star.size
                            )

                            let twinkle: Double
                            if shouldAnimate {
                                twinkle = (1 - twinkleAmplitude) + twinkleAmplitude
                                    * (0.5 + 0.5 * sin(time * star.twinkleSpeed + star.phase))
                            } else {
                                twinkle = 1
                            }

                            let opacity = star.baseOpacity * twinkle

                            context.opacity = opacity
                            context.fill(
                                Circle().path(in: rect),
                                with: .color(MysticColors.starWhite)
                            )

                            if star.size > 1.8 {
                                let glowRect = rect.insetBy(
                                    dx: -star.size * 0.6,
                                    dy: -star.size * 0.6
                                )
                                context.opacity = opacity * 0.32
                                let glowColor = star.size > 2.5
                                    ? MysticColors.stardust
                                    : MysticColors.neonLavender
                                context.fill(
                                    Circle().path(in: glowRect),
                                    with: .color(glowColor)
                                )
                            }
                        }
                    }
                }
                .ignoresSafeArea()

                // MARK: - Vivid Aurora Bokeh Blobs
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MysticColors.auroraGreen.opacity(0.35 * mode.nebulaOpacity),
                                MysticColors.auroraGreen.opacity(0.08 * mode.nebulaOpacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 280
                        )
                    )
                    .frame(width: 600, height: 600)
                    .offset(x: -100, y: -220)
                    .blur(radius: 50)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MysticColors.celestialPink.opacity(0.22 * mode.nebulaOpacity),
                                MysticColors.celestialPink.opacity(0.05 * mode.nebulaOpacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 15,
                            endRadius: 220
                        )
                    )
                    .frame(width: 500, height: 500)
                    .offset(x: 140, y: 320)
                    .blur(radius: 55)

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                MysticColors.neonLavender.opacity(0.2 * mode.nebulaOpacity),
                                MysticColors.neonLavender.opacity(0.04 * mode.nebulaOpacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 240
                        )
                    )
                    .frame(width: 550, height: 400)
                    .offset(x: 80, y: -40)
                    .blur(radius: 60)

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                MysticColors.auroraGreen.opacity(0.18 * mode.nebulaOpacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 180
                        )
                    )
                    .frame(width: 400, height: 300)
                    .offset(x: -120, y: 160)
                    .blur(radius: 45)

                // Extra vivid blob — top right magenta
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MysticColors.celestialPink.opacity(0.15 * mode.nebulaOpacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 160
                        )
                    )
                    .frame(width: 350, height: 350)
                    .offset(x: 160, y: -300)
                    .blur(radius: 40)

                // Extra vivid blob — center aurora shimmer
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MysticColors.auroraGreen.opacity(0.12 * mode.nebulaOpacity),
                                MysticColors.neonLavender.opacity(0.06 * mode.nebulaOpacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 200
                        )
                    )
                    .frame(width: 450, height: 450)
                    .offset(x: -40, y: 80)
                    .blur(radius: 50)
            }
            .onAppear {
                if stars.isEmpty {
                    generateStars(in: geometry.size)
                }
            }
            .onChange(of: geometry.size) { _, _ in
                generateStars(in: geometry.size)
            }
            .onChange(of: starCount) { _, _ in
                generateStars(in: geometry.size)
            }
            .onChange(of: mode) { _, _ in
                generateStars(in: geometry.size)
            }
            .onChange(of: seed) { _, _ in
                generateStars(in: geometry.size)
            }
        }
    }

    private func generateStars(in size: CGSize) {
        let requested = CGFloat(max(0, starCount)) * mode.densityMultiplier
        let adjustedCount = max(0, Int(requested.rounded()))

        var generator = SeededGenerator(seed: resolvedSeed(for: size))
        stars = (0..<adjustedCount).map { index in
            Star(
                id: index,
                x: CGFloat.random(in: 0...1, using: &generator),
                y: CGFloat.random(in: 0...1, using: &generator),
                size: CGFloat.random(in: 0.5...3.5, using: &generator),
                baseOpacity: Double.random(in: 0.2...0.9, using: &generator),
                twinkleSpeed: Double.random(in: 1.0...4.0, using: &generator),
                phase: Double.random(in: 0...(2 * .pi), using: &generator)
            )
        }
    }

    private func resolvedSeed(for size: CGSize) -> UInt64 {
        if let seed {
            return seed
        }

        let w = UInt64(max(1, Int(size.width.rounded())))
        let h = UInt64(max(1, Int(size.height.rounded())))
        let c = UInt64(max(1, starCount))
        let modeValue: UInt64
        switch mode {
        case .screen: modeValue = 11
        case .modal: modeValue = 29
        case .staticBackdrop: modeValue = 47
        }
        return (w << 32) ^ (h << 8) ^ (c << 1) ^ modeValue
    }
}

// MARK: - View Modifier
struct StarFieldBackground: ViewModifier {
    let starCount: Int
    let mode: StarFieldMode
    let isAnimated: Bool
    let seed: UInt64?

    func body(content: Content) -> some View {
        content
            .background(
                StarField(
                    starCount: starCount,
                    mode: mode,
                    isAnimated: isAnimated,
                    seed: seed
                )
            )
    }
}

extension View {
    func starFieldBackground(
        starCount: Int = 100,
        mode: StarFieldMode = .screen,
        isAnimated: Bool = true,
        seed: UInt64? = nil
    ) -> some View {
        modifier(
            StarFieldBackground(
                starCount: starCount,
                mode: mode,
                isAnimated: isAnimated,
                seed: seed
            )
        )
    }
}
