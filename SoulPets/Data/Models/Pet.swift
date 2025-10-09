import Foundation
import SwiftData

/// 宠物类型枚举
enum PetType: String, Codable, CaseIterable {
    case cat = "Cat"
    case dog = "Dog"
}

/// 性别枚举
enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

/// 体重单位枚举
enum WeightUnit: String, Codable, CaseIterable {
    case kg = "kg"
    case lbs = "lbs"
}

/// 宠物模型
@Model
final class Pet {
    // MARK: - 属性 (CloudKit要求所有属性可选或有默认值)
    var id: UUID = UUID()
    var name: String = ""
    var petType: PetType?  // CloudKit要求枚举类型必须可选
    var breed: String = ""
    var avatar: Data?
    var gender: Gender?  // CloudKit要求枚举类型必须可选
    var isNeutered: Bool = false
    var birthday: Date = Date()
    var adoptionDay: Date?
    var microchipID: String = ""
    var insurancePolicyNo: String = ""
    var weightUnitPreference: WeightUnit?  // CloudKit要求枚举类型必须可选
    /// 宠物的性格描述
    var personality: String?
    /// 与主人的故事
    var story: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - 关系
    @Relationship(deleteRule: .cascade, inverse: \Weight.pet)
    var weights: [Weight]?
    
    @Relationship(deleteRule: .cascade, inverse: \WeightGoal.pet)
    var weightGoals: [WeightGoal]?
    
    @Relationship(deleteRule: .nullify, inverse: \Record.pets)
    var records: [Record]?
    
    @Relationship(deleteRule: .nullify, inverse: \Reminder.pets)
    var reminders: [Reminder]?
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        name: String = "",
        petType: PetType? = nil,
        breed: String = "",
        avatar: Data? = nil,
        gender: Gender? = nil,
        isNeutered: Bool = false,
        birthday: Date = Date(),
        adoptionDay: Date? = nil,
        microchipID: String = "",
        insurancePolicyNo: String = "",
        weightUnitPreference: WeightUnit? = nil,
        personality: String? = nil,
        story: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.petType = petType
        self.breed = breed
        self.avatar = avatar
        self.gender = gender
        self.isNeutered = isNeutered
        self.birthday = birthday
        self.adoptionDay = adoptionDay
        self.microchipID = microchipID
        self.insurancePolicyNo = insurancePolicyNo
        self.weightUnitPreference = weightUnitPreference
        self.personality = personality
        self.story = story
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 计算属性
extension Pet {
    /// 计算宠物年龄
    var age: (years: Int, months: Int, days: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: birthday, to: Date())
        return (years: components.year ?? 0, months: components.month ?? 0, days: components.day ?? 0)
    }
    
    /// 计算领养天数
    var daysWithOwner: Int? {
        guard let adoptionDay = adoptionDay else { return nil }
        return Calendar.current.dateComponents([.day], from: adoptionDay, to: Date()).day
    }
    
    /// 计算到下个生日的天数
    var daysToNextBirthday: Int {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        
        // 获取生日的月和日
        let birthdayMonth = calendar.component(.month, from: birthday)
        let birthdayDay = calendar.component(.day, from: birthday)
        
        // 计算今年的生日日期
        var birthdayThisYear = calendar.date(from: DateComponents(year: currentYear, month: birthdayMonth, day: birthdayDay)) ?? Date()
        
        // 如果今年的生日已经过了，计算明年的生日
        if birthdayThisYear < today {
            birthdayThisYear = calendar.date(from: DateComponents(year: currentYear + 1, month: birthdayMonth, day: birthdayDay)) ?? Date()
        }
        
        return calendar.dateComponents([.day], from: today, to: birthdayThisYear).day ?? 0
    }
} 