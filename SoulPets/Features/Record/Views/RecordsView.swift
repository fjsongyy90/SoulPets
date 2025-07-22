import SwiftUI
import SwiftData

/// 记录主视图
struct RecordsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: RecordViewModel
    @State private var showingAddRecordSheet = false
    @State private var searchText = ""
    
    // 背景和强调色
    private let backgroundColor = Color(red: 0.99, green: 0.98, blue: 0.94)
    private let accentColor = Color(red: 0.69, green: 0.45, blue: 0.25)
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: RecordViewModel(modelContext: modelContext))
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
            .navigationTitle(LocalizedStringKey("Records"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddRecordSheet = true
                    } label: {
                        Image(systemName: "plus")
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
        }
    }
    
    // MARK: - 子视图
    
    /// 宠物筛选器视图
    private var petFilterView: some View {
        HStack {
            Text("Filter:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("", selection: Binding(
                get: { viewModel.isShowingAllPets },
                set: { viewModel.togglePetFilter(isAllPets: $0) }
            )) {
                Text(LocalizedStringKey("All Pets")).tag(true)
                // 这里应该动态显示当前选择的宠物名称
                Text("Current Pet").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Spacer()
        }
    }
    
    /// 搜索栏视图
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(LocalizedStringKey("Search records..."), text: $searchText)
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
            
            Text(LocalizedStringKey("No Records"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(LocalizedStringKey("Add your first record to start tracking your pet's journey."))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button {
                showingAddRecordSheet = true
            } label: {
                Text(LocalizedStringKey("Add Record"))
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
                    RecordCardView(record: record)
                        .padding(.horizontal)
                        .contextMenu {
                            Button {
                                // 编辑记录
                            } label: {
                                Label(LocalizedStringKey("Edit Record"), systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                viewModel.deleteRecord(record)
                            } label: {
                                Label(LocalizedStringKey("Delete Record"), systemImage: "trash")
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
    
    // 卡片颜色
    private let cardColor = Color.white
    private let accentColor = Color(red: 0.69, green: 0.45, blue: 0.25)
    
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
                    
                    Text(LocalizedStringKey(record.tag.name))
                        .font(.headline)
                }
                
                Spacer()
                
                // 时间戳
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 宠物头像（如果是"所有宠物"视图）
            if let pets = record.pets, !pets.isEmpty {
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
                    .foregroundColor(.primary)
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