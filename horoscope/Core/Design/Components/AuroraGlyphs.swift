import SwiftUI

enum AuroraGlyphKind {
    case tarot
    case eye
    case saturn
    case dreamcatcher
    case profile
}

struct AuroraGlyph: View {
    let kind: AuroraGlyphKind
    var color: Color = AuroraColors.textPrimary
    var lineWidth: CGFloat = 1.8

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                switch kind {
                case .tarot:
                    tarotGlyph(size: size)
                case .eye:
                    eyeGlyph(size: size)
                case .saturn:
                    saturnGlyph(size: size)
                case .dreamcatcher:
                    dreamcatcherGlyph(size: size)
                case .profile:
                    profileGlyph(size: size)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func tarotGlyph(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                .stroke(color.opacity(0.95), lineWidth: lineWidth)
                .frame(width: size * 0.7, height: size * 0.92)

            RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                .stroke(color.opacity(0.45), lineWidth: lineWidth * 0.8)
                .frame(width: size * 0.52, height: size * 0.74)

            Diamond()
                .stroke(color.opacity(0.92), lineWidth: lineWidth)
                .frame(width: size * 0.18, height: size * 0.18)

            Circle()
                .fill(color.opacity(0.16))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(y: -size * 0.23)

            Circle()
                .fill(color.opacity(0.16))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(y: size * 0.23)
        }
    }

    private func eyeGlyph(size: CGFloat) -> some View {
        ZStack {
            EyeShape()
                .stroke(color.opacity(0.95), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.88, height: size * 0.56)

            Circle()
                .stroke(color.opacity(0.84), lineWidth: lineWidth)
                .frame(width: size * 0.22, height: size * 0.22)

            Circle()
                .fill(color.opacity(0.94))
                .frame(width: size * 0.09, height: size * 0.09)

            Capsule(style: .continuous)
                .fill(color.opacity(0.2))
                .frame(width: size * 0.08, height: size * 0.18)
                .rotationEffect(.degrees(45))
                .offset(x: size * 0.2, y: -size * 0.18)
        }
    }

    private func saturnGlyph(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.92), lineWidth: lineWidth)
                .frame(width: size * 0.38, height: size * 0.38)

            Circle()
                .fill(color.opacity(0.14))
                .frame(width: size * 0.3, height: size * 0.3)

            Ellipse()
                .stroke(color.opacity(0.9), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size * 0.82, height: size * 0.28)
                .rotationEffect(.degrees(-18))

            Ellipse()
                .stroke(color.opacity(0.38), style: StrokeStyle(lineWidth: lineWidth * 0.8, lineCap: .round))
                .frame(width: size * 0.62, height: size * 0.18)
                .rotationEffect(.degrees(-18))

            Circle()
                .fill(color.opacity(0.9))
                .frame(width: size * 0.05, height: size * 0.05)
                .offset(x: size * 0.22, y: -size * 0.19)
        }
    }

    private func dreamcatcherGlyph(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.95), lineWidth: lineWidth)
                .frame(width: size * 0.56, height: size * 0.56)

            DreamWebShape()
                .stroke(color.opacity(0.45), lineWidth: lineWidth * 0.75)
                .frame(width: size * 0.4, height: size * 0.4)

            VStack(spacing: size * 0.02) {
                Spacer(minLength: size * 0.48)
                HStack(spacing: size * 0.08) {
                    featherStem(size: size * 0.22)
                    featherStem(size: size * 0.28)
                    featherStem(size: size * 0.2)
                }
            }
        }
    }

    private func profileGlyph(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.95), lineWidth: lineWidth)
                .frame(width: size * 0.84, height: size * 0.84)

            Circle()
                .stroke(color.opacity(0.92), lineWidth: lineWidth)
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(y: -size * 0.14)

            ProfileShouldersShape()
                .stroke(color.opacity(0.92), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.46, height: size * 0.24)
                .offset(y: size * 0.18)
        }
    }

    private func featherStem(size: CGFloat) -> some View {
        VStack(spacing: 0) {
            Capsule(style: .continuous)
                .fill(color.opacity(0.6))
                .frame(width: lineWidth, height: size * 0.44)

            FeatherShape()
                .stroke(color.opacity(0.92), lineWidth: lineWidth * 0.8)
                .frame(width: size * 0.38, height: size * 0.52)
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct EyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

private struct DreamWebShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for factor in stride(from: 0.33, through: 1.0, by: 0.33) {
            path.addEllipse(in: CGRect(
                x: center.x - radius * factor,
                y: center.y - radius * factor,
                width: radius * 2 * factor,
                height: radius * 2 * factor
            ))
        }

        for angle in stride(from: Double(0), to: Double.pi * 2, by: Double.pi / 3) {
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            path.move(to: center)
            path.addLine(to: point)
        }

        return path
    }
}

private struct FeatherShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.midX * 0.9, y: rect.midY)
        )

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.midX * 1.1, y: rect.midY)
        )
        return path
    }
}

private struct ProfileShouldersShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.2),
            control: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.12)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.12)
        )
        return path
    }
}
