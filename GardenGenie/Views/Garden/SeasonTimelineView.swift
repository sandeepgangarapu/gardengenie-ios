import SwiftUI

/// A year at a glance: one thin row per stage (seeds indoors, plant out,
/// harvest) across Jan–Dec, with a marker on the current month. Separate rows
/// keep overlapping windows readable.
struct SeasonTimelineView: View {
    let windows: [SeasonWindow]
    var currentMonth: Int = Calendar.current.component(.month, from: .now)

    private let monthLetters = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(windows.sorted { $0.kind.rawValue < $1.kind.rawValue }, id: \.self) { window in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(window.kind.label)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .frame(width: 84, alignment: .leading)
                    track(for: window)
                }
            }
            HStack(spacing: AppTheme.Spacing.sm) {
                Color.clear.frame(width: 84, height: 1)
                HStack(spacing: 2) {
                    ForEach(1...12, id: \.self) { month in
                        Text(monthLetters[month - 1])
                            .font(.system(size: 9, weight: month == currentMonth ? .bold : .regular))
                            .foregroundStyle(month == currentMonth ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground,
                    in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private func track(for window: SeasonWindow) -> some View {
        HStack(spacing: 2) {
            ForEach(1...12, id: \.self) { month in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(window.contains(month: month) ? color(for: window.kind) : Color.white.opacity(0.06))
                    .frame(height: 8)
                    .overlay {
                        if month == currentMonth {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.9), lineWidth: 1)
                        }
                    }
            }
        }
    }

    private func color(for kind: SeasonWindow.Kind) -> Color {
        switch kind {
        case .seedIndoors: return AppTheme.Colors.sunYellow
        case .plantOut: return AppTheme.Colors.secondaryGreen
        case .harvest: return Color(red: 0.91, green: 0.33, blue: 0.24)
        }
    }

    private var accessibilitySummary: String {
        let names = Calendar.current.monthSymbols
        return windows.map { window in
            "\(window.kind.label): \(names[window.startMonth - 1]) to \(names[window.endMonth - 1])"
        }.joined(separator: ". ")
    }
}

#Preview {
    SeasonTimelineView(windows: [
        SeasonWindow(kind: .seedIndoors, startMonth: 2, endMonth: 3),
        SeasonWindow(kind: .plantOut, startMonth: 4, endMonth: 5),
        SeasonWindow(kind: .harvest, startMonth: 5, endMonth: 3),
    ])
    .padding()
    .background(.black)
}
