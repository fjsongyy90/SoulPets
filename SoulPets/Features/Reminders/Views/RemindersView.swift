import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RemindersViewModel()
    @State private var showingAddReminder = false
    @State private var showingReminderToRecordAlert = false
    @State private var selectedReminderForRecord: Reminder?
    
    @Query private var allPets: [Pet]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 筛选器
                filterSection
                
                // 主内容
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.isEmpty {
                    emptyStateView
                } else {
                    remindersList
                }
            }
            .navigationTitle(String(localized: "reminders.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddReminder = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddEditReminderView()
            }
            .sheet(isPresented: $showingEditReminder) {
                if let reminder = reminderToEdit {
                    AddEditReminderView(reminderToEdit: reminder)
                }
            }
            .alert(
                String(localized: "reminder.completed_title"),
                isPresented: $showingReminderToRecordAlert
            ) {
                Button(String(localized: "reminder.create_record")) {
                    createRecordFromReminder()
                }
                Button(String(localized: "common.cancel"), role: .cancel) {
                    selectedReminderForRecord = nil
                }
            } message: {
                Text(String(localized: "reminder.create_record_message"))
            }
            .onAppear {
                viewModel.loadReminders(from: modelContext)
            }
            .refreshable {
                viewModel.loadReminders(from: modelContext)
            }
        }
    }
    
    // MARK: - 筛选器部分
    private var filterSection: some View {
        VStack(spacing: 12) {
            // 状态筛选器
            Picker(String(localized: "filter.status"), selection: $viewModel.selectedFilter) {
                ForEach(RemindersViewModel.FilterType.allCases, id: \.self) { filter in
                    Text(filter.localizedName)
                        .tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // 宠物筛选器
            if !allPets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 全部宠物选项
                        PetFilterChip(
                            title: RemindersViewModel.PetFilter.all.displayName,
                            isSelected: viewModel.selectedPetFilter.isAll
                        ) {
                            viewModel.setPetFilter(.all)
                        }
                        
                        // 具体宠物选项
                        ForEach(allPets, id: \.id) { pet in
                            PetFilterChip(
                                title: pet.name,
                                isSelected: viewModel.selectedPetFilter.isSpecific(pet: pet)
                            ) {
                                viewModel.setPetFilter(.specific(pet))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text(String(localized: "common.loading"))
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.selectedFilter == .upcoming ? "bell" : "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.medium)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        switch viewModel.selectedFilter {
        case .upcoming:
            return String(localized: "reminders.empty.upcoming.title")
        case .completed:
            return String(localized: "reminders.empty.completed.title")
        }
    }
    
    private var emptyStateMessage: String {
        switch viewModel.selectedFilter {
        case .upcoming:
            return String(localized: "reminders.empty.upcoming.message")
        case .completed:
            return String(localized: "reminders.empty.completed.message")
        }
    }
    
    // MARK: - 提醒列表
    private var remindersList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 今日待办（仅在 upcoming 状态显示）
                if viewModel.selectedFilter == .upcoming && !viewModel.filteredTodayReminders.isEmpty {
                    todayRemindersSection
                }
                
                // 其他提醒
                ForEach(viewModel.displayReminders, id: \.id) { reminder in
                    NavigationLink(destination: ReminderDetailView(reminder: reminder)) {
                        ReminderCard(
                            reminder: reminder,
                            isToday: viewModel.filteredTodayReminders.contains(where: { $0.id == reminder.id }),
                            onComplete: { reminder in
                                handleReminderCompletion(reminder)
                            },
                            onEdit: { reminder in
                                editReminder(reminder)
                            },
                            onDelete: { reminder in
                                viewModel.deleteReminder(reminder, modelContext: modelContext)
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    // MARK: - 今日待办部分
    private var todayRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "reminders.today"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(viewModel.todayReminderCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .clipShape(Capsule())
            }
            
            ForEach(viewModel.filteredTodayReminders, id: \.id) { reminder in
                NavigationLink(destination: ReminderDetailView(reminder: reminder)) {
                    ReminderCard(
                        reminder: reminder,
                        isToday: true,
                        onComplete: { reminder in
                            handleReminderCompletion(reminder)
                        },
                        onEdit: { reminder in
                            editReminder(reminder)
                        },
                        onDelete: { reminder in
                            viewModel.deleteReminder(reminder, modelContext: modelContext)
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - 处理提醒完成
    private func handleReminderCompletion(_ reminder: Reminder) {
        // 先标记为完成
        viewModel.markReminderAsCompleted(reminder, modelContext: modelContext)
        
        // 然后询问是否创建记录
        selectedReminderForRecord = reminder
        showingReminderToRecordAlert = true
    }
    
    private func createRecordFromReminder() {
        guard let reminder = selectedReminderForRecord else { return }
        
        if let newRecord = viewModel.showCreateRecordFromReminder(reminder, modelContext: modelContext) {
            // TODO: 跳转到记录编辑页面
            print("创建了新记录: \(newRecord.id)")
        }
        
        selectedReminderForRecord = nil
    }
    
    // MARK: - 编辑提醒
    @State private var reminderToEdit: Reminder?
    @State private var showingEditReminder = false
    
    private func editReminder(_ reminder: Reminder) {
        reminderToEdit = reminder
        showingEditReminder = true
    }
}

// MARK: - 宠物筛选芯片
struct PetFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.accentColor : Color(UIColor.systemGray5)
                )
                .foregroundColor(
                    isSelected ? .white : .primary
                )
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 提醒卡片
struct ReminderCard: View {
    let reminder: Reminder
    let isToday: Bool
    let onComplete: (Reminder) -> Void
    let onEdit: (Reminder) -> Void
    let onDelete: (Reminder) -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 标签图标
            Image(systemName: reminder.tag.iconName)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    // 宠物信息
                    if let pets = reminder.pets, !pets.isEmpty {
                        Text(pets.map { $0.name }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 重复规则
                    if let repeatRule = reminder.repeatRuleText {
                        Text(repeatRule)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 操作按钮
            if isToday && !reminder.isCompletedToday {
                Button(action: { onComplete(reminder) }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .contextMenu {
            Button(String(localized: "common.edit")) {
                onEdit(reminder)
            }
            
            Button(String(localized: "common.delete"), role: .destructive) {
                onDelete(reminder)
            }
        }
    }
}

// MARK: - PetFilter 扩展
extension RemindersViewModel.PetFilter {
    var isAll: Bool {
        if case .all = self { return true }
        return false
    }
    
    func isSpecific(pet: Pet) -> Bool {
        if case .specific(let selectedPet) = self {
            return selectedPet.id == pet.id
        }
        return false
    }
}

#Preview {
    RemindersView()
        .modelContainer(for: [Pet.self, Reminder.self, Tag.self, ReminderCompletion.self])
} 