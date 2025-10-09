import SwiftUI
import SwiftData
import Charts
import OSLog

/// 体重图表视图组件
struct WeightChartView: View {
    @ObservedObject var viewModel: WeightViewModel
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "WeightChartView")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            headerView
            
            // 图表内容
            chartContent
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 子视图
    
    /// 标题视图
    private var headerView: some View {
        HStack {
            Text(String(localized: "Weight Trend"))
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
            
            Spacer()
            
            // 时间范围选择菜单（放在标题右侧）
            Menu {
                ForEach(WeightChartTimeRange.allCases, id: \.self) { range in
                    Button {
                        viewModel.selectedTimeRange = range
                    } label: {
                        Text(range.localizedString)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.selectedTimeRange.localizedString)
                        .font(.appCaption)
                        .foregroundColor(.appTextPrimary)
                    Image(systemName: "chevron.down")
                        .font(.appCaption2)
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(16)
            }
        }
    }
    
    /// 图表内容
    private var chartContent: some View {
        Group {
            if viewModel.chartData.isEmpty {
                emptyChartView
            } else {
                weightChart
            }
        }
    }
    
    /// 空状态图表视图
    private var emptyChartView: some View {
        Text(viewModel.chartEmptyStateText)
            .font(.appBody)
            .foregroundColor(.appTextSecondary)
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)
            .cornerRadius(12)
    }
    
    /// 体重图表
    private var weightChart: some View {
        Chart(viewModel.chartData, id: \.id) { weight in
            // 区域填充 - 增加视觉质感
            AreaMark(
                x: .value("Date", weight.date),
                y: .value("Weight", weight.formattedWeightValue)
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.appAccent.opacity(0.3),
                        Color.appAccent.opacity(0.1),
                        Color.appAccent.opacity(0.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // 曲线
            LineMark(
                x: .value("Date", weight.date),
                y: .value("Weight", weight.formattedWeightValue)
            )
            .foregroundStyle(Color.appAccent)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.cardinal)
            
            // 数据点
            PointMark(
                x: .value("Date", weight.date),
                y: .value("Weight", weight.formattedWeightValue)
            )
            .foregroundStyle(Color.appAccent)
            .symbol(Circle())
            .symbolSize(60)
            
            // 目标线
            if let goal = viewModel.activeWeightGoal {
                RuleMark(y: .value("Target", goal.targetWeight))
                    .foregroundStyle(Color.appWarning)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .annotation(position: .topTrailing) {
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("Target: %.1f %@", comment: ""),
                            goal.targetWeight,
                            goal.pet?.weightUnitPreference?.rawValue ?? "kg"
                        ))
                            .font(.appCaption)
                            .foregroundColor(.appWarning)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cardBackground)
                            .cornerRadius(6)
                    }
            }
        }
        .chartYAxis {
            // 移除Y轴标签和刻度线，让图表更干净
            AxisMarks(values: .automatic) { _ in }
        }
        .chartXAxis {
            // 弱化X轴样式
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                    .foregroundStyle(Color.appTextSecondary.opacity(0.2))
                AxisValueLabel()
                    .font(.appCaption2)
                    .foregroundStyle(Color.appTextSecondary.opacity(0.6))
            }
        }
        .frame(height: 220)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
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
    
    return WeightChartView(viewModel: viewModel)
        .modelContainer(container)
        .padding()
        .background(Color.appBackground)
}
