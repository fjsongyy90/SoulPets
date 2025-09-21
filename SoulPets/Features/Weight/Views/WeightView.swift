import SwiftUI
import SwiftData
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
    
    // 使用统一的颜色定义
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                Color.appBackground.ignoresSafeArea()
                
                if (viewModel.selectedPet == nil && !allPets.isEmpty) || viewModel.isLoading {
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
                            .foregroundColor(.appAccent)
                    }
                    .disabled(viewModel.selectedPet == nil)
                }
            }
            .fullScreenCover(isPresented: $showingAddWeight) {
                AddEditWeightView(pet: viewModel.selectedPet)
                    .onDisappear {
                        // 返回后轻量刷新，不展示loading
                        viewModel.refreshData(modelContext: modelContext)
                    }
            }
            .fullScreenCover(item: $weightToEdit) { weight in
                AddEditWeightView(pet: viewModel.selectedPet, weightToEdit: weight)
                    .onDisappear {
                        weightToEdit = nil
                        // 返回后轻量刷新，不展示loading
                        viewModel.refreshData(modelContext: modelContext)
                    }
            }
            .sheet(isPresented: $showingWeightGoal) {
                WeightGoalView(pet: viewModel.selectedPet)
                    .onDisappear {
                        logger.info("🔄 体重目标页面关闭，刷新数据")
                        // 返回后轻量刷新，不展示loading
                        viewModel.refreshData(modelContext: modelContext)
                    }
            }
            .fullScreenCover(isPresented: $showingAddPet) {
                AddPetView(modelContext: modelContext)
                    .onDisappear {
                        // 延迟刷新，避免闪烁，并且只在有新宠物时刷新
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // 检查是否有新的宠物被添加
                            if let firstPet = allPets.first, viewModel.selectedPet == nil {
                                appState.setSelectedPet(firstPet)
                                viewModel.loadWeightData(for: firstPet, modelContext: modelContext)
                            }
                            
                            // 切换到主页tab
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                                tabBarController.selectedIndex = 0
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
        .preferredColorScheme(.light)
    }
    
    // MARK: - 子视图
    
    /// 加载状态视图
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text(String(localized: "Loading..."))
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
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
                    Text("Track Their Healthy Growth")
                        .font(.appSemiBold(size: 22))
                        .foregroundColor(.appTextPrimary)
                    
                    Text(String(localized: "empty_state.weight.subtitle"))
                        .font(.appRegular(size: 16))
                        .lineSpacing(6)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                
                Button(action: {
                    showingAddPet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(String(localized: "Add Your First Pet"))
                            .font(.appSemiBold(size: 17))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.appAccent)
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
                    .font(.appSemiBold(size: 22))
                    .foregroundColor(.appTextPrimary)
            
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
                    .font(.appSemiBold(size: 22))
                    .foregroundColor(.appTextPrimary)
                
                Text("The first beat of their digital heartbeat is weight. Let's start tracking.")
                    .font(.appRegular(size: 16))
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.appTextSecondary)
                    .padding(.horizontal, 40)
                
                Button {
                    showingAddWeight = true
                } label: {
                    Text("Add First Weight Record")
                        .font(.appSemiBold(size: 17))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.appAccent)
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
                WeightChartView(viewModel: viewModel)
                    .padding(.horizontal)
                
                // 数据摘要卡片
                DataSummaryView(viewModel: viewModel, showingWeightGoal: $showingWeightGoal)
                    .padding(.horizontal)
                
                // 历史记录列表
                WeightHistoryListView(
                    viewModel: viewModel,
                    weightToEdit: $weightToEdit,
                    weightToDelete: $weightToDelete,
                    showingDeleteAlert: $showingDeleteAlert
                )
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
                        accentColor: .appAccent,
                        textColor: .appTextPrimary,
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
