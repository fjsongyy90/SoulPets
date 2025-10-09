import SwiftUI
import SwiftData
import OSLog

/// 记录主视图
struct RecordsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel: RecordViewModel
    @StateObject private var appState = AppState.shared
    @State private var showingAddRecordSheet = false
    @State private var showingAddPet = false
    @State private var searchText = ""
    
    // 新增状态管理
    @State private var showingPetSelector = false
    @State private var showingDatePicker = false
    @State private var showingSearchBar = false
    @State private var showingTagSelector = false
    @State private var selectedDate: Date?
    @State private var selectedTag: Tag?
    @State private var selectedRecord: Record?
    @Query private var pets: [Pet]
    @Query private var allTags: [Tag]
    
    // 日志
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "RecordView")
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    init(modelContext: ModelContext, currentPet: Pet? = nil) {
        _viewModel = StateObject(wrappedValue: RecordViewModel(modelContext: modelContext))
        // 如果传入了当前宠物，设置到全局状态中
        if let currentPet = currentPet {
            Task { @MainActor in
                AppState.shared.setSelectedPet(currentPet)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 筛选器和搜索栏（仅在有宠物时显示）
                    if !pets.isEmpty {
                        filterAndSearchView
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // 宠物选择器（展开时显示） - 添加平滑动画
                        if showingPetSelector {
                            petSelectorView
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                                .animation(.easeInOut(duration: 0.3), value: showingPetSelector)
                        }
                        
                        // 标签选择器（展开时显示） - 添加平滑动画
                        if showingTagSelector {
                            tagSelectorView
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                                .animation(.easeInOut(duration: 0.3), value: showingTagSelector)
                        }
                        
                        // 搜索栏（展开时显示） - 添加平滑动画
                        if showingSearchBar {
                            searchBarView
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                                .animation(.easeInOut(duration: 0.3), value: showingSearchBar)
                        }
                    }
                    
                    // 记录列表
                    if viewModel.records.isEmpty {
                        emptyStateView
                    } else {
                        recordsListView
                    }
                }
            }
            .navigationTitle(String(localized: "Records"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 确保没有其他模态视图正在显示
                        guard !showingDatePicker else { return }
                        showingAddRecordSheet = true
                    } label: {
                        Image("add_icon")
                            .foregroundColor(accentColor)
                    }
                }
            }
        .fullScreenCover(isPresented: $showingAddRecordSheet, onDismiss: {
            // 当添加记录的sheet关闭时，重新加载记录
            viewModel.loadRecords()
        }) {
            AddRecordView(modelContext: modelContext)
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
            .navigationDestination(item: $selectedRecord) { record in
                RecordDetailView(record: record)
            }
            .sheet(isPresented: $showingDatePicker) {
                datePickerSheet
            }
            .onChange(of: searchText) { oldValue, newValue in
                viewModel.searchText = newValue
                viewModel.loadRecords()
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                // 根据选择的日期筛选记录
                filterRecordsByDate()
            }
            .onChange(of: selectedTag) { oldValue, newValue in
                // 根据选择的标签筛选记录
                filterRecords()
            }
            .onAppear {
                logger.info("📱 Records页面onAppear开始")
                
                // 使用AppState的宠物筛选同步机制
                let filterState = appState.getRecordsPageFilter()
                logger.info("📱 Records页面获取筛选状态: \(filterState.displayName)")
                
                switch filterState {
                case .all:
                    viewModel.setShowAllPets(updateAppState: false)
                case .specific(let pet):
                    viewModel.setCurrentPet(pet, updateAppState: false)
                }
                
                viewModel.loadRecords()
                logger.info("📱 Records页面onAppear完成")
            }
            .onChange(of: appState.recordsPageFilter) { oldFilter, newFilter in
                // 🔧 关键修复：监听recordsPageFilter的变化，而不是selectedPet
                // 这样可以确保当AppState同步更新筛选状态时，UI能正确响应
                let oldName = oldFilter?.displayName ?? "nil"
                let newName = newFilter?.displayName ?? "nil"
                logger.info("📱 Records页面监听到筛选变化: \(oldName) -> \(newName)")
                
                guard let newFilter = newFilter else { 
                    logger.warning("⚠️ Records页面收到nil筛选，忽略")
                    return 
                }
                
                // 更新ViewModel状态
                switch newFilter {
                case .all:
                    logger.info("🔄 Records页面切换到所有宠物")
                    viewModel.setShowAllPets(updateAppState: false)
                case .specific(let pet):
                    logger.info("🔄 Records页面切换到宠物: \(pet.name)")
                    viewModel.setCurrentPet(pet, updateAppState: false)
                }
                
                viewModel.loadRecords()
                logger.info("✅ Records页面筛选更新完成")
            }
            .onReceive(NotificationCenter.default.publisher(for: .recordCreated)) { _ in
                // 收到记录创建通知，刷新记录列表
                viewModel.loadRecords()
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 新的筛选器和搜索栏视图
    private var filterAndSearchView: some View {
        HStack(spacing: 8) {
            // All pets 按钮 - 优化动画效果
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingPetSelector.toggle()
                    if showingPetSelector {
                        showingSearchBar = false
                        showingTagSelector = false
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    let currentFilter = appState.getRecordsPageFilter()
                    switch currentFilter {
                    case .all:
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 12))
                        Text(String(localized: "All"))
                            .font(.appCaption)
                    case .specific(let pet):
                        // 显示当前选中宠物的头像
                        if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        } else {
                            let imageName = pet.petType?.defaultImageName ?? "default_pet"
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                        Text(pet.name)
                            .font(.appCaption)
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
            
            // 日期选择按钮
            Button {
                // 确保没有其他模态视图正在显示
                guard !showingAddRecordSheet else { return }
                showingDatePicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    if let selectedDate = selectedDate {
                        Text(formatShortDate(selectedDate))
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    } else {
                        Text(String(localized: "Date"))
                            .font(.appCaption)
                    }
                }
                .foregroundColor(selectedDate != nil ? accentColor : textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(selectedDate != nil ? accentColor.opacity(0.1) : Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
            }
            
            // 标签选择按钮 - 优化动画效果
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingTagSelector.toggle()
                    if showingTagSelector {
                        showingPetSelector = false
                        showingSearchBar = false
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                        .font(.system(size: 12))
                    if let selectedTag = selectedTag {
                        Text(selectedTag.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    } else {
                        Text(String(localized: "Tag"))
                            .font(.appCaption)
                    }
                    
                    Image(systemName: showingTagSelector ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(selectedTag != nil ? accentColor : textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(selectedTag != nil ? accentColor.opacity(0.1) : Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
            }
            
            Spacer()
            
            // 搜索按钮 - 优化动画效果
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingSearchBar.toggle()
                    if showingSearchBar {
                        showingPetSelector = false
                        showingTagSelector = false
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
    
    /// 宠物选择器视图
    private var petSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All Pets" 选项
                Button {
                    // 设置记录页面的筛选状态为All（用户主动操作）
                    viewModel.setShowAllPets(updateAppState: true)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingPetSelector = false
                    }
                } label: {
                        VStack(spacing: 4) {
                            let currentFilter = appState.getRecordsPageFilter()
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
                                .font(.appCaption)
                                .foregroundColor(isAllSelected ? accentColor : textColor)
                                .fontWeight(isAllSelected ? .semibold : .regular)
                        }
                }
                
                // 各个宠物选项
                ForEach(pets) { pet in
                    Button {
                        viewModel.setCurrentPet(pet, updateAppState: true)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingPetSelector = false
                        }
                    } label: {
                        VStack(spacing: 4) {
                            let currentFilter = appState.getRecordsPageFilter()
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
                                let imageName = pet.petType?.defaultImageName ?? "default_pet"
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
                                    )
                            }
                            
                            Text(pet.name)
                                .font(.appCaption)
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
    
    /// 搜索栏视图
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(labelColor)
            
            TextField(String(localized: "Search records..."), text: $searchText)
                .foregroundColor(textColor)
                .onSubmit {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingSearchBar = false
                    }
                }
                .toolbar {
        // 键盘工具栏 - 添加Done按钮
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(String(localized: "Done")) {
                // 关闭键盘
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .foregroundColor(accentColor)
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
    
    /// 标签选择器视图
    private var tagSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // "All Tags" 选项
            HStack {
                Button {
                    selectedTag = nil
                    viewModel.selectedTag = nil
                    filterRecords()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingTagSelector = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 16))
                            .foregroundColor(selectedTag == nil ? .white : accentColor)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(selectedTag == nil ? accentColor : Color(red: 0.97, green: 0.90, blue: 0.83))
                            )
                        
                        Text(String(localized: "All Tags"))
                            .font(.appSubheadline)
                            .foregroundColor(selectedTag == nil ? accentColor : textColor)
                            .fontWeight(selectedTag == nil ? .semibold : .regular)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            
            // 获取已使用的标签
            let usedTags = getUsedTags()
            
            if !usedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(usedTags) { tag in
                            Button {
                                selectedTag = tag
                                viewModel.selectedTag = tag
                                filterRecords()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showingTagSelector = false
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    let iconName = tag.iconName
                                    Image(iconName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(selectedTag?.id == tag.id ? accentColor : Color.clear, lineWidth: 2)
                                        )
                                    
                                    Text(tag.name)
                                        .font(.caption)
                                        .foregroundColor(selectedTag?.id == tag.id ? accentColor : textColor)
                                        .fontWeight(selectedTag?.id == tag.id ? .semibold : .regular)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 60)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                    Text(String(localized: "No tags used yet"))
                        .font(.appCaption)
                        .foregroundColor(labelColor)
                        .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
    
    /// 日期选择器弹窗
    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    String(localized: "Select Date"),
                    selection: Binding(
                        get: { selectedDate ?? Date() },
                        set: { selectedDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .accentColor(accentColor)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle(String(localized: "Filter by Date"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 左侧清除按钮
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Clear")) {
                        selectedDate = nil
                        showingDatePicker = false
                    }
                    .foregroundColor(labelColor)
                }
                
                // 右侧完成按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Done")) {
                        showingDatePicker = false
                    }
                    .foregroundColor(accentColor)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            if pets.isEmpty {
                // 未添加宠物状态
                Image("empty_record")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                    .opacity(0.4) // 降低透明度显示未激活状态
                
                VStack(spacing: 20) {
                    Text(String(localized: "Every Memory is a Treasure"))
                        .font(.appSemiBold(size: 22))
                        .foregroundColor(textColor)
                    
                    Text(String(localized: "empty_state.records.subtitle"))
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
                // 有宠物但无记录状态
                Image("empty_record")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 180)
                    .clipShape(Circle()) // 裁剪成圆形
                
                VStack(spacing: 20) {
                    Text(String(localized: "No Records Yet"))
                        .font(.appSemiBold(size: 22))
                        .foregroundColor(textColor)
                    
                    Text(String(localized: "Give your bond a digital heartbeat. Add the first record."))
                        .font(.appRegular(size: 16))
                        .lineSpacing(6)
                        .foregroundColor(labelColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showingAddRecordSheet = true
                    }) {
                        Text(String(localized: "Add First Record"))
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
                .padding(.top, 40)
            }
            
            Spacer()
        }
    }
    
    /// 记录列表视图
    private var recordsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.records) { record in
                    NavigationLink(destination: RecordDetailView(record: record)) {
                        RecordCardView(
                            record: record, 
                            accentColor: accentColor, 
                            textColor: textColor, 
                            labelColor: labelColor,
                            showPetAvatars: true
                        )
                        .id("\(record.id)_\(record.pets?.map { "\($0.id)_\($0.avatar?.hashValue ?? 0)" }.joined(separator: "_") ?? "")")
                        .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button {
                            // 编辑记录 - 创建一个状态来处理导航
                            selectedRecord = record
                        } label: {
                            Label(String(localized: "Edit"), systemImage: "pencil")
                                .foregroundColor(accentColor)
                        }
                        
                        Button(role: .destructive) {
                            viewModel.deleteRecord(record)
                        } label: {
                            Label(String(localized: "Delete"), systemImage: "trash")
                        }
                    }
                }
                .padding(.top, 16)
            }
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - 辅助函数
    
    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// 格式化短日期
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    /// 根据选择的日期筛选记录
    private func filterRecordsByDate() {
        if let selectedDate = selectedDate {
            viewModel.filterRecordsByDate(selectedDate)
        } else {
            viewModel.loadRecords() // 如果没有选择日期，则加载所有记录
        }
    }
    
    /// 获取已使用的标签
    private func getUsedTags() -> [Tag] {
        // 获取所有记录中使用过的标签
        let allRecords = RecordService.getAllRecords(modelContext: modelContext)
        let usedTagIds = Set(allRecords.compactMap { $0.tag?.id })
        return allTags.filter { usedTagIds.contains($0.id) }
    }
    
    /// 综合筛选记录
    private func filterRecords() {
        // 根据当前的筛选条件重新加载记录
        if let selectedTag = selectedTag {
            viewModel.filterRecordsByTag(selectedTag)
        } else if let selectedDate = selectedDate {
            viewModel.filterRecordsByDate(selectedDate)
        } else {
            viewModel.loadRecords()
        }
    }
}

/// 记录卡片视图 - 全新设计
struct RecordCardView: View {
    let record: Record
    let accentColor: Color
    let textColor: Color
    let labelColor: Color
    let showPetAvatars: Bool
    
    // 卡片颜色 - 带有极微弱米黄的白色，营造温暖感
    private let cardColor = Color(red: 1.0, green: 0.996, blue: 0.988) // #FFFEFC
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部区域：标签信息 + 相对时间
            HStack(alignment: .top) {
                // 左侧：标签图标和名称
                HStack(spacing: 8) {
                    let iconName = record.tag?.iconName ?? "questionmark.circle"
                    Image(iconName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    
                    let tagName = record.tag?.name ?? "Unknown"
                    Text(String(localized: LocalizedStringResource(stringLiteral: tagName)))
                        .font(.appHeadline)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 右侧：人性化的相对时间
                Text(record.timestamp.formatRelativeString())
                    .font(.appCaption)
                    .foregroundColor(labelColor)
                    .lineLimit(1)
            }
            
            // 次级头部区域：宠物信息（紧随标签下方）
            if showPetAvatars, let pets = record.pets, !pets.isEmpty {
                petInfoSection(pets: pets)
            }
            
            // 内容区域：备注
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.appBody)
                    .foregroundColor(textColor)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 内容区域：照片缩略图
            if let photos = record.photos, !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photos) { photo in
                            if let uiImage = UIImage(data: photo.photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - 子视图组件
    
    /// 宠物信息区域
    @ViewBuilder
    private func petInfoSection(pets: [Pet]) -> some View {
        if pets.count == 1 {
            // 单宠物：显示头像 + 名字
            HStack(spacing: 6) {
                petAvatarView(pet: pets[0], size: 20)
                
                Text(pets[0].name)
                    .font(.appCaption)
                    .foregroundColor(labelColor)
                    .lineLimit(1)
                
                Spacer()
            }
        } else {
            // 多宠物：横向排列头像，可略带重叠效果
            HStack(spacing: -4) { // 负间距创造重叠效果
                ForEach(pets.prefix(4)) { pet in // 最多显示4个头像
                    petAvatarView(pet: pet, size: 20)
                        .overlay(
                            Circle()
                                .stroke(cardColor, lineWidth: 1) // 白色边框分离重叠的头像
                        )
                }
                
                // 如果宠物数量超过4个，显示数量标识
                if pets.count > 4 {
                    Text("+\(pets.count - 4)")
                        .font(.caption2)
                        .foregroundColor(labelColor)
                        .fontWeight(.medium)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(Color(red: 0.95, green: 0.88, blue: 0.80))
                                .overlay(
                                    Circle()
                                        .stroke(cardColor, lineWidth: 1)
                                )
                        )
                }
                
                Spacer()
            }
        }
    }
    
    /// 宠物头像视图
    @ViewBuilder
    private func petAvatarView(pet: Pet, size: CGFloat) -> some View {
        if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(Color(red: 0.95, green: 0.88, blue: 0.80))
                    .frame(width: size, height: size)
                
                let imageName = pet.petType?.defaultImageName ?? "default_pet"
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.7, height: size * 0.7)
            }
        }
    }
}

#Preview {
    RecordsView(modelContext: ModelContext(try! ModelContainer(for: Pet.self, Record.self, Tag.self, RecordPhoto.self)))
}

// MARK: - 通知名称扩展
extension Notification.Name {
    static let recordCreated = Notification.Name("recordCreated")
} 
