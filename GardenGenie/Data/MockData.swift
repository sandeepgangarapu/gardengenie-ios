import Foundation

/// Static mock data for the app. Replace with a real data source later.
enum MockData {

    // Stable plant IDs so tasks can reference them reliably.
    static let tomatoID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let potatoID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let tulipID  = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

    static let plants: [Plant] = [
        Plant(
            id: tomatoID,
            name: "Tomato",
            botanicalName: "Solanum lycopersicum",
            description: "A warm-season favorite, tomatoes reward regular watering and full sun with juicy, flavorful fruit. Stake or cage plants early to keep branches supported as fruit develops.",
            iconName: "leaf.fill",
            statusTag: "Thriving",
            sunlightNeeds: "Full Sun (6–8 hours)",
            wateringFrequency: "Every 2–3 days",
            plantingSeason: "Spring (March–May)",
            soilType: "Rich, well-drained loam, pH 6.0–6.8",
            daysToHarvest: "60–85 days",
            companionPlants: ["Basil", "Carrots", "Parsley"]
        ),
        Plant(
            id: potatoID,
            name: "Potato",
            botanicalName: "Solanum tuberosum",
            description: "Hardy and forgiving, potatoes grow underground from seed pieces. Hill soil around stems as they grow to boost yield and protect tubers from sunlight.",
            iconName: "leaf.circle.fill",
            statusTag: "Growing",
            sunlightNeeds: "Full Sun (6+ hours)",
            wateringFrequency: "1–2 inches per week",
            plantingSeason: "Early Spring (2–4 weeks before last frost)",
            soilType: "Loose, well-drained, slightly acidic (pH 5.0–6.0)",
            daysToHarvest: "70–120 days",
            companionPlants: ["Beans", "Corn", "Horseradish"]
        ),
        Plant(
            id: tulipID,
            name: "Tulip",
            botanicalName: "Tulipa gesneriana",
            description: "A cheerful spring bloomer. Plant bulbs in fall so they can chill through winter; they'll reward you with vivid color as the weather warms.",
            iconName: "camera.macro",
            statusTag: "Dormant",
            sunlightNeeds: "Full to Partial Sun",
            wateringFrequency: "Weekly during growth, none when dormant",
            plantingSeason: "Fall planting (September–November)",
            soilType: "Sandy, well-drained, neutral pH",
            daysToHarvest: nil,
            companionPlants: ["Daffodils", "Grape Hyacinth"]
        )
    ]

    static let tasks: [GardenTask] = [
        GardenTask(
            id: UUID(),
            name: "Check for pests",
            dueDate: Date(),
            plantID: potatoID,
            plantName: "Potato",
            isCompleted: false,
            iconName: "ladybug.fill"
        ),
        GardenTask(
            id: UUID(),
            name: "Water tomato plants",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            plantID: tomatoID,
            plantName: "Tomato",
            isCompleted: false,
            iconName: "drop.fill"
        ),
        GardenTask(
            id: UUID(),
            name: "Hill potato mounds",
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            plantID: potatoID,
            plantName: "Potato",
            isCompleted: false,
            iconName: "mountain.2.fill"
        ),
        GardenTask(
            id: UUID(),
            name: "Prune lower leaves",
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            plantID: tomatoID,
            plantName: "Tomato",
            isCompleted: false,
            iconName: "scissors"
        ),
        GardenTask(
            id: UUID(),
            name: "Prepare tulip bed",
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            plantID: tulipID,
            plantName: "Tulip",
            isCompleted: false,
            iconName: "leaf.arrow.circlepath"
        )
    ]
}
