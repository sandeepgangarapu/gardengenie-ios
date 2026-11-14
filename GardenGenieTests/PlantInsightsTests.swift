import Foundation
import Testing
@testable import GardenGenie

struct PlantInsightsTests {

    @Test func seasonWindowsWrapTheYear() {
        let harvest = SeasonWindow(kind: .harvest, startMonth: 11, endMonth: 2)
        #expect(harvest.contains(month: 11))
        #expect(harvest.contains(month: 1))
        #expect(harvest.contains(month: 2))
        #expect(!harvest.contains(month: 3))
        #expect(!harvest.contains(month: 10))

        let spring = SeasonWindow(kind: .plantOut, startMonth: 4, endMonth: 5)
        #expect(spring.contains(month: 4) && spring.contains(month: 5))
        #expect(!spring.contains(month: 6))
    }

    func plant(mustDo: [CareItem], others: [CareItem] = []) -> Plant {
        Plant(id: UUID(), name: "Test", carePlan: CarePlan(mustDo: mustDo, others: others))
    }

    @Test func careLevelFromMustDosAndFrequency() {
        let water3 = CareItem(title: "Watering", frequency: "Every 2-3 days")
        let waterDaily = CareItem(title: "Watering", frequency: "Daily")
        let feed = CareItem(title: "Fertilizing", frequency: "Every 4-6 weeks")
        let check = CareItem(title: "Disease Check", frequency: "Weekly")
        let stake = CareItem(title: "Staking", frequency: nil)

        // Basil: one must-do, watering every 3 days.
        #expect(CareLevel(plant: plant(mustDo: [water3], others: [feed])) == .easy)
        // Daily watering bumps a single must-do to Moderate.
        #expect(CareLevel(plant: plant(mustDo: [waterDaily])) == .moderate)
        // Roma tomato: three must-dos.
        #expect(CareLevel(plant: plant(mustDo: [water3, feed, check])) == .moderate)
        #expect(CareLevel(plant: plant(mustDo: [waterDaily, feed, check, stake])) == .demanding)
        // No guide, no verdict.
        #expect(CareLevel(plant: Plant(id: UUID(), name: "Bare")) == nil)
        #expect(CareLevel(plant: plant(mustDo: [])) == nil)
    }

    @Test func companionMatchingToleratesPluralsAndVarieties() {
        let garden = ["roma tomato", "carrot", "sweet basil"]
        #expect(Companions.gardenContains("tomato", garden))
        #expect(Companions.gardenContains("Carrots", garden))
        #expect(Companions.gardenContains("basil", garden))
        #expect(!Companions.gardenContains("onions", garden))
        #expect(!Companions.gardenContains("", garden))
    }
}

@MainActor
struct CareLogStoreTests {
    let plantID = UUID()
    let calendar = Calendar(identifier: .gregorian)
    var now: Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: 15))! }

    func task(_ name: String, daysFromNow: Int, done: Bool = false, plant: UUID? = nil) -> GardenTask {
        GardenTask(name: name, dueDate: calendar.date(byAdding: .day, value: daysFromNow, to: now)!,
                   plantID: plant ?? plantID, plantName: "Roma tomato", isCompleted: done, iconName: "drop.fill")
    }

    @Test func loggingFindsTheOldestMatchingTaskDueByToday() {
        let tasks = [
            task("Watering", daysFromNow: 0),
            task("Deep watering", daysFromNow: -2),
            task("Watering", daysFromNow: 2),           // not due yet
            task("Watering", daysFromNow: -1, done: true),
            task("Watering", daysFromNow: -3, plant: UUID()),
            task("Pinch back flowers", daysFromNow: 0),
        ]
        let match = CareLogStore.matchingTask(for: .watered, plantID: plantID, in: tasks, now: now, calendar: calendar)
        #expect(match?.name == "Deep watering")
        #expect(CareLogStore.matchingTask(for: .pruned, plantID: plantID, in: tasks, now: now, calendar: calendar)?.name
                == "Pinch back flowers")
        #expect(CareLogStore.matchingTask(for: .harvested, plantID: plantID, in: tasks, now: now, calendar: calendar) == nil)
        #expect(CareLogStore.matchingTask(for: .note, plantID: plantID, in: tasks, now: now, calendar: calendar) == nil)
    }

    @Test func entriesPersistNewestFirst() throws {
        let suite = "CareLogStoreTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = CareLogStore(userDefaults: defaults)
        store.add(.watered, plantID: plantID, date: now)
        let note = store.add(.note, plantID: plantID, note: "First flowers", date: now.addingTimeInterval(60))
        store.add(.watered, plantID: UUID(), date: now)

        let reloaded = CareLogStore(userDefaults: defaults)
        #expect(reloaded.entries(for: plantID).map(\.kind) == [.note, .watered])
        #expect(reloaded.entries(for: plantID).first?.note == "First flowers")

        reloaded.delete(note.id)
        #expect(CareLogStore(userDefaults: defaults).entries(for: plantID).map(\.kind) == [.watered])
    }
}
