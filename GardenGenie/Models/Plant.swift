import Foundation

/// A plant in the user's garden, including its care requirements.
struct Plant: Identifiable, Hashable {
    let id: UUID
    var name: String
    var botanicalName: String
    var description: String

    /// SF Symbol name used as the plant's icon.
    var iconName: String

    /// Short status tag like "Thriving" or "Dormant".
    var statusTag: String

    // Care information
    var sunlightNeeds: String
    var wateringFrequency: String
    var plantingSeason: String
    var soilType: String
    /// Nil for non-edible plants like flowers.
    var daysToHarvest: String?
    var companionPlants: [String]
}
