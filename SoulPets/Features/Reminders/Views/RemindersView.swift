import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RemindersViewModel()
    @State private var showingAddReminder = false
    @State private var showingEditReminder = false
    @State private var showingReminderToRecordAlert = false
    @State private var showingDeleteAlert = false
    @State private var selectedReminderForRecord: Reminder?
    @State private var reminderToEdit: Reminder?
    @State private var reminderToDelete: Reminder?
    
    // 新增状态管理 - 参考Record模块
    @State private var showingPetSelector = false
    @State private var showingSearchBar = false
    @State private var searchText = ""
    @State private var currentPet: Pet?
    
    @Query private var allPets: [Pet]
    
    // 颜色定义 - 与Record模块保持一致
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 筛选器和搜索栏 - 采用Record模块的设计
                    filterAndSearchView
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // 宠物选择器（展开时显示）
                    if showingPetSelector {
                        petSelectorView
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    // 搜索栏（展开时显示）
                    if showingSearchBar {
                        searchBarView
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    // 主内容
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.isEmpty {
                        emptyStateView
                    } else {
                        remindersList
                    }
                }
            }
            .navigationTitle(String(localized: "Reminders"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddReminder = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddEditReminderView()
                    .onDisappear {
                        viewModel.loadReminders(from: modelContext)
                    }
            }
            .sheet(isPresented: $showingEditReminder) {
                if let reminder = reminderToEdit {
                    AddEditReminderView(reminderToEdit: reminder)
                        .onDisappear {
                            reminderToEdit = nil
                            viewModel.loadReminders(from: modelContext)
                        }
                }
            }
            .customChoiceAlert(
                title: String(localized: "reminder.completed_title"),
                message: String(localized: "reminder.create_record_message"),
                isPresented: $showingReminderToRecordAlert,
                primaryTitle: String(localized: "reminder.create_record"),
                primaryAction: {
                    createRecordFromReminder()
                },
                secondaryTitle: String(localized: "common.cancel"),
                secondaryAction: {
                    selectedReminderForRecord = nil
                }
            )
            .customConfirmAlert(
                title: String(localized: "Delete Reminder"),
                message: String(localized: "This action cannot be undone."),
                isPresented: $showingDeleteAlert,
                confirmTitle: String(localized: "Delete"),
                cancelTitle: String(localized: "Cancel"),
                confirmAction: {
                    if let reminder = reminderToDelete {
                        viewModel.deleteReminder(reminder, modelContext: modelContext)
                        reminderToDelete = nil
                    }
                },
                isDestructive: true
            )
            .onChange(of: searchText) { oldValue, newValue in
                // 实现搜索功能
                viewModel.searchText = newValue
                viewModel.loadReminders(from: modelContext)
            }
            .onAppear {
                viewModel.loadReminders(from: modelContext)
            }
            .refreshable {
                viewModel.loadReminders(from: modelContext)
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 筛选器和搜索栏视图 - 参考Record模块
    private var filterAndSearchView: some View {
        HStack(spacing: 8) {
            // 宠物筛选按钮
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingPetSelector.toggle()
                    if showingPetSelector {
                        showingSearchBar = false
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    if let currentPet = currentPet {
                        // 显示当前选中宠物的头像
                        if let avatarData = currentPet.avatar, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        } else {
                            Image(currentPet.petType == .dog ? "dog" : "cat")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .padding(3)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.97, green: 0.90, blue: 0.83))
                                )
                        }
                        Text(currentPet.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 12))
                        Text(String(localized: "All"))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Image(systemName: showingPetSelector ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
            }
            
            // 状态筛选按钮
            Button {
                // 切换状态筛选
                viewModel.selectedFilter = viewModel.selectedFilter == .upcoming ? .completed : .upcoming
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.selectedFilter == .upcoming ? "clock" : "checkmark.circle")
                        .font(.system(size: 12))
                    Text(viewModel.selectedFilter == .upcoming ? String(localized: "Upcoming") : String(localized: "Completed"))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
            }
            
            Spacer()
            
            // 搜索按钮
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSearchBar.toggle()
                    if showingSearchBar {
                        showingPetSelector = false
                    }
                }
            } label: {
                Image(systemName: showingSearchBar ? "xmark" : "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(showingSearchBar ? .white : textColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(showingSearchBar ? accentColor : Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
            }
        }
    }
    
    /// 宠物选择器视图 - 参考Record模块
    private var petSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All Pets" 选项
                Button {
                    currentPet = nil
                    viewModel.setPetFilter(.all)
                    withAnimation {
                        showingPetSelector = false
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 20))
                            .foregroundColor(currentPet == nil ? .white : accentColor)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(currentPet == nil ? accentColor : Color(red: 0.97, green: 0.90, blue: 0.83))
                            )
                        
                        Text(String(localized: "All"))
                            .font(.caption)
                            .foregroundColor(currentPet == nil ? accentColor : textColor)
                            .fontWeight(currentPet == nil ? .semibold : .regular)
                    }
                }
                
                // 各个宠物选项
                ForEach(allPets) { pet in
                    Button {
                        currentPet = pet
                        viewModel.setPetFilter(.specific(pet))
                        withAnimation {
                            showingPetSelector = false
                        }
                    } label: {
                        VStack(spacing: 4) {
                            if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(currentPet?.id == pet.id ? accentColor : Color.clear, lineWidth: 2)
                                    )
                            } else {
                                Image(pet.petType == .dog ? "dog" : "cat")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color(red: 0.97, green: 0.90, blue: 0.83))
                                            .overlay(
                                                Circle()
                                                    .stroke(currentPet?.id == pet.id ? accentColor : Color.clear, lineWidth: 2)
                                            )
                                    )
                            }
                            
                            Text(pet.name)
                                .font(.caption)
                                .foregroundColor(currentPet?.id == pet.id ? accentColor : textColor)
                                .fontWeight(currentPet?.id == pet.id ? .semibold : .regular)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
    
    /// 搜索栏视图 - 参考Record模块
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(labelColor)
            
            TextField(String(localized: "Search reminders..."), text: $searchText)
                .foregroundColor(textColor)
                .onSubmit {
                    withAnimation {
                        showingSearchBar = false
                    }
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(labelColor)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text(String(localized: "common.loading"))
                .foregroundColor(labelColor)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 空状态视图 - 参考Record模块
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: viewModel.selectedFilter == .upcoming ? "bell" : "checkmark.circle")
                .font(.system(size: 70))
                .foregroundColor(accentColor.opacity(0.7))
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(textColor)
            
            Text(emptyStateMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(labelColor)
                .padding(.horizontal, 40)
            
            if viewModel.selectedFilter == .upcoming {
                Button {
                    showingAddReminder = true
                } label: {
                    Text(String(localized: "Add Reminder"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(accentColor)
                        )
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
    }
    
    private var emptyStateTitle: String {
        switch viewModel.selectedFilter {
        case .upcoming:
            return String(localized: "No Upcoming Reminders")
        case .completed:
            return String(localized: "No Completed Reminders")
        }
    }
    
    private var emptyStateMessage: String {
        switch viewModel.selectedFilter {
        case .upcoming:
            return String(localized: "Create your first reminder to stay on top of your pet's care schedule.")
        case .completed:
            return String(localized: "Completed reminders will appear here once you mark them as done.")
        }
    }
    
    // MARK: - 提醒列表 - 重新设计卡片样式
    private var remindersList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 今日待办（仅在 upcoming 状态显示）
                if viewModel.selectedFilter == .upcoming && !viewModel.filteredTodayReminders.isEmpty {
                    todayRemindersSection
                }
                
                // 未来提醒部分（仅在 upcoming 状态显示）
                if viewModel.selectedFilter == .upcoming && !viewModel.filteredUpcomingReminders.isEmpty {
                    upcomingRemindersSection
                }
                
                // 已完成提醒（仅在 completed 状态显示）
                if viewModel.selectedFilter == .completed && !viewModel.filteredCompletedReminders.isEmpty {
                    completedRemindersSection
                }
            }
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - 今日待办部分 - 重新设计
    private var todayRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Today"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Text("\(viewModel.todayReminderCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.1))
                    .foregroundColor(accentColor)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            // 今日提醒使用不同的ID前缀避免冲突
            ForEach(Array(viewModel.filteredTodayReminders.enumerated()), id: \.offset) { index, reminder in
                NavigationLink(destination: ReminderDetailView(reminder: reminder)) {
                    ReminderCardView(
                        reminder: reminder,
                        isToday: true,
                        accentColor: accentColor,
                        textColor: textColor,
                        labelColor: labelColor,
                        onComplete: { reminder in
                            handleReminderCompletion(reminder)
                        },
                        onEdit: { reminder in
                            editReminder(reminder)
                        },
                        onDelete: { reminder in
                            handleReminderDeletion(reminder)
                        }
                    )
                    .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - 未来提醒部分 - 新增
    private var upcomingRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Upcoming"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Text("\(viewModel.filteredUpcomingReminders.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(labelColor.opacity(0.1))
                    .foregroundColor(labelColor)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            // 未来提醒
            ForEach(Array(viewModel.filteredUpcomingReminders.enumerated()), id: \.offset) { index, reminder in
                NavigationLink(destination: ReminderDetailView(reminder: reminder)) {
                    ReminderCardView(
                        reminder: reminder,
                        isToday: false,
                        accentColor: accentColor,
                        textColor: textColor,
                        labelColor: labelColor,
                        onComplete: { reminder in
                            handleReminderCompletion(reminder)
                        },
                        onEdit: { reminder in
                            editReminder(reminder)
                        },
                        onDelete: { reminder in
                            handleReminderDeletion(reminder)
                        }
                    )
                    .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - 已完成提醒部分 - 新增
    private var completedRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Completed"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Text("\(viewModel.filteredCompletedReminders.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(Color.green)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            // 已完成提醒
            ForEach(Array(viewModel.filteredCompletedReminders.enumerated()), id: \.offset) { index, reminder in
                NavigationLink(destination: ReminderDetailView(reminder: reminder)) {
                    ReminderCardView(
                        reminder: reminder,
                        isToday: false,
                        accentColor: accentColor,
                        textColor: textColor,
                        labelColor: labelColor,
                        onComplete: { reminder in
                            handleReminderCompletion(reminder)
                        },
                        onEdit: { reminder in
                            editReminder(reminder)
                        },
                        onDelete: { reminder in
                            handleReminderDeletion(reminder)
                        }
                    )
                    .padding(.horizontal)
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
    
    // MARK: - 处理提醒删除
    private func handleReminderDeletion(_ reminder: Reminder) {
        reminderToDelete = reminder
        showingDeleteAlert = true
    }
    
    // MARK: - 编辑提醒
    private func editReminder(_ reminder: Reminder) {
        // 确保没有其他模态视图正在显示
        guard !showingAddReminder && !showingReminderToRecordAlert else {
            return
        }
        
        reminderToEdit = reminder
        showingEditReminder = true
    }
}

// MARK: - 提醒卡片 - 重新设计以匹配Record风格
struct ReminderCardView: View {
    let reminder: Reminder
    let isToday: Bool
    let accentColor: Color
    let textColor: Color
    let labelColor: Color
    let onComplete: (Reminder) -> Void
    let onEdit: (Reminder) -> Void
    let onDelete: (Reminder) -> Void
    
    // 卡片颜色
    private let cardColor = Color.white
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标签和时间
            HStack {
                // 标签图标和名称
                HStack(spacing: 6) {
                    Image(systemName: reminder.tag.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(accentColor)
                        )
                    
                    Text(String(localized: LocalizedStringResource(stringLiteral: reminder.tag.name)))
                        .font(.headline)
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                // 完成按钮（今日提醒且未完成时显示）
                if isToday && !reminder.isCompletedToday {
                    Button {
                        onComplete(reminder)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                }
            }
            
            // 宠物头像（如果关联多只宠物）
            if let pets = reminder.pets, !pets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(pets) { pet in
                            if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                            } else {
                                Image(pet.petType == .dog ? "dog" : "cat")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .padding(5)
                                    .background(
                                        Circle()
                                            .fill(Color(red: 0.97, green: 0.90, blue: 0.83))
                                    )
                            }
                        }
                    }
                }
            }
            
            // 备注
            if let notes = reminder.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundColor(textColor)
                    .lineLimit(3)
            }
            
            // 重复规则和下次提醒时间
            HStack {
                if let repeatRule = reminder.repeatRuleText {
                    Text(repeatRule)
                        .font(.caption)
                        .foregroundColor(labelColor)
                }
                
                Spacer()
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(labelColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .contextMenu {
            Button {
                onEdit(reminder)
            } label: {
                Label(String(localized: "Edit"), systemImage: "pencil")
                    .foregroundColor(accentColor)
            }
            
            Button(role: .destructive) {
                onDelete(reminder)
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        }
    }
    
    // 格式化日期
    private var formattedDate: String {
        let formatter = DateFormatter()
        if isToday {
            formatter.timeStyle = .short
            return formatter.string(from: reminder.startDate)
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: reminder.startDate)
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