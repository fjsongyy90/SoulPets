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
    @State private var selectedReminderForNavigation: Reminder? // 程序化导航状态
    
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddReminder = true
                    } label: {
                        Image("add_icon")
                            .foregroundColor(accentColor)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingAddReminder) {
                AddEditReminderView(modelContext: modelContext)
                    .onDisappear {
                        viewModel.loadReminders(from: modelContext)
                    }
            }
            .fullScreenCover(isPresented: $showingAddPet) {
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
                    AddEditReminderView(reminderToEdit: reminder, modelContext: modelContext)
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
                logger.info("📱 Reminders页面onAppear开始")
                
                // 🔧 修复：避免重复标记为手动修改，只获取筛选状态
                let filterState = appState.getRemindersPageFilter()
                logger.info("📱 Reminders页面获取筛选状态: \(filterState.displayName)")
                
                switch filterState {
                case .all:
                    viewModel.setPetFilter(.all, updateAppState: false)
                    logger.info("🐾 提醒页面恢复筛选状态: 所有宠物")
                case .specific(let pet):
                    viewModel.setPetFilter(.specific(pet), updateAppState: false)
                    logger.info("🐾 提醒页面恢复筛选状态: \(pet.name)")
                }
                
                viewModel.loadReminders(from: modelContext)
                logger.info("📱 Reminders页面onAppear完成")
            }
            .onChange(of: appState.remindersPageFilter) { oldFilter, newFilter in
                // 🔧 关键修复：监听remindersPageFilter的变化，而不是selectedPet
                // 这样可以确保当AppState同步更新筛选状态时，UI能正确响应
                let oldName = oldFilter?.displayName ?? "nil"
                let newName = newFilter?.displayName ?? "nil"
                logger.info("📱 Reminders页面监听到筛选变化: \(oldName) -> \(newName)")
                
                guard let newFilter = newFilter else { 
                    logger.warning("⚠️ Reminders页面收到nil筛选，忽略")
                    return 
                }
                
                // 更新ViewModel状态
                switch newFilter {
                case .all:
                    viewModel.setPetFilter(.all, updateAppState: false)
                    logger.info("🔄 Reminders页面切换到所有宠物")
                case .specific(let pet):
                    viewModel.setPetFilter(.specific(pet), updateAppState: false)
                    logger.info("🔄 Reminders页面切换到宠物: \(pet.name)")
                }
                
                viewModel.loadReminders(from: modelContext)
                logger.info("✅ Reminders页面筛选更新完成")
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
                    let currentFilter = appState.getRemindersPageFilter()
                    switch currentFilter {
                    case .all:
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 12))
                        Text(String(localized: "All"))
                            .font(.caption)
                            .fontWeight(.medium)
                    case .specific(let pet):
                        // 显示当前选中宠物的头像
                        if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        } else {
                            Image(pet.petType == .dog ? "pet_dog" : "pet_cat")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                        Text(pet.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
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
                    // 设置提醒页面的筛选状态为All（用户主动操作）
                    viewModel.setPetFilter(.all, updateAppState: true)
                    withAnimation {
                        showingPetSelector = false
                    }
                } label: {
                        VStack(spacing: 4) {
                            let currentFilter = appState.getRemindersPageFilter()
                            let isAllSelected = (currentFilter == .all)
                            
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 20))
                                .foregroundColor(isAllSelected ? .white : accentColor)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(isAllSelected ? accentColor : Color(red: 0.97, green: 0.90, blue: 0.83))
                                )
                            
                            Text(String(localized: "All"))
                                .font(.caption)
                                .foregroundColor(isAllSelected ? accentColor : textColor)
                                .fontWeight(isAllSelected ? .semibold : .regular)
                        }
                }
                
                // 各个宠物选项
                ForEach(allPets) { pet in
                    Button {
                        viewModel.setPetFilter(.specific(pet), updateAppState: true)
                        withAnimation {
                            showingPetSelector = false
                        }
                    } label: {
                        VStack(spacing: 4) {
                            let currentFilter = appState.getRemindersPageFilter()
                            let isSelected = (currentFilter == .specific(pet))
                            
                            if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
                                    )
                            } else {
                                Image(pet.petType == .dog ? "pet_dog" : "pet_cat")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
                                    )
                            }
                            
                            Text(pet.name)
                                .font(.caption)
                                .foregroundColor(isSelected ? accentColor : textColor)
                                .fontWeight(isSelected ? .semibold : .regular)
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
                    Text("Never Miss a Moment of Care")
                        .font(.appSemiBold(size: 22))
                        .foregroundColor(textColor)
                    
                    Text(String(localized: "empty_state.reminders.subtitle"))
                        .font(.appRegular(size: 16))
                        .lineSpacing(6)
                        .foregroundColor(labelColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showingAddPet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                            
                                                    Text(String(localized: "Add Your First Pet"))
                            .font(.appSemiBold(size: 17))
                        }
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
                        .font(.appSemiBold(size: 22))
                        .foregroundColor(textColor)
                    
                    Text(emptyStateMessage)
                        .font(.appRegular(size: 16))
                        .lineSpacing(6)
                        .foregroundColor(labelColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    if viewModel.selectedFilter == .upcoming {
                        Button(action: {
                            showingAddReminder = true
                        }) {
                            Text("Add First Reminder")
                                .font(.appSemiBold(size: 17))
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
        .navigationDestination(item: $selectedReminderForNavigation) { reminder in
            ReminderDetailView(reminder: reminder)
        }
    }
    
    // MARK: - 今日待办部分 - TabView分页布局
    private var todayRemindersSection: some View {
        VStack(alignment: .leading, spacing: 20) { // 增加spacing从16到20
            // 标题区域 - 移除计数徽章，简化视觉层次
            VStack(alignment: .leading, spacing: 6) { // 增加标题和副标题间距
                Text(String(localized: "Today's To-do"))
                    .font(.appTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                
                Text(String(localized: "Time to show some love"))
                    .font(.appCaption)
                    .foregroundColor(labelColor)
            }
            .padding(.horizontal)
            .padding(.top, 12) // 与上方筛选器增加间距
            
            // TabView分页的今日待办卡片
            if !viewModel.filteredTodayReminders.isEmpty {
                TabView {
                    ForEach(Array(viewModel.filteredTodayReminders.enumerated()), id: \.offset) { index, reminder in
                        TodayReminderCardView(
                            reminder: reminder,
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
                        .onTapGesture {
                            selectedReminderForNavigation = reminder
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 隐藏页面指示器
                .frame(height: 280) // 匹配卡片高度
            }
        }
    }
    
    // MARK: - 未来安排部分 - 纵向滚动紧凑卡片
    private var upcomingRemindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题区域
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Upcoming Plans"))
                        .font(.appTitle3)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    
                    Text(String(localized: "Stay prepared for what's ahead"))
                        .font(.appCaption)
                        .foregroundColor(labelColor)
                }
                
                Spacer()
                
                // 计数标签
                if viewModel.filteredUpcomingReminders.count > 0 {
                    Text("\(viewModel.filteredUpcomingReminders.count)")
                        .font(.appCaption)
                        .fontWeight(.medium)
                        .foregroundColor(labelColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(labelColor.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal)
            
            // 纵向滚动的未来安排卡片
            LazyVStack(spacing: 8) {
                ForEach(Array(viewModel.filteredUpcomingReminders.enumerated()), id: \.offset) { index, reminder in
                    UpcomingReminderCardView(
                        reminder: reminder,
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
                    .onTapGesture {
                        selectedReminderForNavigation = reminder
                    }
                }
            }
            .padding(.horizontal)
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
            
            // 已完成提醒 - 使用未来安排卡片样式
            LazyVStack(spacing: 8) {
                ForEach(Array(viewModel.filteredCompletedReminders.enumerated()), id: \.offset) { index, reminder in
                    UpcomingReminderCardView(
                        reminder: reminder,
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
                    .onTapGesture {
                        selectedReminderForNavigation = reminder
                    }
                }
            }
            .padding(.horizontal)
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

// MARK: - 今日待办卡片 - 情感化大卡片设计
struct TodayReminderCardView: View {
    let reminder: Reminder
    let accentColor: Color
    let textColor: Color
    let labelColor: Color
    let onComplete: (Reminder) -> Void
    let onEdit: (Reminder) -> Void
    let onDelete: (Reminder) -> Void
    
    // 卡片尺寸 - 大卡片设计，接近屏幕宽度
    private let cardColor = Color(red: 1.0, green: 0.996, blue: 0.988) // 温暖白色
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var isCompleted: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // 顶部：大幅精美插画区域 - 逾期状态环境色染色
                ZStack {
                    // 背景渐变 - 根据逾期状态调整颜色
                    LinearGradient(
                        colors: isOverdue ? [
                            Color.appWarning.opacity(0.15),
                            Color.appWarning.opacity(0.08)
                        ] : [
                            Color(red: 0.98, green: 0.94, blue: 0.88),
                            Color(red: 0.96, green: 0.92, blue: 0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // 标签图标 - 放大显示作为情感化插画
                    VStack {
                        Image(reminder.tag.iconName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72) // 稍微增大图标
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 120) // 增加插画区域高度
                .clipShape(
                    .rect(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 16
                    )
                )
                
                // 中部：大号标题和状态
                VStack(alignment: .leading, spacing: 12) {
                    // 提醒标题 - 增强字体层级
                    Text(String(localized: LocalizedStringResource(stringLiteral: reminder.tag.name)))
                        .font(.appTitle2) // 从Title3升级到Title2
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // 状态信息 - 逾期提醒特殊处理
                    HStack {
                        if isOverdue {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.appWarning)
                                
                                Text("overdue \(overdueDays) days")
                                    .font(.appFootnote) // 稍微增大字体
                                    .fontWeight(.semibold)
                                    .foregroundColor(.appWarning)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.appWarning.opacity(0.15))
                            )
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(accentColor)
                                
                                Text("Today")
                                    .font(.appFootnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(accentColor)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(accentColor.opacity(0.1))
                            )
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 8) // 添加底部间距
                
                Spacer()
                
                // 底部：宠物信息行 + 滑动完成交互
                VStack(spacing: 10) {
                    // 宠物信息行 - 重新布局
                    HStack(alignment: .center) {
                        // 左侧：宠物头像和名字
                        if let pets = reminder.pets, !pets.isEmpty {
                            HStack(spacing: 8) {
                                // 显示第一个宠物的头像
                                let firstPet = pets[0]
                                if let avatarData = firstPet.avatar, let uiImage = UIImage(data: avatarData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 24, height: 24)
                                        .clipShape(Circle())
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 0.95, green: 0.88, blue: 0.80))
                                            .frame(width: 24, height: 24)
                                        
                                        Image(firstPet.petType == .dog ? "pet_dog" : "pet_cat")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 16, height: 16)
                                    }
                                }
                                
                                if pets.count == 1 {
                                    Text(firstPet.name)
                                        .font(.appSubheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(textColor)
                                        .lineLimit(1)
                                } else {
                                    Text("\(firstPet.name) +\(pets.count - 1)")
                                        .font(.appSubheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(textColor)
                                        .lineLimit(1)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // 右侧：时间信息
                        Text(formattedTime)
                            .font(.appSubheadline)
                            .fontWeight(.medium)
                            .foregroundColor(labelColor)
                    }
                    
                    // 滑动完成交互轨道
                    swipeToCompleteTrack(geometry: geometry)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
            }
        }
        .frame(width: max(300, UIScreen.main.bounds.width - 48), height: 280) // 增加高度确保内容完整显示
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .scaleEffect(isCompleted ? 0.95 : 1.0)
        .opacity(isCompleted ? 0.8 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
        .contextMenu {
            Button {
                completeReminder()
            } label: {
                Label(String(localized: "Complete"), systemImage: "checkmark.circle")
                    .foregroundColor(.appSuccess)
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
    
    // MARK: - 计算属性
    
    // 获取提醒的实际显示日期（下一次发生的日期）
    private var actualReminderDate: Date {
        return ReminderService.getNextReminderDate(for: reminder) ?? reminder.startDate
    }
    
    // 判断是否逾期
    private var isOverdue: Bool {
        let calendar = Calendar.current
        let comparison = calendar.compare(actualReminderDate, to: Date(), toGranularity: .day)
        return comparison == .orderedAscending
    }
    
    // 逾期天数
    private var overdueDays: Int {
        if isOverdue {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: actualReminderDate, to: Date())
            return components.day ?? 0
        }
        return 0
    }
    
    // 格式化时间
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: actualReminderDate)
    }
    
    // MARK: - 滑动完成交互
    
    @ViewBuilder
    private func swipeToCompleteTrack(geometry: GeometryProxy) -> some View {
        let trackWidth = geometry.size.width - 36 // 减去左右padding
        let pawSize: CGFloat = 32
        let maxDragDistance = trackWidth - pawSize - 16
        
        ZStack(alignment: .leading) {
            // 轨道背景
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 40)
            
            // 进度填充
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.appSuccess.opacity(0.3), .appSuccess.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(pawSize + 8, dragOffset + pawSize + 8), height: 40)
                .animation(.easeOut(duration: 0.2), value: dragOffset)
            
            // 爪印图标 - 可拖拽
            HStack {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDragging ? .white : .appSuccess)
                    .frame(width: pawSize, height: pawSize)
                    .background(
                        Circle()
                            .fill(isDragging ? .appSuccess : Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                    )
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                // 限制拖拽范围
                                dragOffset = min(max(0, value.translation.width), maxDragDistance)
                            }
                            .onEnded { value in
                                isDragging = false
                                
                                // 如果拖拽超过80%的距离，完成任务
                                if dragOffset > maxDragDistance * 0.8 {
                                    completeReminder()
                                } else {
                                    // 否则弹回起始位置
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
                
                Spacer()
                
                // 提示文字
                if dragOffset < maxDragDistance * 0.3 {
                    Text(String(localized: "Swipe to complete"))
                        .font(.appCaption)
                        .foregroundColor(labelColor.opacity(0.7))
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func completeReminder() {
        // 播放愉悦的完成动画
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isCompleted = true
            dragOffset = 0
        }
        
        // 延迟调用完成回调，让动画播放
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete(reminder)
        }
        
        // 可以在这里添加更多愉悦的反馈，比如触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - 未来安排卡片 - 信息密度高的紧凑设计
struct UpcomingReminderCardView: View {
    let reminder: Reminder
    let accentColor: Color
    let textColor: Color
    let labelColor: Color
    let onComplete: (Reminder) -> Void
    let onEdit: (Reminder) -> Void
    let onDelete: (Reminder) -> Void
    
    private let cardColor = Color(red: 1.0, green: 0.996, blue: 0.988)
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧：标签图标 + 提醒标题
            HStack(spacing: 10) {
                // 小图标
                Image(reminder.tag.iconName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    // 提醒标题
                    Text(String(localized: LocalizedStringResource(stringLiteral: reminder.tag.name)))
                        .font(.appSubheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                    
                    // 关联宠物
                    if let pets = reminder.pets, !pets.isEmpty {
                        HStack(spacing: -2) {
                            ForEach(pets.prefix(3)) { pet in
                                if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 16, height: 16)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(cardColor, lineWidth: 1)
                                        )
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 0.95, green: 0.88, blue: 0.80))
                                            .frame(width: 16, height: 16)
                                        
                                        Image(pet.petType == .dog ? "pet_dog" : "pet_cat")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 10, height: 10)
                                    }
                                    .overlay(
                                        Circle()
                                            .stroke(cardColor, lineWidth: 1)
                                    )
                                }
                            }
                            
                            if pets.count > 3 {
                                Text("+\(pets.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(labelColor)
                                    .frame(width: 16, height: 16)
                                    .background(
                                        Circle()
                                            .fill(Color(red: 0.95, green: 0.88, blue: 0.80))
                                            .overlay(
                                                Circle()
                                                    .stroke(cardColor, lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // 右侧：倒计时和具体日期
            VStack(alignment: .trailing, spacing: 4) {
                // 倒计时
                if !countdownText.isEmpty {
                    Text(countdownText)
                        .font(.appFootnote)
                        .fontWeight(.semibold)
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.1))
                        )
                }
                
                // 具体日期
                Text(formattedDate)
                    .font(.appCaption)
                    .foregroundColor(labelColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
        .contextMenu {
            Button {
                onComplete(reminder)
            } label: {
                Label(String(localized: "Complete"), systemImage: "checkmark.circle")
                    .foregroundColor(.appSuccess)
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
    
    // MARK: - 计算属性
    
    // 获取提醒的实际显示日期（下一次发生的日期）
    private var actualReminderDate: Date {
        return ReminderService.getNextReminderDate(for: reminder) ?? reminder.startDate
    }
    
    // 倒计时文本
    private var countdownText: String {
        let calendar = Calendar.current
        let today = Date()
        
        if let days = calendar.dateComponents([.day], from: today, to: actualReminderDate).day {
            if days == 1 {
                return String(localized: "Tomorrow")
            } else if days > 1 {
                return String(localized: "In \(days) days")
            }
        }
        
        return ""
    }
    
    // 格式化日期
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: actualReminderDate)
    }
}

// MARK: - PetFilter 扩展
extension RemindersViewModel.PetFilter {
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
