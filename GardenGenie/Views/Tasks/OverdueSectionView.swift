import SwiftUI

/// Collapsible red-accented section showing pending tasks that are past due.
struct OverdueSectionView: View {
    let tasks: [GardenTask]
    @Bindable var taskVM: TaskViewModel

    @State private var isExpanded: Bool = true
    @State private var rescheduleTarget: GardenTask?

    var body: some View {
        if tasks.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                header
                if isExpanded {
                    VStack(spacing: 0) {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                            OverdueRow(
                                task: task,
                                onComplete: {
                                    withAnimation(.snappy) {
                                        taskVM.toggleCompletion(for: task.id)
                                    }
                                },
                                onReschedule: { rescheduleTarget = task },
                                onDismiss: {
                                    withAnimation(.snappy) {
                                        taskVM.dismiss(task.id)
                                    }
                                }
                            )
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)

                            if index < tasks.count - 1 {
                                AppTheme.Colors.divider
                                    .frame(height: 1)
                                    .padding(.horizontal, AppTheme.Spacing.md)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                            .fill(AppTheme.Colors.accentPink.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                            .strokeBorder(AppTheme.Colors.accentPink.opacity(0.35), lineWidth: 1)
                    )
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
            }
            .sheet(item: $rescheduleTarget) { task in
                RescheduleSheet(task: task) { newDate in
                    taskVM.reschedule(task.id, to: newDate)
                    rescheduleTarget = nil
                }
            }
        }
    }

    private var header: some View {
        Button {
            withAnimation(.snappy) { isExpanded.toggle() }
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accentPink)
                Text("Overdue")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text("\(tasks.count)")
                    .pillTag(color: AppTheme.Colors.accentPink)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
        .buttonStyle(.plain)
    }
}

private struct OverdueRow: View {
    let task: GardenTask
    let onComplete: () -> Void
    let onReschedule: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: task.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accentPink)
                .frame(width: 28, height: 28)
                .background(AppTheme.Colors.accentPink.opacity(0.18),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                TaskDateLabel(dueDate: task.dueDate, isOverdue: true)
            }

            Spacer()

            HStack(spacing: AppTheme.Spacing.sm) {
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.Colors.accentBlue)
                }
                .buttonStyle(.plain)

                Menu {
                    Button {
                        onReschedule()
                    } label: {
                        Label("Reschedule", systemImage: "calendar")
                    }
                    Button(role: .destructive) {
                        onDismiss()
                    } label: {
                        Label("Dismiss", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
}

private struct RescheduleSheet: View {
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
