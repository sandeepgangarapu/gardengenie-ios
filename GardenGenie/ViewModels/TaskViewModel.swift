import Foundation
import Observation

/// Owns the collection of garden tasks. Exposes sectioned views and a toggle method.
///
/// Tasks are persisted to `UserDefaults` as a JSON blob under `taskStore.v1`
/// (mirrors the `MyGardenStore` pattern). Every mutation triggers a re-snapshot,
/// so state survives app kills.
@Observable
final class TaskViewModel {

    private static let key = "taskStore.v1"

    var tasks: [GardenTask] = []

    var pendingTasks: [GardenTask] {
        tasks
            .filter { !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var completedTasks: [GardenTask] {
        tasks
            .filter(\.isCompleted)
            .sorted { $0.dueDate > $1.dueDate }
    }

    /// Count of completed tasks — used in Settings profile card.
    var completedCount: Int { completedTasks.count }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    // MARK: - Mutations

    /// Flip completion state for a task by ID. For recurring pending tasks, completing
    /// the row freezes it as history and spawns a new pending row at the next occurrence.
    func toggleCompletion(for taskID: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        let task = tasks[index]

        if !task.isCompleted, task.recurrence.isRecurring,
           let next = task.recurrence.nextDate(after: task.dueDate) {
            tasks[index].isCompleted = true
            var follow = task
            follow = GardenTask(
                name: task.name,
                dueDate: next,
                plantID: task.plantID,
                plantName: task.plantName,
                isCompleted: false,
                iconName: task.iconName,
                kind: task.kind,
                recurrence: task.recurrence
            )
            tasks.append(follow)
        } else {
            tasks[index].isCompleted.toggle()
        }
        persist()
    }

    /// Add a new task (e.g. from a care plan "Others" item).
    func addTask(_ task: GardenTask) {
        guard !tasks.contains(where: {
            $0.name == task.name
                && $0.plantID == task.plantID
                && !$0.isCompleted
                && Calendar.current.isDate($0.dueDate, inSameDayAs: task.dueDate)
        }) else { return }
        tasks.append(task)
        persist()
    }

    func reschedule(_ id: UUID, to newDate: Date) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].dueDate = newDate
        persist()
    }

    func dismiss(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Timeline queries

    /// Silently roll forward recurring tasks whose dueDate is in the past so they land
    /// on today or the nearest future occurrence. Skipped occurrences are NOT logged.
    func rollForwardRecurringTasks(now: Date = Date()) {
        let startOfToday = Calendar.current.startOfDay(for: now)
        var didMutate = false
        for index in tasks.indices {
            guard !tasks[index].isCompleted,
                  tasks[index].recurrence.isRecurring,
                  tasks[index].dueDate < startOfToday else { continue }

            var candidate = tasks[index].dueDate
            var safety = 0
            while candidate < startOfToday, safety < 1_000,
                  let next = tasks[index].recurrence.nextDate(after: candidate) {
                candidate = next
                safety += 1
            }
            tasks[index].dueDate = candidate
            didMutate = true
        }
        if didMutate { persist() }
    }

    /// Pending, non-completed tasks whose day is strictly before today.
    var overdueTasks: [GardenTask] {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        return pendingTasks.filter { $0.dueDate < startOfToday }
    }

    /// Set of day-start dates (future-or-today) that have at least one pending task.
    /// Used by the day strip to show dot indicators.
    var daysWithTasks: Set<Date> {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        var set = Set<Date>()
        for task in pendingTasks {
            let day = calendar.startOfDay(for: task.dueDate)
            guard day >= startOfToday else { continue }
            set.insert(day)
        }
        return set
    }

    /// Pending tasks grouped by day, sorted ascending, within the provided date range.
    /// Overdue items are excluded (they surface in the Overdue bucket instead).
    func tasksByDay(in range: ClosedRange<Date>) -> [(day: Date, tasks: [GardenTask])] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        var buckets: [Date: [GardenTask]] = [:]
        for task in pendingTasks {
            let day = calendar.startOfDay(for: task.dueDate)
            guard day >= startOfToday,
                  day >= calendar.startOfDay(for: range.lowerBound),
                  day <= calendar.startOfDay(for: range.upperBound) else { continue }
            buckets[day, default: []].append(task)
        }
        return buckets
            .map { (day: $0.key, tasks: $0.value.sorted { $0.dueDate < $1.dueDate }) }
            .sorted { $0.day < $1.day }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = userDefaults.data(forKey: Self.key) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractional
        guard let snapshot = try? decoder.decode(StoredSnapshot.self, from: data) else { return }
        tasks = snapshot.tasks
    }

    private func persist() {
        let snapshot = StoredSnapshot(tasks: tasks)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        userDefaults.set(data, forKey: Self.key)
    }

    private struct StoredSnapshot: Codable {
        var tasks: [GardenTask]
    }
}
