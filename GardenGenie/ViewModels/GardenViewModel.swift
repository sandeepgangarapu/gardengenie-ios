import Foundation
import Observation

/// Owns the collection of plants and exposes search/filter state.
@Observable
final class GardenViewModel {
    var plants: [Plant]
    var searchText: String = ""

    /// Plants filtered by the current search text.
    var filteredPlants: [Plant] {
        guard !searchText.isEmpty else { return plants }
        return plants.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    init(plants: [Plant] = MockData.plants) {
        self.plants = plants
    }

    /// Convenience lookup for rebuilding a Plant from an ID.
    func plant(for id: UUID) -> Plant? {
        plants.first { $0.id == id }
    }
}
