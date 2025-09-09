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
            
            // 时间范围选择器
            timeRangeSelector
            
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
        }
    }
    
    /// 时间范围选择器
    private var timeRangeSelector: some View {
        HStack(spacing: 8) {
            ForEach(WeightChartTimeRange.allCases, id: \.self) { range in
                Button {
                    viewModel.selectedTimeRange = range
                } label: {
                    Text(range.localizedString)
                        .font(.appCaption)
                        .foregroundColor(viewModel.selectedTimeRange == range ? .white : .appTextPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.selectedTimeRange == range ? .appAccent : Color.gray.opacity(0.1))
                        )
                }
            }
            
            Spacer()
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
            LineMark(
                x: .value("Date", weight.date),
                y: .value("Weight", weight.formattedWeightValue)
            )
            .foregroundStyle(Color.appAccent)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            PointMark(
                x: .value("Date", weight.date),
                y: .value("Weight", weight.formattedWeightValue)
            )
            .foregroundStyle(Color.appAccent)
            .symbol(Circle())
            
            // 目标线
            if let goal = viewModel.activeWeightGoal {
                RuleMark(y: .value("Target", goal.targetWeight))
                    .foregroundStyle(Color.appError)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
        }
        .frame(height: 200)
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
