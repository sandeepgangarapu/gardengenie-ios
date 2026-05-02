import SwiftUI

struct OnboardingZoneResultView: View {
    let zoneInfo: USDAZoneLookup.ZoneInfo?
    let onGetStarted: () -> Void

    @State private var showContent = false
    @State private var showZone = false
    @State private var showFacts = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            ZStack {
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

                if let description = zoneInfo?.growingSeasonDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                }
            }
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)

            if let info = zoneInfo {
                growingSeasonCard(info: info)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .opacity(showFacts ? 1.0 : 0.0)
                    .offset(y: showFacts ? 0 : 12)
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
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) { showContent = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.9)) { showFacts = true }
        }
    }

    private func growingSeasonCard(info: USDAZoneLookup.ZoneInfo) -> some View {
        let startIdx = monthIndex(from: info.lastFrostDate)
        let endIdx = monthIndex(from: info.firstFrostDate)
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

        return VStack(spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Label("Growing Season", systemImage: "leaf.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .labelStyle(.titleAndIcon)
                Spacer()
                if let days = info.growingSeasonDays {
                    Text("\(days) days")
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
            }

            GeometryReader { geo in
                let count = months.count
                let segmentWidth = geo.size.width / CGFloat(count)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.Colors.textTertiary.opacity(0.15))

                    if let s = startIdx, let e = endIdx {
                        Capsule()
                            .fill(AppTheme.Colors.secondaryGreen)
                            .frame(
                                width: segmentWidth * CGFloat(e - s + 1),
                                height: 10
                            )
                            .offset(x: segmentWidth * CGFloat(s))
                    }
                }
                .frame(height: 10)
            }
            .frame(height: 10)

            HStack(spacing: 0) {
                ForEach(months.indices, id: \.self) { i in
                    let inSeason: Bool = {
                        guard let s = startIdx, let e = endIdx else { return false }
                        return i >= s && i <= e
                    }()
                    Text(months[i])
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(
                            inSeason
                                ? AppTheme.Colors.textPrimary
                                : AppTheme.Colors.textTertiary
                        )
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    private func monthIndex(from dateString: String?) -> Int? {
        guard let dateString, let firstWord = dateString.split(separator: " ").first else {
            return nil
        }
        let key = String(firstWord.prefix(3)).lowercased()
        let names = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
        return names.firstIndex(of: key)
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        OnboardingZoneResultView(
            zoneInfo: USDAZoneLookup.ZoneInfo(
                zone: "6a",
                state: "MA",
                temperatureRange: "-10 to -5",
                firstFrostDate: "October 17-31",
                lastFrostDate: "April 1-21",
                growingSeasonDays: 179,
                growingSeasonDescription: "Moderate growing season - good for most vegetables and annual flowers"
            ),
            onGetStarted: {}
        )
    }
}
