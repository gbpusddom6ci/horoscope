import SwiftUI

enum AuroraBackdropStyle {
    case sanctumGlow
    case oracleMist
    case atlasGrid
    case ambient

    fileprivate var palette: AuroraBackdropPalette {
        switch self {
        case .sanctumGlow:
            return AuroraBackdropPalette(
                top: AuroraColors.auroraMint,
                middle: AuroraColors.auroraCyan,
                bottom: AuroraColors.auroraViolet,
                accent: AuroraColors.auroraRose,
                includesConstellations: false
            )
        case .oracleMist:
            return AuroraBackdropPalette(
                top: AuroraColors.auroraViolet,
                middle: AuroraColors.auroraRose,
                bottom: AuroraColors.auroraCyan,
                accent: AuroraColors.auroraMint,
                includesConstellations: false
            )
        case .atlasGrid:
            return AuroraBackdropPalette(
                top: AuroraColors.auroraCyan,
                middle: AuroraColors.auroraMint,
                bottom: AuroraColors.auroraViolet,
                accent: AuroraColors.polarWhite,
                includesConstellations: true
            )
        case .ambient:
            return AuroraBackdropPalette(
                top: AuroraColors.auroraRose,
                middle: AuroraColors.auroraViolet,
                bottom: AuroraColors.auroraMint,
                accent: AuroraColors.auroraCyan,
                includesConstellations: false
            )
        }
    }
}

private struct AuroraBackdropPalette {
    let top: Color
    let middle: Color
    let bottom: Color
    let accent: Color
    let includesConstellations: Bool
}

