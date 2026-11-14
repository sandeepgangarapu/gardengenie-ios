import Foundation

/// One row in the care-plan sheet: a task the user can switch on, with its
/// repeat rule and first date already worked out from the plant's guide.
struct CarePlanDraftItem: Identifiable, Hashable {
    let id: String
    var name: String
    /// The guide's own wording, shown under the row so the parsed repeat can be
    /// checked against it ("Every 2–3 days during dry spells").
    var guideText: String?
    var iconName: String
    var kind: TaskKind
    var recurrence: TaskRecurrence
    var startDate: Date
    var isIncluded: Bool
    /// A pending task with the same name already exists for this plant. The row
    /// is shown so the plan reads complete, but it can't be added twice.
    var isAlreadyScheduled: Bool
}

/// Turns a plant's care guide into a ready-to-confirm list of tasks.
enum CarePlanBuilder {

    /// Must-do items with a recognizable cadence start switched on; optional
    /// items, one-off items and the seed-starting / planting dates start off.
    static func items(
        for plant: Plant,
        existing: [GardenTask],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> [CarePlanDraftItem] {
        let startOfToday = calendar.startOfDay(for: today)
        let scheduledNames = Set(
            existing
                .filter { $0.plantID == plant.id && !$0.isCompleted }
                .map { $0.name.lowercased() }
        )
        var items: [CarePlanDraftItem] = []

        func addCare(_ item: CareItem, isMustDo: Bool) {
            let recurrence = TaskRecurrence(careFrequency: item.frequency) ?? .none
            let scheduled = scheduledNames.contains(item.title.lowercased())
            items.append(CarePlanDraftItem(
                id: "care:\(item.title)",
                name: item.title,
                guideText: item.frequency,
                iconName: item.iconName ?? "checkmark.circle.fill",
                kind: .care,
                recurrence: recurrence,
                startDate: firstDate(for: recurrence, from: startOfToday, calendar: calendar),
                isIncluded: isMustDo && recurrence.isRecurring && !scheduled,
                isAlreadyScheduled: scheduled
            ))
        }

        func addOneOff(kind: TaskKind, name: String, icon: String, window: String) {
            let scheduled = scheduledNames.contains(name.lowercased())
            items.append(CarePlanDraftItem(
                id: "\(kind.rawValue):\(name)",
                name: name,
                guideText: "Guide window: \(window)",
                iconName: icon,
                kind: kind,
                recurrence: .none,
                startDate: MonthDateParser.defaultDate(from: window, referenceDate: today, calendar: calendar),
                isIncluded: false,
                isAlreadyScheduled: scheduled
            ))
        }

        plant.carePlan?.mustDo?.forEach { addCare($0, isMustDo: true) }
        plant.carePlan?.others?.forEach { addCare($0, isMustDo: false) }
        if let window = plant.seedStarting?.month, !window.isEmpty {
            addOneOff(kind: .seedStarting, name: "Start \(plant.name) seeds indoors",
                      icon: "leaf.arrow.triangle.circlepath", window: window)
        }
        if let window = plant.planting?.month, !window.isEmpty {
            addOneOff(kind: .planting, name: "Plant \(plant.name) outdoors",
                      icon: "leaf.circle.fill", window: window)
        }
        return items
    }

    /// Short cadences (weekly or more often) start today. Longer ones start one
    /// interval out: you don't fertilize the day you bring a plant home.
    static func firstDate(for recurrence: TaskRecurrence, from start: Date, calendar: Calendar = .current) -> Date {
        guard let days = recurrence.approximateDays, days > 7 else { return start }
        if recurrence == .monthly {
            return calendar.date(byAdding: .month, value: 1, to: start) ?? start
        }
        return calendar.date(byAdding: .day, value: days, to: start) ?? start
    }

    /// The tasks to create for the rows the user left switched on.
    static func tasks(from items: [CarePlanDraftItem], plant: Plant) -> [GardenTask] {
        items
            .filter { $0.isIncluded && !$0.isAlreadyScheduled }
            .map {
                GardenTask(
                    name: $0.name,
                    dueDate: $0.startDate,
                    plantID: plant.id,
                    plantName: plant.name,
                    iconName: $0.iconName,
                    kind: $0.kind,
                    recurrence: $0.recurrence
                )
            }
    }
}
