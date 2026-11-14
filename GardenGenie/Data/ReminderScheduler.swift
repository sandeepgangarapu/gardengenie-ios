import SwiftUI
import UserNotifications

/// UserDefaults keys and helpers for the reminder preferences shown in
/// Settings and in the care-plan sheet.
enum ReminderSettings {
    /// Master switch. Already used by the Settings "Task Notifications" toggle.
    static let enabledKey = "task_notifications"
    /// Time of day reminders fire, as minutes after midnight.
    static let minutesKey = "reminder_minutes"
    static let defaultMinutes = 8 * 60

    static func isEnabled(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: enabledKey) as? Bool ?? true
    }

    static func minutes(_ defaults: UserDefaults = .standard) -> Int {
        defaults.object(forKey: minutesKey) as? Int ?? defaultMinutes
    }

    /// Bridges the stored minutes to a `Date` so it can drive a time-only DatePicker.
    static func timeBinding(_ minutes: Binding<Int>, calendar: Calendar = .current) -> Binding<Date> {
        Binding(
            get: {
                calendar.date(
                    bySettingHour: minutes.wrappedValue / 60,
                    minute: minutes.wrappedValue % 60,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { date in
                let parts = calendar.dateComponents([.hour, .minute], from: date)
                minutes.wrappedValue = (parts.hour ?? 8) * 60 + (parts.minute ?? 0)
            }
        )
    }
}

/// A reminder the app intends to schedule. Kept apart from
/// `UNNotificationRequest` so the planning rules can be unit-tested.
struct PlannedReminder: Equatable {
    let taskID: UUID
    let fireDate: Date
    let title: String
    let body: String
    /// Groups a day's reminders together in Notification Center.
    let threadID: String
}

enum ReminderPlanner {
    static let identifierPrefix = "task."
    static let taskIDKey = "taskID"
    /// iOS keeps at most 64 pending local notifications per app; leave headroom.
    static let maxPending = 60

    static func identifier(for taskID: UUID) -> String { identifierPrefix + taskID.uuidString }

    /// One reminder per pending task, on its due day at the reminder time.
    /// Tasks whose reminder time has already passed get none. Soonest first,
    /// capped at `limit`.
    static func plan(
        tasks: [GardenTask],
        now: Date,
        minutes: Int,
        calendar: Calendar = .current,
        limit: Int = maxPending
    ) -> [PlannedReminder] {
        let dayFormatter = DateFormatter()
        dayFormatter.calendar = calendar
        dayFormatter.dateFormat = "yyyy-MM-dd"

        let planned = tasks.compactMap { task -> PlannedReminder? in
            guard !task.isCompleted,
                  let fire = calendar.date(
                      bySettingHour: minutes / 60, minute: minutes % 60, second: 0,
                      of: calendar.startOfDay(for: task.dueDate)
                  ),
                  fire > now else { return nil }
            return PlannedReminder(
                taskID: task.id,
                fireDate: fire,
                title: task.plantName,
                body: task.kind == .care ? "\(task.name) is due today." : "Today: \(task.name).",
                threadID: "day-" + dayFormatter.string(from: fire)
            )
        }
        return Array(planned.sorted { $0.fireDate < $1.fireDate }.prefix(limit))
    }
}

/// Keeps the system's pending notifications in step with the task list.
///
/// `sync(_:)` is called after every task change (see `TaskViewModel.onPersist`)
/// and when the app becomes active. It replaces all task reminders each time,
/// which is simpler than diffing and cheap at this scale.
@MainActor
final class ReminderScheduler {
    static let shared = ReminderScheduler()

    static let categoryID = "GG_TASK"
    static let doneActionID = "GG_TASK_DONE"
    static let tomorrowActionID = "GG_TASK_TOMORROW"

    private let center = UNUserNotificationCenter.current()
    private var syncTask: Task<Void, Never>?

    /// Registers the Done / Tomorrow buttons. Call once at launch.
    func registerCategories() {
        let done = UNNotificationAction(identifier: Self.doneActionID, title: "Done", options: [])
        let tomorrow = UNNotificationAction(identifier: Self.tomorrowActionID, title: "Tomorrow", options: [])
        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [done, tomorrow],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }

    /// Shows the system permission prompt the first time. Returns whether
    /// reminders can be delivered.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    /// Replace all task reminders with ones for `tasks`. Rapid calls coalesce:
    /// a newer sync cancels an older one that hasn't finished.
    func sync(_ tasks: [GardenTask]) {
        syncTask?.cancel()
        let enabled = ReminderSettings.isEnabled()
        let minutes = ReminderSettings.minutes()
        syncTask = Task {
            let prefix = ReminderPlanner.identifierPrefix

            let pending = await center.pendingNotificationRequests().map(\.identifier)
            guard !Task.isCancelled else { return }
            center.removePendingNotificationRequests(withIdentifiers: pending.filter { $0.hasPrefix(prefix) })

            // Clear delivered reminders for tasks that are done or deleted.
            let open = Set(tasks.filter { !$0.isCompleted }.map { ReminderPlanner.identifier(for: $0.id) })
            let delivered = await center.deliveredNotifications().map(\.request.identifier)
            center.removeDeliveredNotifications(
                withIdentifiers: delivered.filter { $0.hasPrefix(prefix) && !open.contains($0) }
            )

            guard enabled else { return }
            switch await center.notificationSettings().authorizationStatus {
            case .authorized, .provisional, .ephemeral: break
            default: return
            }

            for reminder in ReminderPlanner.plan(tasks: tasks, now: Date(), minutes: minutes) {
                guard !Task.isCancelled else { return }
                try? await center.add(Self.request(for: reminder))
            }
        }
    }

    private static func request(for reminder: PlannedReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        content.categoryIdentifier = categoryID
        content.threadIdentifier = reminder.threadID
        content.userInfo = [ReminderPlanner.taskIDKey: reminder.taskID.uuidString]

        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        return UNNotificationRequest(
            identifier: ReminderPlanner.identifier(for: reminder.taskID),
            content: content,
            trigger: trigger
        )
    }
}
