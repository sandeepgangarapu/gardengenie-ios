import SwiftUI

/// Lightweight sheet for scheduling tasks from contextual views (seed starting, planting, care).
/// Shows only date picker and optional repeat, since plant/kind are implied by context.
struct ScheduleTaskSheet: View {
    let plant: Plant
    let kind: TaskKind
    let defaultDate: Date
    let prefilledName: String?
    let prefilledIcon: String?
    @Bindable var taskVM: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var recurrence: TaskRecurrence = .none

    init(plant: Plant,
         kind: TaskKind,
         defaultDate: Date,
         taskVM: TaskViewModel,
         prefilledName: String? = nil,
         prefilledIcon: String? = nil) {
        self.plant = plant
        self.kind = kind
        self.defaultDate = defaultDate
        self.taskVM = taskVM
        self.prefilledName = prefilledName
        self.prefilledIcon = prefilledIcon
        _date = State(initialValue: defaultDate)
    }

    private var taskName: String {
        if let name = prefilledName {
            return name
        }
        switch kind {
        case .seedStarting: return "Start \(plant.name) seeds indoors"
        case .planting: return "Plant \(plant.name) outdoors"
        case .care: return "Care for \(plant.name)"
        }
    }

    private var taskIcon: String {
        if let icon = prefilledIcon {
            return icon
        }
        switch kind {
        case .seedStarting: return "leaf.arrow.triangle.circlepath"
        case .planting: return "leaf.circle.fill"
        case .care: return "checkmark.circle.fill"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: taskIcon)
                        .font(.title2)
                        .foregroundStyle(AppTheme.Colors.accentPink)
                    Text(taskName)
                        .font(.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppTheme.Spacing.md)
                .padding(.horizontal, AppTheme.Spacing.md)

                DatePicker(
                    "Date",
                    selection: $date,
                    in: Calendar.current.startOfDay(for: .now)...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)

                HStack {
                    Text("Repeat")
                        .font(.body)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Spacer()
                    Picker("Repeat", selection: $recurrence) {
                        ForEach(TaskRecurrence.pickerOptions, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .labelsHidden()
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.md)

                Spacer()
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to Tasks") {
                        let task = GardenTask(
                            name: taskName,
                            dueDate: date,
                            plantID: plant.id,
                            plantName: plant.name,
                            iconName: taskIcon,
                            kind: kind,
                            recurrence: recurrence
                        )
                        taskVM.addTask(task)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ScheduleTaskSheet(
        plant: MockData.plants[0],
        kind: .care,
        defaultDate: Date(),
        taskVM: TaskViewModel(),
        prefilledName: "Water deeply",
        prefilledIcon: "drop.fill"
    )
    .preferredColorScheme(.dark)
}
