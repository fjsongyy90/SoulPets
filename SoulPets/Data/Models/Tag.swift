import Foundation
import SwiftData

/// 标签分类枚举
enum TagCategory: String, Codable, CaseIterable {
    case dailyLife = "Daily Life"
    case routineHealth = "Routine Health"
    case groomingAndCleaning = "Grooming & Cleaning"
    case homeAndSupplies = "Home & Supplies"
    case medicalCare = "Medical Care"
    case planningAndMilestones = "Planning & Milestones"
}

@Model
final class Tag {
    // MARK: - 属性
    var id: UUID
    var code: String
    var name: String
    var iconName: String
    var category: TagCategory
    var defaultIsReminder: Bool
    var associatedPetTypes: [PetType]
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - 关系
    @Relationship(inverse: \Record.tag)
    var records: [Record]?
    
    @Relationship(inverse: \Reminder.tag)
    var reminders: [Reminder]?
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        code: String,
        name: String,
        iconName: String,
        category: TagCategory,
        defaultIsReminder: Bool,
        associatedPetTypes: [PetType],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.iconName = iconName
        self.category = category
        self.defaultIsReminder = defaultIsReminder
        self.associatedPetTypes = associatedPetTypes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 