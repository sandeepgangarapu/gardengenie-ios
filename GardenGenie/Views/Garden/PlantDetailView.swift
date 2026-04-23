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
            let subtitle = [plant.type?.capitalized, plant.indoorOutdoor?.capitalized]
                .compactMap { $0 }
                .joined(separator: " — ")
            if !subtitle.isEmpty {
                Text(subtitle)
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

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(icon: "sun.max.fill", label: "Sunlight", value: shortValue(plant.sunRequirements ?? "N/A"), color: AppTheme.Colors.sunYellow)
            statItem(icon: "drop.fill", label: "Water", value: shortValue(plant.requirements?.water ?? "N/A"), color: AppTheme.Colors.skyBlue)
            statItem(icon: "calendar", label: "Season", value: shortValue(plant.seasonality ?? "N/A"), color: AppTheme.Colors.secondaryGreen)
            statItem(icon: "mountain.2.fill", label: "Soil", value: shortValue(plant.requirements?.soil ?? "N/A"), color: AppTheme.Colors.earthBrown)
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func statItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    /// Extracts first word / short form from a long care string.
    private func shortValue(_ value: String) -> String {
        // Try to return the first meaningful word
        let cleaned = value
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        let words = cleaned.split(separator: " ")
        if let first = words.first {
            return String(first)
        }
        return value
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
