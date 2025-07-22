import Foundation
import SwiftData
import OSLog

/// 宠物服务，负责处理宠物相关的业务逻辑
class PetService {
    private static let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "Pet")
    
    /// 获取所有宠物
    static func getAllPets(modelContext: ModelContext) -> [Pet] {
        let descriptor = FetchDescriptor<Pet>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("获取宠物列表时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 按类型筛选宠物
    static func getPets(ofType petType: PetType, modelContext: ModelContext) -> [Pet] {
        let descriptor = FetchDescriptor<Pet>(
            predicate: #Predicate<Pet> { pet in
                pet.petType == petType
            },
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("按类型获取宠物时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取特定宠物
    static func getPet(withId id: UUID, modelContext: ModelContext) -> Pet? {
        let descriptor = FetchDescriptor<Pet>(
            predicate: #Predicate<Pet> { pet in
                pet.id == id
            }
        )
        
        do {
            let pets = try modelContext.fetch(descriptor)
            return pets.first
        } catch {
            logger.error("按ID获取宠物时出错: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 创建新宠物
    static func createPet(
        name: String,
        petType: PetType,
        breed: String,
        avatar: Data?,
        gender: Gender,
        isNeutered: Bool,
        birthday: Date,
        adoptionDay: Date?,
        microchipID: String?,
        insurancePolicyNo: String?,
        weightUnitPreference: WeightUnit,
        modelContext: ModelContext
    ) -> Pet {
        let newPet = Pet(
            name: name,
            petType: petType,
            breed: breed,
            avatar: avatar,
            gender: gender,
            isNeutered: isNeutered,
            birthday: birthday,
            adoptionDay: adoptionDay,
            microchipID: microchipID ?? "",
            insurancePolicyNo: insurancePolicyNo ?? "",
            weightUnitPreference: weightUnitPreference
        )
        
        modelContext.insert(newPet)
        
        do {
            try modelContext.save()
            logger.info("成功创建宠物: \(name)")
        } catch {
            logger.error("创建宠物时出错: \(error.localizedDescription)")
        }
        
        return newPet
    }
    
    /// 更新宠物信息
    static func updatePet(
        pet: Pet,
        name: String,
        breed: String,
        avatar: Data?,
        gender: Gender,
        isNeutered: Bool,
        birthday: Date,
        adoptionDay: Date?,
        microchipID: String?,
        insurancePolicyNo: String?,
        weightUnitPreference: WeightUnit,
        modelContext: ModelContext
    ) {
        pet.name = name
        pet.breed = breed
        if let avatar = avatar {
            pet.avatar = avatar
        }
        pet.gender = gender
        pet.isNeutered = isNeutered
        pet.birthday = birthday
        pet.adoptionDay = adoptionDay
        pet.microchipID = microchipID ?? ""
        pet.insurancePolicyNo = insurancePolicyNo ?? ""
        pet.weightUnitPreference = weightUnitPreference
        pet.updatedAt = Date()
        
        do {
            try modelContext.save()
            logger.info("成功更新宠物信息: \(name)")
        } catch {
            logger.error("更新宠物信息时出错: \(error.localizedDescription)")
        }
    }
    
    /// 删除宠物
    static func deletePet(pet: Pet, modelContext: ModelContext) {
        modelContext.delete(pet)
        
        do {
            try modelContext.save()
            logger.info("成功删除宠物: \(pet.name)")
        } catch {
            logger.error("删除宠物时出错: \(error.localizedDescription)")
        }
    }
    
    /// 为宠物生日创建提醒
    static func createBirthdayReminder(pet: Pet, modelContext: ModelContext) {
        // 寻找生日标签
        let tagDescriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.code == "planning.birthday"
            }
        )
        
        do {
            let birthdayTags = try modelContext.fetch(tagDescriptor)
            
            guard let birthdayTag = birthdayTags.first else {
                logger.error("找不到生日标签，无法创建提醒")
                return
            }
            
            // 设置今年的生日日期
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            let birthdayMonth = calendar.component(.month, from: pet.birthday)
            let birthdayDay = calendar.component(.day, from: pet.birthday)
            
            guard let nextBirthdayDate = calendar.date(from: DateComponents(year: currentYear, month: birthdayMonth, day: birthdayDay)) else {
                logger.error("无法计算今年的生日日期")
                return
            }
            
            // 如果今年的生日已经过了，设置为明年的生日
            var reminderDate = nextBirthdayDate
            if reminderDate < Date() {
                guard let nextYearDate = calendar.date(byAdding: .year, value: 1, to: nextBirthdayDate) else {
                    logger.error("无法计算明年的生日日期")
                    return
                }
                reminderDate = nextYearDate
            }
            
            // 创建提醒
            let reminder = Reminder(
                startDate: reminderDate,
                notes: "\(pet.name)的生日",
                repeatInterval: 1,
                repeatUnit: .yearly,
                tag: birthdayTag,
                pets: [pet]
            )
            
            modelContext.insert(reminder)
            try modelContext.save()
            logger.info("成功为\(pet.name)创建生日提醒")
            
            // 设置通知
            NotificationService.scheduleReminderNotification(reminder: reminder, pet: pet)
            
        } catch {
            logger.error("创建生日提醒时出错: \(error.localizedDescription)")
        }
    }
    
    /// 为宠物领养纪念日创建提醒
    static func createAdoptionDayReminder(pet: Pet, modelContext: ModelContext) {
        guard let adoptionDay = pet.adoptionDay else {
            logger.warning("宠物没有设置领养日，无法创建提醒")
            return
        }
        
        // 寻找领养纪念日标签
        let tagDescriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.code == "planning.adoption"
            }
        )
        
        do {
            let adoptionTags = try modelContext.fetch(tagDescriptor)
            
            guard let adoptionTag = adoptionTags.first else {
                logger.error("找不到领养纪念日标签，无法创建提醒")
                return
            }
            
            // 设置今年的领养纪念日期
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            let adoptionMonth = calendar.component(.month, from: adoptionDay)
            let adoptionDayOfMonth = calendar.component(.day, from: adoptionDay)
            
            guard let nextAdoptionDate = calendar.date(from: DateComponents(year: currentYear, month: adoptionMonth, day: adoptionDayOfMonth)) else {
                logger.error("无法计算今年的领养纪念日期")
                return
            }
            
            // 如果今年的领养纪念日已经过了，设置为明年的领养纪念日
            var reminderDate = nextAdoptionDate
            if reminderDate < Date() {
                guard let nextYearDate = calendar.date(byAdding: .year, value: 1, to: nextAdoptionDate) else {
                    logger.error("无法计算明年的领养纪念日期")
                    return
                }
                reminderDate = nextYearDate
            }
            
            // 创建提醒
            let reminder = Reminder(
                startDate: reminderDate,
                notes: "今天是你和\(pet.name)相遇的\(calendar.dateComponents([.year], from: adoptionDay, to: reminderDate).year ?? 0 + 1)周年纪念日！",
                repeatInterval: 1,
                repeatUnit: .yearly,
                tag: adoptionTag,
                pets: [pet]
            )
            
            modelContext.insert(reminder)
            try modelContext.save()
            logger.info("成功为\(pet.name)创建领养纪念日提醒")
            
            // 设置通知
            NotificationService.scheduleReminderNotification(reminder: reminder, pet: pet)
            
        } catch {
            logger.error("创建领养纪念日提醒时出错: \(error.localizedDescription)")
        }
    }
} 