import SwiftUI
import SwiftData
import OSLog

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var appState = AppState.shared
    @State private var viewModel: RemindersViewModel
    @State private var showingAddReminder = false
    @State private var showingEditReminder = false
    @State private var showingReminderToRecordAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingAddPet = false
    @State private var selectedReminderForRecord: Reminder?
    @State private var reminderToEdit: Reminder?
    @State private var reminderToDelete: Reminder?
    
    // 新增状态管理 - 参考Record模块
    @State private var showingPetSelector = false
    @State private var showingSearchBar = false
    @State private var searchText = ""
    
    @Query private var allPets: [Pet]
    
    // 日志
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "RemindersView")
    
    // 初始化
    init() {
        // 在init中我们无法访问Environment，所以先创建基础的ViewModel
        // 在onAppear时再进行默认宠物的设置
        _viewModel = State(initialValue: RemindersViewModel())
    }
    
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
                    // 筛选器和搜索栏（仅在有宠物时显示）
                    if !allPets.isEmpty {
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
            .sheet(isPresented: $showingAddPet) {
                AddPetView(modelContext: modelContext)
                    .onDisappear {
                        // 添加宠物后切换到主页tab
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                                tabBarController.selectedIndex = 0 // 切换到主页
                            }
                        }
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
            .confirmationDialog(
                String(localized: "reminder.completed_title"),
                isPresented: $showingReminderToRecordAlert,
                titleVisibility: .visible
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
            .confirmationDialog(
                String(localized: "Delete Reminder"),
                isPresented: $showingDeleteAlert,
                titleVisibility: .visible
            ) {
                Button(String(localized: "Delete"), role: .destructive) {
                    if let reminder = reminderToDelete {
                        viewModel.deleteReminder(reminder, modelContext: modelContext)
                        reminderToDelete = nil
                    }
                }
                
                Button(String(localized: "Cancel"), role: .cancel) {
                    reminderToDelete = nil
                }
            } message: {
                Text(String(localized: "This action cannot be undone."))
            }
            .onChange(of: searchText) { oldValue, newValue in
                // 实现搜索功能
                viewModel.searchText = newValue
                viewModel.loadReminders(from: modelContext)
            }
            .onAppear {
                // 使用全局状态中的选中宠物
                if let selectedPet = appState.selectedPet {
                    viewModel.setPetFilter(.specific(selectedPet))
                    logger.info("🐾 提醒页面使用全局选中的宠物: \(selectedPet.name)")
                } else if !allPets.isEmpty {
                    // 如果全局状态没有选中宠物，选择第一只宠物
                    let firstPet = allPets.first!
                    appState.setSelectedPet(firstPet)
                    viewModel.setPetFilter(.specific(firstPet))
                    logger.info("🐾 提醒页面设置默认宠物: \(firstPet.name)")
                }
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
                    if let selectedPet = appState.selectedPet {
                        // 显示当前选中宠物的头像
                        if let avatarData = selectedPet.avatar, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        } else {
                            Image(selectedPet.petType == .dog ? "pet_dog" : "pet_cat")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                        Text(selectedPet.name)
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
                    appState.setSelectedPet(nil)
                    viewModel.setPetFilter(.all)
                    withAnimation {
                        showingPetSelector = false
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 20))
                            .foregroundColor(appState.selectedPet == nil ? .white : accentColor)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(appState.selectedPet == nil ? accentColor : Color(red: 0.97, green: 0.90, blue: 0.83))
                            )
                        
                        Text(String(localized: "All"))
                            .font(.caption)
                            .foregroundColor(appState.selectedPet == nil ? accentColor : textColor)
                            .fontWeight(appState.selectedPet == nil ? .semibold : .regular)
                    }
                }
                
                // 各个宠物选项
                ForEach(allPets) { pet in
                    Button {
                        appState.setSelectedPet(pet)
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
                                            .stroke(appState.selectedPet?.id == pet.id ? accentColor : Color.clear, lineWidth: 2)
                                    )
                            } else {
                                Image(pet.petType == .dog ? "pet_dog" : "pet_cat")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(appState.selectedPet?.id == pet.id ? accentColor : Color.clear, lineWidth: 2)
                                    )
                            }
                            
                            Text(pet.name)
                                .font(.caption)
                                .foregroundColor(appState.selectedPet?.id == pet.id ? accentColor : textColor)
                                .fontWeight(appState.selectedPet?.id == pet.id ? .semibold : .regular)
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
            
            if allPets.isEmpty {
                // 未添加宠物状态
                Image("empty_reminder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                    .opacity(0.4) // 降低透明度显示未激活状态
                
                VStack(spacing: 20) {
                    Text("Add a Pet First")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                    
                    Text("You need to create a pet profile first to track their reminders.")
                        .font(.body)
                        .foregroundColor(labelColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showingAddPet = true
                    }) {
                        Text("Go to Add Pet")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(accentColor)
                            )
                    }
                }
                .padding(.top, 40)
            } else {
                // 有宠物但无提醒状态
                Image("empty_reminder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 180)
                    .clipShape(Circle()) // 裁剪成圆形
                
                VStack(spacing: 20) {
                    Text(emptyStateTitle)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                    
                    Text(emptyStateMessage)
                        .font(.body)
                        .foregroundColor(labelColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    if viewModel.selectedFilter == .upcoming {
                        Button(action: {
                            showingAddReminder = true
                        }) {
                            Text("Add First Reminder")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(accentColor)
                                )
                        }
                    }
                }
                .padding(.top, 40)
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
            return String(localized: "The digital heartbeat is peaceful. Time to enjoy the real one.")
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
                    .id("today_\(reminder.id)_\(reminder.pets?.map { "\($0.id)_\($0.avatar?.hashValue ?? 0)" }.joined(separator: "_") ?? "")")
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
                    .id("upcoming_\(reminder.id)_\(reminder.pets?.map { "\($0.id)_\($0.avatar?.hashValue ?? 0)" }.joined(separator: "_") ?? "")")
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
                    .id("completed_\(reminder.id)_\(reminder.pets?.map { "\($0.id)_\($0.avatar?.hashValue ?? 0)" }.joined(separator: "_") ?? "")")
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
            // 记录创建成功，发送通知让记录模块刷新数据
            NotificationCenter.default.post(name: .recordCreated, object: newRecord)
            logger.info("✅ 从提醒创建了新记录: \(newRecord.id), 标签: \(newRecord.tag.name)")
        } else {
            logger.error("❌ 从提醒创建记录失败")
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
                    Image(reminder.tag.iconName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                    
                    Text(String(localized: LocalizedStringResource(stringLiteral: reminder.tag.name)))
                        .font(.headline)
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                // 时间显示（所有提醒都显示时间）
                HStack(spacing: 4) {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(labelColor)
                    
                    // 如果是明天的提醒，显示"Tomorrow"标签
                    if isTomorrow {
                        Text(String(localized: "Tomorrow"))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(accentColor.opacity(0.1))
                            )
                            .foregroundColor(accentColor)
                    }
                }
            }
            
            // 第二行：备注和完成按钮
            HStack {
                // 备注（如果有的话）
                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundColor(textColor)
                        .lineLimit(3)
                } else {
                    // 如果没有备注，用空的 VStack 占位
                    VStack { }
                }
                
                Spacer()
                
                // 完成按钮（仅今天未完成的提醒显示）
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
            
            // 底部区域：左侧重复规则，右侧宠物头像
            HStack {
                // 重复规则
                if let repeatRule = reminder.repeatRuleText {
                    Text(repeatRule)
                        .font(.caption)
                        .foregroundColor(labelColor)
                }
                
                Spacer()
                
                // 宠物头像（移到右下角）
                if let pets = reminder.pets, !pets.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(pets.prefix(3)) { pet in // 最多显示3个头像，避免过度拥挤
                            if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                            } else {
                                Image(pet.petType == .dog ? "pet_dog" : "pet_cat")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(Color(red: 0.97, green: 0.90, blue: 0.83))
                                    )
                            }
                        }
                        
                        // 如果宠物数量超过3个，显示省略号
                        if pets.count > 3 {
                            Text("+\(pets.count - 3)")
                                .font(.caption2)
                                .foregroundColor(labelColor)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.97, green: 0.90, blue: 0.83))
                                )
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .contextMenu {
            // Complete 操作 - 移除限制，所有提醒都可以完成
            Button {
                onComplete(reminder)
            } label: {
                Label(String(localized: "Complete"), systemImage: "checkmark.circle")
                    .foregroundColor(.green)
            }
            
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
    
    // 格式化日期 - 自定义格式 "Aug 12, 2025 at 16:44"
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX") // 确保英文月份缩写
        return formatter.string(from: reminder.startDate)
    }
    
    // 判断是否是明天的提醒
    private var isTomorrow: Bool {
        let calendar = Calendar.current
        let startDate = reminder.startDate
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        return calendar.isDate(startDate, inSameDayAs: tomorrow)
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