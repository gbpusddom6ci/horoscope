import SwiftUI

// MARK: - App Theme
public struct AppTheme {
    public static let primary = Color(hex: "14B8A6") // Teal-emerald
    public static let accent = Color(hex: "F43F5E") // Rose
    public static let success = Color(hex: "22C55E")
    
    // Background with adaptive light mode warm tint and deep dark mode base
    public static let bgLight = Color(hex: "FCFBFA") // Very light warm tint
    public static let bgDark = Color(hex: "0D0D12")  // Deep navy-black base
    
    public static let background = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark 
            ? UIColor(bgDark) 
            : UIColor(bgLight)
    })
}

// MARK: - Typography Modifiers
public struct AppTypography {
    public static let titleExtraBold = Font.system(size: 34, weight: .heavy, design: .default)
    public static let titleBold = Font.system(size: 28, weight: .bold, design: .default)
    public static let headline = Font.system(size: 22, weight: .semibold, design: .default)
    public static let body = Font.system(size: 17, weight: .regular, design: .default)
    public static let captionMedium = Font.system(size: 13, weight: .medium, design: .default)
}

struct PremiumTextModifier: ViewModifier {
    var font: Font
    var color: Color
    var lineSpacing: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
            .lineSpacing(lineSpacing)
    }
}

extension View {
    public func premiumText(font: Font = AppTypography.body, color: Color = .primary, lineSpacing: CGFloat = 8) -> some View {
        self.modifier(PremiumTextModifier(font: font, color: color, lineSpacing: lineSpacing))
    }
}

// MARK: - GlassCard Component (Liquid Glass)
public struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    var content: Content
    
    public init(cornerRadius: CGFloat = 24, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Button Styles
public struct BigGlowingButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(16)
            .shadow(color: AppTheme.primary.opacity(0.4), radius: configuration.isPressed ? 5 : 15, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}

public struct SecondaryPillButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.captionMedium)
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
