import SwiftUI

struct CareDetailView: View {
    let plant: Plant
    @Bindable var taskVM: TaskViewModel
    @State private var selectedTab: CareTab = .mustDo
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
                    Text("Others").tag(CareTab.others)
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
    }

    private var careItems: some View {
        Group {
            if selectedTab == .mustDo {
                if let mustDo = plant.carePlan?.mustDo, !mustDo.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        ForEach(mustDo) { item in
                            careItemCard(item)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                } else {
                    Text("No critical care items")
                        .font(.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Spacing.lg)
                }
            } else {
                if let others = plant.carePlan?.others, !others.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        ForEach(others) { item in
                            VStack {
                                careItemCard(item)
                                Button {
                                    addToTasks(item)
                                } label: {
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        Image(systemName: "plus.circle")
                                        Text("Add to Tasks")
                                    }
                                    .font(.callout.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(AppTheme.Spacing.md)
                                    .foregroundStyle(AppTheme.Colors.accentPink)
                                    .background(AppTheme.Colors.accentPink.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                } else {
                    Text("No additional care items")
                        .font(.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Spacing.lg)
                }
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
        let newTask = GardenTask(
            id: UUID(),
            name: item.title,
            dueDate: Date(),
            plantID: plant.id,
            plantName: plant.name,
            isCompleted: false,
            iconName: item.iconName ?? "checkmark.circle.fill"
        )
        taskVM.addTask(newTask)
    }
}

#Preview {
    CareDetailView(plant: MockData.plants[0], taskVM: TaskViewModel())
        .preferredColorScheme(.dark)
}