struct AuroraBackdrop: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let style: AuroraBackdropStyle
    @State private var drift = false
    @State private var breathe = false

    var body: some View {
        GeometryReader { geometry in
            let palette = style.palette
            ZStack {
                AuroraGradients.canvas
                .ignoresSafeArea()

                Circle()
                    .fill(palette.top.opacity(0.24))
                    .frame(width: geometry.size.width * 0.96, height: geometry.size.width * 0.96)
                    .blur(radius: 95)
                    .offset(
                        x: drift ? -geometry.size.width * 0.12 : -geometry.size.width * 0.02,
                        y: -geometry.size.height * 0.32
                    )

                Ellipse()
                    .fill(palette.middle.opacity(0.18))
                    .frame(width: geometry.size.width * 1.24, height: geometry.size.height * 0.34)
                    .rotationEffect(.degrees(drift ? -13 : -19))
                    .blur(radius: 72)
                    .offset(
                        x: drift ? geometry.size.width * 0.08 : -geometry.size.width * 0.04,
                        y: -geometry.size.height * 0.12
                    )

                auroraVeil(
                    colors: [palette.top.opacity(0.96), palette.middle.opacity(0.92), palette.bottom.opacity(0.88)],
                    width: geometry.size.width * 1.34,
                    height: geometry.size.height * 0.16,
                    x: drift ? geometry.size.width * 0.08 : -geometry.size.width * 0.08,
                    y: -geometry.size.height * 0.2,
                    rotation: drift ? -14 : -20,
                    blur: 34,
                    opacity: 0.58
                )

                auroraVeil(
                    colors: [palette.middle.opacity(0.84), palette.bottom.opacity(0.86), palette.accent.opacity(0.72)],
                    width: geometry.size.width * 1.22,
                    height: geometry.size.height * 0.18,
                    x: drift ? -geometry.size.width * 0.03 : geometry.size.width * 0.12,
                    y: geometry.size.height * 0.02,
                    rotation: drift ? 12 : 18,
                    blur: 40,
                    opacity: 0.4
                )

                auroraVeil(
                    colors: [palette.accent.opacity(0.64), palette.bottom.opacity(0.82), palette.middle.opacity(0.58)],
                    width: geometry.size.width * 1.08,
                    height: geometry.size.height * 0.14,
                    x: drift ? geometry.size.width * 0.16 : geometry.size.width * 0.02,
                    y: geometry.size.height * 0.29,
                    rotation: drift ? -10 : -4,
                    blur: 36,
                    opacity: 0.36
                )

                Circle()
                    .fill(palette.bottom.opacity(0.16))
                    .frame(width: geometry.size.width * 0.82, height: geometry.size.width * 0.82)
                    .blur(radius: 84)
                    .offset(
                        x: geometry.size.width * 0.3,
                        y: geometry.size.height * 0.31
                    )

                starDust(in: geometry.size, tint: palette.accent)
                    .opacity(palette.includesConstellations ? 0.7 : 0.38)

                if palette.includesConstellations {
                    constellationOverlay(in: geometry.size, tint: palette.accent)
                        .opacity(0.42)
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, AuroraColors.vignette.opacity(0.78)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AuroraColors.vignette.opacity(0.42), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .ignoresSafeArea()
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: AuroraMotion.ambientDuration).repeatForever(autoreverses: true)) {
                    drift = true
                }
                withAnimation(.easeInOut(duration: 5.6).repeatForever(autoreverses: true)) {
                    breathe = true
                }
            }
        }
    }

    private func auroraVeil(
        colors: [Color],
        width: CGFloat,
        height: CGFloat,
        x: CGFloat,
        y: CGFloat,
        rotation: Double,
        blur: CGFloat,
        opacity: Double
    ) -> some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .scaleEffect(x: breathe ? 1.06 : 0.94, y: breathe ? 1.04 : 0.98)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
            .blur(radius: blur)
            .blendMode(.screen)
            .opacity(opacity)
            .mask(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.78),
                        Color.white.opacity(0.92),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private func starDust(in size: CGSize, tint: Color) -> some View {
        ZStack {
            ForEach(0..<18, id: \.self) { index in
                let normalizedX = CGFloat((index * 37) % 100) / 100
                let normalizedY = CGFloat((index * 23) % 100) / 100
                let diameter = CGFloat((index % 3) + 1) * 1.6
                Circle()
                    .fill(tint.opacity(index.isMultiple(of: 2) ? 0.22 : 0.12))
                    .frame(width: diameter, height: diameter)
                    .blur(radius: diameter * 0.6)
                    .offset(
                        x: size.width * normalizedX - size.width / 2,
                        y: size.height * normalizedY - size.height / 2
                    )
            }
        }
    }

    private func constellationOverlay(in size: CGSize, tint: Color) -> some View {
        Canvas { context, _ in
            let points: [CGPoint] = [
                CGPoint(x: size.width * 0.14, y: size.height * 0.18),
                CGPoint(x: size.width * 0.25, y: size.height * 0.28),
                CGPoint(x: size.width * 0.37, y: size.height * 0.24),
                CGPoint(x: size.width * 0.53, y: size.height * 0.31),
                CGPoint(x: size.width * 0.67, y: size.height * 0.24),
                CGPoint(x: size.width * 0.79, y: size.height * 0.36),
                CGPoint(x: size.width * 0.7, y: size.height * 0.48),
                CGPoint(x: size.width * 0.56, y: size.height * 0.43)
            ]

            let links = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (3, 7), (7, 6)]

            for link in links {
                var path = Path()
                path.move(to: points[link.0])
                path.addLine(to: points[link.1])
                context.stroke(path, with: .color(tint.opacity(0.16)), lineWidth: 0.8)
            }

            for point in points {
                let dotRect = CGRect(x: point.x - 1.5, y: point.y - 1.5, width: 3, height: 3)
                context.fill(Path(ellipseIn: dotRect), with: .color(tint.opacity(0.42)))
            }

            var orbitalArc = Path()
            orbitalArc.addEllipse(in: CGRect(
                x: -size.width * 0.12,
                y: size.height * 0.56,
                width: size.width * 0.88,
                height: size.height * 0.32
            ))
            context.stroke(orbitalArc, with: .color(tint.opacity(0.08)), lineWidth: 1)
        }
    }
}

struct LumenCard<Content: View>: View {
    let accent: Color
    let padding: CGFloat
    let content: Content

    init(
        accent: Color = AuroraColors.auroraMint,
        padding: CGFloat = AuroraSpacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.accent = accent
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AuroraRadius.md, style: .continuous)

