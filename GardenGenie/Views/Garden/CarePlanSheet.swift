import SwiftUI

/// "Set up care for <plant>": the plant's care guide turned into a list of
/// tasks with repeats and start dates filled in. Shown right after Add to
/// Garden and from the Care Guide toolbar. Confirming adds every row that's
/// switched on in one go.
struct CarePlanSheet: View {
    let plant: Plant
    @Bindable var taskVM: TaskViewModel
    /// Fetches the plant with its regional variant. Used when `plant` was opened
    /// without one (common from Explore), since frequencies live on the variant.
    var refreshPlant: (() async -> Plant?)? = nil

    @Environment(\.dismiss) private var dismiss
    @AppStorage("usda_zone") private var usdaZone = ""
    @AppStorage(ReminderSettings.enabledKey) private var remindersOn = true
    @AppStorage(ReminderSettings.minutesKey) private var reminderMinutes = ReminderSettings.defaultMinutes

    @State private var resolvedPlant: Plant?
    @State private var items: [CarePlanDraftItem] = []
    @State private var isLoadingSchedule = false

    private var activePlant: Plant { resolvedPlant ?? plant }
    private var selected: [CarePlanDraftItem] { items.filter { $0.isIncluded && !$0.isAlreadyScheduled } }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.md) {
                    if isLoadingSchedule { loadingRow }
                    if items.isEmpty && !isLoadingSchedule {
                        emptyState
                    } else {
                        itemsCard
                    }
                    reminderCard
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.md)
            }
            addButton
        }
        .background(AppTheme.Colors.cardBackground.ignoresSafeArea())
        .presentationDetents([.fraction(0.8), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppTheme.Colors.cardBackground)
        .task { await load() }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Set up care for \(activePlant.name)")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(usdaZone.isEmpty
                     ? "Filled in from the care guide. Edit anytime."
                     : "Filled in from the zone \(usdaZone) guide. Edit anytime.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Spacer(minLength: AppTheme.Spacing.sm)
            Button("Not now") { dismiss() }
                .font(.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.md)
    }

    private var loadingRow: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ProgressView().controlSize(.small)
            Text(usdaZone.isEmpty ? "Getting the care schedule…" : "Getting the zone \(usdaZone) schedule…")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.xs)
    }

    private var emptyState: some View {
        Text("This plant's guide doesn't have a care schedule yet. You can still add tasks from the Tasks tab.")
            .font(.callout)
            .foregroundStyle(AppTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.cardBackgroundElevated,
                        in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
    }

    private var itemsCard: some View {
        VStack(spacing: 0) {
            ForEach($items) { $item in
                CarePlanRow(item: $item)
                if item.id != items.last?.id {
                    AppTheme.Colors.divider.frame(height: 1).padding(.leading, 56)
                }
            }
        }
        .background(AppTheme.Colors.cardBackgroundElevated,
                    in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .disabled(isLoadingSchedule)
        .opacity(isLoadingSchedule ? 0.5 : 1)
    }

    private var reminderCard: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "bell.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accentPink)
                .frame(width: 28, height: 28)
                .background(AppTheme.Colors.accentPink.opacity(0.18),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text("Remind me at")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            DatePicker("Reminder time",
                       selection: ReminderSettings.timeBinding($reminderMinutes),
                       displayedComponents: .hourAndMinute)
                .labelsHidden()
                .disabled(!remindersOn)
                .opacity(remindersOn ? 1 : 0.4)
            Spacer(minLength: 0)
            Toggle("Reminders", isOn: $remindersOn)
                .labelsHidden()
                .tint(AppTheme.Colors.accentPink)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, 12)
        .background(AppTheme.Colors.cardBackgroundElevated,
                    in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
    }

    private var addButton: some View {
        Button(action: addTasks) {
            Text(addButtonTitle)
                .pillButton(style: .primary)
        }
        .buttonStyle(.plain)
        .disabled(selected.isEmpty || isLoadingSchedule)
        .opacity(selected.isEmpty || isLoadingSchedule ? 0.45 : 1)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.sm)
        .padding(.bottom, AppTheme.Spacing.md)
    }

    private var addButtonTitle: String {
        let count = selected.count
        guard count > 0 else { return "Choose tasks to add" }
        let noun = count == 1 ? "task" : "tasks"
        return selected.allSatisfy(\.recurrence.isRecurring)
            ? "Add \(count) recurring \(noun)"
            : "Add \(count) \(noun)"
    }

    // MARK: - Actions

    private func load() async {
        items = CarePlanBuilder.items(for: plant, existing: taskVM.tasks)
        // The adapter sets `zone` only when a regional variant was available.
        guard plant.zone == nil, let refreshPlant else { return }
        isLoadingSchedule = true
        defer { isLoadingSchedule = false }
        if let fresh = await refreshPlant() {
            resolvedPlant = fresh
            items = CarePlanBuilder.items(for: fresh, existing: taskVM.tasks)
        }
    }

    private func addTasks() {
        for task in CarePlanBuilder.tasks(from: items, plant: activePlant) {
            taskVM.addTask(task)
        }
        if remindersOn {
            Task {
                await ReminderScheduler.shared.requestAuthorizationIfNeeded()
                ReminderScheduler.shared.sync(taskVM.tasks)
            }
        }
        dismiss()
    }
}

