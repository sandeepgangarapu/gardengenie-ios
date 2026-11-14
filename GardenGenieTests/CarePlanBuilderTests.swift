import Foundation
import Testing
@testable import GardenGenie

struct CarePlanBuilderTests {
    /// Needs a locale: month names like "Feb" come from the calendar's locale,
    /// and a bare `Calendar(identifier:)` has none.
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()
    /// Fri Nov 13 2026, 3 PM local.
    var today: Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: 15))! }

    func romaTomato() -> Plant {
        Plant(
            id: UUID(),
            name: "Roma tomato",
            seedStarting: SeedStartingInfo(month: "Feb – Mar"),
            planting: PlantingInfo(month: "Apr – May"),
            carePlan: CarePlan(
                mustDo: [
                    CareItem(title: "Watering", frequency: "Every 2-3 days", iconName: "drop.fill"),
                    CareItem(title: "Fertilizing", frequency: "Every 3-4 weeks", iconName: "leaf.fill"),
                    CareItem(title: "Staking", frequency: "Once at transplant", iconName: nil),
                ],
                others: [
                    CareItem(title: "Pest Check", frequency: "Weekly", iconName: "ant.fill"),
                ]
            )
        )
    }

    @Test func mustDosWithACadenceStartSwitchedOn() {
        let items = CarePlanBuilder.items(for: romaTomato(), existing: [], today: today, calendar: calendar)
        let byName = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0) })

        #expect(byName["Watering"]?.isIncluded == true)
        #expect(byName["Watering"]?.recurrence == .everyNDays(3))
        #expect(byName["Fertilizing"]?.isIncluded == true)
        // A must-do with no regular cadence is offered, but off.
        #expect(byName["Staking"]?.isIncluded == false)
        #expect(byName["Staking"]?.recurrence == TaskRecurrence.none)
        // Optional items start off even when they have a cadence.
        #expect(byName["Pest Check"]?.isIncluded == false)
        #expect(byName["Pest Check"]?.recurrence == .weekly)
    }

    @Test func shortCadencesStartTodayLongOnesOneIntervalOut() {
        let items = CarePlanBuilder.items(for: romaTomato(), existing: [], today: today, calendar: calendar)
        let start = calendar.startOfDay(for: today)
        let watering = items.first { $0.name == "Watering" }!
        let fertilizing = items.first { $0.name == "Fertilizing" }!

        #expect(watering.startDate == start)
        #expect(fertilizing.startDate == calendar.date(byAdding: .day, value: 28, to: start))
    }

    @Test func seedStartingAndPlantingAreOneOffsOnTheNextWindow() {
        let items = CarePlanBuilder.items(for: romaTomato(), existing: [], today: today, calendar: calendar)
        let seed = items.first { $0.kind == .seedStarting }!
        let plant = items.first { $0.kind == .planting }!

        #expect(seed.name == "Start Roma tomato seeds indoors")
        #expect(seed.isIncluded == false)
        #expect(seed.recurrence == TaskRecurrence.none)
        #expect(calendar.component(.month, from: seed.startDate) == 2)
        #expect(calendar.component(.year, from: seed.startDate) == 2027)
        #expect(calendar.component(.month, from: plant.startDate) == 4)
    }

    @Test func existingPendingTasksAreLockedNotDuplicated() {
        let plant = romaTomato()
        let existing = [
            GardenTask(name: "watering", dueDate: today, plantID: plant.id, plantName: plant.name, iconName: "drop.fill"),
            // Completed history shouldn't block a new plan.
            GardenTask(name: "Fertilizing", dueDate: today, plantID: plant.id, plantName: plant.name,
                       isCompleted: true, iconName: "leaf.fill"),
            // Same name on a different plant doesn't count.
            GardenTask(name: "Pest Check", dueDate: today, plantID: UUID(), plantName: "Basil", iconName: "ant.fill"),
        ]
        let items = CarePlanBuilder.items(for: plant, existing: existing, today: today, calendar: calendar)

        let watering = items.first { $0.name == "Watering" }!
        #expect(watering.isAlreadyScheduled)
        #expect(!watering.isIncluded)
        #expect(items.first { $0.name == "Fertilizing" }!.isAlreadyScheduled == false)
        #expect(items.first { $0.name == "Pest Check" }!.isAlreadyScheduled == false)

        let tasks = CarePlanBuilder.tasks(from: items, plant: plant)
        #expect(tasks.map(\.name) == ["Fertilizing"])
    }

    @Test func tasksCarryTheEditedRepeatAndDate() {
        let plant = romaTomato()
        var items = CarePlanBuilder.items(for: plant, existing: [], today: today, calendar: calendar)
        let index = items.firstIndex { $0.name == "Watering" }!
        items[index].recurrence = .weekly
        items[index].startDate = calendar.date(byAdding: .day, value: 2, to: today)!

        let watering = CarePlanBuilder.tasks(from: items, plant: plant).first { $0.name == "Watering" }!
        #expect(watering.recurrence == .weekly)
        #expect(watering.dueDate == items[index].startDate)
        #expect(watering.plantID == plant.id)
        #expect(watering.plantName == "Roma tomato")
        #expect(watering.kind == .care)
    }

    @Test func plantWithoutAGuideHasNoItems() {
        let bare = Plant(id: UUID(), name: "Mystery plant")
        #expect(CarePlanBuilder.items(for: bare, existing: [], today: today, calendar: calendar).isEmpty)
    }
}
