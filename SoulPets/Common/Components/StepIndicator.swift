import SwiftUI

/// 步骤指示器组件
struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitles: [String]
    
    var body: some View {
        HStack {
            ForEach(0..<totalSteps, id: \.self) { step in
                VStack(spacing: 8) {
                    // 步骤圆圈
                    ZStack {
                        Circle()
                            .fill(step <= currentStep ? Color("AccentColor") : Color(.systemGray5))
                            .frame(width: 30, height: 30)
                        
                        Text("\(step + 1)")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(step <= currentStep ? .white : .gray)
                    }
                    
                    // 步骤标题
                    Text(LocalizedStringKey(stepTitles[step]))
                        .font(.caption)
                        .foregroundColor(step <= currentStep ? Color("AccentColor") : .gray)
                }
                
                // 连接线
                if step < totalSteps - 1 {
                    Spacer()
                    Rectangle()
                        .fill(step < currentStep ? Color("AccentColor") : Color(.systemGray5))
                        .frame(height: 2)
                    Spacer()
                }
            }
        }
        .padding()
    }
}

#Preview {
    StepIndicator(
        currentStep: 1,
        totalSteps: 3,
        stepTitles: ["Pet Type", "Basic Info", "Important Dates"]
    )
} 