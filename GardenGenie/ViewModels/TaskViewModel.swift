import Foundation
import Observation

/// Owns the collection of garden tasks. Exposes sectioned views and a toggle method.
@Observable
final class TaskViewModel {
    var tasks: [GardenTask]

    var pendingTasks: [GardenTask] {
        tasks
            .filter { !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var completedTasks: [GardenTask] {
        tasks.filter(\.isCompleted)
    }

    /// Count of completed tasks — used in Settings profile card.
    var completedCount: Int { completedTasks.count }

    init(tasks: [GardenTask] = MockData.tasks) {
        self.tasks = tasks
    }

    /// Flip completion state for a task by ID.
    func toggleCompletion(for taskID: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].isCompleted.toggle()
    }

    /// Add a new task (e.g. from a care plan "Others" item).
    func addTask(_ task: GardenTask) {
        // Avoid duplicates by name + plant
        guard !tasks.contains(where: { $0.name == task.name && $0.plantID == task.plantID && !$0.isCompleted }) else { return }
        tasks.append(task)
    }
}
