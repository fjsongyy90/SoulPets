import Foundation
import SwiftData
import OSLog

/// 标签管理视图模型
@MainActor
class TagManagementViewModel: ObservableObject {
    // MARK: - 属性
    @Published var tagsByCategory: [TagCategory: [Tag]] = [:]
    @Published var selectedPetType: PetType?
    @Published var availablePetTypes: [PetType] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "TagManagementViewModel")
    
    // MARK: - 初始化
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAvailablePetTypes()
    }
    
    // MARK: - 数据加载
    
    /// 加载用户拥有的宠物类型
    private func loadAvailablePetTypes() {
        do {
            let petDescriptor = FetchDescriptor<Pet>()
            let pets = try modelContext.fetch(petDescriptor)
            
            // 获取用户拥有的宠物类型
            let petTypes = Set(pets.map { $0.petType })
            availablePetTypes = Array(petTypes).sorted { $0.rawValue < $1.rawValue }
            
            // 自动选择第一个宠物类型（无论是一个还是多个）
            if !availablePetTypes.isEmpty {
                selectedPetType = availablePetTypes.first
                loadTags()
            }
            
            logger.info("加载到 \(self.availablePetTypes.count) 种宠物类型，默认选中: \(String(describing: self.selectedPetType?.rawValue))")
        } catch {
            logger.error("加载宠物类型失败: \(error.localizedDescription)")
            errorMessage = String(localized: "Failed to load pet types")
        }
    }
    
    /// 加载标签数据
    func loadTags() {
        isLoading = true
        errorMessage = nil
        
        if let petType = selectedPetType {
            // 加载特定宠物类型的标签
            tagsByCategory = TagManagementService.getTagsByCategory(for: petType, in: modelContext)
        } else {
            // 加载所有标签
            tagsByCategory = TagManagementService.getAllTagsByCategory(in: modelContext)
        }
        
        logger.info("成功加载标签数据，共 \(self.tagsByCategory.count) 个分类")
        
        isLoading = false
    }
    
    /// 选择宠物类型
    func selectPetType(_ petType: PetType) {
        selectedPetType = petType
        loadTags()
        logger.info("选择宠物类型: \(petType.rawValue)")
    }
    
    // MARK: - 标签操作
    
    /// 切换标签的提醒可用性
    func toggleReminderAvailability(for tag: Tag) {
        do {
            try TagManagementService.toggleTagReminderAvailability(tag, in: modelContext)
            logger.info("切换标签 \(tag.name) 的提醒可用性为: \(tag.defaultIsReminder)")
            
            // 刷新数据
            loadTags()
        } catch {
            logger.error("切换标签提醒可用性失败: \(error.localizedDescription)")
            errorMessage = String(localized: "Failed to update reminder availability")
        }
    }
    
    /// 切换标签可见性
    func toggleVisibility(for tag: Tag) {
        do {
            // 检查是否可以隐藏
            if !TagManagementService.isTagHidden(tag) && !TagManagementService.canHideTag(tag, in: modelContext) {
                errorMessage = String(localized: "Cannot hide tag with active reminders")
                return
            }
            
            try TagManagementService.toggleTagVisibility(tag, in: modelContext)
            logger.info("切换标签 \(tag.name) 的可见性")
            
            // 刷新数据
            loadTags()
        } catch {
            logger.error("切换标签可见性失败: \(error.localizedDescription)")
            errorMessage = String(localized: "Failed to toggle tag visibility")
        }
    }
    
    /// 重新排序标签
    func reorderTags(in category: TagCategory, from source: IndexSet, to destination: Int) {
        logger.info("开始重新排序标签 - 分类: \(category.rawValue)")
        logger.info("源索引: \(source.description), 目标索引: \(destination)")
        
        guard var tags = tagsByCategory[category] else { 
            logger.error("无法找到分类 \(category.rawValue) 的标签")
            return 
        }
        
        logger.info("当前标签顺序: \(tags.map { "\($0.name)(\($0.id.uuidString.prefix(8)))" }.joined(separator: ", "))")
        
        // 执行UI层面的重排序
        tags.move(fromOffsets: source, toOffset: destination)
        tagsByCategory[category] = tags
        
        logger.info("重排序后标签顺序: \(tags.map { "\($0.name)(\($0.id.uuidString.prefix(8)))" }.joined(separator: ", "))")
        
        // 保存到数据库
        do {
            try TagManagementService.reorderTags(in: category, newOrder: tags, in: modelContext)
            logger.info("成功保存标签排序到数据库 - 分类: \(category.rawValue)")
        } catch {
            logger.error("保存标签排序失败: \(error.localizedDescription)")
            errorMessage = String(localized: "Failed to save tag order")
            
            // 失败时恢复原始顺序
            loadTags()
        }
    }
    
    // MARK: - 辅助方法
    
    /// 获取标签使用统计
    func getUsageStats(for tag: Tag) -> (recordCount: Int, reminderCount: Int) {
        return TagManagementService.getTagUsageStats(for: tag, in: modelContext)
    }
    
    /// 检查标签是否隐藏
    func isTagHidden(_ tag: Tag) -> Bool {
        return TagManagementService.isTagHidden(tag)
    }
    
    /// 获取分类标题的本地化字符串
    func getCategoryTitle(_ category: TagCategory) -> String {
        switch category {
        case .dailyLife:
            return String(localized: "Daily Life")
        case .routineHealth:
            return String(localized: "Routine Health")
        case .groomingCleaning:
            return String(localized: "Grooming & Cleaning")
        case .homeSupplies:
            return String(localized: "Home & Supplies")
        case .medicalCare:
            return String(localized: "Medical Care")
        case .planningMilestones:
            return String(localized: "Planning & Milestones")
        }
    }
    
    /// 获取排序后的分类列表
    var sortedCategories: [TagCategory] {
        return TagCategory.allCases.filter { tagsByCategory[$0]?.isEmpty == false }
    }
    
    /// 清除错误消息
    func clearError() {
        errorMessage = nil
    }
} 