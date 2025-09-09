import SwiftUI
import SwiftData
import OSLog

/// 体重数据摘要视图组件
struct DataSummaryView: View {
    @ObservedObject var viewModel: WeightViewModel
    @Binding var showingWeightGoal: Bool
    
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "DataSummaryView")
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // 当前体重卡片
                currentWeightCard
                
                // 体重变化卡片
                weightChangeCard
            }
            
            // 体重目标卡片
            weightGoalCard
        }
    }
    
    // MARK: - 子视图
    
    /// 当前体重卡片
    private var currentWeightCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Current Weight"))
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
            
            Text(viewModel.formattedCurrentWeight)
                .font(.appTitle2)
                .foregroundColor(.appTextPrimary)
            
            if !viewModel.formattedCurrentWeightDate.isEmpty {
                Text(viewModel.formattedCurrentWeightDate)
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 体重变化卡片
    private var weightChangeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Weight Change"))
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
            
            Text(viewModel.formattedWeightTrend)
                .font(.appTitle2)
                .foregroundColor(weightTrendColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 体重目标卡片
    private var weightGoalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Weight Goal"))
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)
                
                Spacer()
                
                Button {
                    logger.info("🎯 点击体重目标按钮")
                    showingWeightGoal = true
                } label: {
                    Text(viewModel.goalButtonText)
                        .font(.appCaption)
                        .foregroundColor(.appAccent)
                }
            }
            
            if viewModel.hasActiveGoal {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.formattedGoalStatusText)
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)
                    
                    HStack {
                        Text(String(localized: "Progress:"))
                            .font(.appBody)
                            .foregroundColor(.appTextSecondary)
                        Text(viewModel.formattedGoalProgressText)
                            .font(.appBody)
                            .fontWeight(.semibold)
                            .foregroundColor(.appAccent)
                        Spacer()
                        Text(viewModel.formattedGoalRemainingDays)
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    // 进度条
                    ProgressView(value: viewModel.getGoalProgress(), total: 100)
                        .tint(Color.appAccent)
                }
                .onAppear {
                    if let goal = viewModel.activeWeightGoal {
                        logger.debug("🎯 显示活跃体重目标: \(goal.targetWeight) \(goal.unit.rawValue)")
                    }
                }
            } else {
                Text(viewModel.formattedGoalStatusText)
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                    .onAppear {
                        logger.debug("❌ 无活跃体重目标，显示设置提示")
                    }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            logger.info("🎯 体重目标卡片显示，当前目标状态: \(viewModel.hasActiveGoal ? "有目标" : "无目标")")
        }
    }
    
    // MARK: - 计算属性
    
    /// 体重变化趋势的颜色
    private var weightTrendColor: Color {
        switch viewModel.weightTrendType {
        case .increase:
            return .appWarning // 增重使用警告色
        case .decrease:
            return .appSuccess // 减重使用成功色
        case .noChange:
            return .appTextPrimary // 无变化使用主要文本色
        case .noData:
            return .appTextPrimary // 无数据使用主要文本色
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Pet.self, Weight.self, WeightGoal.self)
    let context = container.mainContext
    
    // 创建示例数据
    let samplePet = Pet(
        name: "Fluffy",
        petType: .cat,
        breed: "Persian",
        gender: .female,
        isNeutered: true,
        birthday: Date(),
        adoptionDay: Date()
    )
    
    context.insert(samplePet)
    
    let viewModel = WeightViewModel()
    viewModel.loadWeightData(for: samplePet, modelContext: context)
    
    @State var showingGoal = false
    
    return DataSummaryView(viewModel: viewModel, showingWeightGoal: $showingGoal)
        .modelContainer(container)
        .padding()
        .background(Color.appBackground)
}
