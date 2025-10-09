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

// MARK: - 预设标签
extension Tag {
    /// 创建预设标签
    static func createDefaultTags() -> [Tag] {
        // 日常生活标签
        let dailyLifeTags: [Tag] = [
            Tag(code: "daily.food", name: "Dinner/Food", iconName: "1_dinner_food", category: .dailyLife, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.water", name: "Water", iconName: "2_water", category: .dailyLife, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.treats", name: "Treats/Wet Food", iconName: "3_treats_wet_food", category: .dailyLife, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.play", name: "Play", iconName: "4_play", category: .dailyLife, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.milk", name: "Milk Feed", iconName: "5_milk_feed", category: .dailyLife, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.potty", name: "Potty", iconName: "6_potty", category: .dailyLife, defaultIsReminder: false, associatedPetTypes: [.cat, .dog]),
            Tag(code: "daily.walk", name: "Walk", iconName: "36_walk", category: .dailyLife, associatedPetTypes: [.dog]),
            Tag(code: "daily.training", name: "Training", iconName: "37_training", category: .dailyLife, associatedPetTypes: [.dog])
        ]
        
        // 日常保健标签
        let routineHealthTags: [Tag] = [
            Tag(code: "health.medication", name: "Medication", iconName: "7_medication", category: .routineHealth, associatedPetTypes: [.cat, .dog]),
            Tag(code: "health.supplements", name: "Supplements", iconName: "8_supplements", category: .routineHealth, associatedPetTypes: [.cat, .dog]),
            Tag(code: "health.deworm", name: "Deworm/Flea & Tick", iconName: "9_deworm_flea_tick", category: .routineHealth, associatedPetTypes: [.cat, .dog]),
            Tag(code: "health.vaccine", name: "Vaccine", iconName: "10_vaccine", category: .routineHealth, associatedPetTypes: [.cat, .dog])
        ]
        
        // 美容清洁标签
        let groomingTags: [Tag] = [
            Tag(code: "grooming.brushing", name: "Brushing", iconName: "11_brushing_grooming", category: .groomingCleaning, associatedPetTypes: [.cat, .dog]),
            Tag(code: "grooming.teeth", name: "Teeth Brushing", iconName: "12_teeth_brushing", category: .groomingCleaning, associatedPetTypes: [.cat, .dog]),
            Tag(code: "grooming.nail", name: "Nail Trim", iconName: "13_nail_trim", category: .groomingCleaning, associatedPetTypes: [.cat, .dog]),
            Tag(code: "grooming.ear", name: "Ear Cleaning", iconName: "14_ear_cleaning", category: .groomingCleaning, associatedPetTypes: [.cat, .dog]),
            Tag(code: "grooming.bath", name: "Bath", iconName: "15_bash", category: .groomingCleaning, associatedPetTypes: [.cat, .dog]),
            Tag(code: "grooming.anal", name: "Anal Gland Express", iconName: "38_anal_gland_express", category: .groomingCleaning, associatedPetTypes: [.dog])
        ]
        
        // 家居用品标签
        let homeSuppliesTags: [Tag] = [
            Tag(code: "home.buy", name: "Buy Supplies", iconName: "16_buy_supplies", category: .homeSupplies, associatedPetTypes: [.cat, .dog]),
            Tag(code: "home.bowls", name: "Wash Bowls", iconName: "18_wash_bowls", category: .homeSupplies, associatedPetTypes: [.cat, .dog]),
            Tag(code: "home.refill", name: "Supplies Refill", iconName: "19_supplies_refill", category: .homeSupplies, associatedPetTypes: [.cat, .dog]),
            Tag(code: "home.toys", name: "Wash Toys", iconName: "23_wash_toys", category: .homeSupplies, associatedPetTypes: [.cat, .dog]),
            Tag(code: "home.litterbox", name: "Scoop Litterbox", iconName: "17_scoop_litterbox", category: .homeSupplies, associatedPetTypes: [.cat]),
            Tag(code: "home.litter", name: "Change Litter", iconName: "20_change_litter", category: .homeSupplies, associatedPetTypes: [.cat]),
            Tag(code: "home.washlitter", name: "Wash Litterbox", iconName: "21_wash_litterbox", category: .homeSupplies, associatedPetTypes: [.cat]),
            Tag(code: "home.cattree", name: "Wash Bed/Tree", iconName: "22_wash_bed_tree", category: .homeSupplies, associatedPetTypes: [.cat]),
            Tag(code: "home.dogbed", name: "Wash Bed", iconName: "22_wash_bed_tree", category: .homeSupplies, associatedPetTypes: [.dog]),
            Tag(code: "home.crate", name: "Wash Crate/Pen", iconName: "39.wash_crate_pen", category: .homeSupplies, associatedPetTypes: [.dog])
        ]
        
        // 医疗护理标签
        let medicalTags: [Tag] = [
            Tag(code: "medical.checkup", name: "Check-up", iconName: "24_check_up", category: .medicalCare, associatedPetTypes: [.cat, .dog]),
            Tag(code: "medical.grooming", name: "Grooming Appointment", iconName: "25_grooming_appointment", category: .medicalCare, associatedPetTypes: [.cat, .dog]),
            Tag(code: "medical.antibody", name: "Antibody Titer", iconName: "26_antibody_titer", category: .medicalCare, associatedPetTypes: [.cat, .dog]),
            Tag(code: "medical.abnormal", name: "Abnormal Condition", iconName: "27_abnormal_condition", category: .medicalCare, defaultIsReminder: false, associatedPetTypes: [.cat, .dog]),
            Tag(code: "medical.surgery", name: "Surgery", iconName: "28_surgery", category: .medicalCare, defaultIsReminder: false, associatedPetTypes: [.cat, .dog]),
            Tag(code: "medical.hospital", name: "Hospitalization", iconName: "29_hospitalization", category: .medicalCare, defaultIsReminder: false, associatedPetTypes: [.cat, .dog])
        ]
        
        // 计划与里程碑标签
        let planningTags: [Tag] = [
            Tag(code: "planning.sitter", name: "Pet Sitter", iconName: "30_pet_sitter", category: .planningMilestones, associatedPetTypes: [.cat, .dog]),
            Tag(code: "planning.boarding", name: "Boarding", iconName: "31_boarding", category: .planningMilestones, associatedPetTypes: [.cat, .dog]),
            Tag(code: "planning.license", name: "License Renewal", iconName: "32_license_renewal", category: .planningMilestones, associatedPetTypes: [.cat, .dog]),
            Tag(code: "planning.insurance", name: "Insurance Renewal", iconName: "33_insurance_renewal", category: .planningMilestones, associatedPetTypes: [.cat, .dog]),
            Tag(code: "planning.birthday", name: "Birthday", iconName: "34_birthday", category: .planningMilestones, associatedPetTypes: [.cat, .dog]),
            Tag(code: "planning.adoption", name: "Adoption/Gotcha Day", iconName: "35_adoption_gotcha_day", category: .planningMilestones, associatedPetTypes: [.cat, .dog])
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
