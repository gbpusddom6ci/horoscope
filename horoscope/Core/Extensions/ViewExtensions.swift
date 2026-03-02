import SwiftUI
import UIKit

// MARK: - View Extensions

extension View {
    /// Disables horizontal bounce/scroll on the nearest parent UIScrollView.
    func disableHorizontalScrollBounce() -> some View {
        overlay(ScrollViewBounceFixView())
    }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
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

// MARK: - ScrollView Horizontal Bounce Fix
private struct ScrollViewBounceFixView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let scrollView = uiView.enclosingUIScrollView()
                ?? uiView.superview?.findUIScrollViewInHierarchy() {
                scrollView.alwaysBounceHorizontal = false
            }
        }
    }
}

private extension UIView {
    func enclosingUIScrollView() -> UIScrollView? {
        var v: UIView? = superview
        while let current = v {
            if let sv = current as? UIScrollView { return sv }
            v = current.superview
        }
        return nil
    }

    func findUIScrollViewInHierarchy() -> UIScrollView? {
        if let sv = self as? UIScrollView { return sv }
        for subview in subviews {
            if let found = subview.findUIScrollViewInHierarchy() { return found }
        }
        return nil
    }
}

// MARK: - Fade In Modifier
struct FadeInModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let delay: Double
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                if reduceMotion {
                    opacity = 1
                    offset = 0
                } else {
                    withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                        opacity = 1
                        offset = 0
                    }
                }
            }
    }
}

// MARK: - Date Extensions
extension Date {
    static func appLocale(
        selectedLanguage: String?,
        fallback: Locale = .autoupdatingCurrent
    ) -> Locale {
        guard let selectedLanguage = selectedLanguage?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !selectedLanguage.isEmpty else {
            return fallback
        }

        return Locale(identifier: selectedLanguage)
    }

    var zodiacSign: ZodiacSign {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        let day = calendar.component(.day, from: self)
        return ZodiacSign.from(month: month, day: day)
    }

    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Self.appLocale(
            selectedLanguage: UserDefaults.standard.string(forKey: "selected_language")
        )
        return formatter.string(from: self)
    }

    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Self.appLocale(
            selectedLanguage: UserDefaults.standard.string(forKey: "selected_language")
        )
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
