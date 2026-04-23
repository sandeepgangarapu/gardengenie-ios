import SwiftUI

struct OnboardingZoneResultView: View {
    let zoneInfo: USDAZoneLookup.ZoneInfo?
    let onGetStarted: () -> Void

    @State private var showContent = false
    @State private var showZone = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            ZStack {
                // Animated expanding rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .strokeBorder(
                            AppTheme.Colors.secondaryGreen.opacity(0.3 - Double(index) * 0.1),
                            lineWidth: 2
                        )
                        .frame(width: 200 + CGFloat(index) * 40, height: 200 + CGFloat(index) * 40)
                        .scaleEffect(showZone ? 1.0 : 0.8)
                        .opacity(showZone ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: showZone)
                }

                Circle()
                    .fill(AppTheme.Colors.cardBackground)
                    .frame(width: 180, height: 180)
                    .overlay(Circle().strokeBorder(AppTheme.Colors.secondaryGreen, lineWidth: 3))
                    .scaleEffect(showZone ? 1.0 : 0.5)
                    .opacity(showZone ? 1.0 : 0.0)

                VStack(spacing: 4) {
                    Text("Zone")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    Text(zoneInfo?.zone ?? "N/A")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.secondaryGreen)
                }
                .scaleEffect(showZone ? 1.0 : 0.5)
                .opacity(showZone ? 1.0 : 0.0)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Perfect!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                if let info = zoneInfo {
                    Text("Your garden is in USDA Hardiness Zone \(info.zone)")
                        .font(.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text(info.description)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                }
            }
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)

            // Temperature range card
            if let info = zoneInfo {
                HStack {
                    factItem(icon: "thermometer.low", label: "Min Temp", value: info.minTemp)
                    Spacer()
                    factItem(icon: "thermometer.high", label: "Max Temp", value: info.maxTemp)
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                        .fill(AppTheme.Colors.cardBackground)
                )
                .padding(.horizontal, AppTheme.Spacing.lg)
                .opacity(showContent ? 1.0 : 0.0)
            }

            Spacer()

            Button(action: onGetStarted) {
                Text("Start Gardening")
                    .pillButton(style: .primary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .opacity(showContent ? 1.0 : 0.0)

            Spacer().frame(height: AppTheme.Spacing.xl)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { showZone = true }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) { showContent = true }
        }
    }

    private func factItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.accentBlue)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        OnboardingZoneResultView(
            zoneInfo: USDAZoneLookup.ZoneInfo(
                zone: "7b",
                minTemp: "5°F",
                maxTemp: "10°F",
                description: "Mild winters with occasional freezes. Great for gardenias, camellias, and citrus with protection."
            ),
            onGetStarted: {}
        )
    }
}
