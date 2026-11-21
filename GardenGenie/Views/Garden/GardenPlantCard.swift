import SwiftUI

/// Poster-style card for a plant in the user's garden, with a care-status chip
/// so you can see at a glance which plants need something today.
struct GardenPlantCard: View {
    let plant: CatalogPlant
    let status: PlantCareStatus
    /// The user's own photo; beats the catalog photo.
    var photo: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PlantArtworkView(
                accent: plant.accentColor,
                symbol: plant.displayIconName,
                content: .resolve(art: plant.art, userPhoto: photo),
                symbolSize: 64,
                endRadius: 260
            )

            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.commonName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                if let type = plant.type, !type.isEmpty {
                    Text(type.capitalized)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .padding(12)
        }
        .overlay(alignment: .topLeading) {
            statusChip.padding(10)
        }
        .frame(width: 160, height: 210)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var statusChip: some View {
        let (text, icon, color) = chipContent
        return HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold))
            Text(text).lineLimit(1)
        }
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .foregroundStyle(color)
    }

    private var chipContent: (String, String, Color) {
        switch status {
        case .overdue(let name):
            return ("\(name) overdue", "exclamationmark.circle.fill", AppTheme.Colors.accentPink)
        case .dueToday(let name):
            return ("\(name) today", "circle.dashed", AppTheme.Colors.skyBlue)
        case .next(_, let date):
            return ("Next: \(TaskSchedule.shortDayLabel(for: date))", "checkmark.circle.fill", AppTheme.Colors.secondaryGreen)
        case .noTasks:
            return ("No care plan yet", "calendar.badge.plus", AppTheme.Colors.textSecondary)
        }
    }
}
