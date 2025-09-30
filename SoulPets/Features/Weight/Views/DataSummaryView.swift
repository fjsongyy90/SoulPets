import SwiftUI
import SwiftData
import OSLog

/// 体重数据摘要视图组件
struct DataSummaryView: View {
    @ObservedObject var viewModel: WeightViewModel
    @Binding var showingWeightGoal: Bool
    
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "DataSummaryView")
    
    var body: some View {
        VStack(spacing: 16) {
            // 上方：两个小卡片并排
            HStack(spacing: 12) {
                currentWeightCompactCard
                
                weightChangeCompactCard
            }
            
            // 下方：体重目标大卡片（仪表盘）
            weightGoalDashboard
        }
    }
    
    // MARK: - 子视图
    
    /// 当前体重紧凑卡片
    private var currentWeightCompactCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Current Weight"))
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
            
            if let latestWeight = viewModel.latestWeight {
                VStack(alignment: .leading, spacing: 4) {
                    Text(latestWeight.formattedWeight())
                        .font(.appTitle2)
                        .foregroundColor(.appTextPrimary)
                    
                    Text(viewModel.latestWeightDateText)
                        .font(.appCaption2)
                        .foregroundColor(.appTextSecondary)
                }
            } else {
                Text("--")
                    .font(.appTitle2)
                    .foregroundColor(.appTextPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 体重变化紧凑卡片
    private var weightChangeCompactCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Weight Change"))
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.formattedWeightTrend)
                    .font(.appTitle2)
                    .foregroundColor(weightTrendColor)
                
                if !viewModel.weightChangeComparisonText.isEmpty {
                    Text(viewModel.weightChangeComparisonText)
                        .font(.appCaption2)
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 体重目标仪表盘（大卡片）
    private var weightGoalDashboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                Text(String(localized: "Weight Goal"))
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)
                
                Spacer()
                
                Button {
                    logger.info("🎯 点击体重目标按钮")
                    showingWeightGoal = true
                } label: {
                    Text(viewModel.activeWeightGoal == nil ? 
                         String(localized: "Set Goal") : 
                         String(localized: "Edit Goal"))
                        .font(.appCaption)
                        .foregroundColor(.appAccent)
                }
            }
            
            // 目标内容
            if let goal = viewModel.activeWeightGoal {
                goalActiveContent(goal: goal)
            } else {
                goalEmptyState
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 激活目标的内容
    private func goalActiveContent(goal: WeightGoal) -> some View {
        VStack(spacing: 12) {
            // 第一行：目标信息和进度
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target: \(goal.targetWeight, specifier: "%.1f") \(goal.pet.weightUnitPreference.rawValue)")
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)
                    
                    Text(viewModel.goalActionSuggestion)
                        .font(.appCaption)
                        .foregroundColor(.appAccent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedGoalProgressText)
                        .font(.appTitle3)
                        .foregroundColor(.appTextPrimary)
                    
                    if let remainingDays = viewModel.goalRemainingDays {
                        Text(remainingDays > 0 ? 
                             "\(remainingDays) days left" : 
                             "Overdue")
                            .font(.appCaption)
                            .foregroundColor(remainingDays > 0 ? .appTextSecondary : .appWarning)
                    }
                }
            }
            
            // 进度条
            ProgressView(value: viewModel.getGoalProgress(), total: 100)
                .tint(Color.appAccent)
                .scaleEffect(y: 2)
        }
    }
    
    /// 目标空状态
    private var goalEmptyState: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.appTextSecondary)
                
                Text("Set a weight goal to track progress")
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                
                Spacer()
            }
        }
    }
    
    /// 当前体重卡片（保留备用）
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


// 1. 创建一个专门用于预览的包装视图
struct DataSummaryView_PreviewWrapper: View {
    // 2. 将 @State 变量移到这里
    @State private var showingGoal = false
    
    var body: some View {
        // 3. 在这里准备数据并创建要预览的视图
        let container = try! ModelContainer(for: Pet.self, Weight.self, WeightGoal.self)
        let context = container.mainContext
        
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
        
        return DataSummaryView(viewModel: viewModel, showingWeightGoal: $showingGoal)
            .modelContainer(container)
            .padding()
            .background(Color.appBackground)
    }
}

// 4. #Preview 现在变得非常简洁
#Preview {
    DataSummaryView_PreviewWrapper()
}