        content
            .padding(padding)
            .background(
                ZStack {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    AuroraColors.surfaceElevated,
                                    AuroraColors.cardBase,
                                    AuroraColors.surface
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    shape
                        .fill(AuroraGradients.silkHighlight)

                    Circle()
                        .fill(accent.opacity(0.18))
                        .frame(width: 180, height: 180)
                        .blur(radius: 46)
                        .offset(x: -80, y: -90)

                    Ellipse()
                        .fill(AuroraGradients.cardWash(accent: accent))
                        .frame(width: 260, height: 120)
                        .rotationEffect(.degrees(-10))
                        .offset(x: 72, y: 54)
                }
            )
            .clipShape(shape)
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(0.58), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                shape
                    .inset(by: 1.25)
                    .stroke(Color.white.opacity(0.04), lineWidth: 0.8)
            )
            .shadow(color: accent.opacity(0.18), radius: 30, x: 0, y: 18)
            .shadow(color: Color.black.opacity(0.28), radius: 26, x: 0, y: 18)
    }
}

enum HaloButtonStyle {
    case primary
    case secondary
    case ghost
}

struct HaloButton: View {
    let title: String
    let icon: String?
    let style: HaloButtonStyle
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: HaloButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AuroraSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(AuroraTypography.bodyStrong(15))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AuroraSpacing.md)
            .padding(.vertical, 14)
            .background(backgroundView)
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .shadow(color: shadowColor, radius: style == .ghost ? 0 : 18, x: 0, y: 10)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            ZStack {
                Capsule(style: .continuous)
                    .fill(AuroraGradients.primaryCTA)

                Capsule(style: .continuous)
                    .fill(AuroraGradients.silkHighlight)
                    .opacity(0.8)

                Circle()
                    .fill(Color.white.opacity(0.24))
                    .frame(width: 72, height: 72)
                    .blur(radius: 14)
                    .offset(x: -54, y: -18)
            }
        case .secondary:
            ZStack {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AuroraColors.surfaceElevated.opacity(0.96),
                                AuroraColors.secondaryCard.opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Capsule(style: .continuous)
                    .fill(AuroraGradients.cardWash(accent: AuroraColors.auroraViolet))
            }
        case .ghost:
            Capsule(style: .continuous)
                .fill(AuroraColors.surface.opacity(0.52))
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return AuroraColors.obsidian
        case .secondary, .ghost:
            return AuroraColors.polarWhite
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return Color.white.opacity(0.25)
        case .secondary:
            return AuroraColors.auroraViolet.opacity(0.26)
        case .ghost:
            return AuroraColors.stroke
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return AuroraColors.auroraMint.opacity(0.24)
        case .secondary:
            return AuroraColors.auroraViolet.opacity(0.16)
        case .ghost:
            return .clear
        }
    }
}

struct PrismChip: View {
    let title: String
    let icon: String?
    let accent: Color
    let isSelected: Bool

    init(_ title: String, icon: String? = nil, accent: Color, isSelected: Bool = false) {
        self.title = title
        self.icon = icon
        self.accent = accent
        self.isSelected = isSelected
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(title)
                .font(AuroraTypography.mono(11))
        }
        .foregroundColor(isSelected ? AuroraColors.obsidian : AuroraColors.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(
                    isSelected
                        ? AnyShapeStyle(AuroraGradients.chipFill(accent: accent))
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    AuroraColors.surfaceElevated.opacity(0.86),
                                    AuroraColors.secondaryCard.opacity(0.78)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Capsule()
                        .fill(AuroraGradients.cardWash(accent: accent))
                        .opacity(isSelected ? 0.0 : 0.65)
                )
        )
        .overlay(
            Capsule()
                .stroke(isSelected ? Color.white.opacity(0.2) : AuroraColors.stroke, lineWidth: 1)
        )
        .shadow(color: isSelected ? accent.opacity(0.24) : .clear, radius: 12, x: 0, y: 8)
    }
}

