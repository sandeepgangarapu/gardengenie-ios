import Foundation
import Observation

/// Owns the collection of plants and exposes search/filter state.
@Observable
final class GardenViewModel {
    /// Full catalog of every known plant.
    let allPlants: [Plant] = MockData.plants

    /// Plants the user has added to their garden (a subset of `allPlants`).
    var plants: [Plant]

    var searchText: String = ""

    /// Search results drawn from the full catalog.
    var filteredPlants: [Plant] {
        guard !searchText.isEmpty else { return allPlants }
        return allPlants.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    init(plants: [Plant] = []) {
        self.plants = plants
    }

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
}
