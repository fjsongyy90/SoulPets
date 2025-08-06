import Foundation
import SwiftData
import OSLog

/// 标签管理服务，用于处理标签的个性化配置
class TagManagementService {
    private let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "TagManagementService")
    
    // MARK: - 获取标签数据
    
    /// 获取指定宠物类型的所有标签，按分类分组
    static func getTagsByCategory(for petType: PetType, in modelContext: ModelContext) -> [TagCategory: [Tag]] {
        let descriptor = FetchDescriptor<Tag>()
        
        do {
            let allTags = try modelContext.fetch(descriptor)
            let applicableTags = allTags.filter { tag in
                tag.isApplicableTo(petType: petType)
            }
            
            // 按分类分组
            let grouped = Dictionary(grouping: applicableTags) { $0.category }
            return grouped
        } catch {
            print("获取标签数据失败: \(error.localizedDescription)")
            return [:]
        }
    }
    
    /// 获取所有标签，按分类分组（用于多宠物类型管理）
    static func getAllTagsByCategory(in modelContext: ModelContext) -> [TagCategory: [Tag]] {
        let descriptor = FetchDescriptor<Tag>()
        
        do {
            let allTags = try modelContext.fetch(descriptor)
            let grouped = Dictionary(grouping: allTags) { $0.category }
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
    
    /// 标签是否隐藏（通过标签名称前缀判断）
    static func isTagHidden(_ tag: Tag) -> Bool {
        return tag.name.hasPrefix("[Hidden]")
    }
    
    /// 隐藏标签
    static func hideTag(_ tag: Tag, in modelContext: ModelContext) throws {
        if !isTagHidden(tag) {
            tag.name = "[Hidden] \(tag.name)"
            tag.updatedAt = Date()
            try modelContext.save()
        }
    }
    
    /// 显示标签
    static func showTag(_ tag: Tag, in modelContext: ModelContext) throws {
        if isTagHidden(tag) {
            tag.name = tag.name.replacingOccurrences(of: "[Hidden] ", with: "")
            tag.updatedAt = Date()
            try modelContext.save()
        }
    }
    
    /// 切换标签可见性
    static func toggleTagVisibility(_ tag: Tag, in modelContext: ModelContext) throws {
        if isTagHidden(tag) {
            try showTag(tag, in: modelContext)
        } else {
            try hideTag(tag, in: modelContext)
        }
    }
    
    // MARK: - 标签排序管理
    
    /// 更新同一分类内标签的排序
    /// 注意：由于SwiftData的限制，这里通过修改标签的code来实现排序
    /// 在实际应用中，可以考虑添加一个sortOrder字段
    static func reorderTags(in category: TagCategory, newOrder: [Tag], in modelContext: ModelContext) throws {
        // 为了简化实现，这里暂时不修改数据库中的排序
        // 在UI层面通过数组排序来实现用户自定义排序
        // 如果需要持久化排序，可以在Tag模型中添加sortOrder字段
        
        for (_, tag) in newOrder.enumerated() {
            tag.updatedAt = Date()
            // 可以在这里添加sortOrder字段的更新
            // tag.sortOrder = index
        }
        
        try modelContext.save()
    }
    
    // MARK: - 统计信息
    
    /// 获取标签使用统计
    static func getTagUsageStats(for tag: Tag, in modelContext: ModelContext) -> (recordCount: Int, reminderCount: Int) {
        do {
            // 统计使用此标签的记录数量
            let tagId = tag.id
            let recordDescriptor = FetchDescriptor<Record>(
                predicate: #Predicate<Record> { record in
                    record.tag.id == tagId
                }
            )
            let recordCount = try modelContext.fetch(recordDescriptor).count
            
            // 统计使用此标签的提醒数量
            let reminderDescriptor = FetchDescriptor<Reminder>(
                predicate: #Predicate<Reminder> { reminder in
                    reminder.tag.id == tagId
                }
            )
            let reminderCount = try modelContext.fetch(reminderDescriptor).count
            
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
            let reminderDescriptor = FetchDescriptor<Reminder>(
                predicate: #Predicate<Reminder> { reminder in
                    reminder.tag.id == tagId
                }
            )
            let activeReminders = try modelContext.fetch(reminderDescriptor)
            
            // 如果有活跃的提醒使用此标签，建议不要隐藏
            return activeReminders.isEmpty
        } catch {
            print("检查标签使用情况失败: \(error.localizedDescription)")
            return true // 出错时允许隐藏
        }
    }
} 