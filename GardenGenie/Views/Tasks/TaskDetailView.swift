import SwiftUI

/// The page a tapped task opens: what it is and when it's due, with Done /
/// Tomorrow / Reschedule / Delete. The plant's care or growing guide is one
/// tap further, instead of being the only thing you land on.
struct TaskDetailView: View {
    let taskID: UUID
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel
    @AppStorage("usda_zone") private var usdaZone = ""
    @AppStorage("state_code") private var stateCode = ""
    @AppStorage("haptics_enabled") private var hapticsEnabled = true

    @Environment(\.dismiss) private var dismiss
    @State private var showReschedule = false
    @State private var showDeleteConfirmation = false

    private var task: GardenTask? { taskVM.tasks.first { $0.id == taskID } }

    var body: some View {
        Group {
            if let task {
                content(task)
            } else {
                ContentUnavailableView("Task deleted", systemImage: "trash",
                                       description: Text("This task is no longer in your list."))
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ task: GardenTask) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                header(task)
                actions(task)
                links(task)
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Task", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accentPink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .sheet(isPresented: $showReschedule) {
            RescheduleSheet(task: task) { newDate in
                taskVM.reschedule(task.id, to: newDate)
                showReschedule = false
            }
        }
        .confirmationDialog("Delete \(task.name)?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Task", role: .destructive) {
                taskVM.dismiss(task.id)
                dismiss()
            }
        } message: {
            if task.recurrence.isRecurring {
                Text("This removes the repeating task for \(task.plantName).")
            }
        }
    }

    // MARK: - Sections

    private func header(_ task: GardenTask) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Image.symbol(task.iconName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accentBlue)
                .frame(width: 56, height: 56)
                .background(AppTheme.Colors.accentBlue.opacity(0.18),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(task.name)
                .font(.title.bold())
                .foregroundStyle(task.isCompleted ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                .strikethrough(task.isCompleted, color: AppTheme.Colors.textTertiary)
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(task.plantName).pillTag(color: AppTheme.Colors.accentPink)
                if task.recurrence.isRecurring { RecurrenceBadge(recurrence: task.recurrence) }
            }
            Text(dueLabel(task))
                .font(.subheadline)
                .foregroundStyle(isOverdue(task) ? AppTheme.Colors.accentPink : AppTheme.Colors.textSecondary)
            if task.isCompleted, task.recurrence.isRecurring, let next = nextOccurrence(of: task) {
                Text("Next one: \(TaskSchedule.shortDayLabel(for: next.dueDate))")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondaryGreen)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actions(_ task: GardenTask) -> some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button {
                withAnimation(.snappy) { taskVM.toggleCompletion(for: task.id) }
            } label: {
                Label(task.isCompleted ? "Mark as Not Done" : "Mark as Done",
                      systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                    .pillButton(style: task.isCompleted ? .secondary : .primary)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(trigger: task.isCompleted) { _, done in hapticsEnabled && done ? .success : nil }

            if !task.isCompleted {
                HStack(spacing: AppTheme.Spacing.sm) {
                    // Only a snooze for things due now; for a future task
                    // "tomorrow" would pull it earlier.
                    if task.isDueByToday() {
                        Button {
                            withAnimation(.snappy) { taskVM.snoozeToTomorrow(task.id) }
                        } label: {
                            Label("Tomorrow", systemImage: "moon.zzz")
                                .pillButton(style: .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        showReschedule = true
                    } label: {
                        Label("Reschedule", systemImage: "calendar")
                            .pillButton(style: .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func links(_ task: GardenTask) -> some View {
        VStack(spacing: 0) {
            NavigationLink {
                TaskDestinationView(task: task, gardenVM: gardenVM, taskVM: taskVM)
            } label: {
                linkRow(icon: task.kind == .care ? "list.bullet.rectangle" : "book.pages",
                        title: task.kind == .care ? "Care guide" : "Growing guide")
            }
            .buttonStyle(.plain)

            if let catalog = gardenVM.myGarden.plants[task.plantID] {
                AppTheme.Colors.divider.frame(height: 1).padding(.leading, 52)
                NavigationLink {
                    PlantDetailView(
                        plant: CatalogPlantAdapter.adapt(
                            catalog, variant: gardenVM.variant(for: catalog, zone: usdaZone, state: stateCode)),
                        gardenVM: gardenVM,
                        taskVM: taskVM,
                        onAdd: { gardenVM.addToCatalogGarden(catalog) },
                        onRemove: { gardenVM.removeFromCatalogGarden(catalog) },
                        isInGardenOverride: { gardenVM.isInCatalogGarden(catalog) },
                        refreshPlant: { await gardenVM.regionalPlant(for: catalog, zone: usdaZone, state: stateCode) }
                    )
                } label: {
                    linkRow(icon: "leaf.fill", title: "Open \(catalog.commonName)")
                }
                .buttonStyle(.plain)
            }
        }
        .background(AppTheme.Colors.cardBackground,
                    in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
    }

    private func linkRow(icon: String, title: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.secondaryGreen)
                .frame(width: 28, height: 28)
                .background(AppTheme.Colors.secondaryGreen.opacity(0.18),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title)
                .font(.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private func isOverdue(_ task: GardenTask) -> Bool {
        !task.isCompleted && task.dueDate < Calendar.current.startOfDay(for: .now)
    }

    private func dueLabel(_ task: GardenTask) -> String {
        let day = TaskSchedule.shortDayLabel(for: task.dueDate)
        if task.isCompleted { return "Done · was due \(day.lowercased() == "today" ? "today" : day)" }
        if isOverdue(task) { return "Overdue since \(task.dueDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))" }
        return day == "Today" || day == "Tomorrow" ? "Due \(day.lowercased())" : "Due \(day)"
    }

    /// The pending follow-up created when a recurring task is completed.
    private func nextOccurrence(of task: GardenTask) -> GardenTask? {
        taskVM.pendingTasks.first {
            $0.plantID == task.plantID && $0.name == task.name && $0.dueDate > task.dueDate
        }
    }
}

/// Long-press menu for a task row, shared by My Garden and Calendar.
struct TaskQuickActions: View {
    let task: GardenTask
    @Bindable var taskVM: TaskViewModel
    var onReschedule: (() -> Void)? = nil

    var body: some View {
        Button(task.isCompleted ? "Mark as Not Done" : "Mark as Done",
               systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle") {
            withAnimation(.snappy) { taskVM.toggleCompletion(for: task.id) }
        }
        if !task.isCompleted {
            if task.isDueByToday() {
                Button("Move to Tomorrow", systemImage: "moon.zzz") {
                    withAnimation(.snappy) { taskVM.snoozeToTomorrow(task.id) }
                }
            }
            if let onReschedule {
                Button("Reschedule…", systemImage: "calendar", action: onReschedule)
            }
        }
        Divider()
        Button("Delete", systemImage: "trash", role: .destructive) {
            withAnimation(.snappy) { taskVM.dismiss(task.id) }
        }
    }
}

extension GardenTask {
    /// Due today or earlier.
    func isDueByToday(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return false }
        return dueDate < startOfTomorrow
    }
}
