import SwiftUI
import SwiftData
import Charts
import OSLog

/// 体重图表视图组件
struct WeightChartView: View {
    @ObservedObject var viewModel: WeightViewModel
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "WeightChartView")

    // ✅ 1. 计算X轴的精确范围
    private var chartXDomain: ClosedRange<Date> {
        // 找到数据中的最早日期，如果没有数据，则回退到3个月前
        let minDataDate = viewModel.chartData.first?.date
        let fallbackStartDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let startDate = minDataDate ?? fallbackStartDate

        // 找到数据中的最晚日期，如果没有数据，则回退到今天
        let maxDataDate = viewModel.chartData.last?.date
        let today = Date()
        let endDateCandidate = maxDataDate ?? today

        // X轴的结束点取 “今天” 和 “最晚数据日期” 中的较晚者，再加上一点填充（例如5天）
        let effectiveEndDate = max(endDateCandidate, today)
        let paddedEndDate = Calendar.current.date(byAdding: .day, value: 5, to: effectiveEndDate) ?? effectiveEndDate

        // 确保开始日期不晚于结束日期
        if startDate > paddedEndDate {
             return startDate...startDate
        }

        return startDate...paddedEndDate
    }

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

    /// 标题视图 (保持不变)
    private var headerView: some View {
        HStack {
            Text(String(localized: "Weight Trend"))
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)

            Spacer()

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

    /// 图表内容 (保持不变)
    private var chartContent: some View {
        Group {
            if viewModel.chartData.isEmpty {
                emptyChartView
            } else {
                weightChart
            }
        }
    }

    /// 空状态图表视图 (保持不变)
    private var emptyChartView: some View {
        Text(viewModel.chartEmptyStateText)
            .font(.appBody)
            .foregroundColor(.appTextSecondary)
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)
            .cornerRadius(12)
    }

    /// 体重图表 (核心修改处)
    private var weightChart: some View {
        Chart(viewModel.chartData, id: \.id) { weight in
            // 区域填充 (保持不变)
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

            // 曲线 (保持不变)
            LineMark(
                x: .value("Date", weight.date),
                y: .value("Weight", weight.formattedWeightValue)
            )
            .foregroundStyle(Color.appAccent)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.cardinal)

            // 数据点 (保持不变)
            PointMark(
                x: .value("Date", weight.date),
                y: .value("Weight", weight.formattedWeightValue)
            )
            .foregroundStyle(Color.appAccent)
            .symbol(Circle())
            .symbolSize(60)

            // 目标线 (保持不变)
            if let goal = viewModel.activeWeightGoal {
                RuleMark(y: .value("Target", goal.targetWeightInPreferredUnit))
                    .foregroundStyle(Color.appWarning)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .annotation(position: .topTrailing) {
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("Target: %.1f %@", comment: ""),
                            goal.targetWeightInPreferredUnit,
                            goal.pet?.weightUnitPreference?.rawValue ?? "kg"
                        ))
                            .font(.appCaption)
                            .foregroundColor(.appWarning)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cardBackground.opacity(0.8))
                            .cornerRadius(6)
                            // ✅ 新增：添加一个微小的向左偏移量
                            .offset(x: 5) // 尝试 -5 或 -8 看看效果
                    }
            }
        }
        // ✅ 2. 强制图表使用我们计算好的X轴范围
        .chartXScale(domain: chartXDomain)
        .chartYAxis {
            // Y轴样式 (保持不变)
            AxisMarks(values: .automatic) { _ in }
        }
        .chartXAxis {
            // ✅ 3. X轴样式：使用 .automatic 让系统在指定范围内自动选择刻度
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                    .foregroundStyle(Color.appTextSecondary.opacity(0.2))
                // 可以保留日期格式，如果觉得标签太密，可以移除 format 参数
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.appCaption2)
                    .foregroundStyle(Color.appTextSecondary.opacity(0.6))
            }
        }
        .frame(height: 220)
        // 移除了这里的 .padding()，因为父VStack已经有padding
        // 移除了这里的 .background & .cornerRadius & .shadow，因为父VStack已经应用
    }
}

// ✅ 4. (重要) 在 WeightGoal 中添加一个计算属性，用于获取转换单位后的目标体重
// 请找到 WeightGoal.swift 文件，并在其中添加这个计算属性：
/*
extension WeightGoal {
    /// 计算属性：获取根据宠物偏好单位转换后的目标体重值
    var targetWeightInPreferredUnit: Double {
        guard let petUnit = pet?.weightUnitPreference, let goalUnit = unit else {
            return targetWeight // 如果缺少信息，返回原始值
        }

        if petUnit == goalUnit {
            return targetWeight // 单位一致，直接返回
        } else if petUnit == .lbs && goalUnit == .kg {
            return targetWeight * 2.20462 // kg -> lbs
        } else if petUnit == .kg && goalUnit == .lbs {
            return targetWeight / 2.20462 // lbs -> kg
        } else {
            return targetWeight // 其他情况（理论上不应发生）
        }
    }
}
*/


#Preview {
    // ... Preview 代码保持不变 ...
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

    // 添加一些体重数据用于预览
    let calendar = Calendar.current
    let today = Date()
    let weight1 = Weight(date: calendar.date(byAdding: .month, value: -2, to: today)!, weightInKg: 4.5, pet: samplePet)
    let weight2 = Weight(date: calendar.date(byAdding: .month, value: -1, to: today)!, weightInKg: 4.3, pet: samplePet)
    let weight3 = Weight(date: today, weightInKg: 4.2, pet: samplePet)
    context.insert(weight1)
    context.insert(weight2)
    context.insert(weight3)

    // 添加一个目标用于预览
    let goal = WeightGoal(targetWeight: 4.0, unit: .kg, startDate: today, targetDate: calendar.date(byAdding: .month, value: 3, to: today)!, pet: samplePet)
    context.insert(goal)


    let viewModel = WeightViewModel()
    // 确保ViewModel加载了数据
    viewModel.loadWeightData(for: samplePet, modelContext: context)

    return WeightChartView(viewModel: viewModel)
        .modelContainer(container)
        .padding()
        .background(Color.appBackground)
}