struct ConstellationHeader<Trailing: View>: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?
    let trailing: Trailing

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: AuroraSpacing.md) {
            VStack(alignment: .leading, spacing: 6) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(AuroraTypography.mono(11))
                        .foregroundColor(AuroraColors.textMuted)
                }

                Text(title)
                    .font(AuroraTypography.title(28))
                    .foregroundColor(AuroraColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(AuroraTypography.body(14))
                        .foregroundColor(AuroraColors.textSecondary)
                        .lineSpacing(4)
                }
            }

            Spacer(minLength: 0)

            trailing
        }
        .overlay(alignment: .topLeading) {
            Capsule(style: .continuous)
                .fill(AuroraGradients.auroraSpectrum)
                .frame(width: 56, height: 3)
                .opacity(0.86)
                .offset(y: -10)
        }
    }
}

extension ConstellationHeader where Trailing == EmptyView {
    init(eyebrow: String? = nil, title: String, subtitle: String? = nil) {
        self.init(eyebrow: eyebrow, title: title, subtitle: subtitle) {
            EmptyView()
        }
    }
}

struct JourneyRailItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let action: () -> Void
}

struct JourneyRail: View {
    let items: [JourneyRailItem]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AuroraSpacing.sm) {
                ForEach(items) { item in
                    Button(action: item.action) {
                        LumenCard(accent: item.accent) {
                            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(item.accent.opacity(0.16))
                                        .frame(width: 42, height: 42)
                                    Image(systemName: item.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(item.accent)
                                }
                                Text(item.title)
                                    .font(AuroraTypography.bodyStrong(15))
                                    .foregroundColor(AuroraColors.textPrimary)
                                Text(item.subtitle)
                                    .font(AuroraTypography.body(13))
                                    .foregroundColor(AuroraColors.textSecondary)
                                    .lineSpacing(3)
                            }
                            .frame(width: 214, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct RitualMeter: View {
    let progress: Double
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AuroraTypography.bodyStrong(15))
                        .foregroundColor(AuroraColors.textPrimary)
                    Text(subtitle)
                        .font(AuroraTypography.body(13))
                        .foregroundColor(AuroraColors.textSecondary)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(AuroraTypography.mono(11))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 10) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AuroraColors.surfaceElevated.opacity(0.88),
                                        AuroraColors.secondaryCard.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accent,
                                        accent.opacity(0.76),
                                        AuroraColors.polarWhite.opacity(0.42)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * max(0, min(progress, 1)))
                            .shadow(color: accent.opacity(0.4), radius: 12, x: 0, y: 4)

                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 12, height: 12)
                            .blur(radius: 0.3)
                            .shadow(color: accent.opacity(0.58), radius: 10, x: 0, y: 0)
                            .offset(x: max(0, geometry.size.width * max(0, min(progress, 1)) - 12))
                            .opacity(progress > 0.04 ? 1 : 0)
                    }
                }
                .frame(height: 12)

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule(style: .continuous)
                            .fill(index < Int(ceil(progress * 3)) ? accent.opacity(0.88) : AuroraColors.surfaceElevated.opacity(0.84))
                            .frame(maxWidth: .infinity)
                            .frame(height: 5)
                    }
                }
            }
        }
    }
}

struct AmbientSheet<Content: View>: View {
    let style: AuroraBackdropStyle
    let content: Content

    init(style: AuroraBackdropStyle = .ambient, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        ZStack {
            AuroraBackdrop(style: style)
            content
        }
    }
}

enum AuroraContentBottomInsetStrategy {
    case none
    case fixed(CGFloat)
    case chromeAware(extra: CGFloat = AuroraSpacing.md)

    func resolve(using chromeMetrics: MainChromeMetrics) -> CGFloat {
        switch self {
        case .none:
            return 0
        case .fixed(let value):
            return max(0, value)
        case .chromeAware(let extra):
            return chromeMetrics.contentBottomReservedSpace + max(0, extra)
        }
    }
}

