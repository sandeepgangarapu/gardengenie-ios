import Foundation

/// Static mock data for the app. Replace with a real data source later.
enum MockData {

    // Stable plant IDs so tasks can reference them reliably.
    static let tomatoID     = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let potatoID     = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let tulipID      = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let basilID      = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let rosemaryID   = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    static let sunflowerID  = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    static let strawberryID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
    static let lavenderID   = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!

    static let plants: [Plant] = [
        Plant(
            id: tomatoID,
            name: "Tomato",
            description: "A warm-season favorite, tomatoes reward regular watering and full sun with juicy, flavorful fruit. Stake or cage plants early to keep branches supported as fruit develops.",
            type: "vegetable",
            zone: "3–11",
            sunRequirements: "Full Sun (6–8 hours)",
            zoneSuitability: "Warm-season annual for USDA zones 3–11",
            seasonality: "Spring",
            indoorOutdoor: "outdoor",
            requirements: PlantRequirements(
                soil: "Rich, well-drained loam, pH 6.0–6.8",
                water: "Every 2–3 days",
                temperature: "60–70°F (soil), 70–85°F (air)",
                humidity: "50–70%",
                fertilizer: "Balanced, high in potassium"
            ),
            seedStarting: SeedStartingInfo(
                month: "February–March",
                instructions: ["Start seeds indoors 6–8 weeks before last frost", "Keep soil warm at 70–75°F", "Transplant when 2–3 true leaves develop"],
                indoorWeeksBeforeLastFrost: 6,
                soilTemperature: "70–75°F",
                depth: "0.25 inches",
                spacing: "2–3 inches apart",
                notes: "Seedlings need bright light to prevent leggy growth"
            ),
            planting: PlantingInfo(
                month: "April–May",
                instructions: ["Plant after last frost when soil reaches 60°F", "Space 24–36 inches apart", "Plant deeply; buried stem will develop roots", "Install stakes or cages immediately"],
                spacing: "24–36 inches",
                depth: "Plant deep, burying stem up to first leaves",
                method: "Transplant seedlings or hardened-off nursery plants",
                notes: "Mulch to retain moisture and regulate soil temperature"
            ),
            carePlan: CarePlan(
                mustDo: [
                    CareItem(title: "Watering", description: "Water deeply every 2–3 days at base of plant. Inconsistent watering causes blossom end rot and cracking.", frequency: "Every 2–3 days", iconName: "drop.fill"),
                    CareItem(title: "Staking/Caging", description: "Install support structures early to prevent stem breakage as fruit develops.", frequency: "Once at planting", iconName: "square.stack.fill"),
                    CareItem(title: "Pruning", description: "Remove lower leaves as plant grows to improve air circulation and reduce disease.", frequency: "Weekly", iconName: "scissors")
                ],
                others: [
                    CareItem(title: "Fertilizing", description: "Feed every 2–3 weeks with balanced fertilizer or compost tea.", frequency: "Every 2–3 weeks", iconName: "leaf.fill"),
                    CareItem(title: "Pinching Suckers", description: "Remove suckers (shoots in leaf axils) to direct energy to fruit.", frequency: "Weekly", iconName: "hand.pinch.fill"),
                    CareItem(title: "Mulching", description: "Apply 2–3 inches of organic mulch to retain moisture and regulate temperature.", frequency: "Once", iconName: "leaf.arrow.circlepath")
                ]
            ),
            typeSpecific: TypeSpecificInfo(
                daysToHarvest: "60–85 days",
                companionPlants: ["Basil", "Carrots", "Parsley"],
                yield: "20–50 fruits per plant",
                varieties: ["Cherry", "Beefsteak", "Roma"]
            )
        ),
        Plant(
            id: potatoID,
            name: "Potato",
            description: "Hardy and forgiving, potatoes grow underground from seed pieces. Hill soil around stems as they grow to boost yield and protect tubers from sunlight.",
            type: "tuber",
            zone: "1–10",
            sunRequirements: "Full Sun (6+ hours)",
            zoneSuitability: "Grows in nearly all USDA zones",
            seasonality: "Spring",
            indoorOutdoor: "outdoor",
            requirements: PlantRequirements(
                soil: "Loose, well-drained, slightly acidic (pH 5.0–6.0)",
                water: "1–2 inches per week",
                temperature: "60–70°F (soil), 65–75°F (air)",
                humidity: "60–80%",
                fertilizer: "Balanced nitrogen, low phosphorus"
            ),
            seedStarting: nil,
            planting: PlantingInfo(
                month: "March–April",
                instructions: ["Plant 2–4 weeks before last frost", "Place seed pieces 4 inches deep, 12 inches apart", "Hill soil as plants grow to prevent green tubers"],
                spacing: "12 inches apart in rows 36 inches apart",
                depth: "4 inches",
                method: "Seed potatoes (cut pieces with at least 2 eyes)",
                notes: "Hilling soil protects tubers from light exposure and increases yield"
            ),
            carePlan: CarePlan(
                mustDo: [
                    CareItem(title: "Watering", description: "Maintain consistent moisture; inconsistent watering causes misshapen tubers and cracking.", frequency: "1–2 inches per week", iconName: "drop.fill"),
                    CareItem(title: "Hilling", description: "Pull soil up around stems as they grow to protect tubers from sunlight (which turns them green and toxic).", frequency: "Every 2–3 weeks", iconName: "mountain.2.fill"),
                    CareItem(title: "Pest Monitoring", description: "Watch for Colorado potato beetles; remove immediately or use approved organic controls.", frequency: "Weekly", iconName: "ladybug.fill")
                ],
                others: [
                    CareItem(title: "Fertilizing", description: "Apply balanced fertilizer at planting and 4 weeks after planting.", frequency: "Twice per season", iconName: "leaf.fill"),
                    CareItem(title: "Mulching", description: "Mulch after plants are 6 inches tall to retain moisture.", frequency: "Once", iconName: "leaf.arrow.circlepath")
                ]
            ),
            typeSpecific: TypeSpecificInfo(
                daysToHarvest: "70–120 days",
                companionPlants: ["Beans", "Corn", "Horseradish"],
                yield: "10–15 lbs per 10 feet of row",
                varieties: ["Russet", "Red Bliss", "Yukon Gold"]
            )
        ),
        Plant(
            id: tulipID,
            name: "Tulip",
            description: "A cheerful spring bloomer. Plant bulbs in fall so they can chill through winter; they'll reward you with vivid color as the weather warms.",
            type: "flower",
            zone: "3–8",
            sunRequirements: "Full to Partial Sun (6 hours minimum)",
            zoneSuitability: "USDA zones 3–8 (requires cold winter)",
            seasonality: "Spring",
            indoorOutdoor: "outdoor",
            requirements: PlantRequirements(
                soil: "Sandy, well-drained, neutral pH (6.5–7.0)",
                water: "Weekly during growth; minimal during dormancy",
                temperature: "35–65°F (chilling required)",
                humidity: "Moderate",
                fertilizer: "Low-nitrogen bulb fertilizer"
            ),
            seedStarting: nil,
            planting: PlantingInfo(
                month: "September–November",
                instructions: ["Plant bulbs 4–6 inches deep, 4–6 inches apart", "Point side up", "In warmer zones, pre-chill bulbs for 12–16 weeks", "Cover with soil and mulch lightly"],
                spacing: "4–6 inches apart",
                depth: "4–6 inches",
                method: "Plant bulbs in fall for spring bloom",
                notes: "Chill requirement (vernalization) ensures flowering"
            ),
            carePlan: CarePlan(
                mustDo: [
                    CareItem(title: "Chilling Period", description: "Bulbs require 12–16 weeks of cold (35–45°F) to bloom properly. This is automatic in cold climates but must be manual in warm zones.", frequency: "Fall–Winter", iconName: "snowflake"),
                    CareItem(title: "Watering (Growing)", description: "Water weekly during active growth and flowering season.", frequency: "Weekly during growth", iconName: "drop.fill")
                ],
                others: [
                    CareItem(title: "Deadheading", description: "Remove spent flowers to prevent seed formation and direct energy back to bulb.", frequency: "As flowers fade", iconName: "scissors"),
                    CareItem(title: "Foliage Care", description: "Let foliage die back naturally; do not cut or tie it until it yellows. Foliage recharges the bulb.", frequency: "Post-bloom", iconName: "leaf.arrow.circlepath"),
                    CareItem(title: "Fertilizing", description: "Apply bulb fertilizer at planting and again in spring as shoots emerge.", frequency: "Twice per season", iconName: "leaf.fill")
                ]
            ),
            typeSpecific: TypeSpecificInfo(
                daysToHarvest: nil,
                companionPlants: ["Daffodils", "Grape Hyacinth", "Primrose"],
                yield: nil,
                varieties: ["Darwin Hybrid", "Parrot", "Rembrandt"]
            )
        ),
        Plant(
            id: basilID,
            name: "Basil",
            description: "An aromatic culinary herb that thrives alongside tomatoes. Pinch flowers to encourage bushy leaf growth and harvest from the top down.",
            type: "herb",
            zone: "2–11",
            sunRequirements: "Full Sun (6–8 hours)",
            zoneSuitability: "Warm-season annual; frost-tender",
            seasonality: "Spring",
            indoorOutdoor: "outdoor",
            requirements: PlantRequirements(
                soil: "Moist, well-drained, pH 6.0–7.0",
                water: "Every 1–2 days; keep soil evenly moist",
                temperature: "70–85°F",
                humidity: "50–70%",
                fertilizer: "Balanced, light feeding"
            ),
            seedStarting: SeedStartingInfo(
                month: "April–May",
                instructions: ["Start seeds indoors 6 weeks before last frost", "Do not cover seeds; they need light to germinate", "Keep soil warm at 70–75°F", "Harden off before transplanting"],
                indoorWeeksBeforeLastFrost: 6,
                soilTemperature: "70–75°F",
                depth: "Surface sowing (light-dependent germination)",
                spacing: "2 inches apart",
                notes: "Basil is frost-sensitive; transplant after all danger of frost"
            ),
            planting: PlantingInfo(
                month: "May–June",
                instructions: ["Plant after last frost when soil is warm", "Space 6–12 inches apart", "Direct sow or transplant hardened seedlings"],
                spacing: "6–12 inches",
                depth: "Surface to 0.5 inches",
                method: "Transplant or direct sow",
                notes: "Loves warm soil and air; sensitive to cold"
            ),
            carePlan: CarePlan(
                mustDo: [
                    CareItem(title: "Pinching", description: "Pinch off flower buds and top growth to encourage bushy, leafy growth and delay flowering.", frequency: "Weekly", iconName: "hand.pinch.fill"),
                    CareItem(title: "Watering", description: "Keep soil consistently moist but not waterlogged. Inconsistent watering reduces flavor.", frequency: "Every 1–2 days", iconName: "drop.fill"),
                    CareItem(title: "Frost Protection", description: "Basil is annual and frost-tender. Harvest heavily before first frost or bring indoors.", frequency: "Late summer", iconName: "thermometer")
                ],
                others: [
                    CareItem(title: "Fertilizing", description: "Light fertilizing every 2–3 weeks keeps plants vigorous.", frequency: "Every 2–3 weeks", iconName: "leaf.fill"),
                    CareItem(title: "Pest Management", description: "Watch for Japanese beetles and spider mites; use neem oil if needed.", frequency: "Weekly scouting", iconName: "ladybug.fill")
                ]
            ),
            typeSpecific: TypeSpecificInfo(
                daysToHarvest: "50–70 days",
                companionPlants: ["Tomato", "Pepper", "Oregano"],
                yield: "Continuous harvest from one plant",
                varieties: ["Sweet", "Thai", "Purple"]
            )
        ),
        Plant(
            id: rosemaryID,
            name: "Rosemary",
            description: "A fragrant, drought-tolerant evergreen herb. Perfect for borders and containers. Its woody stems and needle-like leaves add Mediterranean charm to any garden.",
            type: "herb",
            zone: "6–11",
            sunRequirements: "Full Sun (6+ hours)",
            zoneSuitability: "USDA zones 6–11; grow as annual in colder zones",
            seasonality: "Perennial evergreen",
            indoorOutdoor: "outdoor",
            requirements: PlantRequirements(
                soil: "Sandy, well-drained, slightly alkaline (pH 7.0–7.5)",
                water: "Drought-tolerant once established; water every 1–2 weeks",
                temperature: "60–70°F optimal",
                humidity: "Low; avoid humid conditions",
                fertilizer: "Light feeding; prefers poor soil"
            ),
            seedStarting: SeedStartingInfo(
                month: "February–March",
                instructions: ["Seeds germinate slowly (2–4 weeks) and unevenly", "Start indoors 8 weeks before last frost", "Keep soil warm and moist", "Propagation from cuttings is faster and more reliable"],
                indoorWeeksBeforeLastFrost: 8,
                soilTemperature: "70°F",
                depth: "0.25 inches",
                spacing: "2 inches apart",
                notes: "Easier to propagate from semi-hardwood cuttings"
            ),
            planting: PlantingInfo(
                month: "April–June",
                instructions: ["Plant after all frost danger in well-drained soil", "Space 24–36 inches apart", "Prefers poor, sandy soil over rich soil", "In cold zones, grow in containers and overwinter indoors"],
                spacing: "24–36 inches",
                depth: "Same depth as nursery pot",
                method: "Transplant or cuttings",
                notes: "Rosemary prefers dry conditions and dislikes sitting in wet soil"
            ),
            carePlan: CarePlan(
                mustDo: [
                    CareItem(title: "Drainage", description: "Ensure excellent drainage. Rosemary rots in wet soil. Use sandy soil and raised beds if needed.", frequency: "Ongoing", iconName: "square.stack.fill"),
                    CareItem(title: "Sun Exposure", description: "Provide 6+ hours of direct sun daily for best flavor and growth.", frequency: "Daily", iconName: "sun.max.fill")
                ],
                others: [
                    CareItem(title: "Pruning", description: "Prune lightly after flowering to maintain shape and bushiness.", frequency: "After bloom", iconName: "scissors"),
                    CareItem(title: "Watering (Established)", description: "Once established (3–6 months), water sparingly. Drought-tolerant.", frequency: "Every 1–2 weeks", iconName: "drop.fill"),
                    CareItem(title: "Overwintering", description: "In zones below 6, grow in containers and bring indoors before first frost.", frequency: "Fall", iconName: "thermometer")
                ]
            ),
            typeSpecific: TypeSpecificInfo(
                daysToHarvest: "80–120 days",
                companionPlants: ["Sage", "Thyme", "Lavender"],
                yield: "Continuous harvest",
                varieties: ["Upright", "Trailing", "Tuscan"]
            )
        ),
        Plant(
            id: sunflowerID,
            name: "Sunflower",
            description: "A towering annual that follows the sun. Sunflowers attract pollinators, provide edible seeds, and add vertical drama to any garden bed.",
            type: "flower",
            zone: "2–11",
            sunRequirements: "Full Sun (8+ hours)",
            zoneSuitability: "Annual for all zones; heat and drought tolerant",
            seasonality: "Summer",
            indoorOutdoor: "outdoor",
            requirements: PlantRequirements(
                soil: "Well-drained, nutrient-rich, pH 6.0–7.5",
                water: "Weekly (deep watering); established plants are drought-tolerant",
                temperature: "70–75°F optimal",
                humidity: "Moderate",
                fertilizer: "Balanced, applied at planting"
            ),
            seedStarting: SeedStartingInfo(
                month: "April–May",
                instructions: ["Sunflowers can be started indoors but prefer direct sowing", "If starting indoors, do so 4–6 weeks before last frost", "Plant in biodegradable pots to minimize root disturbance"],
                indoorWeeksBeforeLastFrost: 4,
                soilTemperature: "50°F (minimum)",
                depth: "0.5–1 inch",
                spacing: "6 inches apart (thin later)",
                notes: "Direct sowing is simpler and more reliable"
            ),
            planting: PlantingInfo(
                month: "April–June",
                instructions: ["Direct sow after last frost when soil is warm", "Plant 1 inch deep, 6 inches apart", "Thin seedlings to 12–24 inches apart depending on height variety", "Plant in succession for continuous summer blooms"],
                spacing: "12–24 inches depending on variety",
                depth: "0.5–1 inch",
                method: "Direct sow seeds",
                notes: "Taller varieties need more space and staking"
            ),
            carePlan: CarePlan(
                mustDo: [
                    CareItem(title: "Watering", description: "Water deeply once or twice weekly. Establish a deep root system.", frequency: "Weekly", iconName: "drop.fill"),
                    CareItem(title: "Support (Tall Varieties)", description: "Stake tall varieties (over 3 feet) to prevent wind damage.", frequency: "At planting", iconName: "square.stack.fill")
                ],
                others: [
                    CareItem(title: "Weeding", description: "Keep area weeded early in season to reduce competition.", frequency: "Every 2–3 weeks", iconName: "leaf.arrow.circlepath"),
                    CareItem(title: "Fertilizing", description: "A single application of balanced fertilizer at planting is usually sufficient.", frequency: "Once at planting", iconName: "leaf.fill"),
                    CareItem(title: "Pest Monitoring", description: "Watch for birds eating seeds and aphids; use deterrents or controls as needed.", frequency: "Weekly", iconName: "ladybug.fill")
                ]
            ),
            typeSpecific: TypeSpecificInfo(
                daysToHarvest: "70–100 days",
                companionPlants: ["Cucumber", "Squash", "Corn"],
                yield: "50–200+ seeds per flower head depending on size",
                varieties: ["Moulin Rouge (4 ft)", "Russian Giant (12 ft)", "Teddy Bear (2 ft)"]
            )
        ),
        Plant(
            id: strawberryID,
            name: "Strawberry",
            description: "Sweet, juicy berries that thrive in containers or raised beds. Keep runners trimmed for larger fruit or let them spread for ground cover.",
            type: "fruit",
            zone: "3–10",
            sunRequirements: "Full Sun (6–8 hours)",
            zoneSuitability: "Perennial or annual depending on variety; USDA zones 3–10",
            seasonality: "Spring",
            indoorOutdoor: "outdoor",
            requirements: PlantRequirements(
                soil: "Rich, slightly acidic (pH 5.5–6.8), well-draining",
                water: "Even moisture; 1–2 inches per week",
                temperature: "55–75°F optimal",
                humidity: "Moderate",
                fertilizer: "Balanced, compost-enriched"
            ),
            seedStarting: SeedStartingInfo(
                month: "December–January",
                instructions: ["Seeds are very small and require light to germinate", "Start indoors 8–10 weeks before last frost", "Do not cover seeds; they need light", "Keep soil moist and warm (70–75°F)", "Seedlings take 6–8 weeks to produce transplants"],
                indoorWeeksBeforeLastFrost: 8,
                soilTemperature: "70–75°F",
                depth: "Surface sowing",
                spacing: "1 inch apart",
                notes: "Seed-grown plants won't fruit until year 2; crowns are faster"
            ),
            planting: PlantingInfo(
                month: "March–April or August–September",
                instructions: ["Plant crowns so the top of crown is just above soil surface", "Space 12–18 inches apart", "In southern zones, plant in fall (August–September); in northern zones, spring (March–April)", "Remove all runners first year to encourage establishment"],
                spacing: "12–18 inches",
                depth: "Crown at soil surface (not buried, not exposed)",
                method: "Crowns or runners",
                notes: "Proper crown depth is critical; too deep or too shallow causes rot or poor establishment"
            ),
            carePlan: CarePlan(
                mustDo: [
                    CareItem(title: "Watering", description: "Keep soil consistently moist but not waterlogged. Drip irrigation is ideal.", frequency: "1–2 inches per week", iconName: "drop.fill"),
                    CareItem(title: "Runner Management (Year 1)", description: "Remove runners first year to direct energy to fruiting crown establishment.", frequency: "As runners appear", iconName: "scissors"),
                    CareItem(title: "Fruit Protection", description: "Use straw mulch or netting to prevent slugs, snails, and rot from soil contact.", frequency: "At bloom", iconName: "leaf.arrow.circlepath")
                ],
                others: [
                    CareItem(title: "Fertilizing", description: "Apply compost or balanced fertilizer in early spring and after harvest.", frequency: "Twice per season", iconName: "leaf.fill"),
                    CareItem(title: "Renewal", description: "Remove old rows every 3–4 years; replant with new crowns for highest yields.", frequency: "Every 3–4 years", iconName: "arrow.circlepath"),
                    CareItem(title: "Pest Monitoring", description: "Scout for spider mites, slugs, and gray mold; use organic controls.", frequency: "Weekly", iconName: "ladybug.fill")
                ]
            ),
            typeSpecific: TypeSpecificInfo(
                daysToHarvest: "60–90 days (from crown; seed-grown plants fruit year 2)",
                companionPlants: ["Borage", "Lettuce", "Spinach"],
                yield: "10–15 lbs per 10 feet of row per year (after year 1)",
                varieties: ["Chandler", "Seascape", "Tristar"]
            )
        ),
        Plant(
            id: lavenderID,
            name: "Lavender",
            description: "Beloved for its calming fragrance and purple blooms. Drought-tolerant once established, lavender attracts bees and butterflies while repelling pests.",
            type: "herb",
            zone: "4–9",
            sunRequirements: "Full Sun (6+ hours)",
            zoneSuitability: "USDA zones 4–9; some varieties to zone 3",
            seasonality: "Perennial evergreen",
            indoorOutdoor: "outdoor",
            requirements: PlantRequirements(
                soil: "Well-drained, alkaline (pH 6.7–7.3)",
                water: "Drought-tolerant once established; water every 2–3 weeks during establishment",
                temperature: "60–70°F optimal",
                humidity: "Low; avoid humid conditions",
                fertilizer: "Minimal; prefers poor soil"
            ),
            seedStarting: SeedStartingInfo(
                month: "February–March",
                instructions: ["Start seeds indoors 8–10 weeks before last frost", "Lavender seeds germinate slowly and inconsistently", "Propagation from cuttings is faster and more reliable", "Keep soil warm at 70°F"],
                indoorWeeksBeforeLastFrost: 8,
                soilTemperature: "70°F",
                depth: "0.25 inches",
                spacing: "2 inches apart",
                notes: "Semi-hardwood cuttings in summer are the most reliable propagation method"
            ),
            planting: PlantingInfo(
                month: "April–May",
                instructions: ["Plant after last frost in well-drained, sandy, or rocky soil", "Space 24–36 inches apart", "Do not amend soil heavily; lavender prefers poor, alkaline soil", "If soil is acidic, add lime before planting"],
                spacing: "24–36 inches",
                depth: "Same depth as nursery pot",
                method: "Transplant or cuttings",
                notes: "Poor soil and excellent drainage are essential; rich soil promotes lush growth and rot"
            ),
            carePlan: CarePlan(
                mustDo: [
                    CareItem(title: "Drainage", description: "Ensure excellent drainage. Wet soil is the primary cause of lavender failure.", frequency: "Ongoing", iconName: "square.stack.fill"),
                    CareItem(title: "Soil pH", description: "Lavender prefers alkaline soil (pH 6.7–7.3). Acidic soils should be amended with lime.", frequency: "At planting", iconName: "leaf.fill")
                ],
                others: [
                    CareItem(title: "Pruning", description: "Prune after flowering in late summer to maintain shape, but do not cut into bare wood.", frequency: "After bloom", iconName: "scissors"),
                    CareItem(title: "Watering (Established)", description: "Drought-tolerant once established; minimal supplemental water needed.", frequency: "Every 2–3 weeks initially", iconName: "drop.fill"),
                    CareItem(title: "Deadheading", description: "Remove spent flower spikes to encourage additional blooms.", frequency: "As flowers fade", iconName: "hand.pinch.fill")
                ]
            ),
            typeSpecific: TypeSpecificInfo(
                daysToHarvest: nil,
                companionPlants: ["Rosemary", "Sage", "Thyme"],
                yield: "Continuous bloom June–September",
                varieties: ["English", "Spanish", "French"]
            )
        )
    ]

    static let tasks: [GardenTask] = []
}
