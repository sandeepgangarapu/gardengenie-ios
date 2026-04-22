import SwiftUI

/// Header row above a day's tasks in the agenda list.
struct AgendaDayHeader: View {
    let day: Date

    var body: some View {
        HStack {
            TaskDateLabel(dueDate: day, style: .header)
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}
