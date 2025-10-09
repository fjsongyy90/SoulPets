import SwiftUI
import SwiftData
import OSLog

/// 体重历史记录列表视图组件
struct WeightHistoryListView: View {
    @ObservedObject var viewModel: WeightViewModel
    @Binding var weightToEdit: Weight?
    @Binding var weightToDelete: Weight?
    @Binding var showingDeleteAlert: Bool
    
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "WeightHistoryListView")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            Text(String(localized: "Weight History"))
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
            
            // 历史记录列表
            if viewModel.weightEntries.isEmpty {
                emptyHistoryView
            } else {
                historyList
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 空状态历史视图
    private var emptyHistoryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "scalemass")
                .font(.system(size: 40))
                .foregroundColor(.appTextSecondary)
            
            Text(viewModel.historyEmptyStateText)
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 历史记录列表
    private var historyList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(viewModel.weightEntries.enumerated()), id: \.element.id) { index, weight in
                VStack(spacing: 0) {
                    // --- MODIFICATION START ---
                    // 移除了 .swipeActions 和 .contextMenu，因为操作已移入行内的按钮
                    weightHistoryRowLight(weight: weight)
                    // --- MODIFICATION END ---
                    
                    // 分割线（最后一项不显示）
                    if index < viewModel.weightEntries.count - 1 {
                        Divider()
                            .background(Color.appTextSecondary.opacity(0.2))
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }
    
    /// 轻量化的体重历史记录行
    private func weightHistoryRowLight(weight: Weight) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                // --- MODIFICATION START ---
                // 1. 在体重数值后拼接单位
                if let pet = weight.pet {
                    let unitStr = pet.weightUnitPreference?.rawValue ?? "kg"
                    Text("\(weight.formattedWeight()) \(unitStr)")
                        .font(.appBody)
                        .fontWeight(.medium)
                        .foregroundColor(.appTextPrimary)
                }
                // --- MODIFICATION END ---
                
                Text(weight.date, style: .date)
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
            }
            
            Spacer()
            
            // 可选：显示变化趋势
            if let previousWeight = previousWeight(for: weight) {
                let change = weight.weightInKg - previousWeight.weightInKg
                if abs(change) > 0.05 { // 只显示有意义的变化
                    HStack(spacing: 4) {
                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .font(.appCaption2)
                            .foregroundColor(change > 0 ? .appWarning : .appSuccess)
                        
                        Text(String(format: "%.1f", abs(change)))
                            .font(.appCaption2)
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            
            // --- MODIFICATION START ---
            // 2. 添加“更多”操作按钮
            Menu {
                // 编辑按钮
                Button {
                    weightToEdit = weight
                } label: {
                    Label(String(localized: "Edit"), systemImage: "pencil")
                }
                
                // 删除按钮
                Button(role: .destructive) {
                    weightToDelete = weight
                    showingDeleteAlert = true
                } label: {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.appTextSecondary)
                    .frame(width: 44, height: 44, alignment: .trailing) // 增大点击区域
            }
            // --- MODIFICATION END ---
        }
        .padding(.leading, 16)
        // 右侧内边距设为0，让按钮可以紧贴边缘，视觉上更好对齐
        .padding(.trailing, 0)
        .padding(.vertical, 12)
        .background(Color.clear) // 透明背景
    }
    
    /// 获取前一条体重记录
    private func previousWeight(for weight: Weight) -> Weight? {
        guard let index = viewModel.weightEntries.firstIndex(of: weight),
              index < viewModel.weightEntries.count - 1 else {
            return nil
        }
        return viewModel.weightEntries[index + 1]
    }
}


// 1. 创建包装视图
struct WeightHistoryListView_PreviewWrapper: View {
    // 2. 将所有的 @State 变量都移到这里
    @State private var weightToEdit: Weight? = nil
    @State private var weightToDelete: Weight? = nil
    @State private var showingDeleteAlert = false
    
    var body: some View {
        // 3. 准备数据和视图
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
        
        let weight1 = Weight(date: Date().addingTimeInterval(-86400 * 7), weightInKg: 4.5, pet: samplePet)
        let weight2 = Weight(date: Date().addingTimeInterval(-86400 * 3), weightInKg: 4.3, pet: samplePet)
        let weight3 = Weight(date: Date(), weightInKg: 4.2, pet: samplePet)
        
        context.insert(weight1)
        context.insert(weight2)
        context.insert(weight3)
        
        let viewModel = WeightViewModel()
        viewModel.loadWeightData(for: samplePet, modelContext: context)
        
        return WeightHistoryListView(
            viewModel: viewModel,
            weightToEdit: $weightToEdit,
            weightToDelete: $weightToDelete,
            showingDeleteAlert: $showingDeleteAlert
        )
        .modelContainer(container)
        .padding()
        .background(Color.appBackground)
    }
}

// 4. #Preview 变得非常简洁
#Preview {
    WeightHistoryListView_PreviewWrapper()
}
