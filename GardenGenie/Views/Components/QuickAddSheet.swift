import SwiftUI

/// The sheet presented when the user taps the floating glass button.
/// Offers quick-add entry points for new plants and tasks.
struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.md) {
                quickAction(
                    title: "Add New Plant",
                    subtitle: "Track a new plant in your garden",
                    icon: "leaf.fill",
                    tint: AppTheme.Colors.primaryGreen
                )
                quickAction(
                    title: "Add New Task",
                    subtitle: "Schedule a watering, pruning, or pest check",
                    icon: "checklist",
                    tint: AppTheme.Colors.skyBlue
                )
                Spacer()
            }
            .padding(AppTheme.Spacing.md)
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func quickAction(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .gardenCard()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickAddSheet()
}
