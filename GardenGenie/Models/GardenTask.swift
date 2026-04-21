import Foundation

/// A garden task such as watering, pruning, or pest-checking.
struct GardenTask: Identifiable, Hashable {
    let id: UUID
    var name: String
    var dueDate: Date
    var plantID: UUID
    /// Plant name denormalized for display convenience (no backend to join against).
    var plantName: String
    var isCompleted: Bool
    /// SF Symbol name for the task's icon.
    var iconName: String
}
