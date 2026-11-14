import Foundation

/// Where a plant stands on care, for the status chip on its card.
enum PlantCareStatus: Equatable {
    /// A task is past due (named after the oldest one).
    case overdue(String)
    /// A task is due today.
    case dueToday(String)
    /// Nothing due today; the next task is on `Date`.
    case next(String, Date)
    /// No pending tasks for this plant.
    case noTasks
}

/// Day-based views over the task list used by the Today home. Pure functions
/// so they're easy to test; `TaskViewModel` owns the data.
enum TaskSchedule {

    /// Pending tasks that are overdue or due today, oldest first.
    static func dueToday(_ tasks: [GardenTask], now: Date = .now, calendar: Calendar = .current) -> [GardenTask] {
        let endOfToday = startOfDay(after: now, calendar: calendar)
        return tasks
            .filter { !$0.isCompleted && $0.dueDate < endOfToday }
            .sorted { $0.dueDate < $1.dueDate }
    }

    /// Completed occurrences that were due today, so "2 of 3 left" adds up.
    static func completedToday(_ tasks: [GardenTask], now: Date = .now, calendar: Calendar = .current) -> [GardenTask] {
        tasks.filter { $0.isCompleted && calendar.isDate($0.dueDate, inSameDayAs: now) }
    }

    /// Pending tasks due after today, within the next `days` days, soonest first.
    static func upcoming(_ tasks: [GardenTask], days: Int = 7, now: Date = .now, calendar: Calendar = .current) -> [GardenTask] {
        let start = startOfDay(after: now, calendar: calendar)
        guard let end = calendar.date(byAdding: .day, value: days, to: start) else { return [] }
        return tasks
            .filter { !$0.isCompleted && $0.dueDate >= start && $0.dueDate < end }
            .sorted { $0.dueDate < $1.dueDate }
    }

    static func status(for plantID: UUID, in tasks: [GardenTask], now: Date = .now, calendar: Calendar = .current) -> PlantCareStatus {
        let pending = tasks
            .filter { $0.plantID == plantID && !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
        guard let first = pending.first else { return .noTasks }
        let startOfToday = calendar.startOfDay(for: now)
        if first.dueDate < startOfToday { return .overdue(first.name) }
        if first.dueDate < startOfDay(after: now, calendar: calendar) { return .dueToday(first.name) }
        return .next(first.name, first.dueDate)
    }

    /// "Today", "Tomorrow", a weekday within the next week ("Sat"), else "Nov 27".
    static func shortDayLabel(for date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return "Today" }
        let startOfToday = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: startOfToday, to: calendar.startOfDay(for: date)).day ?? 0
        if days == 1 { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .current
        formatter.setLocalizedDateFormatFromTemplate(days > 1 && days < 7 ? "EEE" : "MMMd")
        return formatter.string(from: date)
    }

    private static func startOfDay(after date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
    }
}
