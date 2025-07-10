import Foundation
import SwiftData

/// 模型注册类，用于提供应用所需的所有SwiftData模型
struct ModelRegistration {
    /// 获取所有应用模型的注册列表
    static var models: [any PersistentModel.Type] {
        [
            Pet.self,
            Tag.self,
            Record.self,
            RecordPhoto.self,
            Weight.self,
            Reminder.self,
            ReminderCompletion.self,
            WeightGoal.self,
            UserSettings.self
        ]
    }
    
    /// 创建一个配置了所有模型的模型容器
    static func createModelContainer() throws -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return container
        } catch {
            print("创建ModelContainer失败: \(error.localizedDescription)")
            throw error
        }
    }
} 