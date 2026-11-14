import Foundation
import Testing
@testable import GardenGenie

/// Phrases below are real `care_schedule` frequencies returned by the backend
/// for zone 8b / WA (Basil, Kale, Lavender, Blueberry, Roma tomato), plus a few
/// common phrasings.
struct CareFrequencyParsingTests {

    @Test(arguments: [
        ("Every 2–3 days during dry spells", TaskRecurrence.everyNDays(3)),
        ("Every 2-3 days", .everyNDays(3)),
        ("Pinch back every 1-2 weeks", .biweekly),
        ("Every 4-6 weeks", .everyNDays(42)),
        ("Every 3-4 weeks", .everyNDays(28)),
        ("Weekly", .weekly),
        ("Biweekly", .biweekly),
        ("Bi-weekly", .biweekly),
        ("Check soil 2–3 times weekly in dry weather; water deeply about 1–2 times weekly as needed.", .everyNDays(4)),
        ("Inspect leaves weekly; check more often when pests are active.", .weekly),
        ("Harvest outer leaves every 1–2 weeks once plants are established.", .biweekly),
        ("Every 2–3 weeks; weekly in dry spells", .everyNDays(21)),
        ("Monthly, especially during summer", .monthly),
        ("Every 4–7 days", .weekly),
        ("Every day", .daily),
        ("Daily in hot weather", .daily),
        ("Twice a week", .everyNDays(4)),
        ("Once a week", .weekly),
        ("Every other week", .biweekly),
        ("Every few days", .everyNDays(3)),
        ("Every month", .monthly),
        ("Every 3 months", .everyNDays(90)),
        ("Every 4 to 6 weeks", .everyNDays(42)),
    ])
    func readsCadence(_ text: String, _ expected: TaskRecurrence) {
        #expect(TaskRecurrence(careFrequency: text) == expected)
    }

    @Test(arguments: [
        "Annually after flowering",
        "Annually",
        "Once in early spring",
        "Apply after plants establish; replenish as needed.",
        "At planting and approximately 3–4 weeks after transplanting or thinning.",
        "For 7–10 days before transplanting.",
        "",
        "   ",
    ])
    func ignoresPhrasesWithoutACadence(_ text: String) {
        #expect(TaskRecurrence(careFrequency: text) == nil)
    }

    @Test func nilFrequencyIsNil() {
        #expect(TaskRecurrence(careFrequency: nil) == nil)
    }

    @Test func displayNameUsesWeeksForWholeWeeks() {
        #expect(TaskRecurrence.everyNDays(21).displayName == "Every 3 weeks")
        #expect(TaskRecurrence.everyNDays(42).displayName == "Every 6 weeks")
        #expect(TaskRecurrence.everyNDays(3).displayName == "Every 3 days")
        #expect(TaskRecurrence.everyNDays(10).displayName == "Every 10 days")
    }

    @Test func pickerOptionsAddACustomValueInIntervalOrder() {
        let options = TaskRecurrence.pickerOptions(including: .everyNDays(42))
        #expect(options.first == TaskRecurrence.none)
        #expect(options.last == .everyNDays(42))
        #expect(options.count == TaskRecurrence.pickerOptions.count + 1)
        #expect(TaskRecurrence.pickerOptions(including: .weekly) == TaskRecurrence.pickerOptions)
    }
}
