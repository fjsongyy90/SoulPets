import Foundation
import SwiftData
import OSLog

/// 模型注册类，用于管理所有SwiftData模型
struct ModelRegistration {
    private static let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "ModelRegistration")
    
    /// 注册的所有模型类型
    static var models: [any PersistentModel.Type] {
        [
            Pet.self,
            Record.self,
            RecordPhoto.self,
            Tag.self,
            Weight.self,
            WeightGoal.self,
            Reminder.self,
            ReminderCompletion.self
            // 未来可能添加的其他模型
        ]
    }
    
    /// 初始化数据库
    @MainActor
    static func initializeDatabase(modelContext: ModelContext) async {
        let startTime = Date()
        logger.info("开始初始化数据库...")
        
        // 检查模型上下文是否有效
        do {
            // 尝试一个简单的查询来验证模型上下文
            var testDescriptor = FetchDescriptor<Tag>()
            testDescriptor.fetchLimit = 1
            _ = try modelContext.fetch(testDescriptor)
            logger.info("模型上下文检查成功")
        } catch {
            logger.error("模型上下文检查失败: \(error.localizedDescription)")
            return
        }
        
        // 检查并创建预设标签
        TagPresetService.syncPresetTags(modelContext: modelContext)
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        logger.info("数据库初始化完成，耗时: \(String(format: "%.3f", timeElapsed))秒")
    }
    
} 
