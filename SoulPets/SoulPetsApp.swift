//
//  SoulPetsApp.swift
//  SoulPets
//
//  Created by 宋友勇 on 2025/7/10.
//

import SwiftUI
import SwiftData
import OSLog
import UserNotifications

@main
struct SoulPetsApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "SoulPetsApp")
    private let startTime = Date()
    
    // 🔧 新增：通知代理，用于处理通知接收和角标更新
    private let notificationDelegate = NotificationDelegate()
    
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
            if showSplash {
                SplashView(showSplash: $showSplash)
            } else if hasCompletedOnboarding {
                ContentView()
                    .modelContainer(sharedModelContainer)
                    .onAppear {
                        // 记录启动时间
                        let launchTime = Date().timeIntervalSince(startTime)
                        logger.info("应用界面加载完成，启动耗时: \(String(format: "%.3f", launchTime))秒")
                        
                        // 应用保存的外观设置
                        UserSettings.shared.applyCurrentAppearance()
                        
                        // 请求通知权限并设置代理
                        requestNotificationPermission()
                        setupNotificationDelegate()
                        
                        // 更新应用角标
                        NotificationService.checkAndUpdateBadgeIfNeeded(modelContext: sharedModelContainer.mainContext)
                        
                        // 在后台线程初始化数据库
                        Task {
                            try? await initializeDatabase()
                        }
                    }
                    // 🔧 新增：监听应用生命周期事件
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        logger.info("📱 应用即将进入前台，更新角标")
                        NotificationService.checkAndUpdateBadgeIfNeeded(modelContext: sharedModelContainer.mainContext)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        logger.info("📱 应用已变为活跃状态，更新角标")
                        NotificationService.updateApplicationBadge(modelContext: sharedModelContainer.mainContext)
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
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
    
    // MARK: - 设置通知代理
    private func setupNotificationDelegate() {
        notificationDelegate.modelContext = sharedModelContainer.mainContext
        UNUserNotificationCenter.current().delegate = notificationDelegate
        logger.info("🔔 已设置通知代理")
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

// MARK: - 通知代理类
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "NotificationDelegate")
    var modelContext: ModelContext?
    
    // 当应用在前台时收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        logger.info("📱 应用在前台收到通知: \(notification.request.identifier)")
        
        // 更新角标
        if let modelContext = modelContext {
            NotificationService.updateApplicationBadge(modelContext: modelContext)
        }
        
        // 在前台显示通知
        completionHandler([.banner, .sound])
    }
    
    // 用户点击通知时调用
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        logger.info("📱 用户点击了通知: \(response.notification.request.identifier)")
        
        // 更新角标
        if let modelContext = modelContext {
            NotificationService.updateApplicationBadge(modelContext: modelContext)
        }
        
        // TODO: 可以在这里添加打开对应提醒页面的逻辑
        
        completionHandler()
    }
}
