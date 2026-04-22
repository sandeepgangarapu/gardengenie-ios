import SwiftUI

/// Compact tappable card showing a month prominently with an icon and label.
/// Used side-by-side in PlantDetailView for seed starting / planting.
struct PlantingCompactCard: View {
    let title: String        // "Seed Starting" or "Planting"
    let month: String?       // "February-March" etc.
    let iconName: String     // SF Symbol
    let accentColor: Color   // sunYellow or secondaryGreen

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Top row: icon in tinted circle + chevron
            HStack {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: iconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accentColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }

            // Label
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.textSecondary)

            // Hero month text
            Text(month.map(Self.abbreviate) ?? "See details")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .strokeBorder(accentColor.opacity(0.12), lineWidth: 1)
        )
    }

    private static let monthAbbreviations: [String: String] = [
        "january": "Jan", "february": "Feb", "march": "Mar", "april": "Apr",
        "may": "May", "june": "Jun", "july": "Jul", "august": "Aug",
        "september": "Sep", "october": "Oct", "november": "Nov", "december": "Dec"
    ]

    /// Abbreviates full month names in a range string (e.g. "February–March" → "Feb–Mar").
    static func abbreviate(_ input: String) -> String {
        var result = input
        for (full, short) in monthAbbreviations {
            let range = NSRange(result.startIndex..., in: result)
            if let regex = try? NSRegularExpression(pattern: "\\b\(full)\\b", options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: short)
            }
        }
        return result
    }
}

#Preview {
    HStack(spacing: AppTheme.Spacing.sm) {
        PlantingCompactCard(
            title: "Seed Starting",
            month: "February-March",
            iconName: "leaf.arrow.triangle.circlepath",
            accentColor: AppTheme.Colors.sunYellow
        )
        PlantingCompactCard(
            title: "Planting",
            month: "April-May",
            iconName: "leaf.circle.fill",
            accentColor: AppTheme.Colors.secondaryGreen
        )
    }
    .padding()
    .background(AppTheme.Colors.background)
    .preferredColorScheme(.dark)
}
