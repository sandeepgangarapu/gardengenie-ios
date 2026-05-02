import Foundation
import Observation

/// Owns the user's plant data — both the legacy in-memory `Plant` collection
/// (used by Tasks/Settings) and the new catalog-backed `CatalogPlant` flow
/// (search-driven, persisted via `MyGardenStore`).
///
/// During the migration, both APIs coexist. The legacy paths can be removed
/// once Tasks/MyGardenView are migrated to the catalog model.
@MainActor
@Observable
final class GardenViewModel {

    // MARK: - Catalog (new, network-backed)

    /// Persistent store for saved catalog plants. Source of truth for MyGardenView.
    let myGarden: MyGardenStore = MyGardenStore()

    /// Most-recent search results (in-memory only; cleared on reset).
    private(set) var searchResults: [CatalogPlant] = []

    /// Variants for the current search results, keyed by plant id.
    private(set) var searchVariants: [UUID: PlantRegionalVariant] = [:]

    /// True while a `searchAsync` call is in flight.
    private(set) var isSearching: Bool = false

    /// Last error to surface to the UI; cleared on next successful search.
    private(set) var lastSearchError: PlantCatalogServiceError?

    // MARK: - Legacy (in-memory, MockData-backed) — kept for Tasks compat

    /// Full catalog of every known plant (legacy MockData).
    let allPlants: [Plant] = MockData.plants

    /// Plants the user added to their legacy garden. Empty by default; the
    /// new catalog flow uses `myGarden` instead.
    var plants: [Plant]

    /// Legacy bookmarks set (Plant.id keyed). Catalog has its own persistence.
    var bookmarkedPlantIDs: Set<UUID> {
        didSet { saveBookmarks() }
    }

    var searchText: String = ""

    /// Search results drawn from the legacy MockData catalog.
    var filteredPlants: [Plant] {
        guard !searchText.isEmpty else { return allPlants }
        return allPlants.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    init(plants: [Plant] = []) {
        self.plants = plants
        self.bookmarkedPlantIDs = Self.loadBookmarks()
    }

    // MARK: - Catalog: search

    /// Fetch a plant guide for the given query and the user's current region.
    /// Result is added to `searchResults` and cached in `myGarden` (without
    /// marking it as in-garden — the user does that explicitly via UI).
    func searchAsync(query: String, zone: String, state: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        lastSearchError = nil
        isSearching = true
        defer { isSearching = false }

        do {
            let response = try await PlantCatalogService.fetch(query: trimmed, zone: zone, state: state)
            myGarden.cacheResponse(response)
            // De-duplicate: if same plant id is already in searchResults, replace it.
            searchResults.removeAll { $0.id == response.plant.id }
            searchResults.insert(response.plant, at: 0)
            searchVariants[response.plant.id] = response.variant
        } catch let error as PlantCatalogServiceError {
            lastSearchError = error
        } catch {
            lastSearchError = .networkFailure(error)
        }
    }

    /// Clear results and any error.
    func clearSearch() {
        searchResults.removeAll()
        searchVariants.removeAll()
        lastSearchError = nil
    }

    // MARK: - Catalog: garden

    func isInCatalogGarden(_ plant: CatalogPlant) -> Bool {
        myGarden.isInGarden(plant.id)
    }

    func addToCatalogGarden(_ plant: CatalogPlant) {
        myGarden.add(plantID: plant.id)
    }

    func removeFromCatalogGarden(_ plant: CatalogPlant) {
        myGarden.remove(plantID: plant.id)
    }

    /// Latest variant available for a saved plant + region (from cache).
    func variant(for plant: CatalogPlant, zone: String, state: String) -> PlantRegionalVariant? {
        // Prefer variant from this session's search; fall back to the persistent cache.
        searchVariants[plant.id] ?? myGarden.variant(for: plant.id, zone: zone, state: state)
    }

    // MARK: - Legacy garden API (kept until Tasks/SettingsView migrate)

    /// Whether a plant is already in the user's legacy garden.
    func isInGarden(_ plant: Plant) -> Bool {
        plants.contains { $0.id == plant.id }
    }

    func addToGarden(_ plant: Plant) {
        guard !isInGarden(plant) else { return }
        plants.append(plant)
    }

    func removeFromGarden(_ plant: Plant) {
        plants.removeAll { $0.id == plant.id }
    }

    func plant(for id: UUID) -> Plant? {
        plants.first { $0.id == id }
    }

    func isBookmarked(_ plant: Plant) -> Bool {
        bookmarkedPlantIDs.contains(plant.id)
    }

    func toggleBookmark(_ plant: Plant) {
        if bookmarkedPlantIDs.contains(plant.id) {
            bookmarkedPlantIDs.remove(plant.id)
        } else {
            bookmarkedPlantIDs.insert(plant.id)
        }
    }

    private static let bookmarksKey = "bookmarkedPlantIDs"

    private func saveBookmarks() {
        let strings = bookmarkedPlantIDs.map { $0.uuidString }
        UserDefaults.standard.set(strings, forKey: Self.bookmarksKey)
    }

    private static func loadBookmarks() -> Set<UUID> {
        guard let strings = UserDefaults.standard.stringArray(forKey: bookmarksKey) else { return [] }
        return Set(strings.compactMap { UUID(uuidString: $0) })
    }
}
