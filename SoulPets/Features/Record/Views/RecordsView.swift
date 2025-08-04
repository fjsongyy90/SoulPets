import SwiftUI
import SwiftData

/// 记录主视图
struct RecordsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: RecordViewModel
    @State private var showingAddRecordSheet = false
    @State private var searchText = ""
    @State private var currentPet: Pet?
    
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
                    // 宠物筛选器
                    petFilterView
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // 搜索栏
                    searchBarView
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
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
            .onChange(of: searchText) { oldValue, newValue in
                viewModel.searchText = newValue
                viewModel.loadRecords()
            }
            .onAppear {
                if let currentPet = currentPet {
                    viewModel.setCurrentPet(currentPet)
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 宠物筛选器视图
    private var petFilterView: some View {
        HStack {
            Text(String(localized: "Filter:"))
                .font(.subheadline)
                .foregroundColor(labelColor)
            
            Picker("", selection: Binding(
                get: { viewModel.isShowingAllPets },
                set: { viewModel.togglePetFilter(isAllPets: $0) }
            )) {
                Text(String(localized: "All Pets")).tag(true)
                if let currentPet = currentPet {
                    Text(currentPet.name).tag(false)
                } else {
                    Text(String(localized: "Current Pet")).tag(false)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .accentColor(accentColor)
            
            Spacer()
        }
    }
    
    /// 搜索栏视图
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(labelColor)
            
            TextField(String(localized: "Search records..."), text: $searchText)
                .foregroundColor(textColor)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
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