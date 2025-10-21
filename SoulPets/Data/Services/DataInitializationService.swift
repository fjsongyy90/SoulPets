import Foundation
import SwiftData
import OSLog

/// 数据初始化服务，负责在应用启动时确保所有必要的数据已经准备就绪
class DataInitializationService {
    private static let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "DataInitialization")
    
    /// 初始化应用所需的所有基础数据
    static func initializeAppData(modelContext: ModelContext) {
        logger.info("开始初始化应用数据...")
        
        // 初始化预设标签
        TagPresetService.syncPresetTags(modelContext: modelContext)
                
        logger.info("应用数据初始化完成")
    }
} 
