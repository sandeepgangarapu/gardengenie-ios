import Foundation

/// A garden task such as watering, pruning, pest-checking, planting, or seed starting.
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
    var kind: TaskKind
    var recurrence: TaskRecurrence

    init(id: UUID = UUID(),
         name: String,
         dueDate: Date,
         plantID: UUID,
         plantName: String,
         isCompleted: Bool = false,
         iconName: String,
         kind: TaskKind = .care,
         recurrence: TaskRecurrence = .none) {
        self.id = id
        self.name = name
        self.dueDate = dueDate
        self.plantID = plantID
        self.plantName = plantName
        self.isCompleted = isCompleted
        self.iconName = iconName
        self.kind = kind
        self.recurrence = recurrence
    }

    // MARK: - Factories

    /// Create a care task from a care plan item.
    static func from(careItem: CareItem,
                     plant: Plant,
                     dueDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                     recurrence: TaskRecurrence = .none) -> GardenTask {
        GardenTask(
            name: careItem.title,
            dueDate: dueDate,
            plantID: plant.id,
            plantName: plant.name,
            iconName: careItem.iconName ?? "leaf.fill",
            kind: .care,
            recurrence: recurrence
        )
    }

    static func seedStarting(for plant: Plant, on date: Date) -> GardenTask {
        GardenTask(
            name: "Start \(plant.name) seeds indoors",
            dueDate: date,
            plantID: plant.id,
            plantName: plant.name,
            iconName: "sparkles",
            kind: .seedStarting,
            recurrence: .none
        )
    }

    static func planting(for plant: Plant, on date: Date) -> GardenTask {
        GardenTask(
            name: "Plant \(plant.name) outdoors",
            dueDate: date,
            plantID: plant.id,
            plantName: plant.name,
            iconName: "leaf.fill",
            kind: .planting,
            recurrence: .none
        )
    }
}
