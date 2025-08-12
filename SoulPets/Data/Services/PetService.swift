import Foundation
import SwiftData
import OSLog

/// 宠物服务，负责处理宠物相关的业务逻辑
class PetService {
    private static let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "Pet")
    
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
        // 1. 删除与该宠物相关的所有记录
        let recordDescriptor = FetchDescriptor<Record>()
        do {
            let allRecords = try modelContext.fetch(recordDescriptor)
            let petRecords = allRecords.filter { record in
                record.pets?.contains { $0.id == pet.id } == true
            }
            
            for record in petRecords {
                // 如果记录只关联这一只宠物，直接删除记录（RecordPhoto会级联删除）
                if record.pets?.count == 1 {
                    modelContext.delete(record)
                } else {
                    // 如果记录关联多只宠物，只移除当前宠物的关联
                    record.pets?.removeAll { $0.id == pet.id }
                }
            }
            logger.info("成功处理\(pet.name)相关的\(petRecords.count)条记录")
        } catch {
            logger.error("删除宠物记录时出错: \(error.localizedDescription)")
        }
        
        // 2. 删除与该宠物相关的所有提醒
        let reminderDescriptor = FetchDescriptor<Reminder>()
        do {
            let allReminders = try modelContext.fetch(reminderDescriptor)
            let petReminders = allReminders.filter { reminder in
                reminder.pets?.contains { $0.id == pet.id } == true
            }
            
            for reminder in petReminders {
                // 如果提醒只关联这一只宠物，先清理通知再删除提醒（包括其完成记录）
                if reminder.pets?.count == 1 {
                    // 清理与该提醒相关的所有通知
                    NotificationService.removeNotificationsForReminder(reminderId: reminder.id)
                    modelContext.delete(reminder)
                } else {
                    // 如果提醒关联多只宠物，只移除当前宠物的关联
                    // 同时需要清理该宠物的特定通知
                    let notificationId = "reminder-\(reminder.id.uuidString)-\(pet.id.uuidString)"
                    NotificationService.removeNotification(withIdentifier: notificationId)
                    reminder.pets?.removeAll { $0.id == pet.id }
                }
            }
            logger.info("成功处理\(pet.name)相关的\(petReminders.count)条提醒")
        } catch {
            logger.error("删除宠物提醒时出错: \(error.localizedDescription)")
        }
        
        // 3. 删除宠物本身（体重数据会通过cascade自动删除）
        modelContext.delete(pet)
        
        do {
            try modelContext.save()
            logger.info("成功删除宠物及其所有相关数据: \(pet.name)")
        } catch {
            logger.error("删除宠物时出错: \(error.localizedDescription)")
        }
    }
    
    /// 删除所有数据
    private static func deleteAllData(in modelContext: ModelContext) throws {
        // 删除所有记录完成
        let reminderCompletionDescriptor = FetchDescriptor<ReminderCompletion>()
        let reminderCompletions = try modelContext.fetch(reminderCompletionDescriptor)
        for completion in reminderCompletions {
            modelContext.delete(completion)
        }
        
        // 删除所有提醒
        let reminderDescriptor = FetchDescriptor<Reminder>()
        let reminders = try modelContext.fetch(reminderDescriptor)
        for reminder in reminders {
            modelContext.delete(reminder)
        }
        
        // 删除所有记录（RecordPhoto会自动级联删除）
        let recordDescriptor = FetchDescriptor<Record>()
        let records = try modelContext.fetch(recordDescriptor)
        for record in records {
            modelContext.delete(record)
        }
        
        // 删除所有体重目标
        let weightGoalDescriptor = FetchDescriptor<WeightGoal>()
        let weightGoals = try modelContext.fetch(weightGoalDescriptor)
        for goal in weightGoals {
            modelContext.delete(goal)
        }
        
        // 删除所有体重记录
        let weightDescriptor = FetchDescriptor<Weight>()
        let weights = try modelContext.fetch(weightDescriptor)
        for weight in weights {
            modelContext.delete(weight)
        }
        
        // 删除所有宠物
        let petDescriptor = FetchDescriptor<Pet>()
        let pets = try modelContext.fetch(petDescriptor)
        for pet in pets {
            modelContext.delete(pet)
        }
        
        // 保存更改
        try modelContext.save()
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
            
            // 创建提醒 - 使用宠物的实际生日作为起始日期
            // 这样年度重复算法就能正确计算每年的生日
            let reminder = Reminder(
                startDate: pet.birthday,
                notes: "\(pet.name)的生日",
                repeatInterval: 1,
                repeatUnit: .yearly,
                tag: birthdayTag,
                pets: [pet]
            )
            
            modelContext.insert(reminder)
            try modelContext.save()
            logger.info("成功为\(pet.name)创建生日提醒，起始日期: \(pet.birthday)")
            
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