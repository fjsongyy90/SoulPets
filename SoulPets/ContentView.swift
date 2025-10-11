//
//  ContentView.swift
//  SoulPets
//
//  Created by 宋友勇 on 2025/7/10.
//

import SwiftUI
import SwiftData
import OSLog

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "ContentView")
    @State private var isModelReady = false
    @State private var errorMessage: String? = nil
    @State private var selectedTab: Int = 0 // 用于追踪当前选中的标签
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    // 适应性强调色 - 在深色模式下使用更亮的版本
    private var adaptiveAccentColor: Color {
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.90, green: 0.71, blue: 0.53, alpha: 1.0) // 深色模式：更亮的版本
            default:
                return UIColor(red: 0.60, green: 0.35, blue: 0.15, alpha: 1.0) // 浅色模式：原始棕褐色
            }
        })
    }
    
    var body: some View {
        ZStack {
            // 应用背景色
            backgroundColor.ignoresSafeArea()
            
            if let error = errorMessage {
                // 显示错误信息
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("数据加载出错")
                        .font(.appTitle2)
                        .foregroundColor(textColor)
                    
                    Text(error)
                        .font(.appBody)
                        .multilineTextAlignment(.center)
                        .foregroundColor(textColor)
                        .padding()
                    
                    Button("重试") {
                        checkModelContext()
                    }
                    .font(.appHeadline)
                    .padding()
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            } else {
                // 主要内容
                TabView(selection: $selectedTab) { // 绑定 selection
                            // 主页标签
                            PetsHomeView()
                                .tabItem {
                                    // 使用三元运算符根据选中状态切换图标
                                    Image(selectedTab == 0 ? "home_fill" : "home_outline")
                                    Text(LocalizedStringKey("Home"))
                                }
                                .tag(0)
                            
                            // 提醒标签
                            RemindersView()
                                .tabItem {
                                    Image(selectedTab == 1 ? "reminder_fill" : "reminder_outline")
                                    Text(LocalizedStringKey("Reminders"))
                                }
                                .tag(1)
                                
                            // 记录标签
                            RecordsView(modelContext: modelContext)
                                .tabItem {
                                    Image(selectedTab == 2 ? "record_fill" : "record_outline")
                                    Text(LocalizedStringKey("Records"))
                                }
                                .tag(2)
                            
                            // 体重标签
                            WeightView()
                                .tabItem {
                                    Image(selectedTab == 3 ? "weight_fill" : "weight_outline")
                                    Text(LocalizedStringKey("Weight"))
                                }
                                .tag(3)
                        }
                        .tint(adaptiveAccentColor)
                    }
        }
        .onAppear {
            checkModelContext()
            configureNavigationBarAppearance()
        }
    }
    
    private func checkModelContext() {
        // 简单测试模型上下文是否可用
        do {
            let pets = try modelContext.fetch(FetchDescriptor<Pet>())
            logger.info("📊 当前数据库中有 \(pets.count) 只宠物")
            
            let tags = try modelContext.fetch(FetchDescriptor<Tag>())
            logger.info("🏷️ 当前数据库中有 \(tags.count) 个标签")
            
            isModelReady = true
            errorMessage = nil
            logger.info("模型上下文检查成功，数据持久化正常")
        } catch {
            isModelReady = false
            errorMessage = "无法访问数据库: \(error.localizedDescription)"
            logger.error("模型上下文检查失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 导航栏外观配置
    private func configureNavigationBarAppearance() {
        // 使用现代的 UINavigationBarAppearance API
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(backgroundColor)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(textColor)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(textColor)]
        
        // 设置按钮颜色为适应性强调色，确保在深色模式下也清晰可见
        UINavigationBar.appearance().tintColor = UIColor(adaptiveAccentColor)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // 配置 TabBar 外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(backgroundColor)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // TabBar 使用自定义强调色，但导航栏使用系统蓝色
        UITabBar.appearance().tintColor = UIColor(accentColor)
        UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
    }
}

#Preview {
    ContentView()
}
