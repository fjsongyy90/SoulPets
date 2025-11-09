import Foundation
import SwiftData

/// 标签分类
enum TagCategory: String, CaseIterable, Codable {
    case dailyLife = "Daily Life"
    case routineHealth = "Routine Health"
    case groomingCleaning = "Grooming & Cleaning"
    case homeSupplies = "Home & Supplies"
    case medicalCare = "Medical Care"
    case planningMilestones = "Planning & Milestones"
}

// 注释掉重复定义的PetType枚举
// /// 宠物类型
// enum PetType: String, CaseIterable, Codable {
//     case cat = "Cat"
//     case dog = "Dog"
// }

/// 标签模型
@Model
final class Tag {
    // MARK: - 属性
    var id: UUID = UUID()
    var code: String = ""
    var name: String = ""
    var iconName: String = ""
    var category: TagCategory?  // CloudKit要求枚举类型必须可选
    var defaultIsReminder: Bool = true
    var isHidden: Bool = false // 标签是否隐藏
    var sortOrder: Int = 0 // 用于排序的字段
    var associatedPetTypes: String = "" // 使用逗号分隔的字符串存储宠物类型
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - 关系 (CloudKit要求反向关系)
    @Relationship(deleteRule: .nullify, inverse: \Record.tag)
    var records: [Record]?
    
    @Relationship(deleteRule: .nullify, inverse: \Reminder.tag)
    var reminders: [Reminder]?
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        code: String = "",
        name: String = "",
        iconName: String = "",
        category: TagCategory? = nil,
        defaultIsReminder: Bool = true,
        isHidden: Bool = false,
        sortOrder: Int = 0,
        associatedPetTypes: [PetType] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.iconName = iconName
        self.category = category
        self.defaultIsReminder = defaultIsReminder
        self.isHidden = isHidden
        self.sortOrder = sortOrder
        self.associatedPetTypes = associatedPetTypes.map { $0.rawValue }.joined(separator: ",") // 转换为逗号分隔的字符串
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 标签辅助方法
extension Tag {
    // v1.1.0: createDefaultTags() 方法已废弃
    // 现在使用 TagPresetService.createAllTags() 来管理所有60个预设标签
    
    // 辅助方法：检查标签是否适用于指定的宠物类型
    func isApplicableTo(petType: PetType) -> Bool {
        // 缓存拆分结果以提高性能
        let petTypes = associatedPetTypes.split(separator: ",").lazy.map { String($0) }
        return petTypes.contains(petType.rawValue)
    }
    
    // 获取此标签适用的所有宠物类型
    func getApplicablePetTypes() -> [PetType] {
        let petTypeStrings = associatedPetTypes.split(separator: ",").map { String($0) }
        return petTypeStrings.compactMap { rawValue in
            return PetType(rawValue: rawValue)
        }
    }
}
