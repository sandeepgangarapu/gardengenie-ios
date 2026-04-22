import SwiftUI

/// Sheet for creating a new task. Used from CareDetailView's "Add to Tasks" button
/// and from the Tasks tab's `+` toolbar action.
struct AddTaskSheet: View {
    @Bindable var taskVM: TaskViewModel
    @Bindable var gardenVM: GardenViewModel

    /// Pre-fill fields (passed when opened from a care item).
    var prefilledName: String = ""
    var prefilledIcon: String = "drop.fill"
    var prefilledPlant: Plant?
    var prefilledKind: TaskKind = .care

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var iconName: String = "drop.fill"
    @State private var kind: TaskKind = .care
    @State private var recurrence: TaskRecurrence = .none
    @State private var dueDate: Date = Date()
    @State private var selectedPlantID: UUID?

    private var availablePlants: [Plant] {
        gardenVM.plants.isEmpty ? gardenVM.allPlants : gardenVM.plants
    }

    private var selectedPlant: Plant? {
        guard let id = selectedPlantID else { return nil }
        return availablePlants.first { $0.id == id }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedPlant != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Name (e.g. Water tomatoes)", text: $name)
                    Picker("Type", selection: $kind) {
                        Text("Care").tag(TaskKind.care)
                        Text("Seed Starting").tag(TaskKind.seedStarting)
                        Text("Planting").tag(TaskKind.planting)
                    }
                }

                Section("Plant") {
                    Picker("Plant", selection: $selectedPlantID) {
                        Text("Select a plant").tag(UUID?.none)
                        ForEach(availablePlants) { plant in
                            Text(plant.name).tag(UUID?.some(plant.id))
                        }
                    }
                }

                Section("When") {
                    DatePicker("Due date",
                               selection: $dueDate,
                               in: Calendar.current.startOfDay(for: .now)...,
                               displayedComponents: .date)
                    Picker("Repeat", selection: $recurrence) {
                        ForEach(TaskRecurrence.pickerOptions, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if name.isEmpty { name = prefilledName }
                iconName = prefilledIcon
                kind = prefilledKind
                if selectedPlantID == nil {
                    selectedPlantID = prefilledPlant?.id ?? availablePlants.first?.id
                }
            }
        }
    }

    private func save() {
        guard let plant = selectedPlant else { return }
        let new = GardenTask(
            name: name.trimmingCharacters(in: .whitespaces),
            dueDate: dueDate,
            plantID: plant.id,
            plantName: plant.name,
            iconName: iconName,
            kind: kind,
            recurrence: recurrence
        )
        taskVM.addTask(new)
        dismiss()
    }
}
