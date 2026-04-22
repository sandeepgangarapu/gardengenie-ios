import SwiftUI

/// Static, non-ticking date label for task rows and day headers.
/// Replaces SwiftUI's `.relative` style which updates live.
struct TaskDateLabel: View {
    let dueDate: Date
    var isOverdue: Bool = false
    var style: Style = .caption

    enum Style {
        case caption    // under task names
        case header     // section headers above a day's tasks
    }

    var body: some View {
        Text(text)
            .font(style == .header ? .title3.bold() : .caption)
            .foregroundStyle(isOverdue ? AppTheme.Colors.accentPink : color)
    }

    private var text: String {
        let formatted = Self.format(dueDate)
        return isOverdue ? "Overdue · \(formatted)" : formatted
    }

    private var color: Color {
        style == .header ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary
    }

    // MARK: - Formatting

    static func format(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let startOfToday = calendar.startOfDay(for: .now)
        let startOfDate = calendar.startOfDay(for: date)
        let diff = calendar.dateComponents([.day], from: startOfToday, to: startOfDate).day ?? 0

        if diff > 1, diff <= 6 {
            return weekdayFormatter.string(from: date)
        }

        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: .now)
        return sameYear
            ? sameYearFormatter.string(from: date)
            : fullFormatter.string(from: date)
    }

    // Cached formatters (DateFormatter allocation is expensive).
    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE · MMM d"
        return f
    }()

    private static let sameYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        TaskDateLabel(dueDate: .now)
        TaskDateLabel(dueDate: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        TaskDateLabel(dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now)!)
        TaskDateLabel(dueDate: Calendar.current.date(byAdding: .day, value: 20, to: .now)!)
        TaskDateLabel(dueDate: Calendar.current.date(byAdding: .day, value: -2, to: .now)!, isOverdue: true)
        TaskDateLabel(dueDate: .now, style: .header)
    }
    .padding()
    .background(.black)
    .preferredColorScheme(.dark)
}
