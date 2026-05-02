import SwiftUI

/// Full detail view for seed starting and planting information.
/// Follows the CareDetailView pattern with a segmented picker when both sections exist.
struct PlantingDetailView: View {
    let seedStarting: SeedStartingInfo?
    let planting: PlantingInfo?
    let plantName: String
    let plant: Plant
    @Bindable var taskVM: TaskViewModel

    enum Tab: String, CaseIterable {
        case seedStarting = "Seed Starting"
        case planting = "Planting"
    }

    @State private var selectedTab: Tab
    @State private var pendingKind: TaskKind?

    private var currentKind: TaskKind {
        selectedTab == .seedStarting ? .seedStarting : .planting
    }

    // Which tabs are available
    private var availableTabs: [Tab] {
        var tabs: [Tab] = []
        if seedStarting != nil { tabs.append(.seedStarting) }
        if planting != nil { tabs.append(.planting) }
        return tabs
    }

    private var showPicker: Bool { availableTabs.count > 1 }

    init(seedStarting: SeedStartingInfo?,
         planting: PlantingInfo?,
         plantName: String,
         plant: Plant,
         taskVM: TaskViewModel,
         initialTab: Tab? = nil) {
        self.seedStarting = seedStarting
        self.planting = planting
        self.plantName = plantName
        self.plant = plant
        self.taskVM = taskVM
        if let initial = initialTab {
            _selectedTab = State(initialValue: initial)
        } else if seedStarting != nil {
            _selectedTab = State(initialValue: .seedStarting)
        } else {
            _selectedTab = State(initialValue: .planting)
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {
                if showPicker {
                    Picker("Section", selection: $selectedTab) {
                        ForEach(availableTabs, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppTheme.Spacing.md)
                }

                if selectedTab == .seedStarting, let info = seedStarting {
                    seedStartingContent(info)
                } else if selectedTab == .planting, let info = planting {
                    plantingContent(info)
                }

                Spacer(minLength: 40)
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle(showPicker ? "Growing Guide" : selectedTab.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pendingKind) { kind in
            let monthString: String? = kind == .seedStarting
                ? seedStarting?.month
                : planting?.month
            ScheduleTaskSheet(
                plant: plant,
                kind: kind,
                defaultDate: MonthDateParser.defaultDate(from: monthString),
                taskVM: taskVM
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    pendingKind = currentKind
                } label: {
                    Image(systemName: "calendar.badge.plus")
                }
                .accessibilityLabel("Schedule \(selectedTab.rawValue)")
            }
        }
    }

    // MARK: - Seed Starting Content

    @ViewBuilder
    private func seedStartingContent(_ info: SeedStartingInfo) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Month
            if let month = info.month {
                detailRow(icon: "calendar", label: "Start Month", value: month, color: AppTheme.Colors.sunYellow)
            }

            // Quick stats grid
            let hasWeeks = info.indoorWeeksBeforeLastFrost != nil
            let hasTemp = info.soilTemperature != nil
            if hasWeeks || hasTemp {
                HStack(spacing: AppTheme.Spacing.sm) {
                    if let weeks = info.indoorWeeksBeforeLastFrost {
                        miniStat(icon: "clock.fill", label: "Weeks Before\nLast Frost", value: "\(weeks)", color: AppTheme.Colors.accentBlue)
                    }
                    if let temp = info.soilTemperature {
                        miniStat(icon: "thermometer.medium", label: "Soil Temp", value: temp, color: AppTheme.Colors.accentPink)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }

            if let depth = info.depth {
                detailRow(icon: "arrow.down.to.line", label: "Depth", value: depth, color: AppTheme.Colors.earthBrown)
            }

            if let spacing = info.spacing {
                detailRow(icon: "arrow.left.and.right", label: "Spacing", value: spacing, color: AppTheme.Colors.secondaryGreen)
            }

            // Instructions
            if let instructions = info.instructions, !instructions.isEmpty {
                instructionsList(instructions)
            }

            // Notes
            if let notes = info.notes {
                notesCard(notes)
            }
        }
    }

    // MARK: - Planting Content

    @ViewBuilder
    private func plantingContent(_ info: PlantingInfo) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if let month = info.month {
                detailRow(icon: "calendar", label: "Plant Month", value: month, color: AppTheme.Colors.secondaryGreen)
            }

            if let method = info.method {
                detailRow(icon: "hand.point.down.fill", label: "Method", value: method, color: AppTheme.Colors.accentBlue)
            }

            if let depth = info.depth {
                detailRow(icon: "arrow.down.to.line", label: "Depth", value: depth, color: AppTheme.Colors.earthBrown)
            }

            if let spacing = info.spacing {
                detailRow(icon: "arrow.left.and.right", label: "Spacing", value: spacing, color: AppTheme.Colors.secondaryGreen)
            }

            if let instructions = info.instructions, !instructions.isEmpty {
                instructionsList(instructions)
            }

            if let notes = info.notes {
                notesCard(notes)
            }
        }
    }

    // MARK: - Shared Sub-Views

    private func detailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                Text(value)
                    .font(.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func miniStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    private func instructionsList(_ instructions: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Instructions")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.accentPink)
                        .frame(width: 20, height: 20)
                        .background(AppTheme.Colors.accentPink.opacity(0.15), in: Circle())
                    Text(instruction)
                        .font(.callout)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func notesCard(_ notes: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.callout)
                .foregroundStyle(AppTheme.Colors.sunYellow)
            Text(notes)
                .font(.callout)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.sunYellow.opacity(0.08))
        )
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}

extension TaskKind: Identifiable {
    var id: String { rawValue }
}