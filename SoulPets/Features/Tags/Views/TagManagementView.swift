import SwiftUI
import SwiftData
import os.log

struct TagManagementView: View {
    // MARK: - 属性
    @StateObject private var viewModel: TagManagementViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .active  // 直接设置为编辑模式
    
    // 调试日志
    private let logger = Logger(subsystem: "com.soulpets.app", category: "TagManagementView")
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    // MARK: - 初始化
    init(modelContext: ModelContext) {
        self._viewModel = StateObject(wrappedValue: TagManagementViewModel(modelContext: modelContext))
    }
    
    // MARK: - 视图
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else {
                    mainContent
                }
            }
            .navigationTitle(String(localized: "Tag Management"))
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)  // 设置编辑模式环境
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
            }
            .alert(String(localized: "Error"), isPresented: .constant(viewModel.errorMessage != nil)) {
                Button(String(localized: "OK")) {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                logger.info("标签管理页面出现，EditMode: \(String(describing: editMode))")
            }
        }
    }
    
    // MARK: - 子视图
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            Text(String(localized: "Loading tags..."))
                .foregroundColor(.secondary)
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // 宠物类型选择器
            if viewModel.availablePetTypes.count > 1 {
                petTypeSelector
                    .padding(.horizontal)
                    .padding(.top)
            }
            
            // 标签列表
            if viewModel.tagsByCategory.isEmpty {
                emptyStateView
            } else {
                tagsList
            }
            
            // Pro功能预告
            proFeatureTeaser
                .padding()
        }
    }
    
    private var petTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Select Pet Type"))
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(viewModel.availablePetTypes, id: \.self) { petType in
                    petTypeButton(petType)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func petTypeButton(_ petType: PetType) -> some View {
        Button(action: {
            viewModel.selectPetType(petType)
        }) {
            HStack {
                Image(systemName: petType == .cat ? "cat.fill" : "dog.fill")
                    .font(.title2)
                Text(petType.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                if viewModel.selectedPetType == petType {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor)
                }
            }
            .padding()
            .background(
                viewModel.selectedPetType == petType ? 
                accentColor.opacity(0.1) : Color.gray.opacity(0.05)
            )
            .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }
    
    private var tagsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.sortedCategories, id: \.self) { category in
                    categorySection(category)
                }
            }
            .padding()
        }
    }
    
    private func categorySection(_ category: TagCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 分类标题
            HStack {
                Text(viewModel.getCategoryTitle(category))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(viewModel.tagsByCategory[category]?.count ?? 0) tags")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 标签列表 - 使用List来支持拖动功能
            if let tags = viewModel.tagsByCategory[category] {
                List {
                    ForEach(tags, id: \.id) { tag in
                        TagItemManagementView(
                            tag: tag,
                            onToggleReminder: {
                                logger.info("点击提醒开关 - 标签: \(tag.name)")
                                viewModel.toggleReminderAvailability(for: tag)
                            },
                            onToggleVisibility: {
                                logger.info("点击可见性开关 - 标签: \(tag.name)")
                                viewModel.toggleVisibility(for: tag)
                            },
                            usageStats: viewModel.getUsageStats(for: tag),
                            isHidden: viewModel.isTagHidden(tag)
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                    .onMove { source, destination in
                        logger.info("🎯 开始拖动操作 - 分类: \(category.rawValue)")
                        logger.info("🎯 源索引: \(source.description), 目标索引: \(destination)")
                        viewModel.reorderTags(in: category, from: source, to: destination)
                    }
                }
                .listStyle(PlainListStyle())
                .scrollDisabled(true)
                .frame(height: CGFloat(tags.count * 70)) // 根据标签数量动态设置高度
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tag")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(String(localized: "No Tags Available"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(String(localized: "Please add some pets first to see their tags"))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var proFeatureTeaser: some View {
        Button(action: {
            // 未来实现Pro功能
        }) {
            HStack {
                Image(systemName: "plus.circle")
                    .font(.title2)
                Text(String(localized: "Add Custom Tag (Pro)"))
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .disabled(true)
        .foregroundColor(.gray)
    }
}

#Preview {
    // 创建预览用的ModelContext
    let schema = Schema([Pet.self, Tag.self, Record.self, RecordPhoto.self, Weight.self, Reminder.self, ReminderCompletion.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    
    return TagManagementView(modelContext: container.mainContext)
} 