struct AuroraHeaderBar<Trailing: View>: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?
    let trailing: Trailing

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: AuroraSpacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(AuroraTypography.mono(10))
                        .foregroundColor(AuroraColors.textMuted)
                }
                Text(title)
                    .font(AuroraTypography.title(24))
                    .foregroundColor(AuroraColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let subtitle {
                    Text(subtitle)
                        .font(AuroraTypography.body(13))
                        .foregroundColor(AuroraColors.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            trailing
                .frame(minWidth: 44, minHeight: 44)
                .background(
                    Circle()
                        .fill(AuroraColors.surfaceElevated.opacity(0.8))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
        .padding(.horizontal, AuroraSpacing.md)
        .padding(.top, AuroraSpacing.md)
        .padding(.bottom, AuroraSpacing.sm)
        .background(
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        AuroraColors.obsidian.opacity(0.86),
                        AuroraColors.obsidian.opacity(0.34),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(AuroraColors.surface.opacity(0.56))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AuroraColors.polarWhite.opacity(0.08),
                                        AuroraColors.auroraViolet.opacity(0.08),
                                        AuroraColors.auroraMint.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(AuroraGradients.cardWash(accent: AuroraColors.auroraViolet))
                            .opacity(0.45)
                    )
                    .padding(.horizontal, AuroraSpacing.sm)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, AuroraColors.auroraViolet.opacity(0.08), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .overlay(alignment: .bottom) {
            Capsule(style: .continuous)
                .fill(AuroraGradients.auroraSpectrum)
                .frame(width: 96, height: 2)
                .opacity(0.52)
                .padding(.bottom, 2)
        }
    }
}

extension AuroraHeaderBar where Trailing == EmptyView {
    init(eyebrow: String? = nil, title: String, subtitle: String? = nil) {
        self.init(eyebrow: eyebrow, title: title, subtitle: subtitle) {
            EmptyView()
        }
    }
}

struct AuroraScreen<Trailing: View, Content: View>: View {
    @Environment(\.mainChromeMetrics) private var chromeMetrics

    let backdropStyle: AuroraBackdropStyle
    let eyebrow: String?
    let title: String
    let subtitle: String?
    let showsHeader: Bool
    let usesScrollView: Bool
    let contentHorizontalPadding: CGFloat
    let contentBottomInsetStrategy: AuroraContentBottomInsetStrategy
    let trailing: Trailing
    let content: Content

    init(
        backdropStyle: AuroraBackdropStyle = .ambient,
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        showsHeader: Bool = true,
        usesScrollView: Bool = true,
        contentHorizontalPadding: CGFloat = AuroraSpacing.md,
        contentBottomInsetStrategy: AuroraContentBottomInsetStrategy = .chromeAware(),
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.backdropStyle = backdropStyle
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.showsHeader = showsHeader
        self.usesScrollView = usesScrollView
        self.contentHorizontalPadding = contentHorizontalPadding
        self.contentBottomInsetStrategy = contentBottomInsetStrategy
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        ZStack {
            AuroraBackdrop(style: backdropStyle)

            VStack(spacing: 0) {
                if showsHeader {
                    AuroraHeaderBar(eyebrow: eyebrow, title: title, subtitle: subtitle) {
                        trailing
                    }
                }

                if usesScrollView {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: AuroraSpacing.md) {
                            content

                            if bottomInset > 0 {
                                Color.clear
                                    .frame(height: bottomInset)
                            }
                        }
                        .padding(.horizontal, contentHorizontalPadding)
                        .padding(.top, AuroraSpacing.md)
                    }
                } else {
                    content
                        .padding(.horizontal, contentHorizontalPadding)
                }
            }
        }
    }

    private var bottomInset: CGFloat {
        contentBottomInsetStrategy.resolve(using: chromeMetrics)
    }
}

extension AuroraScreen where Trailing == EmptyView {
    init(
        backdropStyle: AuroraBackdropStyle = .ambient,
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        showsHeader: Bool = true,
        usesScrollView: Bool = true,
        contentHorizontalPadding: CGFloat = AuroraSpacing.md,
        contentBottomInsetStrategy: AuroraContentBottomInsetStrategy = .chromeAware(),
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            backdropStyle: backdropStyle,
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
            showsHeader: showsHeader,
            usesScrollView: usesScrollView,
            contentHorizontalPadding: contentHorizontalPadding,
            contentBottomInsetStrategy: contentBottomInsetStrategy,
            trailing: { EmptyView() },
            content: content
        )
    }
}
