//
//  OnboardingView.swift
//  SoulPets
//
//  Created by CodeBuddy on 2025/8/23.
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showMainApp = false
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        ZStack {
            Color(hex: "#FDFBF8")
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // 页面一：欢迎与情感链接
                WelcomePageView()
                    .tag(0)
                
                // 页面二：核心功能概览
                FeaturesPageView()
                    .tag(1)
                
                // 页面三：隐私承诺
                PrivacyPageView()
                    .tag(2)
                
                // 页面四：开启旅程
                GetStartedPageView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // 顶部跳过按钮（前三页显示）
            if currentPage < 3 {
                VStack {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            hasCompletedOnboarding = true
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                    Spacer()
                }
            }
            
            // 底部页面指示器（前三页显示）
            if currentPage < 3 {
                VStack {
                    Spacer()
                    PageIndicator(currentPage: currentPage, totalPages: 4)
                        .padding(.bottom, 50)
                }
            }
        }
    }
}

// MARK: - 页面一：欢迎与情感链接
struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 主插画区域
            Image("onboarding_welcome")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 300, maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .background(
                    // 临时占位图
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            VStack {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color(hex: "#E5B487"))
                                Text("Welcome Illustration")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                )
            
            VStack(spacing: 16) {
                // 主标题
                Text("Welcome to SoulPets")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                // 副标题
                Text("The digital heartbeat of your bond with pets.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - 页面二：核心功能概览
struct FeaturesPageView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 主插画区域
            Image("onboarding_features")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 280, maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .background(
                    // 临时占位图
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            VStack(spacing: 20) {
                                // 爱心中心
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#E5B487").opacity(0.3))
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color(hex: "#E5B487"))
                                }
                                
                                // 功能图标
                                HStack(spacing: 30) {
                                    VStack {
                                        Image(systemName: "timeline.selection")
                                            .font(.system(size: 24))
                                        Text("Records")
                                            .font(.caption2)
                                    }
                                    
                                    VStack {
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 24))
                                        Text("Reminders")
                                            .font(.caption2)
                                    }
                                    
                                    VStack {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.system(size: 24))
                                        Text("Health")
                                            .font(.caption2)
                                    }
                                }
                                .foregroundColor(Color(hex: "#E5B487"))
                                
                                Text("Features Illustration")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                )
            
            VStack(spacing: 16) {
                // 主标题
                Text("All-in-One, for Your One and Only.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                // 副标题
                Text("Effortlessly track records, reminders, and health. All in one private space.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - 页面三：隐私承诺
struct PrivacyPageView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 主插画区域
            Image("onboarding_privacy")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 260, maxHeight: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .background(
                    // 临时占位图
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            VStack(spacing: 20) {
                                // 手机和盾牌
                                ZStack {
                                    // 盾牌背景
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 100))
                                        .foregroundColor(Color(hex: "#E5B487").opacity(0.3))
                                    
                                    // 手机
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .frame(width: 60, height: 100)
                                        .overlay(
                                            VStack {
                                                Circle()
                                                    .fill(Color(hex: "#E5B487"))
                                                    .frame(width: 20, height: 20)
                                                    .overlay(
                                                        Image(systemName: "pawprint.fill")
                                                            .font(.system(size: 8))
                                                            .foregroundColor(.white)
                                                    )
                                                Spacer()
                                            }
                                            .padding(8)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                Text("Privacy Illustration")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                )
            
            VStack(spacing: 20) {
                // 主标题
                Text("Your Privacy is Our Foundation.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                // 重点承诺
                VStack(spacing: 8) {
                    Text("Your pet's data never leaves your device.")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#E5B487"))
                    
                    Text("No accounts, no tracking, 100% yours.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - 页面四：开启旅程
struct GetStartedPageView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 主插画区域
            Image("onboarding_get_started")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 240, maxHeight: 240)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .background(
                    // 临时占位图
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            VStack(spacing: 15) {
                                // 可爱宠物
                                Circle()
                                    .fill(Color(hex: "#E5B487").opacity(0.3))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "pawprint.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(Color(hex: "#E5B487"))
                                    )
                                
                                // 加号图标
                                Circle()
                                    .fill(Color(hex: "#E5B487"))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                Text("Get Started Illustration")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                )
            
            VStack(spacing: 30) {
                // 主标题
                Text("Ready to Start the Journey?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
                    // 开始按钮
                    Button(action: {
                        requestNotificationPermission()
                        hasCompletedOnboarding = true
                    }) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "#E5B487"))
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 40)
                    
                    // 权限说明
                    Text("We'll request notification permission to send you timely reminders. You can change this in Settings anytime.")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                // 无论是否授权，都继续进入主应用
                print("Notification permission granted: \(granted)")
            }
        }
    }
}

// MARK: - 页面指示器
struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color(hex: "#E5B487") : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}

// MARK: - 调试扩展
extension OnboardingView {
    /// 重置欢迎页状态（仅用于调试）
    static func resetOnboardingStatus() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        print("🔄 已重置欢迎页状态，下次启动将显示欢迎页")
    }
}