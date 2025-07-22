import Foundation
import SwiftData

/// 标签预设服务，用于初始化和管理应用中的标签数据
class TagPresetService {
    /// 初始化预设标签数据
    static func initializePresetTags(modelContext: ModelContext) {
        // 检查是否已有标签数据
        let descriptor = FetchDescriptor<Tag>()
        do {
            let existingTags = try modelContext.fetch(descriptor)
            // 如果已有标签数据，则不再初始化
            if !existingTags.isEmpty {
                print("已存在标签数据，跳过初始化")
                return
            }
        } catch {
            print("检查标签数据时发生错误: \(error.localizedDescription)")
            return
        }
        
        // 创建并保存预设标签
        createAllTags().forEach { modelContext.insert($0) }
        
        do {
            try modelContext.save()
            print("成功初始化预设标签数据")
        } catch {
            print("保存预设标签时发生错误: \(error.localizedDescription)")
        }
    }
    
    /// 创建所有预设标签
    private static func createAllTags() -> [Tag] {
        var allTags: [Tag] = []
        
        // 日常生活标签
        allTags.append(contentsOf: [
            createTag(code: "daily.food", name: "Dinner/Food", iconName: "food", category: .dailyLife, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "daily.water", name: "Water", iconName: "water", category: .dailyLife, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "daily.treats", name: "Treats/Wet Food", iconName: "treats", category: .dailyLife, defaultIsReminder: true, petTypes: [.cat]),
            createTag(code: "daily.treats.dog", name: "Treats", iconName: "treats", category: .dailyLife, defaultIsReminder: true, petTypes: [.dog]),
            createTag(code: "daily.walk", name: "Walk", iconName: "walk", category: .dailyLife, defaultIsReminder: true, petTypes: [.dog]),
            createTag(code: "daily.training", name: "Training", iconName: "training", category: .dailyLife, defaultIsReminder: true, petTypes: [.dog]),
            createTag(code: "daily.play", name: "Play", iconName: "play", category: .dailyLife, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "daily.milk", name: "Milk Feed", iconName: "milk", category: .dailyLife, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "daily.potty", name: "Potty", iconName: "potty", category: .dailyLife, defaultIsReminder: false, petTypes: [.cat, .dog])
        ])
        
        // 日常保健标签
        allTags.append(contentsOf: [
            createTag(code: "health.medication", name: "Medication", iconName: "medication", category: .routineHealth, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "health.supplements", name: "Supplements", iconName: "supplements", category: .routineHealth, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "health.deworm", name: "Deworm/Flea & Tick", iconName: "deworm", category: .routineHealth, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "health.vaccine", name: "Vaccine", iconName: "vaccine", category: .routineHealth, defaultIsReminder: true, petTypes: [.cat, .dog])
        ])
        
        // 美容清洁标签
        allTags.append(contentsOf: [
            createTag(code: "grooming.brushing", name: "Brushing", iconName: "brushing", category: .groomingCleaning, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "grooming.teeth", name: "Teeth Brushing", iconName: "teeth", category: .groomingCleaning, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "grooming.nail", name: "Nail Trim", iconName: "nail", category: .groomingCleaning, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "grooming.ear", name: "Ear Cleaning", iconName: "ear", category: .groomingCleaning, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "grooming.bath", name: "Bath", iconName: "bath", category: .groomingCleaning, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "grooming.anal", name: "Anal Gland Express", iconName: "anal", category: .groomingCleaning, defaultIsReminder: true, petTypes: [.dog])
        ])
        
        // 家居用品标签
        allTags.append(contentsOf: [
            createTag(code: "home.buy", name: "Buy Supplies", iconName: "supplies", category: .homeSupplies, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "home.bowls", name: "Wash Bowls", iconName: "bowls", category: .homeSupplies, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "home.refill", name: "Supplies Refill", iconName: "refill", category: .homeSupplies, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "home.scoop", name: "Scoop Litterbox", iconName: "scoop", category: .homeSupplies, defaultIsReminder: true, petTypes: [.cat]),
            createTag(code: "home.litter", name: "Change Litter", iconName: "litter", category: .homeSupplies, defaultIsReminder: true, petTypes: [.cat]),
            createTag(code: "home.litterbox", name: "Wash Litterbox", iconName: "litterbox", category: .homeSupplies, defaultIsReminder: true, petTypes: [.cat]),
            createTag(code: "home.bed.cat", name: "Wash Bed/Tree", iconName: "bed", category: .homeSupplies, defaultIsReminder: true, petTypes: [.cat]),
            createTag(code: "home.bed.dog", name: "Wash Bed", iconName: "bed", category: .homeSupplies, defaultIsReminder: true, petTypes: [.dog]),
            createTag(code: "home.crate", name: "Wash Crate/Pen", iconName: "crate", category: .homeSupplies, defaultIsReminder: true, petTypes: [.dog]),
            createTag(code: "home.toys", name: "Wash Toys", iconName: "toys", category: .homeSupplies, defaultIsReminder: true, petTypes: [.cat, .dog])
        ])
        
        // 医疗护理标签
        allTags.append(contentsOf: [
            createTag(code: "medical.checkup", name: "Check-up", iconName: "checkup", category: .medicalCare, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "medical.grooming", name: "Grooming Appointment", iconName: "grooming", category: .medicalCare, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "medical.antibody", name: "Antibody Titer", iconName: "antibody", category: .medicalCare, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "medical.abnormal", name: "Abnormal Condition", iconName: "abnormal", category: .medicalCare, defaultIsReminder: false, petTypes: [.cat, .dog]),
            createTag(code: "medical.surgery", name: "Surgery", iconName: "surgery", category: .medicalCare, defaultIsReminder: false, petTypes: [.cat, .dog]),
            createTag(code: "medical.hospitalization", name: "Hospitalization", iconName: "hospital", category: .medicalCare, defaultIsReminder: false, petTypes: [.cat, .dog])
        ])
        
        // 规划与里程碑标签
        allTags.append(contentsOf: [
            createTag(code: "planning.sitter", name: "Pet Sitter", iconName: "sitter", category: .planningMilestones, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "planning.boarding", name: "Boarding", iconName: "boarding", category: .planningMilestones, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "planning.license", name: "License Renewal", iconName: "license", category: .planningMilestones, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "planning.insurance", name: "Insurance Renewal", iconName: "insurance", category: .planningMilestones, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "planning.birthday", name: "Birthday", iconName: "birthday", category: .planningMilestones, defaultIsReminder: true, petTypes: [.cat, .dog]),
            createTag(code: "planning.adoption", name: "Adoption/Gotcha Day", iconName: "adoption", category: .planningMilestones, defaultIsReminder: true, petTypes: [.cat, .dog])
        ])
        
        return allTags
    }
    
