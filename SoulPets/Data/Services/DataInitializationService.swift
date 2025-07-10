import Foundation
import SwiftData
import OSLog

/// 数据初始化服务，负责在应用启动时确保所有必要的数据已经准备就绪
class DataInitializationService {
    private static let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "DataInitialization")
    
    /// 初始化应用所需的所有基础数据
    static func initializeAppData(modelContext: ModelContext) {
        logger.info("开始初始化应用数据...")
        
        // 初始化预设标签
        TagPresetService.initializePresetTags(modelContext: modelContext)
        
        // 初始化用户设置
        initializeUserSettings(modelContext: modelContext)
        
        logger.info("应用数据初始化完成")
    }
    
    /// 初始化用户设置
    private static func initializeUserSettings(modelContext: ModelContext) {
        // 检查是否已有用户设置
        let descriptor = FetchDescriptor<UserSettings>()
        
        do {
            let existingSettings = try modelContext.fetch(descriptor)
            if !existingSettings.isEmpty {
                logger.info("已存在用户设置，跳过初始化")
                return
            }
            
            // 创建默认用户设置
            let defaultSettings = UserSettings(
                appearance: .system,
                userName: nil,
                iCloudSyncEnabled: true
            )
            
            modelContext.insert(defaultSettings)
            try modelContext.save()
            logger.info("成功创建默认用户设置")
        } catch {
            logger.error("初始化用户设置时发生错误: \(error.localizedDescription)")
        }
    }
} 