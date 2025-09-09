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
        LazyVStack(spacing: 8) {
            ForEach(viewModel.weightEntries) { weight in
                weightHistoryRow(weight)
            }
        }
    }
    
    /// 体重历史记录行
    private func weightHistoryRow(_ weight: Weight) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(weight.formattedWeight())
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.appTextPrimary)
                
                Text(weight.date, style: .date)
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
            }
            
            Spacer()
            
            // 编辑按钮
            Button {
                weightToEdit = weight
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.appAccent)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .contextMenu {
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
    
    // 添加一些示例体重记录
    let weight1 = Weight(date: Date().addingTimeInterval(-86400 * 7), weightInKg: 4.5, pet: samplePet)
    let weight2 = Weight(date: Date().addingTimeInterval(-86400 * 3), weightInKg: 4.3, pet: samplePet)
    let weight3 = Weight(date: Date(), weightInKg: 4.2, pet: samplePet)
    
    context.insert(weight1)
    context.insert(weight2)
    context.insert(weight3)
    
    let viewModel = WeightViewModel()
    viewModel.loadWeightData(for: samplePet, modelContext: context)
    
    @State var weightToEdit: Weight? = nil
    @State var weightToDelete: Weight? = nil
    @State var showingDeleteAlert = false
    
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
