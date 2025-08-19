import SwiftUI
import SwiftData

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
                        
                        // 宠物选择器（展开时显示）
                        if showingPetSelector {
                            petSelectorView
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        
                        // 标签选择器（展开时显示）
                        if showingTagSelector {
                            tagSelectorView
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
                    
                    // 记录列表
                    if viewModel.records.isEmpty {
                        emptyStateView
                    } else {
                        recordsListView
                    }
                }
            }
            .navigationTitle(String(localized: "Records"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 确保没有其他模态视图正在显示
                        guard !showingDatePicker else { return }
                        showingAddRecordSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(accentColor)
                    }
                }
            }
        .sheet(isPresented: $showingAddRecordSheet, onDismiss: {
            // 当添加记录的sheet关闭时，重新加载记录
            viewModel.loadRecords()
        }) {
            AddRecordView(modelContext: modelContext)
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
            .navigationDestination(item: $selectedRecord) { record in
                RecordDetailView(record: record)
            }
            .sheet(isPresented: $showingDatePicker) {
                datePickerSheet
                    .onDisappear {
                        // 确保在日期选择器关闭时清理状态
                        selectedDate = nil
                    }
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
                // 使用全局状态中的选中宠物
                if let selectedPet = appState.selectedPet {
                    viewModel.setCurrentPet(selectedPet)
                    viewModel.isShowingAllPets = false
                } else if !pets.isEmpty {
                    // 如果全局状态没有选中宠物，选择第一只宠物
                    let firstPet = pets.first!
                    appState.setSelectedPet(firstPet)
                    viewModel.setCurrentPet(firstPet)
                    viewModel.isShowingAllPets = false
                }
                viewModel.loadRecords()
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
            // All pets 按钮
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingPetSelector.toggle()
                    if showingPetSelector {
                        showingSearchBar = false
                        showingTagSelector = false
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
                            .font(.appCaption)
                            .lineLimit(1)
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 12))
                        Text(String(localized: "All"))
                            .font(.appCaption)
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
            
            // 标签选择按钮
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
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
            
            // 搜索按钮
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
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
                    appState.setSelectedPet(nil)
                    viewModel.currentPet = nil
                    viewModel.isShowingAllPets = true
                    viewModel.loadRecords()
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
                            .font(.appCaption)
                            .foregroundColor(appState.selectedPet == nil ? accentColor : textColor)
                            .fontWeight(appState.selectedPet == nil ? .semibold : .regular)
                    }
                }
                
                // 各个宠物选项
                ForEach(pets) { pet in
                    Button {
                        appState.setSelectedPet(pet)
                        viewModel.setCurrentPet(pet)
                        viewModel.isShowingAllPets = false
                        viewModel.loadRecords()
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
                                .font(.appCaption)
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
    
    /// 搜索栏视图
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(labelColor)
            
            TextField(String(localized: "Search records..."), text: $searchText)
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
    
    /// 标签选择器视图
    private var tagSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // "All Tags" 选项
            HStack {
                Button {
                    selectedTag = nil
                    viewModel.selectedTag = nil
                    filterRecords()
                    withAnimation {
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
                                withAnimation {
                                    showingTagSelector = false
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(tag.iconName)
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
                
                HStack(spacing: 16) {
                    // 清除日期按钮
                    Button {
                        selectedDate = nil
                        showingDatePicker = false
                    } label: {
                        Text(String(localized: "Clear"))
                            .font(.headline)
                            .foregroundColor(labelColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(labelColor, lineWidth: 1)
                            )
                    }
                    
                    // 确认按钮
                    Button {
                        showingDatePicker = false
                    } label: {
                        Text(String(localized: "Done"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(accentColor)
                            )
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle(String(localized: "Filter by Date"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Cancel")) {
                        showingDatePicker = false
                    }
                    .foregroundColor(accentColor)
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
                    Text("Add a Pet First")
                        .font(.appTitle2)
                        .foregroundColor(textColor)
                    
                    Text("You need to create a pet profile first to track their records.")
                        .font(.appBody)
                        .foregroundColor(labelColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showingAddPet = true
                    }) {
                        Text("Go to Add Pet")
                            .font(.appHeadline)
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
                    Text("No Records Yet")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                    
                    Text("Give your bond a digital heartbeat. Add the first record.")
                        .font(.body)
                        .foregroundColor(labelColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showingAddRecordSheet = true
                    }) {
                        Text("Add First Record")
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
        let usedTagIds = Set(allRecords.map { $0.tag.id })
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

/// 记录卡片视图
struct RecordCardView: View {
    let record: Record
    let accentColor: Color
    let textColor: Color
    let labelColor: Color
    let showPetAvatars: Bool
    
    // 卡片颜色
    private let cardColor = Color.white
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标签和时间
            HStack {
                // 标签图标和名称
                HStack(spacing: 6) {
                    Image(record.tag.iconName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    
                    Text(String(localized: LocalizedStringResource(stringLiteral: record.tag.name)))
                        .font(.appHeadline)
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                // 时间戳（移到原来宠物头像的位置）
                Text(formattedDate)
                    .font(.appSubheadline)
                    .foregroundColor(labelColor)
            }
            
            // 备注
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.appBody)
                    .foregroundColor(textColor)
                    .lineLimit(3)
            }
            
            // 照片缩略图
            if let photos = record.photos, !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photos) { photo in
                            if let uiImage = UIImage(data: photo.photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            
            // 底部区域：左侧空白，右侧宠物头像
            HStack {
                Spacer()
                
                // 宠物头像（移到右下角）
                if showPetAvatars, let pets = record.pets, !pets.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(pets.prefix(3)) { pet in // 最多显示3个头像，避免过度拥挤
                            if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.97, green: 0.90, blue: 0.83))
                                        .frame(width: 24, height: 24)
                                    
                                    Image(pet.petType == .dog ? "pet_dog" : "pet_cat")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 18, height: 18)
                                        .clipShape(Circle())
                                }
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
    }
    
    // 格式化日期
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: record.timestamp)
    }
}

#Preview {
    RecordsView(modelContext: ModelContext(try! ModelContainer(for: Pet.self, Record.self, Tag.self, RecordPhoto.self)))
}

// MARK: - 通知名称扩展
extension Notification.Name {
    static let recordCreated = Notification.Name("recordCreated")
} 
