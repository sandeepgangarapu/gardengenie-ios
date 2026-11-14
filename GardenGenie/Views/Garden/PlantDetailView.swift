import PhotosUI
import SwiftUI

/// Everything about one plant on one page: hero, two primary actions, a stats
/// strip, what its care involves, its season, companions and, once it's in
/// your garden, a care log with a floating log bar for one-tap entries.
///
/// Care details show for every plant (in your garden or not) so you can judge
/// the effort before adding it. "View Care" still opens the full guide.
struct PlantDetailView: View {
    let plant: Plant
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel

    /// Optional overrides used by the catalog flow to route Add/Remove through
    /// `MyGardenStore` instead of the legacy in-memory `gardenVM.plants`.
    /// All three should be supplied together; if any are nil, the view falls back
    /// to the legacy garden API.
    var onAdd: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil
    var isInGardenOverride: (() -> Bool)? = nil
    /// Re-fetches the plant with its regional variant (care frequencies,
    /// planting windows). Passed through to the care-plan sheet.
    var refreshPlant: (() async -> Plant?)? = nil

    @AppStorage("haptics_enabled") private var hapticsEnabled = true

    @State private var isExpanded = false
    @State private var showRemoveConfirmation = false
    @State private var showCarePlan = false
    @State private var showPhotoPicker = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showNoteAlert = false
    @State private var noteText = ""
    @State private var toast: String?
    @State private var feedbackTick = 0

    // MARK: - Derived state

    private var effectiveInGarden: Bool {
        isInGardenOverride?() ?? gardenVM.isInGarden(plant)
    }

    private var hasCareContent: Bool {
        plant.carePlan != nil || plant.seedStarting != nil || plant.planting != nil
    }

    private var photo: UIImage? { gardenVM.photos.image(for: plant.id) }

    private var careItems: [(item: CareItem, isMustDo: Bool)] {
        (plant.carePlan?.mustDo ?? []).map { ($0, true) } + (plant.carePlan?.others ?? []).map { ($0, false) }
    }

    private var pendingTasks: [GardenTask] {
        taskVM.pendingTasks.filter { $0.plantID == plant.id }
    }

    private func performAdd() {
        if let onAdd { onAdd() } else { gardenVM.addToGarden(plant) }
    }

