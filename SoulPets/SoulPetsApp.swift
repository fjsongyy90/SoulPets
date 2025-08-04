//
//  SoulPetsApp.swift
//  SoulPets
//
//  Created by 宋友勇 on 2025/7/10.
//

import SwiftUI
import SwiftData
import OSLog

@main
struct SoulPetsApp: App {
    private let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "SoulPetsApp")
    private let startTime = Date()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Pet.self,
            Record.self,
            RecordPhoto.self,
            Tag.self,
            Weight.self,
            Reminder.self,
            ReminderCompletion.self
        ])
        
        // 暂时禁用 CloudKit 集成，使用本地存储
        // 后续版本中将添加符合 CloudKit 要求的数据模型
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // cloudKitDatabase: .private("iCloud.com.yourapp.SoulPets") // 暂时注释掉
        )
        
        do {
            // 尝试创建容器
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("成功创建ModelContainer")
            return container
        } catch {
            // 记录错误并尝试恢复
            print("创建ModelContainer失败: \(error)")
            
            // 如果常规方式失败，尝试使用内存模式创建临时容器
            do {
                let recoveryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [recoveryConfig])
            } catch {
                fatalError("无法创建ModelContainer，即使是内存模式也失败: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    // 记录启动时间
                    let launchTime = Date().timeIntervalSince(startTime)
                    logger.info("应用界面加载完成，启动耗时: \(String(format: "%.3f", launchTime))秒")
                    
                    // 在后台线程初始化数据库
                    Task {
                        try? await initializeDatabase()
                    }
                }
        }
    }
    
    // 在后台线程初始化数据库
    private func initializeDatabase() async throws {
        // 直接在主线程上执行数据库初始化
        _ = await MainActor.run {
            Task {
                await ModelRegistration.initializeDatabase(modelContext: self.sharedModelContainer.mainContext)
            }
        }
    }
    
    // 保留此方法但默认不使用，仅在需要重置数据时手动调用
    static func clearSwiftDataStore() {
        // 仅在开发环境中或首次安装时清除数据库
        #if DEBUG
        // 获取应用程序支持目录
        guard let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("无法获取应用程序支持目录")
            return
        }
        
        // SwiftData存储的默认位置
        let storeDirectory = appSupportDirectory.appendingPathComponent("default.store")
        
        // 检查目录是否存在
        if FileManager.default.fileExists(atPath: storeDirectory.path) {
            do {
                try FileManager.default.removeItem(at: storeDirectory)
                print("成功删除SwiftData存储目录")
            } catch {
                print("删除SwiftData存储目录失败: \(error)")
            }
        } else {
            print("SwiftData存储目录不存在")
        }
        #endif
    }
}
