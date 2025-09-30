//
//  OnboardingView.swift
//  SoulPets
//
//  Created by CodeBuddy on 2025/8/23.
//
//  Optimized by a 20-year Senior iOS UI/Dev Expert on 2025/9/1.
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        ZStack {
            // 背景色保持不变，符合品牌调性
            Color(hex: "#FDFBF8")
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                WelcomePageView().tag(0)
                FeaturesPageView().tag(1)
                PrivacyPageView().tag(2)
                GetStartedPageView(hasCompletedOnboarding: $hasCompletedOnboarding).tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            // 使用更平滑的动画曲线
            .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: currentPage)
            
            // 顶部跳过按钮（前三页显示）
            if currentPage < 3 {
                VStack {
                    HStack {
                        Spacer()
                        Button(String(localized: "Skip")) {
                            // 点击跳过时，增加一个动画效果
                            withAnimation {
                                hasCompletedOnboarding = true
                            }
                        }
                        .font(.appCallout)
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                    Spacer()
                }
                .transition(.opacity) // 跳过按钮在最后一页消失时有淡出效果
            }
            
            // 底部页面指示器
            VStack {
                Spacer()
                PageIndicator(currentPage: currentPage, totalPages: 4)
                    // 优化：调整指示器位置，使其更协调
                    .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - 页面一：欢迎与情感链接
struct WelcomePageView: View {
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) { // 优化：使用自定义间距
            Spacer(minLength: 80) // 优化：向上推内容，让版式更稳定

            // 主插画区域
            Image("onboarding_welcome")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(maxWidth: 300, maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                // ... 占位图代码保持不变 ...
            
            Spacer().frame(height: 50) // 优化：拉开插画与文字的距离

            VStack(spacing: 12) { // 优化：缩小主副标题间距
                // 主标题
                Text(String(localized: "Welcome to SoulPets"))
                    .font(.appPetCardName)
                    .foregroundColor(.black)
                
                // 副标题
                Text(String(localized: "The digital heartbeat of your bond with pets."))
                    .font(.appOnboardingSubtitle)
                    .foregroundColor(.black.opacity(0.7))
                    .lineSpacing(5) // 优化：增加行间距
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(showContent ? 1 : 0) // 动效
            .offset(y: showContent ? 0 : 20) // 动效
            
            Spacer(minLength: 120) // 优化：确保底部有足够空间
        }
        .padding(.horizontal, 30)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}

// MARK: - 页面二：核心功能概览
struct FeaturesPageView: View {
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)

            // 主插画区域
            Image("onboarding_features")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(maxWidth: 280, maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                // ... 占位图代码保持不变 ...

            Spacer().frame(height: 50)

            VStack(spacing: 12) {
                // 主标题
                Text(String(localized: "All-in-One, for Your One and Only."))
                    .font(.appTitle)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                // 副标题
                Text(String(localized: "Effortlessly track records, reminders, and health. All in one private space."))
                    .font(.appCallout)
                    .foregroundColor(.black.opacity(0.7))
                    .lineSpacing(4) // 优化：增加行间距
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            .opacity(showContent ? 1 : 0) // 动效
            .offset(y: showContent ? 0 : 20) // 动效
            
            Spacer(minLength: 120)
        }
        .padding(.horizontal, 30)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - 页面三：隐私承诺
struct PrivacyPageView: View {
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)

            // 主插画区域
            Image("onboarding_privacy")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(maxWidth: 260, maxHeight: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                // ... 占位图代码保持不变 ...

            Spacer().frame(height: 50)

            VStack(spacing: 24) { // 优化：调整间距
                // 主标题
                Text(String(localized: "Your Privacy is Our Foundation."))
                    .font(.appTitle)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                // 重点承诺
                VStack(spacing: 10) {
                    // 优化：强化核心承诺，增加背景使其突出
                    Text(String(localized: "Your pet's data never leaves your device."))
                        .font(.appTitle3)
                        .foregroundColor(Color(hex: "#C98B5F"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#E5B487").opacity(0.15))
                        .cornerRadius(12)
                    
                    Text(String(localized: "No accounts, no tracking, 100% yours."))
                        .font(.appCallout)
                        .foregroundColor(.black.opacity(0.7))
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .opacity(showContent ? 1 : 0) // 动效
            .offset(y: showContent ? 0 : 20) // 动效
            
            Spacer(minLength: 120)
        }
        .padding(.horizontal, 30)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                showContent = true
            }
        }
    }
}


// MARK: - 页面四：开启旅程
struct GetStartedPageView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var showContent = false
    @State private var isButtonPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)

            // 主插画区域
            Image("onboarding_get_started")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(maxWidth: 240, maxHeight: 240)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                // ... 占位图代码保持不变 ...

            Spacer().frame(height: 60)

            VStack(spacing: 40) { // 优化：拉开标题与按钮的距离
                // 主标题
                Text(String(localized: "Ready to Start the Journey?"))
                    .font(.appTitle)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) { // 优化：缩小按钮与说明文字的距离
                    // 开始按钮
                    Button(action: {
                        requestNotificationPermission()
                        withAnimation {
                           hasCompletedOnboarding = true
                        }
                    }) {
                        Text(String(localized: "Get Started"))
                            .font(.appDataValue)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "#E5B487"))
                            .cornerRadius(28)
                    }
                    .scaleEffect(isButtonPressed ? 0.98 : 1.0) // 优化：增加按钮按压动效
                    .pressEvents {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isButtonPressed = true
                        }
                    } onRelease: {
                        withAnimation(.easeInOut) {
                            isButtonPressed = false
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // 权限说明
                    // 优化：精简文案
                    Text(String(localized: "We'll ask for permission to send timely reminders."))
                        .font(.appSmallText)
                        .foregroundColor(.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 45) // 优化：调整内边距
                }
            }
            .opacity(showContent ? 1 : 0) // 动效
            .offset(y: showContent ? 0 : 20) // 动效
            
            Spacer(minLength: 120)
        }
        .padding(.horizontal, 30)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                showContent = true
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
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
        HStack(spacing: 10) { // 优化：增加指示器间距
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color(hex: "#E5B487") : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    // 优化：使用更有弹性的动画
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}

// MARK: - 调试/辅助代码
extension OnboardingView {
    /// 重置欢迎页状态（仅用于调试）
    static func resetOnboardingStatus() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        print("🔄 已重置欢迎页状态，下次启动将显示欢迎页")
    }
}


// 辅助扩展：简化按钮按压事件处理
struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        onPress()
                    })
                    .onEnded({ _ in
                        onRelease()
                    })
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressActions(onPress: {
            onPress()
        }, onRelease: {
            onRelease()
        }))
    }
}
