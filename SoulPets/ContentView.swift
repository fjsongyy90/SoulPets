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
    private let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "ContentView")
    @State private var isModelReady = false
    @State private var errorMessage: String? = nil
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
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
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(textColor)
                        .padding()
                    
                    Button("重试") {
                        checkModelContext()
                    }
                    .padding()
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            } else {
                // 主要内容
                TabView {
                    // 主页标签
                    PetsHomeView()
                        .tabItem {
                            Label(LocalizedStringKey("Home"), systemImage: "house")
                        }
                    
                    // 记录标签
                    RecordsView(modelContext: modelContext)
                        .tabItem {
                            Label(LocalizedStringKey("Records"), systemImage: "list.bullet.clipboard")
                        }
                    
                    // 提醒标签 (未来实现)
                    Text(LocalizedStringKey("Reminders Coming Soon"))
                        .foregroundColor(textColor)
                        .tabItem {
                            Label(LocalizedStringKey("Reminders"), systemImage: "bell")
                        }
                    
                    // 体重标签 (未来实现)
                    Text(LocalizedStringKey("Weight Coming Soon"))
                        .foregroundColor(textColor)
                        .tabItem {
                            Label(LocalizedStringKey("Weight"), systemImage: "scalemass")
                        }
                }
                .accentColor(accentColor)
            }
        }
        .onAppear {
            checkModelContext()
        }
    }
    
    private func checkModelContext() {
        // 简单测试模型上下文是否可用
        do {
            let _ = try modelContext.fetch(FetchDescriptor<Pet>())
            isModelReady = true
            errorMessage = nil
            logger.info("模型上下文检查成功")
        } catch {
            isModelReady = false
            errorMessage = "无法访问数据库: \(error.localizedDescription)"
            logger.error("模型上下文检查失败: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
