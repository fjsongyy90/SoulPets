import SwiftUI

/// 进度条组件
struct ProgressBar: View {
    var progress: CGFloat // 0-1之间
    
    // 确保进度值是有效的
    private var safeProgress: CGFloat {
        guard progress.isFinite else { return 0.0 }
        return min(max(progress, 0.0), 1.0)
    }
    
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
                    .frame(width: max(0, geometry.size.width * safeProgress), height: 8)
                    .cornerRadius(4)
                
                // 进度点
                Circle()
                    .fill(Color(red: 0.85, green: 0.60, blue: 0.35))
                    .frame(width: 16, height: 16)
                    .offset(x: max(0, min(geometry.size.width * safeProgress - 8, geometry.size.width - 16)))
            }
        }
        .frame(height: 16)
    }
}

#Preview {
    ProgressBar(progress: 0.7)
        .padding()
} 