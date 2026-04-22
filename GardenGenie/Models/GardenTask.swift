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

    // MARK: - Factory from CareItem

    /// Create a task from a care plan item, due tomorrow by default.
    static func from(careItem: CareItem, plant: Plant) -> GardenTask {
        GardenTask(
            id: UUID(),
            name: careItem.title,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            plantID: plant.id,
            plantName: plant.name,
            isCompleted: false,
            iconName: careItem.iconName ?? "leaf.fill"
        )
    }
}
