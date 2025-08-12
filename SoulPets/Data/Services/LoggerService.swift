import Foundation
import OSLog

/// 日志服务，提供应用统一的日志记录功能
class LoggerService {
    private static let subsystem = "com.byte.driver.SoulPets"
    
    /// 创建特定分类的日志记录器
    static func createLogger(category: String) -> Logger {
        return Logger(subsystem: subsystem, category: category)
    }
    
    // 预定义的日志记录器
    static let general = createLogger(category: "General")
    static let database = createLogger(category: "Database")
    static let ui = createLogger(category: "UI")
    static let network = createLogger(category: "Network")
    static let notification = createLogger(category: "Notification")
    
    /// 记录调试信息
    static func debug(_ message: String, logger: Logger = general) {
        logger.debug("\(message)")
    }
    
    /// 记录一般信息
    static func info(_ message: String, logger: Logger = general) {
        logger.info("\(message)")
    }
    
    /// 记录提示信息
    static func notice(_ message: String, logger: Logger = general) {
        logger.notice("\(message)")
    }
    
    /// 记录警告信息
    static func warning(_ message: String, logger: Logger = general) {
        logger.warning("⚠️ \(message)")
    }
    
    /// 记录错误信息
    static func error(_ message: String, error: Error? = nil, logger: Logger = general) {
        if let error = error {
            logger.error("❌ \(message): \(error.localizedDescription)")
        } else {
            logger.error("❌ \(message)")
        }
    }
    
    /// 记录严重错误信息
    static func critical(_ message: String, error: Error? = nil, logger: Logger = general) {
        if let error = error {
            logger.critical("🔥 \(message): \(error.localizedDescription)")
        } else {
            logger.critical("🔥 \(message)")
        }
    }
    
    /// 记录方法执行时间
    static func measureTime<T>(description: String, logger: Logger = general, operation: () -> T) -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        logger.debug("⏱ \(description) - 耗时: \(String(format: "%.4f", timeElapsed))秒")
        return result
    }
    
    /// 异步记录方法执行时间
    static func measureAsyncTime<T>(description: String, logger: Logger = general, operation: () async -> T) async -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        logger.debug("⏱ \(description) - 耗时: \(String(format: "%.4f", timeElapsed))秒")
        return result
    }
} 