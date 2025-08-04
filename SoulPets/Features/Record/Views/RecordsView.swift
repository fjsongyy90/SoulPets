import SwiftUI
import SwiftData

/// 记录主视图
struct RecordsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: RecordViewModel
    @State private var showingAddRecordSheet = false
    @State private var searchText = ""
    @State private var currentPet: Pet?
    
    // 新增状态管理
    @State private var showingPetSelector = false
    @State private var showingDatePicker = false
    @State private var showingSearchBar = false
    @State private var selectedDate: Date?
    @Query private var pets: [Pet]
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    init(modelContext: ModelContext, currentPet: Pet? = nil) {
        _viewModel = StateObject(wrappedValue: RecordViewModel(modelContext: modelContext))
        _currentPet = State(initialValue: currentPet)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 新的筛选器和搜索栏
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
                        showingAddRecordSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddRecordSheet) {
                AddRecordView(modelContext: modelContext)
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
            .onAppear {
                // 如果传入了当前宠物，设置为当前宠物
                if let currentPet = currentPet {
                    viewModel.setCurrentPet(currentPet)
                }
                // 如果没有传入当前宠物，但viewModel已经自动设置了（只有一只宠物的情况），同步状态
                else if let vmCurrentPet = viewModel.currentPet {
                    currentPet = vmCurrentPet
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 新的筛选器和搜索栏视图
    private var filterAndSearchView: some View {
        HStack(spacing: 12) {
            // All pets 按钮
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingPetSelector.toggle()
                    if showingPetSelector {
                        showingSearchBar = false
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if let currentPet = currentPet {
                        // 显示当前选中宠物的头像
                        if let avatarData = currentPet.avatar, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                        } else {
                            Image(currentPet.petType == .dog ? "dog" : "cat")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .padding(4)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.97, green: 0.90, blue: 0.83))
                                )
                        }
                        Text(currentPet.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 14))
                        Text(String(localized: "All Pets"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Image(systemName: showingPetSelector ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
            }
            
            // 日期选择按钮
            Button {
                showingDatePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                    if let selectedDate = selectedDate {
                        Text(formatDate(selectedDate))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    } else {
                        Text(String(localized: "Date"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .foregroundColor(selectedDate != nil ? accentColor : textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(selectedDate != nil ? accentColor.opacity(0.1) : Color.white)
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
                    .font(.system(size: 16))
                    .foregroundColor(showingSearchBar ? .white : textColor)
                    .frame(width: 36, height: 36)
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
                    currentPet = nil
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
                ForEach(pets) { pet in
                    Button {
                        currentPet = pet
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
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 70))
                .foregroundColor(accentColor.opacity(0.7))
            
            Text(String(localized: "No Records"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(textColor)
            
            Text(String(localized: "Add your first record to start tracking your pet's journey."))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(labelColor)
                .padding(.horizontal, 40)
            
            Button {
                showingAddRecordSheet = true
            } label: {
                Text(String(localized: "Add Record"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(accentColor)
                    )
            }
            .padding(.top, 10)
            
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
                            showPetAvatars: viewModel.isShowingAllPets
                        )
                        .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button {
                            // 编辑记录 - 现在通过详情页实现
                        } label: {
                            Label(String(localized: "View Details"), systemImage: "eye")
                                .foregroundColor(accentColor)
                        }
                        
                        Button(role: .destructive) {
                            viewModel.deleteRecord(record)
                        } label: {
                            Label(String(localized: "Delete Record"), systemImage: "trash")
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
    
    /// 根据选择的日期筛选记录
    private func filterRecordsByDate() {
        if let selectedDate = selectedDate {
            viewModel.filterRecordsByDate(selectedDate)
        } else {
            viewModel.loadRecords() // 如果没有选择日期，则加载所有记录
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
                    Image(systemName: record.tag.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(accentColor)
                        )
                    
                    Text(String(localized: LocalizedStringResource(stringLiteral: record.tag.name)))
                        .font(.headline)
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                // 时间戳
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(labelColor)
            }
            
            // 宠物头像（如果是"所有宠物"视图）
            if showPetAvatars, let pets = record.pets, !pets.isEmpty {
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
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
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