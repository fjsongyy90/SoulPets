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
        createDefaultTagsIfNeeded(modelContext: modelContext)
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        logger.info("数据库初始化完成，耗时: \(String(format: "%.3f", timeElapsed))秒")
    }
    
    /// 检查并创建预设标签
    @MainActor
    private static func createDefaultTagsIfNeeded(modelContext: ModelContext) {
        let startTime = Date()
        
        // 检查是否已存在标签
        let descriptor = FetchDescriptor<Tag>()
        
        do {
            let existingTags = try modelContext.fetch(descriptor)
            
            // 如果没有标签，创建预设标签
            if existingTags.isEmpty {
                logger.info("创建预设标签")
                
                // 批量创建预设标签以提高性能
                let defaultTags = Tag.createDefaultTags()
                
                // 添加到数据库
                for tag in defaultTags {
                    modelContext.insert(tag)
                }
                
                // 保存更改
                try modelContext.save()
                
                let timeElapsed = Date().timeIntervalSince(startTime)
                logger.info("成功创建\(defaultTags.count)个预设标签，耗时: \(String(format: "%.3f", timeElapsed))秒")
            } else {
                logger.info("标签已存在，跳过创建")
            }
        } catch {
            logger.error("检查或创建预设标签时出错: \(error.localizedDescription)")
        }
    }
} 