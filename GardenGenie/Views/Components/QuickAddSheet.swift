import SwiftUI

/// The sheet presented when the user taps the floating circle button.
/// Offers quick-add entry points for new plants and tasks — dark themed.
struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Drag indicator area
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.20))
                .frame(width: 36, height: 5)
                .padding(.top, AppTheme.Spacing.sm)

            Text("Quick Add")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.Spacing.md)

            quickAction(
                title: "Add New Plant",
                subtitle: "Track a new plant in your garden",
                icon: "leaf.fill",
                tint: AppTheme.Colors.accentPink
            )
            quickAction(
                title: "Add New Task",
                subtitle: "Schedule a watering, pruning, or pest check",
                icon: "checklist",
                tint: AppTheme.Colors.accentBlue
            )
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden) // we draw our own
    }

    @ViewBuilder
    private func quickAction(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(AppTheme.Colors.cardBackgroundElevated)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickAddSheet()
        .preferredColorScheme(.dark)
}
