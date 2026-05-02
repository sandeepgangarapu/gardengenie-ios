import SwiftUI

/// Routes a tapped task to the correct detail view based on its `kind`.
struct TaskDestinationView: View {
    let task: GardenTask
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel
    @AppStorage("usda_zone") private var usdaZone = ""
    @AppStorage("state_code") private var stateCode = ""

    /// Resolve from legacy in-memory garden, then the catalog store (adapted).
    private var resolvedPlant: Plant? {
        if let p = gardenVM.plant(for: task.plantID) { return p }
        if let catalog = gardenVM.myGarden.plants[task.plantID] {
            let variant = gardenVM.variant(for: catalog, zone: usdaZone, state: stateCode)
            return CatalogPlantAdapter.adapt(catalog, variant: variant)
        }
        return nil
    }

    var body: some View {
        if let plant = resolvedPlant {
            switch task.kind {
            case .care:
                CareDetailView(plant: plant, taskVM: taskVM)
            case .seedStarting:
                PlantingDetailView(
                    seedStarting: plant.seedStarting,
                    planting: plant.planting,
                    plantName: plant.name,
                    plant: plant,
                    taskVM: taskVM,
                    initialTab: .seedStarting
                )
            case .planting:
                PlantingDetailView(
                    seedStarting: plant.seedStarting,
                    planting: plant.planting,
                    plantName: plant.name,
                    plant: plant,
                    taskVM: taskVM,
                    initialTab: .planting
                )
            }
        } else {
            ContentUnavailableView(
                "Plant not available",
                systemImage: "leaf.slash",
                description: Text("This task's plant is no longer in your catalog.")
            )
        }
    }
}
