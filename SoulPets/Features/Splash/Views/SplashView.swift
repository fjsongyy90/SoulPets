//
//  SplashView.swift
//  SoulPets
//
//  Created by CodeBuddy on 2025/8/24.
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 1.0
    @State private var logoOpacity: Double = 0.0
    @State private var sloganOpacity: Double = 0.0
    @State private var heartbeatCount = 0
    @Binding var showSplash: Bool
    
    var body: some View {
        ZStack {
            // 背景色
            Color(hex: "#FDFBF8")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 中央Logo区域
                VStack(spacing: 20) {
                    // Logo占位图
                    Image("soulpets_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .background(
                            // 临时占位Logo
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#E5B487").opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                // 爪印图标
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color(hex: "#E5B487"))
                                    .overlay(
                                        // 心形镂空效果
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color(hex: "#FDFBF8"))
                                            .offset(y: -5)
                                    )
                            }
                        )
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // 品牌名称
                    Text("SoulPets")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .opacity(logoOpacity)
                }
                
                // 品牌口号
                VStack(spacing: 8) {
                    Text("The digital heartbeat of your")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                    
                    Text("bond with pets.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                }
                .multilineTextAlignment(.center)
                .opacity(sloganOpacity)
                
                Spacer()
            }
        }
        .onAppear {
            startSplashAnimation()
        }
    }
    
    private func startSplashAnimation() {
        // 第一阶段：Logo渐显
        withAnimation(.easeOut(duration: 0.6)) {
            logoOpacity = 1.0
        }
        
        // 第二阶段：Slogan渐显（延迟0.3秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.6)) {
                sloganOpacity = 1.0
            }
        }
        
        // 第三阶段：心跳动画（延迟0.8秒开始）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            startHeartbeatAnimation()
        }
        
        // 第四阶段：结束启动页（总时长2.5秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                showSplash = false
            }
        }
    }
    
    private func startHeartbeatAnimation() {
        // 心跳动画：轻微的缩放效果，循环2次
        let heartbeatAnimation = Animation
            .easeInOut(duration: 0.6)
            .repeatCount(2, autoreverses: true)
        
        withAnimation(heartbeatAnimation) {
            logoScale = 1.03
        }
        
        // 动画结束后恢复原始大小
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                logoScale = 1.0
            }
        }
    }
}

#Preview {
    SplashView(showSplash: .constant(true))
}