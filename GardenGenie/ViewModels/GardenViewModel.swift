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

    // MARK: - Catalog: Explore listing (zone-filtered)

    /// Cached plants available in the user's current `(zone, state)`. Populated
    /// by `loadExplorePlants`. Empty until that runs (or if the catalog has no
    /// regional variants for this region yet).
    private(set) var explorePlants: [CatalogPlant] = []

    /// True while `loadExplorePlants` is in flight.
    private(set) var isLoadingExplore: Bool = false

    /// Last error from `loadExplorePlants`; cleared on the next successful load.
    private(set) var exploreError: PlantCatalogServiceError?

    // MARK: - Legacy (in-memory) — kept for Tasks compat

    /// Plants the user added to their legacy garden. Empty by default; the
    /// new catalog flow uses `myGarden` instead.
    var plants: [Plant]

    /// Legacy bookmarks set (Plant.id keyed). Catalog has its own persistence.
    var bookmarkedPlantIDs: Set<UUID> {
        didSet { saveBookmarks() }
    }

    init(plants: [Plant] = []) {
        self.plants = plants
        self.bookmarkedPlantIDs = Self.loadBookmarks()
    }

    // MARK: - Catalog: Explore loader

    /// Fetch the list of cached plants for the user's region. Skips the call
    /// if a load is already in flight, and clears `exploreError` on success.
    /// Safe to call repeatedly (e.g. on tab switch / pull-to-refresh).
    func loadExplorePlants(zone: String, state: String) async {
        guard !isLoadingExplore else { return }
        isLoadingExplore = true
        defer { isLoadingExplore = false }

        do {
            let plants = try await PlantCatalogService.listForZone(zone: zone, state: state)
            explorePlants = plants
            exploreError = nil
        } catch let error as PlantCatalogServiceError {
            exploreError = error
        } catch {
            exploreError = .networkFailure(error)
        }
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

    // MARK: - Catalog: autocomplete

    /// Live autocomplete suggestions from cached plants (no LLM).
    private(set) var suggestions: [PlantCatalogService.SearchSuggestion] = []

    /// Fetch autocomplete suggestions. Call on debounced text changes.
    func updateSuggestions(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            suggestions = []
            return
        }
        do {
            suggestions = try await PlantCatalogService.searchCached(query: trimmed)
        } catch {
            // Silently degrade — autocomplete is best-effort.
            suggestions = []
        }
    }

    func clearSuggestions() {
        suggestions = []
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
