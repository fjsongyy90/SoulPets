import SwiftUI
import SwiftData
import os.log

struct TagManagementView: View {
    // MARK: - 属性
    @StateObject private var viewModel: TagManagementViewModel
    @Environment(\.dismiss) private var dismiss
    // 移除编辑模式，使用自定义拖动手柄
    
    // 折叠状态管理
    @State private var collapsedCategories: Set<TagCategory> = []
    
    // 调试日志
    private let logger = Logger(subsystem: "com.soulpets.app", category: "TagManagementView")
    
    // 颜色定义 - 使用统一的应用颜色
    private let backgroundColor = Color.appBackground
    private let accentColor = Color.appAccent
    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                    .font(.appBody)
                    .foregroundColor(.appAccent)
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
                logger.info("标签管理页面出现")
            }
        }
    }
    
    // MARK: - 子视图
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            Text(String(localized: "Loading tags..."))
                .font(.appBody)
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
                .font(.appHeadline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(viewModel.availablePetTypes, id: \.self) { petType in
                    petTypeButton(petType)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func petTypeButton(_ petType: PetType) -> some View {
        Button(action: {
            viewModel.selectPetType(petType)
        }) {
            HStack {
                // v1.1.0: 使用 PetType 扩展的 defaultImageName 属性获取正确的图标
                Image(petType.defaultImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                Text(petType.rawValue)
                    .font(.appBody)
                Spacer()
            }
            .padding(12)
            .background(
                viewModel.selectedPetType == petType ? 
                Color.appAccent.opacity(0.1) : Color.gray.opacity(0.1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        viewModel.selectedPetType == petType ? 
                        Color.appAccent : Color.clear, 
                        lineWidth: 1.5
                    )
            )
            .cornerRadius(12)
        }
        .foregroundColor(viewModel.selectedPetType == petType ? .primary : .secondary)
    }
    
    private var tagsList: some View {
        List {
            ForEach(viewModel.sortedCategories, id: \.self) { category in
                Section {
                    if let tags = viewModel.tagsByCategory[category] {
                        // 根据折叠状态决定是否显示标签
                        if !collapsedCategories.contains(category) {
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
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                            .onMove { source, destination in
                                logger.info("🎯 开始拖动操作 - 分类: \(category.rawValue)")
                                logger.info("🎯 源索引: \(source.description), 目标索引: \(destination)")
                                viewModel.reorderTags(in: category, from: source, to: destination)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(viewModel.getCategoryTitle(category))
                            .font(.appHeadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(viewModel.tagsByCategory[category]?.count ?? 0) tags")
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                        
                        // 折叠按钮
                        Button(action: {
                            toggleCategoryCollapse(category)
                        }) {
                            Image(systemName: collapsedCategories.contains(category) ? "chevron.right" : "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(accentColor)
                                .animation(.easeInOut(duration: 0.2), value: collapsedCategories.contains(category))
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.top, 16)
                    .textCase(.none)
                }
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tag")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(String(localized: "No Tags Available"))
                .font(.appTitle2)
                .foregroundColor(.primary)
            
            Text(String(localized: "Please add some pets first to see their tags"))
                .font(.appBody)
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
                Image(systemName: "plus")
                    .font(.title2)
                Text(String(localized: "Add Custom Tag (Pro)"))
                    .font(.appBody)
                Spacer()
                Image(systemName: "crown.fill")
                    .foregroundColor(Color(hex: "FFD700"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appAccent.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appAccent.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
            .cornerRadius(12)
        }
        .disabled(true)
        .foregroundColor(.appAccent)
    }
    
    // MARK: - 辅助方法
    
    /// 切换分类的折叠状态
    private func toggleCategoryCollapse(_ category: TagCategory) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if collapsedCategories.contains(category) {
                collapsedCategories.remove(category)
                logger.info("展开分类: \(category.rawValue)")
            } else {
                collapsedCategories.insert(category)
                logger.info("折叠分类: \(category.rawValue)")
            }
        }
    }
}

#Preview {
    // 创建预览用的ModelContext
    let schema = Schema(ModelRegistration.models)
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    
    return TagManagementView(modelContext: container.mainContext)
} 