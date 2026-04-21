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

    init(tasks: [GardenTask] = MockData.tasks) {
        self.tasks = tasks
    }

    /// Flip completion state for a task by ID.
    func toggleCompletion(for taskID: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].isCompleted.toggle()
    }
}
