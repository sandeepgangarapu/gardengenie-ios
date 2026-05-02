import SwiftUI

/// Temporary debug surface that renders every (CareTitle → IconName) pair
/// from the canonical mapping. Used once to confirm the 4 custom Material
/// Symbols (gg.compost / gg.stake / gg.pot / gg.harden) and the 2 newly
/// allowlisted Apple symbols (basket.fill, leaf.arrow.circlepath) all
/// resolve via Image.symbol(_:). Delete this file once verified.
struct IconDebugView: View {

    /// Mirrors backend-ios/tests/test_care_icon_mapping.py::CARE_ICON_MAP.
    /// Order matches the plan's title→icon table for easy visual scanning.
    private let mapping: [(title: String, icon: String)] = [
        ("Watering",       "drop.fill"),
        ("Pruning",        "scissors"),
        ("Fertilizing",    "leaf.fill"),
        ("Mulching",       "gg.compost"),
        ("Staking",        "gg.stake"),
        ("Pest Check",     "ant.fill"),
        ("Disease Check",  "cross.case.fill"),
        ("Deadheading",    "scissors"),
        ("Harvesting",     "basket.fill"),
        ("Weeding",        "leaf.arrow.circlepath"),
        ("Repotting",      "gg.pot"),
        ("Thinning",       "leaf.arrow.circlepath"),
        ("Hardening Off",  "gg.harden"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(mapping, id: \.title) { row in
                    HStack(spacing: 16) {
                        Image.symbol(row.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.accentBlue)
                            .frame(width: 36, height: 36)
                            .background(
                                AppTheme.Colors.accentBlue.opacity(0.18),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.body)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text(row.icon)
                                .font(.caption.monospaced())
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, 12)
                    AppTheme.Colors.divider.frame(height: 1).padding(.horizontal, AppTheme.Spacing.md)
                }
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Icon Debug")
        .navigationBarTitleDisplayMode(.inline)
    }
}
