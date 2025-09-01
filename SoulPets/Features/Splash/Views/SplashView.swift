import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 1.0
    @State private var elementsOpacity: Double = 0.0 // 合并透明度控制
    @Binding var showSplash: Bool
    
    // MARK: - 优化后的代码
    var body: some View {
        ZStack {
            // 背景色 (来自您的项目)
            Color(hex: "#FDFBF8")
                .ignoresSafeArea()
            
            VStack(spacing: 25) { // 优化间距
                // Logo & 品牌名
                VStack(spacing: 16) {
                    Image("soulpets_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .scaleEffect(logoScale)
                    
                    Text("SoulPets")
                        .font(.custom("Nunito-ExtraBold", size: 36)) // 优化字体
                        .foregroundColor(Color(hex: "#8B6F62"))   // 优化颜色
                }
                
                // Slogan
                Text("The digital heartbeat of\nyour bond with pets.")
                    .font(.custom("Nunito-Regular", size: 17)) // 优化字体
                    .foregroundColor(Color(hex: "#A88C7D"))   // 优化颜色
                    .multilineTextAlignment(.center)
                    .lineSpacing(6) // 优化行间距
            }
            .opacity(elementsOpacity)
        }
        .onAppear {
            startSplashAnimation()
        }
    }
    
    private func startSplashAnimation() {
        // 第一阶段：所有元素渐显
        withAnimation(.easeOut(duration: 0.8)) {
            elementsOpacity = 1.0
        }
        
        // 第二阶段：心跳动画（延迟0.8秒开始）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            startHeartbeatAnimation()
        }
        
        // 第三阶段：结束启动页（总时长约2.8秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                // 为了平滑过渡，让元素在页面消失前渐隐
                elementsOpacity = 0.0
            }
            // 确保动画有时间播放完毕
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showSplash = false
            }
        }
    }
    
    private func startHeartbeatAnimation() {
        // 优化后的心跳动画，使用Spring
        let sequenceTimer = 0.5 // 每次心跳的间隔
        
        // 第一次心跳
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
            logoScale = 1.08 // 增加心跳幅度
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + sequenceTimer) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                logoScale = 1.0
            }
        }
        
        // 第二次心跳
        DispatchQueue.main.asyncAfter(deadline: .now() + sequenceTimer * 1.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                logoScale = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + sequenceTimer) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    logoScale = 1.0
                }
            }
        }
    }
}

#Preview {
    SplashView(showSplash: .constant(true))
}
