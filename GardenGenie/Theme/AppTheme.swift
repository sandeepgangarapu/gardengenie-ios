import SwiftUI

/// Design tokens for the GardenGenie app — dark card-based aesthetic.
/// Centralizes colors, spacing, corner radii, and reusable modifiers.
enum AppTheme {

    // MARK: - Colors

    enum Colors {
        /// OLED true-black background.
        static let background = Color(red: 0.00, green: 0.00, blue: 0.00)
        /// Slightly-lighter dark-gray for grouped cards.
        static let cardBackground = Color(red: 0.08, green: 0.08, blue: 0.09)
        /// Elevated card surface for grouped inner rows.
        static let cardBackgroundElevated = Color(red: 0.11, green: 0.11, blue: 0.12)
        /// Subtle divider between rows.
        static let divider = Color.white.opacity(0.08)

        /// Pink primary accent — CTAs, active states.
        static let accentPink = Color(red: 0.95, green: 0.30, blue: 0.47)
        /// Blue secondary accent — settings icons, toggles, stat numbers.
        static let accentBlue = Color(red: 0.26, green: 0.56, blue: 0.96)

        /// Primary text — white on dark.
        static let textPrimary = Color.white
        /// Secondary text — 60 % white.
        static let textSecondary = Color.white.opacity(0.60)
        /// Tertiary text — 38 % white.
        static let textTertiary = Color.white.opacity(0.38)

        // Stat-color palette (kept for care-grid tints)
        static let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
        static let sunYellow = Color(red: 0.98, green: 0.82, blue: 0.28)
        static let earthBrown = Color(red: 0.55, green: 0.38, blue: 0.24)
        static let secondaryGreen = Color(red: 0.56, green: 0.77, blue: 0.49)

        /// Legacy alias so old references compile.
        static let primaryGreen = accentPink

        /// Status tag colors (remapped to new accents).
        static func statusColor(for tag: String) -> Color {
            switch tag.lowercased() {
            case "thriving":    return accentPink
            case "growing":     return sunYellow
            case "dormant":     return earthBrown
            case "needs water": return skyBlue
            default:            return .gray
            }
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Corner Radii

    enum CornerRadius {
        static let card: CGFloat = 22
        static let button: CGFloat = 28
        static let tag: CGFloat = 10
        static let icon: CGFloat = 18
    }
}

// MARK: - Pill Button Style

/// `.primary` = pink fill, white text.  `.secondary` = dark fill, subtle stroke.
enum PillButtonStyle {
    case primary
    case secondary
}

// MARK: - Card Modifier

/// Flat dark card — no shadow, optional hairline stroke.
struct GardenCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
            )
    }
}

// MARK: - View Extensions

extension View {

    /// Applies the dark card style — rounded, flat fill, no shadow.
    func gardenCard() -> some View {
        modifier(GardenCardModifier())
    }

    /// Small pill tag: colored text on translucent colored capsule.
    func pillTag(color: Color) -> some View {
        self
            .font(.caption.weight(.semibold))
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    /// 36×36 circular icon button with elevated card fill.
    func circularIconButton() -> some View {
        self
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(AppTheme.Colors.cardBackgroundElevated)
            )
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    /// Pill-shaped CTA button. `.primary` = pink fill; `.secondary` = dark fill + stroke.
    func pillButton(style: PillButtonStyle) -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .background {
                switch style {
                case .primary:
                    Capsule()
                        .fill(AppTheme.Colors.accentPink)
                case .secondary:
                    Capsule()
                        .fill(AppTheme.Colors.cardBackgroundElevated)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
            }
    }
}
