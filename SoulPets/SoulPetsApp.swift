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
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "SoulPetsApp")
    private let startTime = Date()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(ModelRegistration.models)
        
        // 配置数据迁移选项 - 暂时使用删除存储的方式解决迁移问题
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .automatic
        )
        
        do {
            // 尝试创建容器
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ 成功创建ModelContainer，CloudKit已启用")
            return container
        } catch {
            // 如果遇到迁移错误，删除旧的存储文件并创建新的容器
            print("❌ 创建ModelContainer失败: \(error)")
            print("🗑️ 尝试删除旧的存储文件并重新创建")
            
            // 删除旧的存储文件
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            if let appSupportURL = appSupportURL {
                let storeURL = appSupportURL.appendingPathComponent("default.store")
                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
                print("🗑️ 已删除旧的存储文件: \(storeURL)")
            }
            
            do {
                let newContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ 成功重新创建ModelContainer")
                return newContainer
            } catch {
                print("❌ 重新创建ModelContainer也失败: \(error)")
                print("🧠 使用内存模式创建临时容器")
                
                // 作为最后的备选方案，创建内存容器
                let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                let memoryContainer = try! ModelContainer(for: schema, configurations: [memoryConfig])
                return memoryContainer
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
                    
                    // 应用保存的外观设置
                    UserSettings.shared.applyCurrentAppearance()
                    
                    // 请求通知权限
                    requestNotificationPermission()
                    
                    // 在后台线程初始化数据库
                    Task {
                        try? await initializeDatabase()
                    }
                }
        }
    }
    
    // MARK: - 请求通知权限
    private func requestNotificationPermission() {
        // 先检查当前权限状态
        NotificationService.checkAuthorizationStatus { status in
            switch status {
            case .notDetermined:
                // 如果用户还未决定，则请求权限
                NotificationService.requestAuthorization { granted in
                    DispatchQueue.main.async {
                        if granted {
                            self.logger.info("🔔 用户授予了通知权限")
                        } else {
                            self.logger.warning("🔕 用户拒绝了通知权限")
                        }
                    }
                }
            case .denied:
                logger.warning("🔕 用户已拒绝通知权限")
            case .authorized, .provisional, .ephemeral:
                logger.info("🔔 通知权限已授权")
            @unknown default:
                logger.warning("🔔 未知的通知权限状态: \(status.rawValue)")
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
