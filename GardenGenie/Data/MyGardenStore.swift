import Foundation
import Observation

/// Local persistence for "My Garden" — survives app kills, works offline.
///
/// Stores:
///   - `plantIDs`: which `CatalogPlant.id` values the user has saved
///   - `plants`: cached `CatalogPlant` rows keyed by id (so MyGardenView renders
///     without re-fetching after offline restart)
///   - `variants`: cached `PlantRegionalVariant` keyed by `"<plant_id>|<zone>|<state>"`
///     so we can show region-specific care in MyGardenView too
///
/// One source of truth for both ExploreView (after a search adds to garden) and
/// MyGardenView (reads from cache).
@MainActor
@Observable
final class MyGardenStore {

    // MARK: - Persistence layout

    private static let key = "myGardenStore.v1"

    // MARK: - Observable state

    private(set) var plantIDs: Set<UUID> = []
    private(set) var plants: [UUID: CatalogPlant] = [:]
    private(set) var variants: [String: PlantRegionalVariant] = [:]

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    private let userDefaults: UserDefaults

    // MARK: - Public API

    /// All saved plants in display order (most-recently-added first).
    var savedPlants: [CatalogPlant] {
        // Insertion order is preserved by Set's iteration only weakly.
        // We rely on the orderedIDs array for stable display.
        orderedIDs.compactMap { plants[$0] }
    }

    /// True if this plant is in the user's garden.
    func isInGarden(_ id: UUID) -> Bool {
        plantIDs.contains(id)
    }

    /// Cache the response from the API; idempotent. Does NOT mark the plant as in-garden.
    func cacheResponse(_ response: PlantGuideResponse) {
        plants[response.plant.id] = response.plant
        let key = variantKey(plantID: response.plant.id,
                             zone: response.variant.usdaZone,
                             state: response.variant.stateCode)
        variants[key] = response.variant
        persist()
    }

    /// Adds the plant to the user's garden. Cache-side data must already be present
    /// (call `cacheResponse` first).
    func add(plantID: UUID) {
        guard plants[plantID] != nil else { return }
        if !plantIDs.contains(plantID) {
            plantIDs.insert(plantID)
            orderedIDs.insert(plantID, at: 0)   // newest first
            persist()
        }
    }

    /// Removes the plant from the garden. Keeps cached data so re-adding is instant.
    func remove(plantID: UUID) {
        plantIDs.remove(plantID)
        orderedIDs.removeAll { $0 == plantID }
        persist()
    }

    /// Lookup a cached variant for a specific (plant, zone, state).
    func variant(for plantID: UUID, zone: String, state: String) -> PlantRegionalVariant? {
        variants[variantKey(plantID: plantID, zone: zone, state: state)]
    }

    // MARK: - Private

    private var orderedIDs: [UUID] = []

    private func variantKey(plantID: UUID, zone: String, state: String) -> String {
        "\(plantID.uuidString)|\(zone)|\(state.uppercased())"
    }

    private func load() {
        guard let data = userDefaults.data(forKey: Self.key) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractional
        guard let snapshot = try? decoder.decode(StoredSnapshot.self, from: data) else { return }
        plantIDs = snapshot.plantIDs
        plants = snapshot.plants
        variants = snapshot.variants
        orderedIDs = snapshot.orderedIDs
    }

    private func persist() {
        let snapshot = StoredSnapshot(
            plantIDs: plantIDs,
            plants: plants,
            variants: variants,
            orderedIDs: orderedIDs
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        userDefaults.set(data, forKey: Self.key)
    }

    private struct StoredSnapshot: Codable {
        var plantIDs: Set<UUID>
        var plants: [UUID: CatalogPlant]
        var variants: [String: PlantRegionalVariant]
        var orderedIDs: [UUID]
    }
}
