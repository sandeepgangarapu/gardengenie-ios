import SwiftUI

struct CareDetailView: View {
    let plant: Plant
    @Bindable var taskVM: TaskViewModel
    @State private var selectedTab: CareTab = .mustDo
    @State private var pendingAdd: CareItem?
    @Environment(\.dismiss) private var dismiss

    enum CareTab {
        case mustDo
        case others
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {
                Picker("Care Type", selection: $selectedTab) {
                    Text("Must Do").tag(CareTab.mustDo)
                    Text("Good to do").tag(CareTab.others)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.md)

                careItems

                Spacer(minLength: 40)
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Care Guide")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pendingAdd) { item in
            AddTaskSheet(
                taskVM: taskVM,
                gardenVM: GardenViewModel(plants: [plant]),
                prefilledName: item.title,
                prefilledIcon: item.iconName ?? "checkmark.circle.fill",
                prefilledPlant: plant,
                prefilledKind: .care
            )
        }
    }

    private var careItems: some View {
        let items: [CareItem]? = selectedTab == .mustDo
            ? plant.carePlan?.mustDo
            : plant.carePlan?.others
        let emptyMessage = selectedTab == .mustDo
            ? "No critical care items"
            : "No additional care items"

        return Group {
            if let items, !items.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    ForEach(items) { item in
                        careItemCard(item)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            } else {
                Text(emptyMessage)
                    .font(.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.lg)
            }
        }
    }

    private func careItemCard(_ item: CareItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if let iconName = item.iconName {
                    Image(systemName: iconName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accentPink)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accentPink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    if let frequency = item.frequency {
                        Text(frequency)
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }

                Spacer()

                Button {
                    addToTasks(item)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.Colors.accentPink)
                        .padding(AppTheme.Spacing.xs)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add to Tasks")
            }

            if let description = item.description {
                Text(description)
                    .font(.callout)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(nil)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.card)
    }

    private func addToTasks(_ item: CareItem) {
        pendingAdd = item
    }
}

#Preview {
    CareDetailView(plant: MockData.plants[0], taskVM: TaskViewModel())
        .preferredColorScheme(.dark)
}
