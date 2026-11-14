import PhotosUI
import SwiftUI

/// The "My Garden" tab, and the app's home: what needs doing today, what's
/// coming up this week, then the user's plants with a care-status chip each.
/// Plants are persisted in `MyGardenStore`; tasks in `TaskViewModel`.
struct MyGardenView: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel
    @Binding var selectedTab: AppTab
    @AppStorage("usda_zone") private var usdaZone = ""
    @AppStorage("state_code") private var stateCode = ""

    @AppStorage("haptics_enabled") private var hapticsEnabled = true
    @State private var showSettings = false

    // Long-press actions
    @State private var rescheduleTarget: GardenTask?
    @State private var carePlanTarget: CatalogPlant?
    @State private var photoTarget: CatalogPlant?
    @State private var photoItem: PhotosPickerItem?
    @State private var noteTarget: CatalogPlant?
    @State private var noteText = ""
    @State private var removeTarget: CatalogPlant?
    @State private var feedbackTick = 0

    /// Group plants by type only once there are enough that grouping helps.
    private let groupByTypeThreshold = 8

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    topBar

                    let saved = gardenVM.myGarden.savedPlants
                    if saved.isEmpty && taskVM.tasks.isEmpty {
                        emptyStateView
                    } else {
                        todaySection
                        comingUpSection
                        if saved.isEmpty {
                            emptyStateView
                        } else {
                            plantsSection(saved)
                            if saved.count >= groupByTypeThreshold {
                                ForEach(plantsByType(saved), id: \.0) { groupName, plants in
                                    carouselSection(title: groupName, subtitle: "By type", plants: plants)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 80)
                }
                .padding(.top, AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: CatalogPlantNavigation.self) { dest in
                let variant = gardenVM.variant(for: dest.plant, zone: usdaZone, state: stateCode)
                let adapted = CatalogPlantAdapter.adapt(dest.plant, variant: variant)
                PlantDetailView(
                    plant: adapted,
                    gardenVM: gardenVM,
                    taskVM: taskVM,
                    onAdd: { gardenVM.addToCatalogGarden(dest.plant) },
                    onRemove: { gardenVM.removeFromCatalogGarden(dest.plant) },
                    isInGardenOverride: { gardenVM.isInCatalogGarden(dest.plant) },
                    refreshPlant: {
                        await gardenVM.regionalPlant(for: dest.plant, zone: usdaZone, state: stateCode)
                    }
                )
            }
            .navigationDestination(for: GardenTask.self) { task in
                TaskDetailView(taskID: task.id, gardenVM: gardenVM, taskVM: taskVM)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(gardenVM: gardenVM, taskVM: taskVM)
            }
            .sheet(item: $rescheduleTarget) { task in
                RescheduleSheet(task: task) { newDate in
                    taskVM.reschedule(task.id, to: newDate)
                    rescheduleTarget = nil
                }
            }
            .sheet(item: $carePlanTarget) { plant in
                CarePlanSheet(
                    plant: CatalogPlantAdapter.adapt(plant, variant: gardenVM.variant(for: plant, zone: usdaZone, state: stateCode)),
                    taskVM: taskVM,
                    refreshPlant: { await gardenVM.regionalPlant(for: plant, zone: usdaZone, state: stateCode) }
                )
            }
            .photosPicker(
                isPresented: Binding(get: { photoTarget != nil }, set: { if !$0 && photoItem == nil { photoTarget = nil } }),
                selection: $photoItem,
                matching: .images
            )
            .onChange(of: photoItem) { _, item in
                guard let item, let plant = photoTarget else { return }
                Task { await savePhoto(item, for: plant) }
            }
            .alert("Add a note", isPresented: Binding(get: { noteTarget != nil }, set: { if !$0 { noteTarget = nil } })) {
                TextField("What did you notice?", text: $noteText)
                Button("Save") { saveNote() }
                Button("Cancel", role: .cancel) { noteText = "" }
            } message: {
                Text(noteTarget.map { "Saved to \($0.commonName)'s log." } ?? "")
            }
            .confirmationDialog(
                "Remove \(removeTarget?.commonName ?? "plant") from your garden?",
                isPresented: Binding(get: { removeTarget != nil }, set: { if !$0 { removeTarget = nil } }),
                titleVisibility: .visible
            ) {
                Button("Remove from Garden", role: .destructive) {
                    if let plant = removeTarget { withAnimation(.snappy) { gardenVM.removeFromCatalogGarden(plant) } }
                }
            }
            .sensoryFeedback(trigger: feedbackTick) { _, _ in hapticsEnabled ? .success : nil }
        }
        .onAppear { taskVM.rollForwardRecurringTasks() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("My Garden")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .circularIconButton()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    /// "Fri, Nov 13 · Zone 8b · 3 plants"
    private var headerSubtitle: String {
        var parts = [Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())]
        if !usdaZone.isEmpty { parts.append("Zone \(usdaZone)") }
        let count = gardenVM.myGarden.savedPlants.count
        if count > 0 { parts.append("\(count) plant\(count == 1 ? "" : "s")") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Today

    @ViewBuilder
    private var todaySection: some View {
        let due = TaskSchedule.dueToday(taskVM.tasks)
        let done = TaskSchedule.completedToday(taskVM.tasks)

        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button { selectedTab = .tasks } label: {
                sectionHeaderContent(
                    title: "Today",
                    trailing: due.isEmpty ? nil : "\(due.count) of \(due.count + done.count) left",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)

            if due.isEmpty && done.isEmpty {
                nothingDueCard
            } else {
                VStack(spacing: 0) {
                    ForEach(due + done) { task in
                        NavigationLink(value: task) {
                            TaskRowView(task: task) {
                                withAnimation(.snappy) { taskVM.toggleCompletion(for: task.id) }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, 10)
                            .background(isOverdue(task) ? AppTheme.Colors.accentPink.opacity(0.08) : .clear)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            TaskQuickActions(task: task, taskVM: taskVM,
                                             onReschedule: task.isCompleted ? nil : { rescheduleTarget = task })
                        }
                        if task.id != (due + done).last?.id {
                            AppTheme.Colors.divider.frame(height: 1).padding(.leading, 56)
                        }
                    }
                }
                .background(AppTheme.Colors.cardBackground,
                            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    private var nothingDueCard: some View {
        let next = TaskSchedule.upcoming(taskVM.tasks, days: 365).first
        return HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22))
                .foregroundStyle(AppTheme.Colors.secondaryGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text("Nothing due today")
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(next.map { "Next: \($0.name) · \($0.plantName), \(TaskSchedule.shortDayLabel(for: $0.dueDate))" }
                     ?? "Add a plant and set up its care plan to get reminders.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground,
                    in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func isOverdue(_ task: GardenTask) -> Bool {
        !task.isCompleted && task.dueDate < Calendar.current.startOfDay(for: .now)
    }

    // MARK: - Coming up

    @ViewBuilder
    private var comingUpSection: some View {
        let upcoming = TaskSchedule.upcoming(taskVM.tasks, days: 7)
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Button { selectedTab = .tasks } label: {
                    sectionHeaderContent(title: "Coming up", trailing: "Next 7 days", showsChevron: true)
                }
                .buttonStyle(.plain)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(upcoming) { task in
                            NavigationLink(value: task) { upcomingChip(task) }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    TaskQuickActions(task: task, taskVM: taskVM,
                                                     onReschedule: { rescheduleTarget = task })
                                }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
            }
        }
    }

    private func upcomingChip(_ task: GardenTask) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(TaskSchedule.shortDayLabel(for: task.dueDate).uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.Colors.accentPink)
            HStack(spacing: 5) {
                Image.symbol(task.iconName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accentBlue)
                Text("\(task.name) · \(task.plantName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.Colors.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        Button {
            selectedTab = .search
        } label: {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "leaf.circle")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(AppTheme.Colors.accentPink.opacity(0.6))

                Text("Your garden is empty")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("Tap here to search and add your first plant")
                    .font(.callout)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
            .padding(.horizontal, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .padding(.horizontal, AppTheme.Spacing.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Plants

    private func plantsSection(_ plants: [CatalogPlant]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeaderContent(title: "Your plants", trailing: nil, showsChevron: false)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(plants) { plant in
                        NavigationLink(value: CatalogPlantNavigation(plant: plant)) {
                            GardenPlantCard(
                                plant: plant,
                                status: TaskSchedule.status(for: plant.id, in: taskVM.tasks),
                                photo: gardenVM.photos.image(for: plant.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu { gardenPlantMenu(plant) }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    private func carouselSection(title: String, subtitle: String, plants: [CatalogPlant]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(plants) { plant in
                        NavigationLink(value: CatalogPlantNavigation(plant: plant)) {
                            catalogCard(plant)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    private func catalogCard(_ plant: CatalogPlant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(plant.accentColor.opacity(0.18))
                Image(systemName: plant.displayIconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(plant.accentColor)
            }
            .frame(width: 160, height: 120)

            Text(plant.commonName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(1)

            if let type = plant.type {
                Text(type.capitalized)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
        .frame(width: 160, alignment: .leading)
    }

    private func plantsByType(_ plants: [CatalogPlant]) -> [(String, [CatalogPlant])] {
        Dictionary(grouping: plants, by: { $0.type?.capitalized ?? "Other" })
            .sorted { $0.key < $1.key }
            .filter { !$0.value.isEmpty }
    }

    // MARK: - Long-press actions

    @ViewBuilder
    private func gardenPlantMenu(_ plant: CatalogPlant) -> some View {
        let dueToday = TaskSchedule.dueToday(taskVM.tasks).filter { $0.plantID == plant.id }
        Button("Mark as Watered", systemImage: "drop.fill") { quickLog(.watered, plant) }
        if !dueToday.isEmpty {
            Button("Finish Today's Tasks (\(dueToday.count))", systemImage: "checkmark.circle") {
                withAnimation(.snappy) { dueToday.forEach { taskVM.markDone($0.id) } }
                feedbackTick += 1
            }
        }
        Button("Set Up Care Plan…", systemImage: "calendar.badge.checkmark") { carePlanTarget = plant }
        Divider()
        Button("Add Photo…", systemImage: "camera") { photoTarget = plant }
        Button("Add Note…", systemImage: "note.text") { noteTarget = plant }
        Button("Log Harvest", systemImage: "basket.fill") { quickLog(.harvested, plant) }
        Divider()
        ShareLink(item: "\(plant.commonName) is growing in my garden. Shared from GardenGenie") {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        Button("Remove from Garden", systemImage: "trash", role: .destructive) { removeTarget = plant }
    }

    /// Same behavior as the plant page's log bar: record it and check off a
    /// matching task due today.
    private func quickLog(_ kind: CareLogKind, _ plant: CatalogPlant) {
        let task = CareLogStore.matchingTask(for: kind, plantID: plant.id, in: taskVM.tasks)
        gardenVM.careLog.add(kind, plantID: plant.id)
        if let task { withAnimation(.snappy) { taskVM.markDone(task.id) } }
        feedbackTick += 1
    }

    private func saveNote() {
        let text = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        noteText = ""
        guard let plant = noteTarget, !text.isEmpty else { return }
        gardenVM.careLog.add(.note, plantID: plant.id, note: text)
        feedbackTick += 1
    }

    private func savePhoto(_ item: PhotosPickerItem, for plant: CatalogPlant) async {
        defer { photoItem = nil; photoTarget = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              (try? gardenVM.photos.save(data, for: plant.id)) != nil else { return }
        gardenVM.careLog.add(.photo, plantID: plant.id)
        feedbackTick += 1
    }

    // MARK: - Section header

    private func sectionHeaderContent(title: String, trailing: String?, showsChevron: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .contentShape(Rectangle())
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}

#Preview {
    @Previewable @State var selectedTab: AppTab = .myGarden
    MyGardenView(
        gardenVM: GardenViewModel(),
        taskVM: TaskViewModel(),
        selectedTab: $selectedTab
    )
    .preferredColorScheme(.dark)
}
