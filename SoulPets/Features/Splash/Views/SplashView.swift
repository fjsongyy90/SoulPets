import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 1.0
    @State private var elementsOpacity: Double = 0.0

    var body: some View {
        ZStack {
            Color(hex: "#FDFBF8")
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                VStack(spacing: 16) {
                    Image("soulpets_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .scaleEffect(logoScale)
                    
                    Text(String(localized: "SoulPets"))
                        .font(.largeTitle) // 建议使用动态字体或自定义字体
                        .foregroundColor(Color(hex: "#8B6F62"))
                }
                
                Text(String(localized: "The digital heartbeat of your\nbond with pets."))
                    .font(.body) // 建议使用动态字体或自定义字体
                    .foregroundColor(Color(hex: "#A88C7D"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .opacity(elementsOpacity)
        }
        .onAppear {
            // ✅ 只负责播放动画，不再控制消失
            startIntroAnimation()
        }
    }
    
    private func startIntroAnimation() {
        // 第一阶段：所有元素渐显
        withAnimation(.easeOut(duration: 0.8)) {
            elementsOpacity = 1.0
        }
        
        // 第二阶段：心跳动画（延迟0.8秒开始，并循环播放）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            startHeartbeatAnimation()
        }
    }
    
    private func startHeartbeatAnimation() {
        // 使用可重复的Spring动画来实现循环心跳
        withAnimation(.spring(response: 0.4, dampingFraction: 0.4).repeatForever(autoreverses: true)) {
            logoScale = 1.08
        }
    }
}

#Preview {
    SplashView()
}
