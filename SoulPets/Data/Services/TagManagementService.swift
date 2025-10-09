import Foundation
import SwiftData
import OSLog

/// 标签管理服务，用于处理标签的个性化配置
class TagManagementService {
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "TagManagementService")
    
    // MARK: - 获取标签数据
    
    /// 获取指定宠物类型的所有标签，按分类分组
    static func getTagsByCategory(for petType: PetType, in modelContext: ModelContext) -> [TagCategory: [Tag]] {
        let descriptor = FetchDescriptor<Tag>(
            sortBy: [SortDescriptor<Tag>(\.sortOrder)]
        )
        
        do {
            let allTags = try modelContext.fetch(descriptor)
            let applicableTags = allTags.filter { tag in
                tag.isApplicableTo(petType: petType)
            }
            
            // 按分类分组，每个分类内的标签已经按sortOrder排序
            // 过滤掉category为nil的标签
            let grouped = Dictionary(grouping: applicableTags.filter { $0.category != nil }) { $0.category! }
            return grouped
        } catch {
            print("获取标签数据失败: \(error.localizedDescription)")
            return [:]
        }
    }
    
    /// 获取所有标签，按分类分组（用于多宠物类型管理）
    static func getAllTagsByCategory(in modelContext: ModelContext) -> [TagCategory: [Tag]] {
        let descriptor = FetchDescriptor<Tag>(
            sortBy: [SortDescriptor<Tag>(\.sortOrder)]
        )
        
        do {
            let allTags = try modelContext.fetch(descriptor)
            // 按分类分组，每个分类内的标签已经按sortOrder排序
            // 过滤掉category为nil的标签
            let grouped = Dictionary(grouping: allTags.filter { $0.category != nil }) { $0.category! }
            return grouped
        } catch {
            print("获取标签数据失败: \(error.localizedDescription)")
            return [:]
        }
    }
    
    // MARK: - 标签配置管理
    
    /// 更新标签的提醒可用性
    static func updateTagReminderAvailability(_ tag: Tag, isAvailableForReminders: Bool, in modelContext: ModelContext) throws {
        tag.defaultIsReminder = isAvailableForReminders
        tag.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 切换标签的提醒可用性
    static func toggleTagReminderAvailability(_ tag: Tag, in modelContext: ModelContext) throws {
        tag.defaultIsReminder.toggle()
        tag.updatedAt = Date()
        try modelContext.save()
    }
    
    // MARK: - 标签可见性管理
    
    /// 标签是否隐藏
    static func isTagHidden(_ tag: Tag) -> Bool {
        return tag.isHidden
    }
    
    /// 隐藏标签
    static func hideTag(_ tag: Tag, in modelContext: ModelContext) throws {
        if !tag.isHidden {
            tag.isHidden = true
            tag.updatedAt = Date()
            try modelContext.save()
        }
    }
    
    /// 显示标签
    static func showTag(_ tag: Tag, in modelContext: ModelContext) throws {
        if tag.isHidden {
            tag.isHidden = false
            tag.updatedAt = Date()
            try modelContext.save()
        }
    }
    
    /// 切换标签可见性
    static func toggleTagVisibility(_ tag: Tag, in modelContext: ModelContext) throws {
        tag.isHidden.toggle()
        tag.updatedAt = Date()
        try modelContext.save()
    }
    
    // MARK: - 标签排序管理
    
    /// 更新同一分类内标签的排序
    static func reorderTags(in category: TagCategory, newOrder: [Tag], in modelContext: ModelContext) throws {
        // 现在真正实现排序持久化
        for (index, tag) in newOrder.enumerated() {
            tag.sortOrder = index
            tag.updatedAt = Date()
        }
        
        try modelContext.save()
    }
    
    // MARK: - 统计信息
    
    /// 获取标签使用统计
    static func getTagUsageStats(for tag: Tag, in modelContext: ModelContext) -> (recordCount: Int, reminderCount: Int) {
        do {
            // 统计使用此标签的记录数量
            let tagId = tag.id
            
            // 由于tag现在是可选的，需要手动过滤
            let allRecords = try modelContext.fetch(FetchDescriptor<Record>())
            let recordCount = allRecords.filter { $0.tag?.id == tagId }.count
            
            // 统计使用此标签的提醒数量
            let allReminders = try modelContext.fetch(FetchDescriptor<Reminder>())
            let reminderCount = allReminders.filter { $0.tag?.id == tagId }.count
            
            return (recordCount: recordCount, reminderCount: reminderCount)
        } catch {
            print("获取标签使用统计失败: \(error.localizedDescription)")
            return (recordCount: 0, reminderCount: 0)
        }
    }
    
    // MARK: - 验证方法
    
    /// 验证标签是否可以被隐藏（检查是否有正在使用的提醒）
    static func canHideTag(_ tag: Tag, in modelContext: ModelContext) -> Bool {
        // 检查是否有使用此标签的活跃提醒
        do {
            let tagId = tag.id
            
            // 由于tag现在是可选的，需要手动过滤
            let allReminders = try modelContext.fetch(FetchDescriptor<Reminder>())
            let activeReminders = allReminders.filter { $0.tag?.id == tagId }
            
            // 如果有活跃的提醒使用此标签，建议不要隐藏
            return activeReminders.isEmpty
        } catch {
            print("检查标签使用情况失败: \(error.localizedDescription)")
            return true // 出错时允许隐藏
        }
    }
} 