import Foundation
import Testing
@testable import GardenGenie

struct PlantingCalendarTests {
    let tomatoWindows = [
        SeasonWindow(kind: .seedIndoors, startMonth: 2, endMonth: 3),
        SeasonWindow(kind: .plantOut, startMonth: 4, endMonth: 5),
        SeasonWindow(kind: .harvest, startMonth: 7, endMonth: 10),
    ]

    @Test func plantingTimeUsesThePlantOutWindow() {
        #expect(PlantingCalendar.isPlantingTime(tomatoWindows, month: 4))
        #expect(PlantingCalendar.isPlantingTime(tomatoWindows, month: 5))
        #expect(!PlantingCalendar.isPlantingTime(tomatoWindows, month: 8)) // harvest, not planting
        // Fall bulbs wrap the year end.
        let tulip = [SeasonWindow(kind: .plantOut, startMonth: 10, endMonth: 12)]
        #expect(PlantingCalendar.isPlantingTime(tulip, month: 11))
        #expect(!PlantingCalendar.isPlantingTime([], month: 11))
    }

    @Test func seedStartSoonLooksAheadAcrossTheNewYear() {
        // November: Feb is 4 months out (Nov, Dec, Jan, Feb).
        #expect(!PlantingCalendar.seedStartIsSoon(tomatoWindows, month: 11, withinMonths: 3))
        #expect(PlantingCalendar.seedStartIsSoon(tomatoWindows, month: 11, withinMonths: 4))
        #expect(PlantingCalendar.seedStartIsSoon(tomatoWindows, month: 12))
        #expect(PlantingCalendar.seedStartIsSoon(tomatoWindows, month: 3)) // window open now
        #expect(!PlantingCalendar.seedStartIsSoon(tomatoWindows, month: 6))
    }

    @Test func companionPairsSkipPlantsAlreadyInTheGarden() {
        let tomato = UUID(), basil = UUID(), kale = UUID(), carrot = UUID()
        let pairs = Companions.pairs(
            candidates: [(basil, "Basil"), (kale, "Kale"), (carrot, "Carrot"), (tomato, "Roma tomato")],
            garden: [(tomato, "Roma tomato", ["basil", "carrots", "onions"])]
        )
        #expect(pairs.map(\.candidateID) == [basil, carrot])
        #expect(pairs.allSatisfy { $0.gardenPlantName == "Roma tomato" })
    }

    @Test func filterChipLabelsArePlural() {
        #expect(ExploreView.pluralLabel(for: "vegetable") == "Vegetables")
        #expect(ExploreView.pluralLabel(for: "herb") == "Herbs")
        #expect(ExploreView.pluralLabel(for: "berry") == "Berries")
        #expect(ExploreView.pluralLabel(for: "grass") == "Grass")
    }
}
