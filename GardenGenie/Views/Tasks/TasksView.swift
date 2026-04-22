import SwiftUI

/// The "Tasks" tab: day strip + agenda grouped by day + overdue bucket + completed history.
struct TasksView: View {
    @Bindable var taskVM: TaskViewModel
    @Bindable var gardenVM: GardenViewModel

    @State private var selectedDay: Date = Calendar.current.startOfDay(for: .now)
    @State private var showCompleted: Bool = false
    @State private var showAddSheet: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    private var agendaRange: ClosedRange<Date> {
        let today = Calendar.current.startOfDay(for: .now)
        return today...Date.distantFuture
    }

    private var agenda: [(day: Date, tasks: [GardenTask])] {
        taskVM.tasksByDay(in: agendaRange)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        topBar

                        WeekStripView(
                            daysWithTasks: taskVM.daysWithTasks,
                            selectedDay: $selectedDay,
                            onDayTap: { day in
                                withAnimation {
                                    proxy.scrollTo(Calendar.current.startOfDay(for: day), anchor: .top)
                                }
                            }
                        )

                        OverdueSectionView(tasks: taskVM.overdueTasks, taskVM: taskVM)

                        agendaSection

                        completedSection

                        Spacer(minLength: 80)
                    }
                    .padding(.top, AppTheme.Spacing.md)
                }
                .background(AppTheme.Colors.background.ignoresSafeArea())
                .navigationBarHidden(true)
                .navigationDestination(for: GardenTask.self) { task in
                    TaskDestinationView(task: task, gardenVM: gardenVM, taskVM: taskVM)
                }
            }
        }
        .onAppear { taskVM.rollForwardRecurringTasks() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { taskVM.rollForwardRecurringTasks() }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTaskSheet(taskVM: taskVM, gardenVM: gardenVM)
        }
    }

    // MARK: - Sections

    private var topBar: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Tasks")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .circularIconButton()
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    @ViewBuilder
    private var agendaSection: some View {
        if agenda.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Upcoming")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding(.horizontal, AppTheme.Spacing.md)
                Text("No upcoming tasks — nice work!")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .font(.callout)
                    .padding(AppTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                            .fill(AppTheme.Colors.cardBackground)
                    )
                    .padding(.horizontal, AppTheme.Spacing.md)
            }
        } else {
            LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.lg, pinnedViews: []) {
                ForEach(agenda, id: \.day) { entry in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        AgendaDayHeader(day: entry.day)
                        dayCard(tasks: entry.tasks)
                    }
                    .id(entry.day)
                }
            }
        }
    }

    private func dayCard(tasks: [GardenTask]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                NavigationLink(value: task) {
                    TaskRowView(task: task) {
                        withAnimation(.snappy) {
                            taskVM.toggleCompletion(for: task.id)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                }
                .buttonStyle(.plain)

                if index < tasks.count - 1 {
                    AppTheme.Colors.divider
                        .frame(height: 1)
                        .padding(.horizontal, AppTheme.Spacing.md)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    @ViewBuilder
    private var completedSection: some View {
        if !taskVM.completedTasks.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Button {
                    withAnimation(.snappy) { showCompleted.toggle() }
                } label: {
                    HStack {
                        Text("Completed")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Text("\(taskVM.completedTasks.count)")
                            .pillTag(color: AppTheme.Colors.accentBlue)
                        Spacer()
                        Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
                .buttonStyle(.plain)

                if showCompleted {
                    dayCard(tasks: taskVM.completedTasks)
                }
            }
        }
    }
}

#Preview {
    TasksView(
        taskVM: TaskViewModel(tasks: MockData.tasks),
        gardenVM: GardenViewModel()
    )
    .preferredColorScheme(.dark)
}