    /// 创建单个标签
    private static func createTag(
        code: String,
        name: String,
        iconName: String,
        category: TagCategory,
        defaultIsReminder: Bool,
        petTypes: [PetType]
    ) -> Tag {
        return Tag(
            code: code,
            name: name,
            iconName: iconName,
            category: category,
            defaultIsReminder: defaultIsReminder,
            associatedPetTypes: petTypes
        )
    }
    
    /// 获取通用标签（同时适用于选中的多种宠物）
    static func getCommonTags(for petTypes: [PetType], in modelContext: ModelContext) -> [Tag] {
        guard !petTypes.isEmpty else { return [] }
        
        // 如果只有一种宠物类型，直接返回适用于该类型的所有标签
        if petTypes.count == 1, let petType = petTypes.first {
            // 创建一个函数来检查标签是否适用于指定的宠物类型
            let petTypeString = petType.rawValue
            
            let descriptor = FetchDescriptor<Tag>()
            do {
                let allTags = try modelContext.fetch(descriptor)
                return allTags.filter { tag in
                    let petTypes = tag.associatedPetTypes.split(separator: ",").map { String($0) }
                    return petTypes.contains(petTypeString)
                }
            } catch {
                print("获取标签时出错: \(error.localizedDescription)")
                return []
            }
        }
        
        // 如果有多种宠物类型，找出所有类型都支持的标签
        var commonTags: [Tag] = []
        let allTagsDescriptor = FetchDescriptor<Tag>()
        
        do {
            let allTags = try modelContext.fetch(allTagsDescriptor)
            commonTags = allTags.filter { tag in
                // 检查所有选中的宠物类型是否都被此标签支持
                return petTypes.allSatisfy { petType in
                    let tagPetTypes = tag.associatedPetTypes.split(separator: ",").map { String($0) }
                    return tagPetTypes.contains(petType.rawValue)
                }
            }
            return commonTags
        } catch {
            print("获取标签时出错: \(error.localizedDescription)")
            return []
        }
    }
} 