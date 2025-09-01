import SwiftUI
import SwiftData
import Charts
import OSLog

/// 体重追踪主页面
struct WeightView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = WeightViewModel()
    @StateObject private var appState = AppState.shared
    @Query private var allPets: [Pet]
    
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "WeightView")
    
    @State private var showingAddWeight = false
    @State private var showingWeightGoal = false
    @State private var showingDeleteAlert = false
    @State private var showingAddPet = false
    @State private var weightToEdit: Weight?
    @State private var weightToDelete: Weight?
    
    // 颜色定义 - 与其他模块保持一致
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    private let cardColor = Color.white
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                backgroundColor.ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if allPets.isEmpty {
                    noPetsView
                } else if viewModel.selectedPet == nil {
                    selectPetView
                } else if !viewModel.hasWeightData {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .navigationTitle(String(localized: "Weight"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddWeight = true
                    } label: {
                        Image("add_icon")
                            .foregroundColor(accentColor)
                    }
                    .disabled(viewModel.selectedPet == nil)
                }
            }
            .sheet(isPresented: $showingAddWeight) {
                AddEditWeightView(pet: viewModel.selectedPet)
                    .onDisappear {
                        viewModel.refreshData(modelContext: modelContext)
                    }
            }
            .sheet(item: $weightToEdit) { weight in
                AddEditWeightView(pet: viewModel.selectedPet, weightToEdit: weight)
                    .onDisappear {
                        weightToEdit = nil
                        viewModel.refreshData(modelContext: modelContext)
                    }
            }
            .sheet(isPresented: $showingWeightGoal) {
                WeightGoalView(pet: viewModel.selectedPet)
                    .onDisappear {
                        logger.info("🔄 体重目标页面关闭，刷新数据")
                        viewModel.refreshData(modelContext: modelContext)
                    }
            }
            .sheet(isPresented: $showingAddPet) {
                AddPetView(modelContext: modelContext)
                    .onDisappear {
                        // 添加宠物后切换到主页tab
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                                tabBarController.selectedIndex = 0 // 切换到主页
                            }
                        }
                    }
            }
            .customConfirmAlert(
                title: String(localized: "Delete Weight Record"),
                message: String(localized: "This action cannot be undone."),
                isPresented: $showingDeleteAlert,
                confirmTitle: String(localized: "Delete"),
                confirmAction: {
                    if let weight = weightToDelete {
                        viewModel.deleteWeight(weight, modelContext: modelContext)
                        weightToDelete = nil
                    }
                },
                isDestructive: true
            )
            .onAppear {
                // 使用全局状态中的选中宠物
                if let selectedPet = appState.selectedPet {
                    viewModel.loadWeightData(for: selectedPet, modelContext: modelContext)
                    logger.info("🐾 体重页面使用全局选中的宠物: \(selectedPet.name)")
                } else if let firstPet = allPets.first {
                    // 如果全局状态没有选中宠物，选择第一只宠物
                    appState.setSelectedPet(firstPet)
                    viewModel.loadWeightData(for: firstPet, modelContext: modelContext)
                    logger.info("🐾 体重页面设置默认宠物: \(firstPet.name)")
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 加载状态视图
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text(String(localized: "Loading..."))
                .font(.appBody)
                .foregroundColor(labelColor)
                .padding(.top)
        }
    }
    
    /// 无宠物状态视图
    private var noPetsView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("empty_weight")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 180, height: 180)
                .clipShape(Circle())
                .opacity(0.4) // 降低透明度显示未激活状态
            
            VStack(spacing: 20) {
                    Text("Add a Pet First")
                        .font(.appTitle2)
                        .foregroundColor(textColor)
                    
                    Text(String(localized: "empty_state.weight.subtitle"))
                        .font(.appBody)
                        .foregroundColor(labelColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                
                Button(action: {
                    showingAddPet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(String(localized: "Add Your First Pet"))
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(accentColor)
                    )
                }
            }
            .padding(.top, 40)
            
            Spacer()
        }
    }
    
    /// 选择宠物视图
    private var selectPetView: some View {
        VStack(spacing: 20) {
                Text(String(localized: "Select a Pet"))
                    .font(.appTitle2)
                    .foregroundColor(textColor)
            
            petSelectorView
        }
        .padding()
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            // 宠物选择器（仅在有宠物时显示）
            if !allPets.isEmpty {
                petSelectorView
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // 空状态插画和文案
            Image("empty_weight")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 180, height: 180)
                .clipShape(Circle()) // 裁剪成圆形
            
            VStack(spacing: 20) {
                Text("No Weight Records")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                
                Text("The first beat of their digital heartbeat is weight. Let's start tracking.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(labelColor)
                    .padding(.horizontal, 40)
                
                Button {
                    showingAddWeight = true
                } label: {
                    Text("Add First Weight Record")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(accentColor)
                        )
                }
            }
            .padding(.top, 40)
            
            Spacer()
        }
    }
    
    /// 主内容视图
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 宠物选择器
                petSelectorView
                    .padding(.horizontal)
                
                // 体重图表
                weightChartView
                    .padding(.horizontal)
                
                // 数据摘要卡片
                dataSummaryCards
                    .padding(.horizontal)
                
                // 历史记录列表
                weightHistoryList
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    /// 宠物选择器
    private var petSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(allPets) { pet in
                    PetAvatarView(
                        pet: pet,
                        isSelected: viewModel.selectedPet?.id == pet.id,
                        accentColor: accentColor,
                        textColor: textColor,
                        size: 60
                    )
                    .onTapGesture {
                        // 更新全局状态
                        appState.setSelectedPet(pet)
                        viewModel.loadWeightData(for: pet, modelContext: modelContext)
                        logger.info("🐾 体重页面切换到宠物: \(pet.name)")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    /// 体重图表视图
    private var weightChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Weight Trend"))
                    .font(.appHeadline)
                    .foregroundColor(textColor)
                
                Spacer()
            }
            
            // 时间范围选择器
            timeRangeSelector
            
            if viewModel.chartData.isEmpty {
                Text(String(localized: "Not enough data for chart"))
                    .font(.appBody)
                    .foregroundColor(labelColor)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(cardColor)
                    .cornerRadius(12)
            } else {
                Chart(viewModel.chartData, id: \.id) { weight in
                    LineMark(
                        x: .value("Date", weight.date),
                        y: .value("Weight", weight.formattedWeightValue)
                    )
                    .foregroundStyle(accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Date", weight.date),
                        y: .value("Weight", weight.formattedWeightValue)
                    )
                    .foregroundStyle(accentColor)
                    .symbol(Circle())
                    
                    // 目标线
                    if let goal = viewModel.activeWeightGoal {
                        RuleMark(y: .value("Target", goal.targetWeight))
                            .foregroundStyle(.red)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                }
                .frame(height: 200)
                .padding()
                .background(cardColor)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
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
                        .foregroundColor(viewModel.selectedTimeRange == range ? .white : textColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.selectedTimeRange == range ? accentColor : Color.gray.opacity(0.1))
                        )
                }
            }
            
            Spacer()
        }
    }
    
    /// 数据摘要卡片
    private var dataSummaryCards: some View {
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
    
    /// 当前体重卡片
    private var currentWeightCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Current Weight"))
                .font(.appCaption)
                .foregroundColor(labelColor)
            
            if let latestWeight = viewModel.latestWeight {
                Text(latestWeight.formattedWeight())
                    .font(.appTitle2)
                    .foregroundColor(textColor)
                
                Text(latestWeight.date, style: .date)
                    .font(.appCaption)
                    .foregroundColor(labelColor)
            } else {
                Text("--")
                    .font(.appTitle2)
                    .foregroundColor(textColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 体重变化卡片
    private var weightChangeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Weight Change"))
                .font(.appCaption)
                .foregroundColor(labelColor)
            
            Text(viewModel.formattedWeightTrend)
                .font(.appTitle2)
                .foregroundColor(viewModel.weightTrend == nil ? textColor : 
                                (viewModel.weightTrend! > 0 ? .orange : .green))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 体重目标卡片
    private var weightGoalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Weight Goal"))
                    .font(.appHeadline)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Button {
                    logger.info("🎯 点击体重目标按钮")
                    showingWeightGoal = true
                } label: {
                    Text(viewModel.activeWeightGoal == nil ? 
                         String(localized: "Set Goal") : 
                         String(localized: "Edit Goal"))
                        .font(.appCaption)
                        .foregroundColor(accentColor)
                }
            }
            
            if let goal = viewModel.activeWeightGoal {
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.formattedGoal)
                        .font(.appBody)
                        .foregroundColor(textColor)
                    
                    HStack {
                        Text(String(localized: "Progress:"))
                            .font(.appBody)
                            .foregroundColor(labelColor)
                        Text(viewModel.formattedGoalProgress())
                            .font(.appBody)
                            .fontWeight(.semibold)
                            .foregroundColor(accentColor)
                        Spacer()
                        Text("\(goal.remainingDays) days left")
                            .font(.appCaption)
                            .foregroundColor(labelColor)
                    }
                    
                    // 进度条
                    ProgressView(value: viewModel.getGoalProgress(), total: 100)
                        .tint(accentColor)
                }
                .onAppear {
                    logger.debug("🎯 显示活跃体重目标: \(goal.targetWeight) \(goal.unit.rawValue)")
                }
            } else {
                Text(String(localized: "Set a weight goal to track progress"))
                    .font(.appBody)
                    .foregroundColor(labelColor)
                    .onAppear {
                        logger.debug("❌ 无活跃体重目标，显示设置提示")
                    }
            }
        }
        .padding()
        .background(cardColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            logger.info("🎯 体重目标卡片显示，当前目标状态: \(viewModel.activeWeightGoal == nil ? "无目标" : "有目标")")
        }
    }
    
    /// 体重历史记录列表
    private var weightHistoryList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Weight History"))
                .font(.appHeadline)
                .foregroundColor(textColor)
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.weightEntries) { weight in
                    weightHistoryRow(weight)
                }
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
                    .foregroundColor(textColor)
                
                Text(weight.date, style: .date)
                    .font(.appCaption)
                    .foregroundColor(labelColor)
            }
            
            Spacer()
            
            Button {
                weightToEdit = weight
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(accentColor)
            }
        }
        .padding()
        .background(cardColor)
        .cornerRadius(8)
        .contextMenu {
            Button {
                weightToEdit = weight
            } label: {
                Label(String(localized: "Edit"), systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                weightToDelete = weight
                showingDeleteAlert = true
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        }
    }
}

// MARK: - 扩展
extension Weight {
    /// 获取格式化的体重值（用于图表）
    var formattedWeightValue: Double {
        return weightInKg
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
    
    return WeightView()
        .modelContainer(container)
} 