// MARK: - Row

private struct CarePlanRow: View {
    @Binding var item: CarePlanDraftItem
    @State private var showDatePicker = false

    private var tint: Color {
        switch item.kind {
        case .care: return AppTheme.Colors.accentBlue
        case .seedStarting: return AppTheme.Colors.sunYellow
        case .planting: return AppTheme.Colors.secondaryGreen
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            checkButton

            Image.symbol(item.iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                if item.isAlreadyScheduled {
                    Text("Already in your tasks")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                } else {
                    repeatMenu
                }
                if let guide = item.guideText, !item.isAlreadyScheduled {
                    Text(guide)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                        .lineLimit(2)
                }
            }
            .opacity(item.isIncluded || item.isAlreadyScheduled ? 1 : 0.6)

            Spacer(minLength: 0)

            if !item.isAlreadyScheduled {
                dateButton
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, 10)
    }

    private var checkButton: some View {
        Button {
            withAnimation(.snappy) { item.isIncluded.toggle() }
        } label: {
            Image(systemName: item.isAlreadyScheduled
                  ? "checkmark.circle"
                  : (item.isIncluded ? "checkmark.circle.fill" : "circle"))
                .font(.system(size: 22))
                .foregroundStyle(item.isIncluded ? AppTheme.Colors.accentPink : AppTheme.Colors.textTertiary)
        }
        .buttonStyle(.plain)
        .disabled(item.isAlreadyScheduled)
        .accessibilityLabel(item.isIncluded ? "Remove \(item.name) from plan" : "Add \(item.name) to plan")
    }

    /// Short, consistent label ("Today", "Nov 27") instead of the compact
    /// DatePicker, whose format changes with the space available.
    private var dateButton: some View {
        Button {
            showDatePicker = true
        } label: {
            Text(dateLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start date, \(dateLabel)")
        .popover(isPresented: $showDatePicker) {
            DatePicker("Start date",
                       selection: $item.startDate,
                       in: Calendar.current.startOfDay(for: .now)...,
                       displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(AppTheme.Colors.accentPink)
                .padding()
                .frame(width: 330)
                .presentationCompactAdaptation(.popover)
                .onChange(of: item.startDate) { _, _ in showDatePicker = false }
        }
    }

    private var dateLabel: String {
        let calendar = Calendar.current
        let date = item.startDate
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let days = calendar.dateComponents([.day], from: .now, to: date).day ?? 0
        return days < 300
            ? date.formatted(.dateTime.month(.abbreviated).day())
            : date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private var repeatMenu: some View {
        Menu {
            ForEach(TaskRecurrence.pickerOptions(including: item.recurrence), id: \.self) { option in
                Button {
                    item.recurrence = option
                } label: {
                    if option == item.recurrence {
                        Label(option.displayName, systemImage: "checkmark")
                    } else {
                        Text(option.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 3) {
                Text(item.recurrence.displayName)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(AppTheme.Colors.accentPink)
        }
        .accessibilityLabel("Repeat: \(item.recurrence.displayName)")
    }
}
