import SwiftUI

/// The "Tasks" tab: custom dark grouped cards with Upcoming and Completed sections.
struct TasksView: View {
    @Bindable var taskVM: TaskViewModel

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    topTitle

                    // Upcoming
                    taskSection(title: "Upcoming", tasks: taskVM.pendingTasks, emptyMessage: "No upcoming tasks — nice work!")

                    // Completed
                    if !taskVM.completedTasks.isEmpty {
                        taskSection(title: "Completed", tasks: taskVM.completedTasks)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // MARK: - Top Title

    private var topTitle: some View {
        Text("Tasks")
            .font(.largeTitle.bold())
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Task Section

    @ViewBuilder
    private func taskSection(title: String, tasks: [GardenTask], emptyMessage: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.md)

            VStack(spacing: 0) {
                if tasks.isEmpty, let msg = emptyMessage {
                    Text(msg)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .font(.callout)
                        .padding(AppTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        TaskRowView(task: task) {
                            withAnimation(.snappy) {
                                taskVM.toggleCompletion(for: task.id)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)

                        if index < tasks.count - 1 {
                            AppTheme.Colors.divider
                                .frame(height: 1)
                                .padding(.horizontal, AppTheme.Spacing.md)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }
}

#Preview {
    TasksView(taskVM: TaskViewModel())
        .preferredColorScheme(.dark)
}
