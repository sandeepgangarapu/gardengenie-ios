import SwiftUI

/// Custom dark settings screen with profile card, grouped sections, and blue-tinted icons.
struct SettingsView: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    // Persisted toggles
    @AppStorage("haptics_enabled") private var hapticsEnabled = true
    @AppStorage("metric_units") private var metricUnits = false
    @AppStorage("task_notifications") private var taskNotifications = true
    @AppStorage("water_reminders") private var waterReminders = true
    @AppStorage("parallax_effects") private var parallaxEffects = true

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    topBar
                    profileCard
                    generalSection
                    gardenPreferencesSection
                    Spacer(minLength: 40)
                }
                .padding(.top, AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .circularIconButton()
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            // Invisible spacer to balance the back button
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppTheme.Spacing.md) {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Gardener")
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text("Member since April 2026")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            .padding(AppTheme.Spacing.md)

            AppTheme.Colors.divider
                .frame(height: 1)
                .padding(.horizontal, AppTheme.Spacing.md)

            HStack(spacing: AppTheme.Spacing.lg) {
                statBadge(count: gardenVM.plants.count, label: "plants growing")
                statBadge(count: taskVM.completedCount, label: "tasks completed")
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func statBadge(count: Int, label: String) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.headline.bold())
                .foregroundStyle(AppTheme.Colors.accentBlue)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }

    // MARK: - General Section

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("General")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.md)

            VStack(spacing: 0) {
                settingsRow(icon: "circle.righthalf.filled", iconColor: AppTheme.Colors.accentBlue, title: "App Appearance") {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text("Auto")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }

                dividerRow

                settingsRow(icon: "waveform", iconColor: AppTheme.Colors.accentBlue, title: "Haptics") {
                    Toggle("", isOn: $hapticsEnabled)
                        .tint(AppTheme.Colors.accentBlue)
                        .labelsHidden()
                }

                dividerRow

                settingsRow(icon: "ruler", iconColor: AppTheme.Colors.accentBlue, title: "Metric Units") {
                    Toggle("", isOn: $metricUnits)
                        .tint(AppTheme.Colors.accentBlue)
                        .labelsHidden()
                }

                dividerRow

                settingsRow(icon: "bell.badge", iconColor: AppTheme.Colors.accentBlue, title: "Task Notifications") {
                    Toggle("", isOn: $taskNotifications)
                        .tint(AppTheme.Colors.accentBlue)
                        .labelsHidden()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    // MARK: - Garden Preferences Section

    private var gardenPreferencesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Garden Preferences")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.md)

            VStack(spacing: 0) {
                settingsRow(icon: "map", iconColor: AppTheme.Colors.secondaryGreen, title: "Planting Zone") {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text("7b")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }

                dividerRow

                settingsRow(icon: "drop.fill", iconColor: AppTheme.Colors.skyBlue, title: "Water Reminders") {
                    Toggle("", isOn: $waterReminders)
                        .tint(AppTheme.Colors.accentBlue)
                        .labelsHidden()
                }

                dividerRow

                settingsRow(icon: "rectangle.stack", iconColor: AppTheme.Colors.accentPink, title: "Parallax Effects") {
                    Toggle("", isOn: $parallaxEffects)
                        .tint(AppTheme.Colors.accentBlue)
                        .labelsHidden()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    // MARK: - Row Helpers

    private func settingsRow<Trailing: View>(icon: String, iconColor: Color, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(title)
                .font(.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            trailing()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, 12)
    }

    private var dividerRow: some View {
        AppTheme.Colors.divider
            .frame(height: 1)
            .padding(.horizontal, AppTheme.Spacing.md)
    }
}

#Preview {
    SettingsView(gardenVM: GardenViewModel(), taskVM: TaskViewModel())
        .preferredColorScheme(.dark)
}
