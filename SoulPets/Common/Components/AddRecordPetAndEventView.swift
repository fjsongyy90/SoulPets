import SwiftUI
import SwiftData
import PhotosUI

/// 添加记录 - 选择宠物和事件视图
struct AddRecordPetAndEventView: View {
    @ObservedObject var viewModel: RecordViewModel
    @Query private var pets: [Pet]
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]
    
    // 标签管理状态
    @State private var showingTagManagement = false
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - 宠物选择卡片
                petSelectorCard
                
                // MARK: - 标签选择部分
                tagSelectorSection
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingTagManagement) {
            TagManagementView(modelContext: viewModel.modelContext)
        }
        .onChange(of: showingTagManagement) { oldValue, newValue in
            // 当标签管理页面关闭后，重新加载标签数据
            if oldValue && !newValue {
                viewModel.loadTags()
            }
        }
    }
    
    // MARK: - 子视图组件
    
    /// 宠物选择卡片 - 优化版
    private var petSelectorCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(localized: "Select Pets"))
                .font(.appTitle3) // 使用更大的标题字体
                .foregroundColor(textColor)
                .padding(.bottom, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(pets) { pet in
                        let isSelected = viewModel.selectedPets.contains(where: { $0.id == pet.id })
                        
                        PetAvatarView(pet: pet, isSelected: isSelected, accentColor: accentColor, textColor: textColor)
                            .scaleEffect(isSelected ? 1.05 : 1.0) // 选中时轻微放大
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.togglePetSelection(pet: pet)
                                }
                            }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            
            // 优化的验证提示 - 使用精致字体
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    if !viewModel.selectedPets.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.green.opacity(0.8))
                    }
                    Text(viewModel.selectedPets.isEmpty ?
                         String(localized: "Select at least one pet") :
                         String.localizedStringWithFormat(NSLocalizedString("%d pet(s) selected", comment: ""), viewModel.selectedPets.count))
                        .font(.appCaption2) // 使用更小但清晰的字体
                        .fontWeight(.semibold) // 突出显示
                        .foregroundColor(viewModel.selectedPets.isEmpty ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(viewModel.selectedPets.isEmpty ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(viewModel.selectedPets.isEmpty ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
                Spacer()
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPets.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.6))
                .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    /// 标签选择部分 - 优化版
    private var tagSelectorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标签选择器标题和管理按钮
            HStack {
                Text(String(localized: "Select Event Type"))
                    .font(.appTitle3) // 使用更大的标题字体
                    .foregroundColor(textColor)
                
                Spacer()
                
                Button(action: {
                    showingTagManagement = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gear")
                            .font(.system(size: 12, weight: .medium))
                        Text(String(localized: "Manage Tags"))
                            .font(.appCaption)
                    }
                    .foregroundColor(accentColor)
                }
            }
            .padding(.horizontal)
            
            // 最近使用的标签 - 只在选择了宠物时显示
            if !viewModel.selectedPets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Recently Used"))
                        .font(.appSubheadline) // 使用统一的子标题字体
                        .foregroundColor(labelColor)
                        .padding(.horizontal)
                    
                    let filteredRecentTags = filterRecentlyUsedTags()
                    
                    if !filteredRecentTags.isEmpty {
                        tagGridView(tags: filteredRecentTags)
                    } else {
                        // 空状态提示
                        Text(String(localized: "No recently used tags for selected pets"))
                            .font(.appCaption)
                            .foregroundColor(labelColor.opacity(0.7))
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .italic()
                    }
                }
            }
            
            // 按分类显示标签
            ForEach(TagCategory.allCases, id: \.self) { category in
                let filteredTags = filterTags(for: category)
                if !filteredTags.isEmpty {
                    VStack(alignment: .leading) {
                        Text(String(localized: LocalizedStringResource(stringLiteral: category.rawValue)))
                            .font(.appSubheadline) // 使用统一的子标题字体
                            .foregroundColor(labelColor)
                            .padding(.horizontal)
                        
                        tagGridView(tags: filteredTags)
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    /// 标签网格视图 - 优化版
    private func tagGridView(tags: [Tag]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tags) { tag in
                    let isSelected = viewModel.selectedTag?.id == tag.id
                    
                    TagItemView(tag: tag, isSelected: isSelected, accentColor: accentColor, textColor: textColor)
                        .frame(width: 100) // 固定宽度确保一致性
                        .scaleEffect(isSelected ? 1.05 : 1.0) // 选中时轻微放大
                        .overlay(
                            // 精致边框效果
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
                        )
                        .background(
                            // 柔和背景效果
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSelected ? accentColor.opacity(0.1) : Color.clear)
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                viewModel.selectTag(tag)
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// 根据宠物类型过滤最近使用的标签
    private func filterRecentlyUsedTags() -> [Tag] {
        guard !viewModel.selectedPets.isEmpty else { return [] }
        
        // 获取选择的宠物类型
        let selectedPetTypes = Set(viewModel.selectedPets.map { $0.petType })
        
        // 过滤最近使用的标签，只保留适用于选择宠物类型的标签
        return viewModel.recentlyUsedTags.filter { tag in
            !tag.isHidden && selectedPetTypes.isSubset(of: Set(tag.getApplicablePetTypes()))
        }
    }
    
    /// 根据宠物类型和分类筛选标签
    private func filterTags(for category: TagCategory) -> [Tag] {
        // 如果没有选择宠物，返回空数组
        guard !viewModel.selectedPets.isEmpty else { return [] }
        
        // 获取所有选中宠物的类型
        let selectedPetTypes = viewModel.selectedPets.map { $0.petType }
        
        // 筛选同时适用于所有选中宠物类型的标签，并排除隐藏的标签
        return tags.filter { tag in
            // 检查标签是否属于当前分类
            guard tag.category == category else { return false }
            
            // 排除隐藏的标签
            guard !tag.isHidden else { return false }
            
            // 检查标签是否适用于所有选中的宠物类型
            return selectedPetTypes.allSatisfy { petType in
                tag.isApplicableTo(petType: petType)
            }
        }
    }
}

#Preview {
    AddRecordPetAndEventView(viewModel: RecordViewModel(modelContext: ModelContext(try! ModelContainer(for: Pet.self, Record.self, Tag.self))))
}
