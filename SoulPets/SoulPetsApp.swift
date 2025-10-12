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

@main
struct SoulPetsApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true
    
    // ✅ 1. 新增状态：用一个可选的 State 变量来持有 ModelContainer
    // 它初始为 nil，表示数据库尚未准备好
    @State private var container: ModelContainer?
    
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "SoulPetsApp")
    private let startTime = Date()
    @State private var shouldPreloadCharts = true
    private let notificationDelegate = NotificationDelegate()
    
    // ❌ 2. 移除旧的、同步初始化的 sharedModelContainer 属性

    var body: some Scene {
        WindowGroup {
            ZStack {
                if shouldPreloadCharts {
                    preloadChartsView()
                }
                
                if showSplash {
                    SplashView(showSplash: $showSplash)
                } else if hasCompletedOnboarding {
                    // ✅ 3. 核心逻辑：根据 container 是否存在来决定显示哪个视图
                    if let container = container {
                        // 如果 container 存在，说明初始化已完成，显示主内容
                        ContentView()
                            .modelContainer(container) // 注入已创建的容器
                            .onAppear {
                                let launchTime = Date().timeIntervalSince(startTime)
                                logger.info("✅ 应用界面加载完成，总启动耗时: \(String(format: "%.3f", launchTime))秒")
                                
                                UserSettings.shared.applyCurrentAppearance()
                                // 注意：大部分一次性初始化工作已移至 setupContainer()
                                // 这里只保留每次视图出现时需要检查的逻辑
                                NotificationService.checkAndUpdateBadgeIfNeeded(modelContext: container.mainContext)
                            }
                            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                                logger.info("📱 应用即将进入前台，更新角标")
                                NotificationService.checkAndUpdateBadgeIfNeeded(modelContext: container.mainContext)
                            }
                            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                                logger.info("📱 应用已变为活跃状态，更新角标")
                                NotificationService.updateApplicationBadge(modelContext: container.mainContext)
                            }
                    } else {
                        // 如果 container 是 nil，显示加载视图
                        LoadingView()
                            .onAppear {
                                // 在 LoadingView 出现时，异步开始创建容器和初始化数据库
                                Task {
                                    await setupContainerAndServices()
                                }
                            }
                    }
                } else {
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
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
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
            
            // e. 所有准备工作完成，将创建好的容器赋值给 State 变量，触发UI刷新
            self.container = createdContainer
            
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
