import SwiftUI

struct OnboardingFeaturesView: View {
    let onContinue: () -> Void

    @State private var visibleFeatures: Set<Int> = []

    private let features: [(icon: String, title: String, description: String, color: Color)] = [
        ("leaf.fill", "Track Your Plants", "Add plants to your garden and monitor their care", AppTheme.Colors.accentPink),
        ("bell.badge.fill", "Smart Reminders", "Never miss a watering or pruning session", AppTheme.Colors.accentBlue),
        ("map.fill", "Zone-Aware Tips", "Get advice tailored to your local climate", AppTheme.Colors.secondaryGreen),
        ("binoculars.fill", "Discover Plants", "Explore plants perfect for your zone", AppTheme.Colors.sunYellow)
    ]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            Text("Everything You Need")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.bottom, AppTheme.Spacing.md)

            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    featureRow(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description,
                        color: feature.color
                    )
                    .opacity(visibleFeatures.contains(index) ? 1.0 : 0.0)
                    .offset(x: visibleFeatures.contains(index) ? 0 : -30)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .pillButton(style: .primary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer().frame(height: AppTheme.Spacing.xl)
        }
        .onAppear { animateFeaturesIn() }
    }

    private func featureRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    private func animateFeaturesIn() {
        for index in features.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                withAnimation(.snappy) {
                    _ = visibleFeatures.insert(index)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        OnboardingFeaturesView(onContinue: {})
    }
}
