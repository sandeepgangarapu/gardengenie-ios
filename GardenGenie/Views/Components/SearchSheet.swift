import SwiftUI

/// Full-tab search view shown when the user taps the floating search button.
/// Provides a search field to filter the full plant catalog, with navigation
/// into `PlantDetailView`.
struct SearchSheet: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    TextField("Search plants…", text: $gardenVM.searchText)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    if !gardenVM.searchText.isEmpty {
                        Button {
                            gardenVM.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                .padding(AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                        .fill(AppTheme.Colors.cardBackgroundElevated)
                )
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.md)

                // Results
                if gardenVM.filteredPlants.isEmpty && !gardenVM.searchText.isEmpty {
                    Spacer()
                    Text("No plants found")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Spacer()
                } else {
                    List(gardenVM.filteredPlants) { plant in
                        NavigationLink(value: plant) {
                            HStack(spacing: AppTheme.Spacing.md) {
                                Image(systemName: plant.iconName)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(plant.accentColor)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        plant.accentColor.opacity(0.18),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plant.name)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.Colors.textPrimary)
                                    if let type = plant.type {
                                        Text(type.capitalized)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.Colors.textSecondary)
                                    }
                                }
                                Spacer()

                                if gardenVM.isInGarden(plant) {
                                    Text("In Garden")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(AppTheme.Colors.accentPink)
                                }
                            }
                        }
                        .listRowBackground(AppTheme.Colors.cardBackground)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: Plant.self) { plant in
                PlantDetailView(plant: plant, gardenVM: gardenVM, taskVM: taskVM)
            }
        }
        .onDisappear {
            gardenVM.searchText = ""
        }
    }
}

#Preview {
    SearchSheet(gardenVM: GardenViewModel(), taskVM: TaskViewModel())
        .preferredColorScheme(.dark)
}
