import SwiftUI

/// Sheet for picking a new due date for an overdue or upcoming task.
/// Presented from TasksView via the trailing swipe action.
struct RescheduleSheet: View {
    let task: GardenTask
    let onSave: (Date) -> Void
    @State private var newDate: Date
    @Environment(\.dismiss) private var dismiss

    init(task: GardenTask, onSave: @escaping (Date) -> Void) {
        self.task = task
        self.onSave = onSave
        _newDate = State(initialValue: max(task.dueDate, Date()))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    Text(task.name)
                    Text(task.plantName)
                        .foregroundStyle(.secondary)
                }
                Section("New date") {
                    DatePicker("Due date",
                               selection: $newDate,
                               in: Calendar.current.startOfDay(for: .now)...,
                               displayedComponents: .date)
                    .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(newDate) }
                }
            }
        }
    }
}
