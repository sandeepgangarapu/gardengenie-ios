import Foundation

/// A month range in the plant's year for the user's region, e.g. seeds
/// indoors Feb–Mar. Ranges can wrap the new year (harvest May–Mar).
struct SeasonWindow: Hashable {
    enum Kind: Int, CaseIterable, Hashable {
        case seedIndoors, plantOut, harvest

        var label: String {
            switch self {
            case .seedIndoors: return "Seeds indoors"
            case .plantOut: return "Plant out"
            case .harvest: return "Harvest"
            }
        }
    }

    let kind: Kind
    /// 1–12
    let startMonth: Int
    /// 1–12; may be less than `startMonth` when the window wraps the year.
    let endMonth: Int

    func contains(month: Int) -> Bool {
        startMonth <= endMonth
            ? (startMonth...endMonth).contains(month)
            : month >= startMonth || month <= endMonth
    }
}

enum Companions {
    /// Whether a companion name from the guide is already growing in the
    /// garden. "tomato" matches "Roma tomato"; "carrots" matches "Carrot".
    static func gardenContains(_ companion: String, _ gardenNames: [String]) -> Bool {
        var key = companion.lowercased().trimmingCharacters(in: .whitespaces)
        if key.hasSuffix("es"), key.count > 4 {
            key.removeLast(2)
        } else if key.hasSuffix("s"), key.count > 3 {
            key.removeLast()
        }
        guard !key.isEmpty else { return false }
        return gardenNames.contains { $0.lowercased().contains(key) }
    }
}

extension Companions {
    /// For each candidate, the first garden plant whose guide lists it as a
    /// companion (e.g. Basil → Roma tomato). Candidates already in the garden
    /// are skipped.
    static func pairs(
        candidates: [(id: UUID, name: String)],
        garden: [(id: UUID, name: String, companions: [String])]
    ) -> [(candidateID: UUID, gardenPlantName: String)] {
        let gardenIDs = Set(garden.map(\.id))
        return candidates.compactMap { candidate in
            guard !gardenIDs.contains(candidate.id) else { return nil }
            let name = candidate.name.lowercased()
            guard let match = garden.first(where: { plant in
                plant.companions.contains { gardenContains($0, [name]) }
            }) else { return nil }
            return (candidate.id, match.name)
        }
    }
}

enum PlantingCalendar {
    /// The plant-out window includes `month`.
    static func isPlantingTime(_ windows: [SeasonWindow], month: Int) -> Bool {
        windows.contains { $0.kind == .plantOut && $0.contains(month: month) }
    }

    /// The seeds-indoors window is open now or opens within the next
    /// `withinMonths` months (counting this one).
    static func seedStartIsSoon(_ windows: [SeasonWindow], month: Int, withinMonths: Int = 3) -> Bool {
        guard let seed = windows.first(where: { $0.kind == .seedIndoors }) else { return false }
        if seed.contains(month: month) { return true }
        return (0..<withinMonths).contains { offset in
            (month - 1 + offset) % 12 + 1 == seed.startMonth
        }
    }
}

/// How much work a plant asks for, judged from its care guide.
enum CareLevel: String {
    case easy = "Easy"
    case moderate = "Moderate"
    case demanding = "Demanding"

    /// One point per must-do item, plus one if any must-do comes round every
    /// two days or more often. 0–1 is Easy, 2–3 Moderate, 4+ Demanding.
    /// `nil` when the plant has no care plan to judge from.
    init?(plant: Plant) {
        guard let plan = plant.carePlan else { return nil }
        let mustDo = plan.mustDo ?? []
        guard !mustDo.isEmpty || !(plan.others ?? []).isEmpty else { return nil }
        var score = mustDo.count
        let hasFrequentTask = mustDo.contains {
            (TaskRecurrence(careFrequency: $0.frequency)?.approximateDays ?? .max) <= 2
        }
        if hasFrequentTask { score += 1 }
        switch score {
        case ...1: self = .easy
        case 2...3: self = .moderate
        default: self = .demanding
        }
    }
}
