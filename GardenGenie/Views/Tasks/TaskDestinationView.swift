import SwiftUI

/// Routes a tapped task to the correct detail view based on its `kind`.
struct TaskDestinationView: View {
    let task: GardenTask
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel

    private var resolvedPlant: Plant? {
        gardenVM.plant(for: task.plantID)
            ?? gardenVM.allPlants.first { $0.id == task.plantID }
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
