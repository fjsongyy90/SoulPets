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
    var id: UUID
    var code: String
    var name: String
    var iconName: String
    var category: TagCategory
    var defaultIsReminder: Bool
    var isHidden: Bool // 标签是否隐藏
    var sortOrder: Int // 用于排序的字段
    var associatedPetTypes: String // 使用逗号分隔的字符串存储宠物类型
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        code: String,
        name: String,
        iconName: String,
        category: TagCategory,
        defaultIsReminder: Bool = true,
        isHidden: Bool = false,
        sortOrder: Int = 0,
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
        self.isHidden = isHidden
        self.sortOrder = sortOrder
        self.associatedPetTypes = associatedPetTypes.map { $0.rawValue }.joined(separator: ",") // 转换为逗号分隔的字符串
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 预设标签
extension Tag {
    /// 创建预设标签
    static func createDefaultTags() -> [Tag] {
        // 日常生活标签
        let dailyLifeTags: [Tag] = [
            Tag(code: "daily.food", name: "Dinner/Food", iconName: "fork.knife", category: .dailyLife, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.water", name: "Water", iconName: "drop", category: .dailyLife, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.treats", name: "Treats/Wet Food", iconName: "heart.fill", category: .dailyLife, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.play", name: "Play", iconName: "gamecontroller", category: .dailyLife, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.milk", name: "Milk Feed", iconName: "drop.fill", category: .dailyLife, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.potty", name: "Potty", iconName: "trash", category: .dailyLife, defaultIsReminder: false, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.walk", name: "Walk", iconName: "figure.walk", category: .dailyLife, associatedPetTypes: [.dog]),
            Tag(code: "daily.training", name: "Training", iconName: "star", category: .dailyLife, associatedPetTypes: [.dog])
        ]
        
        // 日常保健标签
        let routineHealthTags: [Tag] = [
            Tag(code: "health.medication", name: "Medication", iconName: "pill", category: .routineHealth, associatedPetTypes: [.cat, .dog]),
            Tag(code: "health.supplements", name: "Supplements", iconName: "cross.case", category: .routineHealth, associatedPetTypes: [.cat, .dog]),
            Tag(code: "health.deworm", name: "Deworm/Flea & Tick", iconName: "ladybug", category: .routineHealth, associatedPetTypes: [.cat, .dog]),
            Tag(code: "health.vaccine", name: "Vaccine", iconName: "syringe", category: .routineHealth, associatedPetTypes: [.cat, .dog])
        ]
        
        // 美容清洁标签
        let groomingTags: [Tag] = [
            Tag(code: "grooming.brushing", name: "Brushing", iconName: "paintbrush", category: .groomingCleaning, associatedPetTypes: [.cat, .dog]),
            Tag(code: "grooming.teeth", name: "Teeth Brushing", iconName: "mouth", category: .groomingCleaning, associatedPetTypes: [.cat, .dog]),
            Tag(code: "grooming.nail", name: "Nail Trim", iconName: "scissors", category: .groomingCleaning, associatedPetTypes: [.cat, .dog]),
            Tag(code: "grooming.ear", name: "Ear Cleaning", iconName: "ear", category: .groomingCleaning, associatedPetTypes: [.cat, .dog]),
            Tag(code: "grooming.bath", name: "Bath", iconName: "shower", category: .groomingCleaning, associatedPetTypes: [.cat, .dog]),
            Tag(code: "grooming.anal", name: "Anal Gland Express", iconName: "drop.triangle", category: .groomingCleaning, associatedPetTypes: [.dog])
        ]
        
        // 家居用品标签
        let homeSuppliesTags: [Tag] = [
            Tag(code: "home.buy", name: "Buy Supplies", iconName: "cart", category: .homeSupplies, associatedPetTypes: [.cat, .dog]),
            Tag(code: "home.bowls", name: "Wash Bowls", iconName: "circle.grid.2x1", category: .homeSupplies, associatedPetTypes: [.cat, .dog]),
            Tag(code: "home.refill", name: "Supplies Refill", iconName: "arrow.clockwise", category: .homeSupplies, associatedPetTypes: [.cat, .dog]),
            Tag(code: "home.toys", name: "Wash Toys", iconName: "cube", category: .homeSupplies, associatedPetTypes: [.cat, .dog]),
            Tag(code: "home.litterbox", name: "Scoop Litterbox", iconName: "square", category: .homeSupplies, associatedPetTypes: [.cat]),
            Tag(code: "home.litter", name: "Change Litter", iconName: "square.fill", category: .homeSupplies, associatedPetTypes: [.cat]),
            Tag(code: "home.washlitter", name: "Wash Litterbox", iconName: "square.on.square", category: .homeSupplies, associatedPetTypes: [.cat]),
            Tag(code: "home.cattree", name: "Wash Bed/Tree", iconName: "house", category: .homeSupplies, associatedPetTypes: [.cat]),
            Tag(code: "home.dogbed", name: "Wash Bed", iconName: "bed.double", category: .homeSupplies, associatedPetTypes: [.dog]),
            Tag(code: "home.crate", name: "Wash Crate/Pen", iconName: "square.grid.3x3", category: .homeSupplies, associatedPetTypes: [.dog])
        ]
        
        // 医疗护理标签
        let medicalTags: [Tag] = [
            Tag(code: "medical.checkup", name: "Check-up", iconName: "stethoscope", category: .medicalCare, associatedPetTypes: [.cat, .dog]),
            Tag(code: "medical.grooming", name: "Grooming Appointment", iconName: "scissors", category: .medicalCare, associatedPetTypes: [.cat, .dog]),
            Tag(code: "medical.antibody", name: "Antibody Titer", iconName: "waveform.path", category: .medicalCare, associatedPetTypes: [.cat, .dog]),
            Tag(code: "medical.abnormal", name: "Abnormal Condition", iconName: "exclamationmark.triangle", category: .medicalCare, defaultIsReminder: false, associatedPetTypes: [.cat, .dog]),
            Tag(code: "medical.surgery", name: "Surgery", iconName: "cross", category: .medicalCare, defaultIsReminder: false, associatedPetTypes: [.cat, .dog]),
            Tag(code: "medical.hospital", name: "Hospitalization", iconName: "building", category: .medicalCare, defaultIsReminder: false, associatedPetTypes: [.cat, .dog])
        ]
        
        // 计划与里程碑标签
        let planningTags: [Tag] = [
            Tag(code: "planning.sitter", name: "Pet Sitter", iconName: "person", category: .planningMilestones, associatedPetTypes: [.cat, .dog]),
            Tag(code: "planning.boarding", name: "Boarding", iconName: "building.2", category: .planningMilestones, associatedPetTypes: [.cat, .dog]),
            Tag(code: "planning.license", name: "License Renewal", iconName: "doc.text", category: .planningMilestones, associatedPetTypes: [.cat, .dog]),
            Tag(code: "planning.insurance", name: "Insurance Renewal", iconName: "shield", category: .planningMilestones, associatedPetTypes: [.cat, .dog]),
            Tag(code: "planning.birthday", name: "Birthday", iconName: "gift", category: .planningMilestones, associatedPetTypes: [.cat, .dog]),
            Tag(code: "planning.adoption", name: "Adoption/Gotcha Day", iconName: "heart.circle", category: .planningMilestones, associatedPetTypes: [.cat, .dog])
        ]
        
        // 合并所有标签
        return dailyLifeTags + routineHealthTags + groomingTags + homeSuppliesTags + medicalTags + planningTags
    }
    
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
