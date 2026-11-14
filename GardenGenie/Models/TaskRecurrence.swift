import Foundation

enum TaskRecurrence: Codable, Hashable {
    case none
    case daily
    case everyNDays(Int)
    case weekly
    case biweekly
    case monthly

    var isRecurring: Bool { self != .none }

    var displayName: String {
        switch self {
        case .none: return "One-time"
        case .daily: return "Daily"
        case .everyNDays(let n):
            // 21 → "Every 3 weeks" reads better than "Every 21 days".
            if n >= 14, n % 7 == 0 { return "Every \(n / 7) weeks" }
            return "Every \(n) days"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Monthly"
        }
    }

    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .everyNDays(let n):
            return calendar.date(byAdding: .day, value: max(n, 1), to: date)
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date)
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        }
    }

    /// Options exposed in pickers. `everyNDays` gets a few preset choices.
    static let pickerOptions: [TaskRecurrence] = [
        .none, .daily, .everyNDays(3), .weekly, .biweekly, .monthly
    ]

    /// `pickerOptions` plus `value` when it isn't one of the presets (e.g. a
    /// parsed "Every 6 weeks"), so a Picker bound to `value` always has a
    /// matching row. Sorted by interval, with one-time first.
    static func pickerOptions(including value: TaskRecurrence) -> [TaskRecurrence] {
        guard !pickerOptions.contains(value) else { return pickerOptions }
        return (pickerOptions + [value]).sorted {
            ($0.approximateDays ?? 0) < ($1.approximateDays ?? 0)
        }
    }

    /// Rough interval length in days; `nil` for one-time tasks.
    var approximateDays: Int? {
        switch self {
        case .none: return nil
        case .daily: return 1
        case .everyNDays(let n): return max(n, 1)
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        }
    }
}
