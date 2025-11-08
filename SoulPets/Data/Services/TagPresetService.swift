import Foundation
import SwiftData
import OSLog // 建议添加日志，方便调试

/// 标签预设服务，用于初始化和管理应用中的标签数据
class TagPresetService {
    private static let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "TagPresetService")
    ///**
    ///同步预设标签数据。
    
    ///这个函数是“幂等”的：
    ///1. 它会遍历代码中定义的所有预设标签（"真相"）。
    ///2. 它会检查数据库中是否已存在该标签（通过唯一的 `code`）。
    ///3. 如果标签不存在，则【插入】新标签。
    ///4. 如果标签已存在，则【更新】其属性（名称、图标、宠物类型等），以匹配代码中的“真相”。
    ///这确保了所有用户（新老用户）的标签库始终与最新版本代码一致。
    ///*/
    static func syncPresetTags(modelContext: ModelContext) {
            logger.info("开始同步预设标签库...")

            // 1. 获取"真相"：代码中定义的所有预设标签
            let allPresetTags = createAllTags()
            
            // 2. 获取"现状"：数据库中已有的所有标签
            let descriptor = FetchDescriptor<Tag>()
            let existingTags: [Tag]
            do {
                existingTags = try modelContext.fetch(descriptor)
            } catch {
                logger.error("获取现有标签失败: \(error.localizedDescription)")
                return
            }
            
            // 3. 将"现状"转为字典，用 code 作为 key 方便快速查找
            // ✅ 修复：使用 (key, value) 冲突解决闭包，安全地处理重复键。
            // 如果遇到重复的 code，我们保留“更新时间(updatedAt)较新”的那个标签。
            var existingTagsDict = Dictionary(existingTags.map { ($0.code, $0) }) { (tag1, tag2) -> Tag in
                logger.warning("🏷️ 数据库中发现重复的标签 code: \(tag1.code)。正在合并...")
                // 保留更新时间较晚（较新）的一个
                return tag1.updatedAt > tag2.updatedAt ? tag1 : tag2
            }
            var hasChanges = false // 跟踪是否有任何变更
            
            // 4. 遍历"真相"，与"现状"对比
            for presetTag in allPresetTags {
                if let existingTag = existingTagsDict[presetTag.code] {
                    // ---------------------------------
                    // 情况一：标签已存在，执行【更新】逻辑
                    // ---------------------------------
                    var needsUpdate = false
                    
                    // 检查各个属性是否有变化
                    if existingTag.name != presetTag.name {
                        existingTag.name = presetTag.name
                        needsUpdate = true
                    }
                    if existingTag.iconName != presetTag.iconName {
                        existingTag.iconName = presetTag.iconName
                        needsUpdate = true
                    }
                    if existingTag.category != presetTag.category {
                        existingTag.category = presetTag.category
                        needsUpdate = true
                    }
                    if existingTag.defaultIsReminder != presetTag.defaultIsReminder {
                        existingTag.defaultIsReminder = presetTag.defaultIsReminder
                        needsUpdate = true
                    }
                    
                    // 【核心】检查宠物类型列表是否有变化
                    if existingTag.associatedPetTypes != presetTag.associatedPetTypes {
                        existingTag.associatedPetTypes = presetTag.associatedPetTypes
                        needsUpdate = true
                    }
                    
                    if needsUpdate {
                        hasChanges = true
                        logger.info("更新标签: \(existingTag.code)")
                    }
                    
                } else {
                    // ---------------------------------
                    // 情况二：标签不存在，执行【插入】逻辑
                    // ---------------------------------
                    logger.info("新增标签: \(presetTag.code)")
                    modelContext.insert(presetTag)
                    hasChanges = true
                }
            }
            
            // 5. 如果有变更，统一保存
            if hasChanges {
                do {
                    try modelContext.save()
                    logger.info("预设标签数据同步完成。")
                } catch {
                    logger.error("保存标签变更失败: \(error.localizedDescription)")
                }
            } else {
                logger.info("标签数据已是最新，无需同步。")
            }
        }
    
    /// 创建所有预设标签（v1.1.0 - 60个标签，支持10种宠物）
    private static func createAllTags() -> [Tag] {
        var allTags: [Tag] = []
        var currentSortOrder = 0
        
        // 定义常用的宠物类型组合，简化代码
        let allPets: [PetType] = [.cat, .dog, .rabbit, .hamster, .guineaPig, .bird, .lizard, .tortoise, .fish, .snake]
        let smallMammals: [PetType] = [.rabbit, .hamster, .guineaPig]
        let reptiles: [PetType] = [.lizard, .tortoise, .snake]
        let herbivores: [PetType] = [.rabbit, .guineaPig, .bird, .lizard, .tortoise]
        let carnivores: [PetType] = [.lizard, .tortoise, .bird, .snake]
        let furryPets: [PetType] = [.cat, .dog, .rabbit, .hamster, .guineaPig]
        let mostPets: [PetType] = [.cat, .dog, .rabbit, .hamster, .guineaPig, .bird, .lizard, .tortoise, .snake]
        
        // ========================================
        // 3.1 日常生活标签 (Daily Life) - 14项
        // ========================================
        allTags.append(contentsOf: [
            // v1.0 标签（保持不变）
            createTag(code: "daily.food", name: "Dinner/Food", iconName: "1_dinner_food", category: .dailyLife, sortOrder: currentSortOrder, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "daily.water", name: "Water", iconName: "2_water", category: .dailyLife, sortOrder: currentSortOrder + 1, defaultIsReminder: true, petTypes: mostPets), // 扩展到9种（除鱼）
            createTag(code: "daily.treats", name: "Treats/Wet Food", iconName: "3_treats_wet_food", category: .dailyLife, sortOrder: currentSortOrder + 2, defaultIsReminder: true, petTypes: [.cat]),
            createTag(code: "daily.treats.dog", name: "Treats", iconName: "3_treats_wet_food", category: .dailyLife, sortOrder: currentSortOrder + 3, defaultIsReminder: true, petTypes: [.dog]),
            createTag(code: "daily.walk", name: "Walk", iconName: "36_walk", category: .dailyLife, sortOrder: currentSortOrder + 4, defaultIsReminder: true, petTypes: [.dog]),
            createTag(code: "daily.training", name: "Training", iconName: "37_training", category: .dailyLife, sortOrder: currentSortOrder + 5, defaultIsReminder: true, petTypes: [.dog]),
            createTag(code: "daily.play", name: "Play", iconName: "4_play", category: .dailyLife, sortOrder: currentSortOrder + 6, defaultIsReminder: true, petTypes: [.cat, .dog, .rabbit, .hamster, .guineaPig, .bird]), // 扩展
            createTag(code: "daily.milk", name: "Milk Feed", iconName: "5_milk_feed", category: .dailyLife, sortOrder: currentSortOrder + 7, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "daily.potty", name: "Potty", iconName: "6_potty", category: .dailyLife, sortOrder: currentSortOrder + 8, defaultIsReminder: false, petTypes: [.cat, .dog, .rabbit, .hamster, .guineaPig]), // 扩展
            
            // v1.1 新增标签
            createTag(code: "daily.hay", name: "Hay Feed", iconName: "41_hay_feed", category: .dailyLife, sortOrder: currentSortOrder + 9, defaultIsReminder: true, petTypes: [.rabbit, .guineaPig]),
            createTag(code: "daily.veggies", name: "Veggies/Fruits", iconName: "42_veggies_fruits", category: .dailyLife, sortOrder: currentSortOrder + 10, defaultIsReminder: true, petTypes: herbivores),
            createTag(code: "daily.insect", name: "Insect/Live Feed", iconName: "43_insect_live_feed", category: .dailyLife, sortOrder: currentSortOrder + 11, defaultIsReminder: true, petTypes: carnivores),
            createTag(code: "daily.frozen", name: "Frozen Feed", iconName: "44_frozen_feed", category: .dailyLife, sortOrder: currentSortOrder + 12, defaultIsReminder: true, petTypes: [.lizard, .snake, .tortoise]),
            createTag(code: "daily.fishfood", name: "Fish Feed", iconName: "45_fish_feed", category: .dailyLife, sortOrder: currentSortOrder + 13, defaultIsReminder: true, petTypes: [.fish])
        ])
        currentSortOrder += 20

        // ========================================
        // 3.2 日常保健标签 (Routine Health) - 4项
        // ========================================
        allTags.append(contentsOf: [
            createTag(code: "health.medication", name: "Medication", iconName: "7_medication", category: .routineHealth, sortOrder: currentSortOrder, defaultIsReminder: true, petTypes: allPets), // 扩展到全部10种
            createTag(code: "health.supplements", name: "Supplements", iconName: "8_supplements", category: .routineHealth, sortOrder: currentSortOrder + 1, defaultIsReminder: true, petTypes: allPets), // 扩展到全部10种
            createTag(code: "health.deworm", name: "Deworm/Flea & Tick", iconName: "9_deworm_flea_tick", category: .routineHealth, sortOrder: currentSortOrder + 2, defaultIsReminder: true, petTypes: mostPets), // 扩展到9种（除鱼）
            createTag(code: "health.vaccine", name: "Vaccine", iconName: "10_vaccine", category: .routineHealth, sortOrder: currentSortOrder + 3, defaultIsReminder: true, petTypes: [.cat, .dog, .rabbit, .bird]) // 扩展
        ])
        currentSortOrder += 20

        // ========================================
        // 3.3 美容清洁标签 (Grooming & Cleaning) - 11项
        // ========================================
        allTags.append(contentsOf: [
            // v1.0 标签
            createTag(code: "grooming.brushing", name: "Brushing", iconName: "11_brushing_grooming", category: .groomingCleaning, sortOrder: currentSortOrder, defaultIsReminder: true, petTypes: furryPets), // 扩展
            createTag(code: "grooming.teeth", name: "Teeth Brushing", iconName: "12_teeth_brushing", category: .groomingCleaning, sortOrder: currentSortOrder + 1, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "grooming.nail", name: "Nail Trim", iconName: "13_nail_trim", category: .groomingCleaning, sortOrder: currentSortOrder + 2, defaultIsReminder: true, petTypes: [.cat, .dog, .rabbit, .hamster, .guineaPig, .bird, .lizard, .tortoise]), // 扩展
            createTag(code: "grooming.ear", name: "Ear Cleaning", iconName: "14_ear_cleaning", category: .groomingCleaning, sortOrder: currentSortOrder + 3, defaultIsReminder: true, petTypes: [.cat, .dog, .rabbit, .hamster, .guineaPig, .lizard]), // 扩展
            createTag(code: "grooming.bath", name: "Bath", iconName: "15_bash", category: .groomingCleaning, sortOrder: currentSortOrder + 4, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "grooming.anal", name: "Anal Gland Express", iconName: "38_anal_gland_express", category: .groomingCleaning, sortOrder: currentSortOrder + 5, defaultIsReminder: true, petTypes: [.dog]),
            
            // v1.1 新增标签
            createTag(code: "grooming.teeth.check", name: "Teeth Check/Trim", iconName: "46_teeth_check_trim", category: .groomingCleaning, sortOrder: currentSortOrder + 6, defaultIsReminder: true, petTypes: smallMammals),
            createTag(code: "grooming.beak", name: "Beak Trim", iconName: "47_beak_trim", category: .groomingCleaning, sortOrder: currentSortOrder + 7, defaultIsReminder: true, petTypes: [.bird]),
            createTag(code: "grooming.wing", name: "Wing Clip", iconName: "48_wing_clip", category: .groomingCleaning, sortOrder: currentSortOrder + 8, defaultIsReminder: true, petTypes: [.bird]),
            createTag(code: "grooming.soak", name: "Soak", iconName: "49_soak", category: .groomingCleaning, sortOrder: currentSortOrder + 9, defaultIsReminder: true, petTypes: reptiles),
            createTag(code: "grooming.shedding", name: "Shedding", iconName: "50_shedding", category: .groomingCleaning, sortOrder: currentSortOrder + 10, defaultIsReminder: false, petTypes: [.lizard, .snake])
        ])
        currentSortOrder += 20

        // ========================================
        // 3.4 家居用品标签 (Home & Supplies) - 10项
        // ========================================
        allTags.append(contentsOf: [
            createTag(code: "home.buy", name: "Buy Supplies", iconName: "16_buy_supplies", category: .homeSupplies, sortOrder: currentSortOrder, defaultIsReminder: true, petTypes: allPets), // 扩展到全部10种
            createTag(code: "home.bowls", name: "Wash Bowls", iconName: "18_wash_bowls", category: .homeSupplies, sortOrder: currentSortOrder + 1, defaultIsReminder: true, petTypes: mostPets), // 扩展到9种（除鱼）
            createTag(code: "home.refill", name: "Supplies Refill", iconName: "19_supplies_refill", category: .homeSupplies, sortOrder: currentSortOrder + 2, defaultIsReminder: true, petTypes: [.cat, .dog, .rabbit, .hamster, .guineaPig, .bird]), // 扩展
            createTag(code: "home.scoop", name: "Scoop Litterbox", iconName: "17_scoop_litterbox", category: .homeSupplies, sortOrder: currentSortOrder + 3, defaultIsReminder: true, petTypes: [.cat]),
            createTag(code: "home.litter", name: "Change Litter", iconName: "20_change_litter", category: .homeSupplies, sortOrder: currentSortOrder + 4, defaultIsReminder: true, petTypes: [.cat]),
            createTag(code: "home.litterbox", name: "Wash Litterbox", iconName: "21_wash_litterbox", category: .homeSupplies, sortOrder: currentSortOrder + 5, defaultIsReminder: true, petTypes: [.cat]),
            createTag(code: "home.bed.cat", name: "Wash Bed/Tree", iconName: "22_wash_bed_tree", category: .homeSupplies, sortOrder: currentSortOrder + 6, defaultIsReminder: true, petTypes: [.cat]),
            createTag(code: "home.bed.dog", name: "Wash Bed", iconName: "22_wash_bed_tree", category: .homeSupplies, sortOrder: currentSortOrder + 7, defaultIsReminder: true, petTypes: [.dog]),
            createTag(code: "home.crate", name: "Wash Crate/Pen", iconName: "39.wash_crate_pen", category: .homeSupplies, sortOrder: currentSortOrder + 8, defaultIsReminder: true, petTypes: [.dog]),
            createTag(code: "home.toys", name: "Wash Toys", iconName: "23_wash_toys", category: .homeSupplies, sortOrder: currentSortOrder + 9, defaultIsReminder: true, petTypes: [.cat, .dog, .rabbit, .hamster, .guineaPig, .bird]) // 扩展
        ])
        currentSortOrder += 20

        // ========================================
        // 3.5 栖息地与环境标签 (Habitat & Environment) - 新分类 - 10项
        // ========================================
        allTags.append(contentsOf: [
            createTag(code: "habitat.bedding", name: "Change Bedding/Substrate", iconName: "51_change_bedding_substrate", category: .homeSupplies, sortOrder: currentSortOrder, defaultIsReminder: true, petTypes: [.rabbit, .hamster, .guineaPig, .bird, .lizard, .tortoise, .snake]),
            createTag(code: "habitat.clean", name: "Habitat Clean", iconName: "52_habitat_clean", category: .homeSupplies, sortOrder: currentSortOrder + 1, defaultIsReminder: true, petTypes: [.rabbit, .hamster, .guineaPig, .bird, .lizard, .tortoise, .snake]),
            createTag(code: "habitat.misting", name: "Misting/Spray", iconName: "53_misting_spray", category: .homeSupplies, sortOrder: currentSortOrder + 2, defaultIsReminder: true, petTypes: [.lizard, .tortoise]),
            createTag(code: "habitat.waterchange", name: "Water Change", iconName: "54_water_change", category: .homeSupplies, sortOrder: currentSortOrder + 3, defaultIsReminder: true, petTypes: [.fish]),
            createTag(code: "habitat.watertest", name: "Water Test", iconName: "55_water_test", category: .homeSupplies, sortOrder: currentSortOrder + 4, defaultIsReminder: true, petTypes: [.fish]),
            createTag(code: "habitat.filter", name: "Clean Filter", iconName: "56_clean_filter", category: .homeSupplies, sortOrder: currentSortOrder + 5, defaultIsReminder: true, petTypes: [.fish]),
            createTag(code: "habitat.plants", name: "Trim Plants", iconName: "57_trim_plants", category: .homeSupplies, sortOrder: currentSortOrder + 6, defaultIsReminder: true, petTypes: [.fish]),
            createTag(code: "habitat.conditioner", name: "Add Conditioner", iconName: "58_add_conditioner", category: .homeSupplies, sortOrder: currentSortOrder + 7, defaultIsReminder: true, petTypes: [.fish]),
            createTag(code: "habitat.uvb", name: "Change UVB Bulb", iconName: "59_change_uvb_bulb", category: .homeSupplies, sortOrder: currentSortOrder + 8, defaultIsReminder: true, petTypes: [.lizard, .tortoise]),
            createTag(code: "habitat.heat", name: "Change Heat Lamp", iconName: "60_change_heat_lamp", category: .homeSupplies, sortOrder: currentSortOrder + 9, defaultIsReminder: true, petTypes: [.lizard, .tortoise, .snake])
        ])
        currentSortOrder += 20

        // ========================================
        // 3.6 医疗护理标签 (Medical Care) - 6项
        // ========================================
        allTags.append(contentsOf: [
            createTag(code: "medical.checkup", name: "Check-up", iconName: "24_check_up", category: .medicalCare, sortOrder: currentSortOrder, defaultIsReminder: true, petTypes: allPets), // 扩展到全部10种
            createTag(code: "medical.grooming", name: "Grooming Appointment", iconName: "25_grooming_appointment", category: .medicalCare, sortOrder: currentSortOrder + 1, defaultIsReminder: true, petTypes: [.cat, .dog, .rabbit, .hamster, .guineaPig, .bird]), // 扩展
            createTag(code: "medical.antibody", name: "Antibody Titer", iconName: "26_antibody_titer", category: .medicalCare, sortOrder: currentSortOrder + 2, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "medical.abnormal", name: "Abnormal Condition", iconName: "27_abnormal_condition", category: .medicalCare, sortOrder: currentSortOrder + 3, defaultIsReminder: false, petTypes: allPets), // 扩展到全部10种
            createTag(code: "medical.surgery", name: "Surgery", iconName: "28_surgery", category: .medicalCare, sortOrder: currentSortOrder + 4, defaultIsReminder: false, petTypes: allPets), // 扩展到全部10种
            createTag(code: "medical.hospitalization", name: "Hospitalization", iconName: "29_hospitalization", category: .medicalCare, sortOrder: currentSortOrder + 5, defaultIsReminder: false, petTypes: allPets) // 扩展到全部10种
        ])
        currentSortOrder += 20

        // ========================================
        // 3.7 计划与纪念日标签 (Planning & Milestones) - 7项
        // ========================================
        allTags.append(contentsOf: [
            createTag(code: "planning.sitter", name: "Pet Sitter", iconName: "30_pet_sitter", category: .planningMilestones, sortOrder: currentSortOrder, defaultIsReminder: true, petTypes: allPets), // 扩展到全部10种
            createTag(code: "planning.boarding", name: "Boarding", iconName: "31_boarding", category: .planningMilestones, sortOrder: currentSortOrder + 1, defaultIsReminder: true, petTypes: allPets), // 扩展到全部10种
            createTag(code: "planning.license", name: "License Renewal", iconName: "32_license_renewal", category: .planningMilestones, sortOrder: currentSortOrder + 2, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "planning.insurance", name: "Insurance Renewal", iconName: "33_insurance_renewal", category: .planningMilestones, sortOrder: currentSortOrder + 3, defaultIsReminder: true, petTypes: allPets), // 扩展到全部10种
            createTag(code: "planning.birthday", name: "Birthday", iconName: "34_birthday", category: .planningMilestones, sortOrder: currentSortOrder + 4, defaultIsReminder: true, petTypes: allPets), // 扩展到全部10种
            createTag(code: "planning.adoption", name: "Adoption/Gotcha Day", iconName: "35_adoption_gotcha_day", category: .planningMilestones, sortOrder: currentSortOrder + 5, defaultIsReminder: true, petTypes: allPets), // 扩展到全部10种
            
            // v1.1 新增标签
            createTag(code: "planning.hibernation", name: "Hibernation/Brumation", iconName: "61_hibernation_brumation", category: .planningMilestones, sortOrder: currentSortOrder + 6, defaultIsReminder: false, petTypes: [.lizard, .tortoise, .snake, .hamster])
        ])
        currentSortOrder += 20
        
        return allTags
    }
    
    /// 创建单个标签
    private static func createTag(
        code: String,
        name: String,
        iconName: String,
        category: TagCategory,
        sortOrder: Int,
        defaultIsReminder: Bool,
        isHidden: Bool = false, // 预设标签默认都是显示状态
        petTypes: [PetType]
    ) -> Tag {
        return Tag(
            code: code,
            name: name,
            iconName: iconName,
            category: category,
            defaultIsReminder: defaultIsReminder,
            isHidden: isHidden,
            sortOrder: sortOrder,
            associatedPetTypes: petTypes
        )
    }
}
