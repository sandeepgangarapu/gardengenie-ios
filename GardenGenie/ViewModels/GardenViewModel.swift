import Foundation
import Observation

/// Owns the collection of plants and exposes search/filter state.
@Observable
final class GardenViewModel {
    /// Full catalog of every known plant.
    let allPlants: [Plant] = MockData.plants

    /// Plants the user has added to their garden (a subset of `allPlants`).
    var plants: [Plant]

    /// IDs of plants the user has bookmarked for later.
    var bookmarkedPlantIDs: Set<UUID> {
        didSet { saveBookmarks() }
    }

    var searchText: String = ""

    /// Search results drawn from the full catalog.
    var filteredPlants: [Plant] {
        guard !searchText.isEmpty else { return allPlants }
        return allPlants.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    init(plants: [Plant] = []) {
        self.plants = plants
        self.bookmarkedPlantIDs = Self.loadBookmarks()
    }

    // MARK: - Garden

    /// Whether a plant is already in the user's garden.
    func isInGarden(_ plant: Plant) -> Bool {
        plants.contains { $0.id == plant.id }
    }

    /// Add a plant to the user's garden.
    func addToGarden(_ plant: Plant) {
        guard !isInGarden(plant) else { return }
        plants.append(plant)
    }

    /// Remove a plant from the user's garden.
    func removeFromGarden(_ plant: Plant) {
        plants.removeAll { $0.id == plant.id }
    }

    /// Convenience lookup for rebuilding a Plant from an ID.
    func plant(for id: UUID) -> Plant? {
        plants.first { $0.id == id }
    }

    // MARK: - Bookmarks

    /// Whether a plant is bookmarked for later.
    func isBookmarked(_ plant: Plant) -> Bool {
        bookmarkedPlantIDs.contains(plant.id)
    }

    /// Toggle bookmark state for a plant.
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
