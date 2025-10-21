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
import Charts
import CloudKit

@main
struct SoulPetsApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    // ✅ 1. 我们的核心状态，决定显示 Splash 还是主内容
    @State private var isDatabaseReady = false
    
    // ✅ 2. 将 container 也设为 State，以便异步初始化
    @State private var container: ModelContainer?
    
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "SoulPetsApp")
    private let startTime = Date()
    @State private var shouldPreloadCharts = true
    private let notificationDelegate = NotificationDelegate()
    

    var body: some Scene {
            WindowGroup {
                ZStack {
                    if shouldPreloadCharts {
                        preloadChartsView()
                    }
                    
                    // ✅ 3. 核心显示逻辑
                    if !isDatabaseReady || container == nil {
                        // 如果数据库未就绪，始终显示 SplashView
                        SplashView()
                            .onAppear {
                                // 在 SplashView 出现时，立即开始异步加载数据库
                                // 使用 Task.detached 确保它不会意外地在主线程上运行过长时间
                                Task.detached(priority: .userInitiated) {
                                    await setupContainerAndServices()
                                }
                            }
                    } else if hasCompletedOnboarding {
                        // 数据库就绪且已完成引导，显示主内容
                        ContentView()
                            .modelContainer(container!) // 此时 container 必然有值
                            .onAppear {
                                let launchTime = Date().timeIntervalSince(startTime)
                                logger.info("✅ 应用界面加载完成，总启动耗时: \(String(format: "%.3f", launchTime))秒")
                                
                                UserSettings.shared.applyCurrentAppearance()
                                NotificationService.checkAndUpdateBadgeIfNeeded(modelContext: container!.mainContext)
                            }
                            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                                logger.info("📱 应用即将进入前台，更新角标")
                                NotificationService.checkAndUpdateBadgeIfNeeded(modelContext: container!.mainContext)
                            }
                            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                                logger.info("📱 应用已变为活跃状态，更新角标")
                                NotificationService.updateApplicationBadge(modelContext: container!.mainContext)
                            }
                    } else {
                        // 数据库就绪但未完成引导，显示引导页
                        OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    }
                }
            }
        }
    
    // ✅ 4. 新增方法：将所有耗时的初始化逻辑封装到一个异步函数中
    @MainActor
    private func setupContainerAndServices() async {
        logger.info("🚀 开始异步初始化 ModelContainer 及相关服务...")
        
        do {
            let schema = Schema(ModelRegistration.models)
            
            // 🔧 根据环境选择不同的iCloud容器
            let modelConfiguration: ModelConfiguration
            #if DEBUG
                // 开发环境使用开发容器
                modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private("iCloud.com.byte.driver.SoulPets.dev")
                )
                logger.info("🔧 使用开发环境iCloud容器: iCloud.com.byte.driver.SoulPets.dev")
            #else
                // 生产环境使用生产容器
                modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private("iCloud.com.byte.driver.SoulPets")
                )
                logger.info("🔧 使用生产环境iCloud容器: iCloud.com.byte.driver.SoulPets")
            #endif
            
            // 异步创建容器 - 这是最关键的异步操作
            let createdContainer = try await Task {
                try ModelContainer(for: schema, configurations: [modelConfiguration])
            }.value
            
            logger.info("✅ ModelContainer 创建成功")
            
            // a. 初始化数据库（例如，首次运行时创建默认标签）
            await ModelRegistration.initializeDatabase(modelContext: createdContainer.mainContext)
            
            // b. 设置通知代理（因为它依赖 modelContext）
            notificationDelegate.modelContext = createdContainer.mainContext
            UNUserNotificationCenter.current().delegate = notificationDelegate
            logger.info("🔔 已设置通知代理")
            
            // c. 请求通知权限
            requestNotificationPermission()
            
            // d. 预热服务
            prewarmCriticalServices()
            
            // ✅ 5. 所有准备工作完成，回到主线程更新状态
            await MainActor.run {
                self.container = createdContainer
                
                // 添加一个最小显示时间，防止 Splash 闪烁过快
                let minimumSplashTime = 2.8 // 与您之前的动画总时长匹配
                let elapsedTime = Date().timeIntervalSince(startTime)
                let delay = max(0, minimumSplashTime - elapsedTime)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        self.isDatabaseReady = true
                    }
                }
            }
            
            logger.info("✅ 异步初始化流程全部完成！")
        } catch {
            // 这里可以添加更复杂的错误处理，比如向用户展示一个错误页面
            fatalError("❌ 异步创建 ModelContainer 失败: \(error.localizedDescription)")
        }
    }
    
    // ... 其他辅助方法保持不变 ...
    private func requestNotificationPermission() {
        NotificationService.checkAuthorizationStatus { status in
            if status == .notDetermined {
                NotificationService.requestAuthorization { _ in }
            } else {
                logger.info("🔔 通知权限状态: \(status.rawValue)")
            }
        }
    }
    
    private func prewarmCriticalServices() {
        DispatchQueue.main.async {
            KeyboardPrewarmer.shared.prewarmKeyboard()
        }
        DispatchQueue.global(qos: .userInitiated).async {
            PhotosPrewarmService.shared.prewarmPhotosAccess()
        }
    }
    
    @ViewBuilder
    private func preloadChartsView() -> some View {
        Chart {
            LineMark(
                x: .value("X", 0),
                y: .value("Y", 0)
            )
        }
        .frame(width: 1, height: 1)
        .position(x: -100, y: -100)
        .opacity(0)
        .allowsHitTesting(false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                shouldPreloadCharts = false
            }
        }
    }
}

// MARK: - 通知代理类
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "NotificationDelegate")
    var modelContext: ModelContext?
    
    // 当应用在前台时收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        logger.info("📱 应用在前台收到通知: \(notification.request.identifier)")
        
        if let modelContext = modelContext {
            Task { @MainActor in
                NotificationService.updateApplicationBadge(modelContext: modelContext)
            }
        }
        
        completionHandler([.banner, .sound])
    }
    
    // 用户点击通知时调用
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        logger.info("📱 用户点击了通知: \(response.notification.request.identifier)")
        
        if let modelContext = modelContext {
            Task { @MainActor in
                NotificationService.updateApplicationBadge(modelContext: modelContext)
            }
        }
        
        completionHandler()
    }
}
