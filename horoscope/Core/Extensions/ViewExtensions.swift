import SwiftUI

// MARK: - View Extensions

extension View {
    /// Apply mystic card background
    func mysticCardStyle(glowColor: Color = MysticColors.neonLavender) -> some View {
        self
            .padding(MysticSpacing.md)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: MysticRadius.lg)
                        .fill(MysticGradients.cardGlass)
                    RoundedRectangle(cornerRadius: MysticRadius.lg)
                        .fill(MysticColors.cardBackground)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: MysticRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MysticRadius.lg)
                    .stroke(glowColor.opacity(0.2), lineWidth: 1)
            )
    }

    /// Shimmer loading effect
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }

    /// Fade in animation on appear
    func fadeInOnAppear(delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(delay: delay))
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: phase * geometry.size.width * 1.6 - geometry.size.width * 0.3)
                    }
                    .mask(content)
                )
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Fade In Modifier
struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                    opacity = 1
                    offset = 0
                }
            }
    }
}

// MARK: - Date Extensions
extension Date {
    var zodiacSign: ZodiacSign {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        let day = calendar.component(.day, from: self)
        return ZodiacSign.from(month: month, day: day)
    }

    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }

    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
