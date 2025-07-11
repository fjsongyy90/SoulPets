import SwiftUI

/// 进度条组件
struct ProgressBar: View {
    var progress: CGFloat // 0-1之间
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景条
                Rectangle()
                    .fill(Color(red: 0.95, green: 0.91, blue: 0.85))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                // 进度条
                Rectangle()
                    .fill(Color(red: 0.85, green: 0.60, blue: 0.35))
                    .frame(width: geometry.size.width * progress, height: 8)
                    .cornerRadius(4)
                
                // 进度点
                Circle()
                    .fill(Color(red: 0.85, green: 0.60, blue: 0.35))
                    .frame(width: 16, height: 16)
                    .offset(x: geometry.size.width * progress - 8)
            }
        }
        .frame(height: 16)
    }
}

#Preview {
    ProgressBar(progress: 0.7)
        .padding()
} 