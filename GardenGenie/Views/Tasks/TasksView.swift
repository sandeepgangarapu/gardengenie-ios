import SwiftUI

/// The "Tasks" tab: day strip + agenda grouped by day + overdue bucket + completed history.
/// Uses a native SwiftUI List so each row supports iOS swipe-to-delete.
struct TasksView: View {
    @Bindable var taskVM: TaskViewModel
    @Bindable var gardenVM: GardenViewModel

    @State private var selectedDay: Date = Calendar.current.startOfDay(for: .now)
    @State private var showCompleted: Bool = false
    @State private var showAddSheet: Bool = false
    @State private var rescheduleTarget: GardenTask?
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
                List {
                    headerSection
                    weekStripSection(proxy: proxy)
                    overdueSection
                    agendaSections
                    completedSection
                    Section { Color.clear.frame(height: 60).listRowBackground(Color.clear) }
                }
                .listStyle(.plain)
                .listSectionSpacing(AppTheme.Spacing.lg)
                .scrollContentBackground(.hidden)
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
        .sheet(item: $rescheduleTarget) { task in
            RescheduleSheet(task: task) { newDate in
                taskVM.reschedule(task.id, to: newDate)
                rescheduleTarget = nil
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
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
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: AppTheme.Spacing.md,
                                      leading: AppTheme.Spacing.md,
                                      bottom: 0,
                                      trailing: AppTheme.Spacing.md))
        }
    }

    private func weekStripSection(proxy: ScrollViewProxy) -> some View {
        Section {
            WeekStripView(
                daysWithTasks: taskVM.daysWithTasks,
                selectedDay: $selectedDay,
                onDayTap: { day in
                    withAnimation {
                        proxy.scrollTo(Calendar.current.startOfDay(for: day), anchor: .top)
                    }
                }
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0,
                                      leading: 0,
                                      bottom: 0,
                                      trailing: 0))
        }
    }

    @ViewBuilder
    private var overdueSection: some View {
        if !taskVM.overdueTasks.isEmpty {
            Section {
                ForEach(taskVM.overdueTasks) { task in
                    NavigationLink(value: task) {
                        TaskRowView(task: task) {
                            withAnimation(.snappy) {
                                taskVM.toggleCompletion(for: task.id)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AppTheme.Colors.accentPink.opacity(0.08))
                    .listRowSeparatorTint(AppTheme.Colors.divider)
                    .listRowInsets(EdgeInsets(top: AppTheme.Spacing.sm,
                                              leading: AppTheme.Spacing.md,
                                              bottom: AppTheme.Spacing.sm,
                                              trailing: AppTheme.Spacing.md))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation(.snappy) { taskVM.dismiss(task.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            rescheduleTarget = task
                        } label: {
                            Label("Reschedule", systemImage: "calendar")
                        }
                        .tint(AppTheme.Colors.accentBlue)
                    }
                }
            } header: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppTheme.Colors.accentPink)
                    Text("Overdue")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text("\(taskVM.overdueTasks.count)")
                        .pillTag(color: AppTheme.Colors.accentPink)
                    Spacer()
                }
                .textCase(nil)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.sm)
            }
        }
    }

    @ViewBuilder
    private var agendaSections: some View {
        if agenda.isEmpty && taskVM.overdueTasks.isEmpty {
            Section {
                Text("No upcoming tasks — nice work!")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .font(.callout)
                    .padding(AppTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(AppTheme.Colors.cardBackground)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0,
                                              leading: AppTheme.Spacing.md,
                                              bottom: 0,
                                              trailing: AppTheme.Spacing.md))
            } header: {
                Text("Upcoming")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .textCase(nil)
                    .padding(.horizontal, AppTheme.Spacing.md)
            }
        } else {
            ForEach(agenda, id: \.day) { entry in
                Section {
                    ForEach(entry.tasks) { task in
                        NavigationLink(value: task) {
                            TaskRowView(task: task) {
                                withAnimation(.snappy) {
                                    taskVM.toggleCompletion(for: task.id)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppTheme.Colors.cardBackground)
                        .listRowSeparatorTint(AppTheme.Colors.divider)
                        .listRowInsets(EdgeInsets(top: AppTheme.Spacing.sm,
                                                  leading: AppTheme.Spacing.md,
                                                  bottom: AppTheme.Spacing.sm,
                                                  trailing: AppTheme.Spacing.md))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation(.snappy) { taskVM.dismiss(task.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                rescheduleTarget = task
                            } label: {
                                Label("Reschedule", systemImage: "calendar")
                            }
                            .tint(AppTheme.Colors.accentBlue)
                        }
                    }
                } header: {
                    AgendaDayHeader(day: entry.day)
                        .textCase(nil)
                        .padding(.horizontal, AppTheme.Spacing.md)
                }
                .id(entry.day)
            }
        }
    }

    @ViewBuilder
    private var completedSection: some View {
        if !taskVM.completedTasks.isEmpty {
            Section {
                if showCompleted {
                    ForEach(taskVM.completedTasks) { task in
                        NavigationLink(value: task) {
                            TaskRowView(task: task) {
                                withAnimation(.snappy) {
                                    taskVM.toggleCompletion(for: task.id)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppTheme.Colors.cardBackground)
                        .listRowSeparatorTint(AppTheme.Colors.divider)
                        .listRowInsets(EdgeInsets(top: AppTheme.Spacing.sm,
                                                  leading: AppTheme.Spacing.md,
                                                  bottom: AppTheme.Spacing.sm,
                                                  trailing: AppTheme.Spacing.md))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation(.snappy) { taskVM.dismiss(task.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
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
                    .textCase(nil)
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
                .buttonStyle(.plain)
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
