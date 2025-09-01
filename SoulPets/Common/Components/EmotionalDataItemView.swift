import SwiftUI

/// 情感化数据项视图 - 用于显示带有情感化文案的数据项
struct EmotionalDataItemView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 数值 - 顶部显示
            Text(value)
                .font(.custom("Nunito-Bold", size: 18))
                .foregroundColor(Color(hex: "A88C7D"))
                .frame(maxWidth: .infinity, alignment: .center)
            
            // 标签 - 底部显示情感化文案
            Text(label)
                .font(.custom("Nunito-Regular", size: 12))
                .foregroundColor(Color(hex: "A88C7D").opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

#Preview("情感数据项") {
    VStack(spacing: 20) {
        EmotionalDataItemView(
            value: "2y 5m 3d",
            label: "Time in this world"
        )
        
        EmotionalDataItemView(
            value: "642 days",
            label: "Guarding each other for"
        )
        
        EmotionalDataItemView(
            value: "in 362 days",
            label: "Next celebration in"
        )
    }
    .padding()
    .background(Color(hex: "F7F1E8"))
}
