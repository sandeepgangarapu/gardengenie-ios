import SwiftUI

/// Detail screen with a blurred backdrop hero, centered poster card, stats row,
/// and companion-plant pills — matching the dark card-based aesthetic.
struct PlantDetailView: View {
    let plant: Plant
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isExpanded = false
    @State private var showRemoveConfirmation = false

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Blurred backdrop + poster card
                    ZStack(alignment: .top) {
                        backdropBlur
                        VStack(spacing: AppTheme.Spacing.md) {
                            Spacer().frame(height: 36) // space for sticky top bar
                            posterCard
                        }
                        .padding(.top, 56) // status bar clearance
                    }

                    titleBlock
                    ctaButtons
                    descriptionBlock
                    statsRow
                    viewCareButton
                    plantingCardsRow

                    Spacer(minLength: 40)
                }
            }

            // Sticky top bar
            topBar
                .padding(.top, 56) // status bar clearance
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Blurred Backdrop

    private var backdropBlur: some View {
        ZStack {
            Image(systemName: plant.iconName)
                .font(.system(size: 200, weight: .ultraLight))
                .foregroundStyle(plant.accentColor.opacity(0.5))
                .blur(radius: 40)
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .clipped()

            // Gradient fade to black
            LinearGradient(
                colors: [.clear, AppTheme.Colors.background],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: 320)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .circularIconButton()
            }
            .buttonStyle(.plain)

            Spacer()

            Button {} label: {
                Image(systemName: "ellipsis")
                    .circularIconButton()
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Centered Poster Card

    private var posterCard: some View {
        ZStack {
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
        .frame(width: 140, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text(plant.name)
                .font(.title.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            if let type = plant.type?.capitalized, !type.isEmpty {
                Text(type)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - CTA Buttons

    private var ctaButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            if gardenVM.isInGarden(plant) {
                Button {
                    showRemoveConfirmation = true
                } label: {
                    Label("Added", systemImage: "checkmark")
                        .pillButton(style: .primary)
                }
                .buttonStyle(.plain)
                .confirmationDialog(
                    "Remove \(plant.name) from your garden?",
                    isPresented: $showRemoveConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Remove from Garden", role: .destructive) {
                        withAnimation(.snappy) { gardenVM.removeFromGarden(plant) }
                    }
                }
            } else {
                Button {
                    withAnimation(.snappy) { gardenVM.addToGarden(plant) }
                } label: {
                    Label("Add to Garden", systemImage: "plus")
                        .pillButton(style: .primary)
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation(.snappy) { gardenVM.toggleBookmark(plant) }
            } label: {
                Label(gardenVM.isBookmarked(plant) ? "Saved" : "Save for Later", systemImage: gardenVM.isBookmarked(plant) ? "bookmark.fill" : "bookmark")
                    .pillButton(style: .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
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

    // MARK: - Stats Row

    private struct StatEntry: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let value: String
        let color: Color
    }

    private var statEntries: [StatEntry] {
        var out: [StatEntry] = []
        func add(_ icon: String, _ label: String, _ value: String?, _ color: Color) {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !trimmed.isEmpty else { return }
            out.append(.init(icon: icon, label: label, value: trimmed, color: color))
        }
        add("house.fill", "Setting", plant.indoorOutdoor?.capitalized, AppTheme.Colors.secondaryGreen)
        add("sun.max.fill", "Sunlight", plant.sunRequirements, AppTheme.Colors.sunYellow)
        add("drop.fill", "Water", plant.requirements?.water, AppTheme.Colors.skyBlue)
        add("calendar", "Season", plant.seasonality, AppTheme.Colors.secondaryGreen)
        add("mountain.2.fill", "Soil", plant.requirements?.soil, AppTheme.Colors.earthBrown)
        add("thermometer.medium", "Temperature", plant.requirements?.temperature, AppTheme.Colors.accentPink)
        add("humidity.fill", "Humidity", plant.requirements?.humidity, AppTheme.Colors.skyBlue)
        add("leaf.fill", "Fertilizer", plant.requirements?.fertilizer, AppTheme.Colors.secondaryGreen)
        add("clock.fill", "Days to Harvest", plant.typeSpecific?.daysToHarvest, AppTheme.Colors.accentPink)
        add("basket.fill", "Yield", plant.typeSpecific?.yield, AppTheme.Colors.secondaryGreen)
        return out
    }

    @ViewBuilder
    private var statsRow: some View {
        let entries = statEntries
        if !entries.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    ForEach(entries) { entry in
                        statItem(entry)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    private func statItem(_ entry: StatEntry) -> some View {
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
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    // MARK: - View Care Button

    @ViewBuilder
    private var viewCareButton: some View {
        if plant.carePlan != nil {
            NavigationLink {
                CareDetailView(plant: plant, taskVM: taskVM)
            } label: {
                Label("View Care", systemImage: "eye")
                    .pillButton(style: .secondary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    // MARK: - Planting Cards Row (Seed Starting + Planting)

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

}

#Preview {
    NavigationStack {
        PlantDetailView(plant: MockData.plants[0], gardenVM: GardenViewModel(), taskVM: TaskViewModel())
    }
    .preferredColorScheme(.dark)
}
