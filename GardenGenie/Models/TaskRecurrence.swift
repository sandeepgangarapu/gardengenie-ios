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
        case .everyNDays(let n): return "Every \(n) days"
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
}
