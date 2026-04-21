import SwiftUI

/// Design tokens for the GardenGenie app.
/// Centralizes colors, spacing, and reusable modifiers so the UI stays consistent.
enum AppTheme {

    enum Colors {
        /// Rich garden green — primary actions, active tabs, accents.
        static let primaryGreen = Color(red: 0.18, green: 0.56, blue: 0.34)
        /// Lighter green — tags, subtle highlights.
        static let secondaryGreen = Color(red: 0.56, green: 0.77, blue: 0.49)
        /// Earthy brown — soil-related UI, secondary icons.
        static let earthBrown = Color(red: 0.55, green: 0.38, blue: 0.24)
        /// Sky blue — water/moisture indicators.
        static let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
        /// Sun yellow — sunlight indicators.
        static let sunYellow = Color(red: 0.98, green: 0.82, blue: 0.28)

        /// Status tag colors
        static func statusColor(for tag: String) -> Color {
            switch tag.lowercased() {
            case "thriving": return primaryGreen
            case "growing": return sunYellow
            case "dormant": return earthBrown
            case "needs water": return skyBlue
            default: return .gray
            }
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum CornerRadius {
        static let card: CGFloat = 20
        static let button: CGFloat = 12
        static let tag: CGFloat = 8
    }
}

// MARK: - Card Modifier

/// Applies GardenGenie's signature card styling using iOS 26 liquid glass.
struct GardenCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            }
    }
}

extension View {
    /// Applies the GardenGenie card style — rounded, soft shadow, subtle border.
    func gardenCard() -> some View {
        modifier(GardenCardModifier())
    }

    /// Applies a small pill tag style with a colored fill.
    func pillTag(color: Color) -> some View {
        self
            .font(.caption.weight(.semibold))
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }
}
