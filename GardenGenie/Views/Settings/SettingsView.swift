import SwiftUI

/// Profile / settings sheet. Minimal placeholder for now.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var useMetricUnits = false
    @State private var userName = "Gardener"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.primaryGreen.opacity(0.15))
                                .frame(width: 64, height: 64)
                            Image(systemName: "person.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.primaryGreen)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(userName)
                                .font(.title3.bold())
                            Text("Growing since April 2026")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }

                Section("Garden Preferences") {
                    Toggle("Task Notifications", isOn: $notificationsEnabled)
                    Toggle("Use Metric Units", isOn: $useMetricUnits)
                    NavigationLink {
                        Text("Planting Zone settings would live here.")
                            .navigationTitle("Planting Zone")
                    } label: {
                        LabeledContent("Planting Zone", value: "7b")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
