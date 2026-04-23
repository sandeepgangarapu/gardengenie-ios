import Foundation

/// Service for looking up USDA hardiness zones from zip codes.
@MainActor
final class USDAZoneLookup {
    static let shared = USDAZoneLookup()

    struct ZoneInfo: Equatable {
        let zone: String
        let minTemp: String
        let maxTemp: String
        let description: String
    }

    private var zipPrefixToZone: [String: String] = [:]

    private let zoneDetails: [String: ZoneInfo] = [
        "3a": ZoneInfo(zone: "3a", minTemp: "-40°F", maxTemp: "-35°F", description: "Cold climate with short growing season. Hardy perennials and cold-tolerant vegetables thrive."),
        "3b": ZoneInfo(zone: "3b", minTemp: "-35°F", maxTemp: "-30°F", description: "Cold climate with short growing season. Many root vegetables and cold-hardy herbs do well."),
        "4a": ZoneInfo(zone: "4a", minTemp: "-30°F", maxTemp: "-25°F", description: "Cold winters require hardy selections. Great for apples, asparagus, and rhubarb."),
        "4b": ZoneInfo(zone: "4b", minTemp: "-25°F", maxTemp: "-20°F", description: "Hardy perennials thrive here. Extended season possible with cold frames."),
        "5a": ZoneInfo(zone: "5a", minTemp: "-20°F", maxTemp: "-15°F", description: "Moderate cold climate with good variety of plants. Many fruit trees thrive here."),
        "5b": ZoneInfo(zone: "5b", minTemp: "-15°F", maxTemp: "-10°F", description: "Diverse growing options with 5-6 month growing season. Great for most vegetables."),
        "6a": ZoneInfo(zone: "6a", minTemp: "-10°F", maxTemp: "-5°F", description: "Transitional climate with diverse plant selection. Excellent for roses and perennials."),
        "6b": ZoneInfo(zone: "6b", minTemp: "-5°F", maxTemp: "0°F", description: "Wide variety of plants thrive. Long growing season for tomatoes and peppers."),
        "7a": ZoneInfo(zone: "7a", minTemp: "0°F", maxTemp: "5°F", description: "Mild winters with occasional freezes. Southern favorites like figs can grow here."),
        "7b": ZoneInfo(zone: "7b", minTemp: "5°F", maxTemp: "10°F", description: "Extended growing season. Great for gardenias, camellias, and citrus with protection."),
        "8a": ZoneInfo(zone: "8a", minTemp: "10°F", maxTemp: "15°F", description: "Warm climate with long growing season. Many tropical plants survive winters here."),
        "8b": ZoneInfo(zone: "8b", minTemp: "15°F", maxTemp: "20°F", description: "Year-round gardening possible. Citrus and palms grow well with minimal protection."),
        "9a": ZoneInfo(zone: "9a", minTemp: "20°F", maxTemp: "25°F", description: "Subtropical climate with rare freezes. Citrus, avocados, and many tropicals thrive."),
        "9b": ZoneInfo(zone: "9b", minTemp: "25°F", maxTemp: "30°F", description: "Nearly frost-free. Mangoes, bananas, and tropical flowers flourish year-round."),
        "10a": ZoneInfo(zone: "10a", minTemp: "30°F", maxTemp: "35°F", description: "Tropical climate with no frost. Coconut palms and tropical fruit trees thrive."),
        "10b": ZoneInfo(zone: "10b", minTemp: "35°F", maxTemp: "40°F", description: "True tropical zone. Year-round growing of any warm-weather plant imaginable.")
    ]

    private init() {
        loadZoneData()
    }

    private func loadZoneData() {
        guard let url = Bundle.main.url(forResource: "USDAZones", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let mapping = try? JSONDecoder().decode([String: String].self, from: data) else {
            return
        }
        zipPrefixToZone = mapping
    }

    func zone(for zipCode: String) -> ZoneInfo? {
        let prefix = String(zipCode.prefix(3))
        guard let zoneCode = zipPrefixToZone[prefix] else {
            // Default fallback for unmapped zips
            return zoneDetails["7b"]
        }
        return zoneDetails[zoneCode] ?? zoneDetails["7b"]
    }
}