    private func performRemove() {
        if let onRemove { onRemove() } else { gardenVM.removeFromGarden(plant) }
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {
                ZStack(alignment: .top) {
                    backdrop
                    posterCard.padding(.top, 104)
                }
                titleBlock
                ctaButtons
                descriptionBlock
                statsRow
                careSection
                seasonSection
                plantingCardsRow
                companionsSection
                logSection
                Spacer(minLength: effectiveInGarden ? 96 : 40)
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        // A visible (but transparent) navigation bar keeps the system back
        // button and the edge-swipe-back gesture, which a hidden bar disables.
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { moreMenu }
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if effectiveInGarden { logBar }
        }
        .overlay(alignment: .bottom) { toastView }
        .sensoryFeedback(trigger: feedbackTick) { _, _ in hapticsEnabled ? .success : nil }
        .sheet(isPresented: $showCarePlan) {
            CarePlanSheet(plant: plant, taskVM: taskVM, refreshPlant: refreshPlant)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await savePhoto(item) }
        }
        .alert("Add a note", isPresented: $showNoteAlert) {
            TextField("What did you notice?", text: $noteText)
            Button("Save") { saveNote() }
            Button("Cancel", role: .cancel) { noteText = "" }
        } message: {
            Text("Saved to \(plant.name)'s log.")
        }
        .confirmationDialog(
            "Remove \(plant.name) from your garden?",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove from Garden", role: .destructive) {
                withAnimation(.snappy) { performRemove() }
            }
        }
    }

    // MARK: - Hero

    private var backdrop: some View {
        ZStack {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 340)
                    .blur(radius: 30)
                    .opacity(0.55)
                    .clipped()
            } else {
                Image(systemName: plant.iconName)
                    .font(.system(size: 200, weight: .ultraLight))
                    .foregroundStyle(plant.accentColor.opacity(0.5))
                    .blur(radius: 40)
                    .frame(maxWidth: .infinity)
                    .frame(height: 340)
                    .clipped()
            }
            LinearGradient(colors: [.clear, AppTheme.Colors.background], startPoint: .top, endPoint: .bottom)
        }
        .frame(height: 340)
    }

    private var posterCard: some View {
        ZStack {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [plant.accentColor.opacity(0.5), plant.accentColor.opacity(0.15), AppTheme.Colors.cardBackground],
                            center: .topTrailing,
                            startRadius: 10,
                            endRadius: 200
                        )
                    )
                Image(systemName: plant.iconName)
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(plant.accentColor.opacity(0.7))
            }
        }
        .frame(width: 140, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text(plant.name)
                .font(.title.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            let subtitle = [plant.type?.capitalized, plant.lifecycle].compactMap { $0 }.filter { !$0.isEmpty }
            if !subtitle.isEmpty {
                Text(subtitle.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Primary actions

    private var ctaButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            if effectiveInGarden {
                Button {
                    showRemoveConfirmation = true
                } label: {
                    Label("In Garden", systemImage: "checkmark")
                        .pillButton(style: .secondary)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    withAnimation(.snappy) { performAdd() }
                    feedbackTick += 1
                    // Offer the care plan straight away, while the user is
                    // thinking about this plant.
                    if hasCareContent { showCarePlan = true }
                } label: {
                    Label("Add to Garden", systemImage: "plus")
                        .pillButton(style: .primary)
                }
                .buttonStyle(.plain)
            }

            if plant.carePlan != nil {
                NavigationLink {
                    CareDetailView(plant: plant, taskVM: taskVM, refreshPlant: refreshPlant)
                } label: {
                    Label("View Care", systemImage: "list.bullet.rectangle")
                        .pillButton(style: .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private var moreMenu: some View {
        Menu {
            if effectiveInGarden {
                if hasCareContent {
                    Button("Set Up Care Plan", systemImage: "calendar.badge.checkmark") { showCarePlan = true }
                }
                Button(photo == nil ? "Add Photo" : "Change Photo", systemImage: "camera") { showPhotoPicker = true }
                Button("Add Note", systemImage: "note.text") { showNoteAlert = true }
                Divider()
            } else {
                Button("Add to Garden", systemImage: "plus") {
                    withAnimation(.snappy) { performAdd() }
                    feedbackTick += 1
                    if hasCareContent { showCarePlan = true }
                }
            }
            ShareLink(item: shareText) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            if effectiveInGarden {
                Divider()
                Button("Remove from Garden", systemImage: "trash", role: .destructive) {
                    showRemoveConfirmation = true
                }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel("More")
    }

    // MARK: - Description

    @ViewBuilder
    private var descriptionBlock: some View {
        if let description = plant.description {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(description)
                    .font(.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(isExpanded ? nil : 3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
                } label: {
                    Text(isExpanded ? "Show less ▲" : "Show more ▼")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accentPink)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    // MARK: - Stats

    private struct StatEntry: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let value: String
        let color: Color
        var valueColor: Color = AppTheme.Colors.textPrimary
    }

    private var statEntries: [StatEntry] {
        var out: [StatEntry] = []
        func add(_ icon: String, _ label: String, _ value: String?, _ color: Color, valueColor: Color = AppTheme.Colors.textPrimary) {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !trimmed.isEmpty else { return }
            out.append(.init(icon: icon, label: label, value: trimmed, color: color, valueColor: valueColor))
        }
        if let level = CareLevel(plant: plant) {
            let tint: Color = switch level {
            case .easy: AppTheme.Colors.secondaryGreen
            case .moderate: AppTheme.Colors.sunYellow
            case .demanding: AppTheme.Colors.accentPink
            }
            add("leaf.circle.fill", "Care level", level.rawValue, tint, valueColor: tint)
        }
        add("sun.max.fill", "Sunlight", plant.sunRequirements, AppTheme.Colors.sunYellow)
        add("clock.fill", "Harvest", plant.typeSpecific?.daysToHarvest, AppTheme.Colors.accentPink)
        add("thermometer.medium", "Ideal temp", plant.requirements?.temperature, Color.orange)
        if let toxic = plant.toxicToPets {
            add("pawprint.fill", "Pets", toxic ? "Toxic" : "Safe",
                toxic ? AppTheme.Colors.accentPink : AppTheme.Colors.secondaryGreen)
        }
        add("mountain.2.fill", "Soil pH", plant.requirements?.soil, AppTheme.Colors.earthBrown)
        add("leaf.fill", "Soil Type", plant.soilType, AppTheme.Colors.earthBrown)
        add("house.fill", "Setting", plant.indoorOutdoor?.capitalized, AppTheme.Colors.secondaryGreen)
        add("arrow.up.and.down", "Height", plant.matureHeight, AppTheme.Colors.accentPink)
        add("arrow.left.and.right", "Spread", plant.matureSpread, AppTheme.Colors.accentPink)
        add("basket.fill", "Yield", plant.typeSpecific?.yield, AppTheme.Colors.secondaryGreen)
        add("calendar", "Season", plant.seasonality, AppTheme.Colors.secondaryGreen)
        return out
    }

    @ViewBuilder
    private var statsRow: some View {
        let entries = statEntries
        if !entries.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: entry.icon)
                                    .font(.caption2)
                                    .foregroundStyle(entry.color)
                                Text(entry.label)
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                            Text(entry.value)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(entry.valueColor)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    // MARK: - What it takes

    @ViewBuilder
    private var careSection: some View {
        let items = careItems
        if !items.isEmpty {
            let mustCount = items.filter(\.isMustDo).count
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                NavigationLink {
                    CareDetailView(plant: plant, taskVM: taskVM, refreshPlant: refreshPlant)
                } label: {
                    sectionHeader(
                        "What it takes",
                        trailing: "\(mustCount) must-do · \(items.count - mustCount) optional",
                        chevron: true
                    )
                }
                .buttonStyle(.plain)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        ForEach(items, id: \.item.id) { entry in
                            careCard(entry.item, isMustDo: entry.isMustDo)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
            }
        }
    }

    private func careCard(_ item: CareItem, isMustDo: Bool) -> some View {
        let scheduled = pendingTasks.first { $0.name.caseInsensitiveCompare(item.title) == .orderedSame }
        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image.symbol(item.iconName ?? "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accentBlue)
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
            Text(item.frequency ?? item.description ?? "")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineLimit(2, reservesSpace: true)
            Spacer(minLength: 0)
            if let scheduled, effectiveInGarden {
                Text("Next · \(TaskSchedule.shortDayLabel(for: scheduled.dueDate))")
                    .pillTag(color: AppTheme.Colors.accentBlue)
            } else if isMustDo {
                Text("Must do").pillTag(color: AppTheme.Colors.accentPink)
            } else {
                Text("Optional").pillTag(color: AppTheme.Colors.textSecondary)
            }
        }
        .padding(12)
        .frame(width: 168, height: 118, alignment: .topLeading)
        .background(AppTheme.Colors.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Season

    @ViewBuilder
    private var seasonSection: some View {
        if !plant.seasonWindows.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                sectionHeader("Season", trailing: nil, chevron: false)
                SeasonTimelineView(windows: plant.seasonWindows)
                    .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    // MARK: - Planting cards (Seed Starting + Planting)

    @ViewBuilder
    private var plantingCardsRow: some View {
        let hasSeedStarting = plant.seedStarting != nil
        let hasPlanting = plant.planting != nil

        if hasSeedStarting || hasPlanting {
            HStack(spacing: AppTheme.Spacing.sm) {
                if hasSeedStarting {
                    NavigationLink {
                        PlantingDetailView(
                            seedStarting: plant.seedStarting,
                            planting: plant.planting,
                            plantName: plant.name,
                            plant: plant,
                            taskVM: taskVM,
                            initialTab: .seedStarting
                        )
                    } label: {
                        PlantingCompactCard(
                            title: "Seed Starting",
                            month: plant.seedStarting?.month,
                            iconName: "leaf.arrow.triangle.circlepath",
                            accentColor: AppTheme.Colors.sunYellow
                        )
                    }
                    .buttonStyle(.plain)
                }

                if hasPlanting {
                    NavigationLink {
                        PlantingDetailView(
                            seedStarting: plant.seedStarting,
                            planting: plant.planting,
                            plantName: plant.name,
                            plant: plant,
                            taskVM: taskVM,
                            initialTab: .planting
                        )
                    } label: {
                        PlantingCompactCard(
                            title: "Planting",
                            month: plant.planting?.month,
                            iconName: "leaf.circle.fill",
                            accentColor: AppTheme.Colors.secondaryGreen
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    // MARK: - Companions

    @ViewBuilder
    private var companionsSection: some View {
        let companions = plant.typeSpecific?.companionPlants ?? []
        if !companions.isEmpty || !plant.avoidPlantingWith.isEmpty {
            let gardenNames = gardenVM.myGarden.savedPlants.map { $0.commonName.lowercased() }
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                sectionHeader("Grows well with", trailing: nil, chevron: false)
                if !companions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                            ForEach(companions, id: \.self) { name in
                                companionBubble(name, inGarden: Companions.gardenContains(name, gardenNames))
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }
                }
                if !plant.avoidPlantingWith.isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "xmark.octagon.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.accentPink)
                        Text("Keep away from \(plant.avoidPlantingWith.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
            }
        }
    }

    private func companionBubble(_ name: String, inGarden: Bool) -> some View {
        VStack(spacing: 4) {
            Text(String(name.prefix(1)).uppercased())
                .font(.title3.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .frame(width: 52, height: 52)
                .background(AppTheme.Colors.secondaryGreen.opacity(0.25), in: Circle())
                .overlay(alignment: .topTrailing) {
                    if inGarden {
                        Circle()
                            .fill(AppTheme.Colors.accentPink)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().strokeBorder(AppTheme.Colors.background, lineWidth: 2))
                    }
                }
            Text(name.capitalized)
                .font(.caption2)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineLimit(1)
            if inGarden {
                Text("In garden")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accentPink)
            }
        }
        .frame(width: 64)
    }

    // MARK: - Log

    @ViewBuilder
    private var logSection: some View {
        let entries = gardenVM.careLog.entries(for: plant.id)
        if effectiveInGarden && !entries.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                sectionHeader("Your log", trailing: "\(entries.count) entr\(entries.count == 1 ? "y" : "ies")", chevron: false)
                VStack(spacing: 0) {
                    ForEach(entries.prefix(6)) { entry in
                        logRow(entry)
                        if entry.id != entries.prefix(6).last?.id {
                            AppTheme.Colors.divider.frame(height: 1).padding(.leading, 52)
                        }
                    }
                }
                .background(AppTheme.Colors.cardBackground,
                            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    private func logRow(_ entry: CareLogEntry) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: entry.kind.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accentBlue)
                .frame(width: 26, height: 26)
                .background(AppTheme.Colors.accentBlue.opacity(0.18), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            Spacer(minLength: 0)
            Text(entry.date.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Delete Entry", systemImage: "trash", role: .destructive) {
                withAnimation(.snappy) { gardenVM.careLog.delete(entry.id) }
            }
        }
    }

    // MARK: - Log bar

    private var logBar: some View {
        HStack(spacing: 10) {
            Button { showNoteAlert = true } label: {
                Image(systemName: "note.text")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 50, height: 50)
                    .contentShape(Circle())
            }
            .glassEffect(.regular, in: .circle)
            .accessibilityLabel("Add note")

            HStack(spacing: 0) {
                ForEach([CareLogKind.watered, .pruned, .fertilized, .harvested], id: \.self) { kind in
                    Button { log(kind) } label: {
                        Image(systemName: kind.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(kind == .watered ? AppTheme.Colors.skyBlue : AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Log \(kind.title.lowercased())")
                }
                Button { showPhotoPicker = true } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Add photo")
            }
            .glassEffect(.regular, in: .capsule)

            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 50, height: 50)
                    .contentShape(Circle())
            }
            .glassEffect(.regular, in: .circle)
            .accessibilityLabel("Share")
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.Colors.textPrimary)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            Text(toast)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: .capsule)
                .padding(.bottom, effectiveInGarden ? 76 : 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    // MARK: - Actions

    /// Records the action and checks off a matching task due today, if any.
    private func log(_ kind: CareLogKind) {
        let task = CareLogStore.matchingTask(for: kind, plantID: plant.id, in: taskVM.tasks)
        gardenVM.careLog.add(kind, plantID: plant.id)
        if let task {
            withAnimation(.snappy) { taskVM.markDone(task.id) }
            showToast("\(kind.title) · checked off \(task.name)")
        } else {
            showToast("\(kind.title) · logged for today")
        }
        feedbackTick += 1
    }

    private func saveNote() {
        let text = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        noteText = ""
        guard !text.isEmpty else { return }
        gardenVM.careLog.add(.note, plantID: plant.id, note: text)
        showToast("Note saved")
        feedbackTick += 1
    }

    private func savePhoto(_ item: PhotosPickerItem) async {
        defer { photoItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            showToast("Couldn't load that photo")
            return
        }
        do {
            try gardenVM.photos.save(data, for: plant.id)
            gardenVM.careLog.add(.photo, plantID: plant.id)
            showToast("Photo added")
            feedbackTick += 1
        } catch {
            showToast("Couldn't save that photo")
        }
    }

    private func showToast(_ text: String) {
        withAnimation(.snappy) { toast = text }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.snappy) { if toast == text { toast = nil } }
        }
    }

    private var shareText: String {
        var lines = [plant.name + (plant.type.map { " (\($0.capitalized))" } ?? "")]
        if let level = CareLevel(plant: plant) { lines.append("Care level: \(level.rawValue)") }
        for (item, _) in careItems.prefix(4) {
            lines.append("• \(item.title)" + (item.frequency.map { ": \($0)" } ?? ""))
        }
        lines.append("Shared from GardenGenie")
        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, trailing: String?, chevron: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            if chevron {
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
