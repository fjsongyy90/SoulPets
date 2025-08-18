import Foundation
import SwiftData
import OSLog

/// PetService的级联删除扩展 - 专门处理SwiftData关系删除问题
extension PetService {
    
    /// 级联删除宠物 - 手动处理所有关系以避免SwiftData关系错误
    static func cascadeDeletePet(pet: Pet, modelContext: ModelContext) {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("🔄 [级联删除] 开始删除宠物: \(pet.name) (ID: \(pet.id))")
        
        do {
            // 步骤1: 手动删除所有Weight记录
            logger.info("📊 [级联删除] 步骤1: 删除体重记录...")
            let weightStartTime = CFAbsoluteTimeGetCurrent()
            
            if let weights = pet.weights {
                for weight in weights {
                    modelContext.delete(weight)
                }
                logger.info("📊 [级联删除] 删除了 \(weights.count) 条体重记录")
            }
            
            logger.info("📊 [级联删除] 体重记录删除完成，耗时: \(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - weightStartTime))秒")
            
            // 步骤2: 手动删除所有WeightGoal记录
            logger.info("📊 [级联删除] 步骤2: 删除体重目标...")
            let goalStartTime = CFAbsoluteTimeGetCurrent()
            
            if let weightGoals = pet.weightGoals {
                for goal in weightGoals {
                    modelContext.delete(goal)
                }
                logger.info("📊 [级联删除] 删除了 \(weightGoals.count) 条体重目标")
            }
            
            logger.info("📊 [级联删除] 体重目标删除完成，耗时: \(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - goalStartTime))秒")
            
            // 步骤3: 处理Records的多对多关系
            logger.info("📊 [级联删除] 步骤3: 处理记录关系...")
            let recordStartTime = CFAbsoluteTimeGetCurrent()
            
            // 获取所有记录并过滤出与该宠物相关的记录
            let recordDescriptor = FetchDescriptor<Record>()
            let allRecords = try modelContext.fetch(recordDescriptor)
            let petRecords = allRecords.filter { record in
                record.pets?.contains { $0.id == pet.id } ?? false
            }
            
            logger.info("📊 [级联删除] 找到 \(petRecords.count) 条相关记录")
            
            for record in petRecords {
                // 检查记录是否只属于这一只宠物
                if let pets = record.pets, pets.count == 1 && pets.first?.id == pet.id {
                    // 只属于这只宠物，删除整个记录（RecordPhoto会通过cascade自动删除）
                    let photoCount = record.photos?.count ?? 0
                    modelContext.delete(record)
                    logger.info("📊 [级联删除] 删除了专属记录 \(record.id) 及其 \(photoCount) 张照片")
                } else if let pets = record.pets {
                    // 属于多只宠物，只移除这只宠物
                    record.pets = pets.filter { $0.id != pet.id }
                    logger.info("📊 [级联删除] 从共享记录 \(record.id) 中移除宠物")
                }
            }
            
            logger.info("📊 [级联删除] 记录处理完成，耗时: \(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - recordStartTime))秒")
            
            // 步骤4: 处理Reminders的多对多关系
            logger.info("📊 [级联删除] 步骤4: 处理提醒关系...")
            let reminderStartTime = CFAbsoluteTimeGetCurrent()
            
            if let reminders = pet.reminders {
                for reminder in reminders {
                    // 检查提醒是否只属于这一只宠物
                    if let pets = reminder.pets, pets.count == 1 && pets.first?.id == pet.id {
                        // 只属于这只宠物，删除整个提醒及其完成记录
                        if let completions = reminder.completions {
                            for completion in completions {
                                modelContext.delete(completion)
                            }
                            logger.info("📊 [级联删除] 删除了提醒 \(reminder.id) 的 \(completions.count) 条完成记录")
                        }
                        modelContext.delete(reminder)
                        logger.info("📊 [级联删除] 删除了专属提醒 \(reminder.id)")
                    } else if let pets = reminder.pets {
                        // 属于多只宠物，只移除这只宠物
                        reminder.pets = pets.filter { $0.id != pet.id }
                        logger.info("📊 [级联删除] 从共享提醒 \(reminder.id) 中移除宠物")
                    }
                }
            }
            
            logger.info("📊 [级联删除] 提醒处理完成，耗时: \(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - reminderStartTime))秒")
            
            // 步骤5: 最后删除宠物本身
            logger.info("📊 [级联删除] 步骤5: 删除宠物本身...")
            let deleteStartTime = CFAbsoluteTimeGetCurrent()
            
            modelContext.delete(pet)
            
            logger.info("📊 [级联删除] 宠物删除完成，耗时: \(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - deleteStartTime))秒")
            
            // 步骤6: 保存更改
            logger.info("📊 [级联删除] 步骤6: 保存数据库更改...")
            let saveStartTime = CFAbsoluteTimeGetCurrent()
            
            try modelContext.save()
            
            let saveEndTime = CFAbsoluteTimeGetCurrent()
            logger.info("✅ [级联删除] 数据库保存成功，耗时: \(String(format: "%.3f", saveEndTime - saveStartTime))秒")
            
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("🎉 [级联删除] 宠物删除成功: \(pet.name)，总耗时: \(String(format: "%.3f", totalTime))秒")
            
            // 步骤7: 异步清理通知
            DispatchQueue.global(qos: .background).async {
                NotificationService.removeAllPendingNotifications()
                logger.info("✅ [级联删除] 通知清理完成")
            }
            
        } catch {
            let errorTime = CFAbsoluteTimeGetCurrent() - startTime
            logger.error("❌ [级联删除] 删除失败，耗时: \(String(format: "%.3f", errorTime))秒")
            logger.error("❌ [级联删除] 错误信息: \(error.localizedDescription)")
            logger.error("❌ [级联删除] 错误详情: \(error)")
            
            // 尝试回滚操作
            logger.info("🔄 [级联删除] 尝试回滚操作...")
            modelContext.rollback()
        }
    }
}