import SwiftUI
import SwiftData

/// 宠物主页视图
struct PetsHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.name) private var pets: [Pet]
    @StateObject private var appState = AppState.shared
    @State private var showingAddPetSheet = false
    @State private var selectedPetIndex: Int = 0
    @State private var showingEditPetSheet = false
    @State private var showingPetDetailSheet = false
    @State private var showingSettingsSheet = false
    
    // 新增：专门用于详情页面的宠物引用，避免状态竞争
    // @State private var detailViewPet: Pet?  // 已改用detailViewPetID
    
    // 新增：专门用于编辑页面的宠物引用，避免状态竞争
    @State private var editViewPet: Pet?
    
    // 新增：延迟清理检查器，处理SwiftData的暂时状态变化
    @State private var delayedCleanupTask: Task<Void, Never>?
    
    // 新增：使用pet ID来避免对象引用问题
    @State private var detailViewPetID: UUID?
    
    // 背景和强调色
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let cardBackground = Color.white
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色 - 使用新的设计规范颜色
                Color(hex: "FDFBF8").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !pets.isEmpty {
                        // 宠物卡片滑动区域
                        GeometryReader { geometry in
                            TabView(selection: $selectedPetIndex) {
                                ForEach(Array(pets.enumerated()), id: \.element.id) { index, pet in
                                    PetIdentityCardView(
                                        petAvatar: pet.avatar,
                                        petName: pet.name,
                                        petInfo: formatPetInfo(pet: pet),
                                        ageValue: formatAge(pet: pet),
                                        ageLabel: "Time in this world",
                                        togetherValue: formatTogetherTime(pet: pet),
                                        togetherLabel: "Guarding each other for",
                                        birthdayValue: formatNextBirthday(pet: pet),
                                        birthdayLabel: "Next celebration in",
                                        onViewProfile: {
                                            // 设置要显示的宠物ID
                                            detailViewPetID = pet.id
                                            
                                            // 使用两层异步确保状态完全更新
                                            DispatchQueue.main.async {
                                                DispatchQueue.main.async {
                                                    showingPetDetailSheet = true
                                                }
                                            }
                                        }
                                    )
                                        .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        }
                        .frame(height: min(520, UIScreen.main.bounds.height * 0.65))
                        .padding(.top, 10)
                        
                        // 页面指示器
                        if pets.count > 1 {
                            HStack(spacing: 12) {
                                ForEach(0..<pets.count, id: \.self) { index in
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(selectedPetIndex == index ? Color(hex: "E5B487") : Color.gray.opacity(0.3))
                                        .animation(.easeInOut(duration: 0.2), value: selectedPetIndex)
                                }
                            }
                            .padding(.top, 3)
                        }
                        
                        Spacer()
                        
                        // 底部隐私承诺文案
                        VStack(spacing: 10) {
                            // 短分隔线
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(Color(hex: "E5B487").opacity(0.5))
                                .frame(width: 60, height: 1)
                            
                            // slogan文字
                        Text("The digital heartbeat of your bond with pets.")
                                .font(.custom("Nunito-Italic", size: 13))
                                .foregroundColor(Color(hex: "A88C7D").opacity(0.7))
                        }
                        .padding(.bottom, 25)
                        
                    } else {
                        // 无宠物时的提示
                        noPetsView
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettingsSheet = true
                    } label: {
                        Image("setting_icon")
                            .foregroundColor(accentColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPetSheet = true
                    } label: {
                        Image("add_icon")
                            .foregroundColor(accentColor)
                    }
                }
            }
            .onChange(of: pets) { oldPets, newPets in
                // 当宠物列表发生变化时，更新状态
                
                // 取消之前的延迟清理任务
                delayedCleanupTask?.cancel()
                
                if newPets.isEmpty && !oldPets.isEmpty {
                    // 宠物列表从有变成无 - 可能是SwiftData的暂时状态
                    appState.setSelectedPet(nil)
                    selectedPetIndex = 0
                    
                    // 启动延迟检查任务，给SwiftData 1秒时间恢复
                    delayedCleanupTask = Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                        
                        await MainActor.run {
                            if pets.isEmpty && detailViewPetID != nil {
                                detailViewPetID = nil
                                if showingPetDetailSheet {
                                    showingPetDetailSheet = false
                                }
                            }
                        }
                    }
                } else if newPets.isEmpty {
                    // 列表一直为空的情况
                    appState.setSelectedPet(nil)
                    selectedPetIndex = 0
                } else {
                    // 有宠物的正常情况
                    
                    // 确保选中索引有效
                    if selectedPetIndex >= newPets.count {
                        selectedPetIndex = max(0, newPets.count - 1)
                    }
                    // 更新选中的宠物
                    if selectedPetIndex < newPets.count {
                        let newSelectedPet = newPets[selectedPetIndex]
                        appState.setSelectedPet(newSelectedPet)
                        
                        // 🔧 只有当detailViewPetID对应的宠物确实被删除时才清理
                        if let currentDetailPetID = detailViewPetID,
                           !newPets.contains(where: { $0.id == currentDetailPetID }) {
                            detailViewPetID = nil
                        }
                    } else if let firstPet = newPets.first {
                        appState.setSelectedPet(firstPet)
                        selectedPetIndex = 0
                    }
                }
            }
            .onChange(of: selectedPetIndex) { oldIndex, newIndex in
                // 确保索引有效并更新选中的宠物
                
                if newIndex < pets.count {
                    appState.setSelectedPet(pets[newIndex])
                }
                
            }
            .onAppear {
                // 初始化状态
                if !pets.isEmpty {
                    if selectedPetIndex >= pets.count {
                        selectedPetIndex = 0
                    }
                    if appState.selectedPet == nil || !pets.contains(where: { $0.id == appState.selectedPet?.id }) {
                        let petToSelect = pets[selectedPetIndex < pets.count ? selectedPetIndex : 0]
                        appState.setSelectedPet(petToSelect)
                    } else {
                        // 如果全局状态中有选中的宠物，同步到本地索引
                        if let selectedPet = appState.selectedPet,
                           let index = pets.firstIndex(where: { $0.id == selectedPet.id }) {
                            selectedPetIndex = index
                        }
                    }
                }
            }
        }
        .onDisappear {
            // 清理延迟任务
            delayedCleanupTask?.cancel()
        }
        .sheet(isPresented: $showingAddPetSheet) {
            AddPetView(modelContext: modelContext)
        }
        .sheet(isPresented: $showingEditPetSheet) {
            if let pet = editViewPet {
                EditPetView(pet: pet)
                    .onDisappear {
                        // 清理临时状态
                        editViewPet = nil
                    }
            }
        }
        .sheet(isPresented: $showingPetDetailSheet) {
            // 主要逻辑：使用detailViewPetID查找宠物
            if let petID = detailViewPetID,
               let pet = pets.first(where: { $0.id == petID }) {
                NavigationStack {
                    PetDetailView(pet: pet)
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    showingPetDetailSheet = false
                                }
                                .foregroundColor(accentColor)
                            }
                        }
                }
                .onAppear {
                    // 设置detailViewPetID以保持状态一致
                    detailViewPetID = pet.id
                }
                .onDisappear {
                    detailViewPetID = nil
                }
            }
            // 🔧 备用逻辑：如果detailViewPetID为nil，使用当前选中的宠物
            else if detailViewPetID == nil, let pet = appState.selectedPet {
                NavigationStack {
                    PetDetailView(pet: pet)
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    showingPetDetailSheet = false
                                }
                                .foregroundColor(accentColor)
                            }
                        }
                }
                .onAppear {
                    // 设置detailViewPetID以保持状态一致
                    detailViewPetID = pet.id
                }
                .onDisappear {
                    detailViewPetID = nil
                }
            }
            // 🔧 第二级备用逻辑：如果selectedPet也为nil，但pets不为空，使用第一只宠物
            else if !pets.isEmpty {
                let pet = pets[0]
                NavigationStack {
                    PetDetailView(pet: pet)
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    showingPetDetailSheet = false
                                }
                                .foregroundColor(accentColor)
                            }
                        }
                }
                .onAppear {
                    // 设置detailViewPetID以保持状态一致
                    detailViewPetID = pet.id
                }
                .onDisappear {
                    detailViewPetID = nil
                }
            }
            // 最后的兜底逻辑
            else {
                Text("No pet selected")
                    .onAppear {
                        // 如果没有找到宠物，自动关闭sheet
                        DispatchQueue.main.async {
                            showingPetDetailSheet = false
                        }
                    }
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
        }
    }
    
    // MARK: - 数据格式化方法
    
    /// 格式化宠物信息（品种和性别）
    private func formatPetInfo(pet: Pet) -> String {
        return "\(pet.breed) · \(pet.gender.rawValue)"
    }
    
    /// 格式化年龄
    private func formatAge(pet: Pet) -> String {
        let age = pet.age
        return "\(age.years)y \(age.months)m \(age.days)d"
    }
    
    /// 格式化陪伴时间
    private func formatTogetherTime(pet: Pet) -> String {
        if let days = pet.daysWithOwner {
            return "\(days) days"
        } else {
            return "∞ days" // 如果没有领养日，显示无限符号
        }
    }
    
    /// 格式化下个生日
    private func formatNextBirthday(pet: Pet) -> String {
        let days = pet.daysToNextBirthday
        if days == 0 {
            return "Today!"
        } else {
            return "in \(days) days"
        }
    }
    
    // 无宠物时的视图
    private var noPetsView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 文案区域 - 标题放在图片上方
            VStack(spacing: 30) {
                
                // 插画图标 - 主页激活状态，不降低透明度
                Image("empty_pet")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                
                VStack(spacing: 20) {
                    Text(String(localized: "Ready to listen to their story?"))
                        .font(.appTitle2)
                        .foregroundColor(textColor)
                    Text("Let's give their journey a digital heartbeat.")
                        .font(.appBody)
                        .multilineTextAlignment(.center)
                        .foregroundColor(labelColor)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showingAddPetSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text(String(localized: "Add Your First Pet"))
                                .font(.appHeadline)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(accentColor)
                        )
                    }
                }
            }
            
            Spacer()
            
            // 底部隐私承诺文案
            VStack(spacing: 10) {
                // 短分隔线
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color(hex: "E5B487").opacity(0.5))
                    .frame(width: 60, height: 1)
                
                // slogan文字
            Text("The digital heartbeat of your bond with pets.")
                    .font(.custom("Nunito-Italic", size: 13))
                    .foregroundColor(Color(hex: "A88C7D").opacity(0.7))
            }
            .padding(.bottom, 25)
        }
        .padding()
    }
}

// 底部标签按钮
struct TabBarButton: View {
    let icon: String
    let text: String
    let isSelected: Bool
    
    var body: some View {
        Button(action: {
            // 切换标签
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(text)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? Color(red: 0.69, green: 0.45, blue: 0.25) : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

// 扩展View以支持圆角
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// 自定义形状以支持特定圆角
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview("宠物主页") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    
    // 添加测试数据
    let pet1 = Pet(
        name: "mimi",
        petType: .cat,
        breed: "British Shorthair",
        gender: .female,
        isNeutered: true,
        birthday: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
        adoptionDay: Calendar.current.date(byAdding: .day, value: -405, to: Date()),
        weightUnitPreference: .kg
    )
    let pet2 = Pet(
        name: "kiki",
        petType: .dog,
        breed: "British Shorthair",
        gender: .female,
        isNeutered: true,
        birthday: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
        adoptionDay: Calendar.current.date(byAdding: .day, value: -405, to: Date()),
        weightUnitPreference: .kg
    )
    container.mainContext.insert(pet1)
    container.mainContext.insert(pet2)
    
    return PetsHomeView()
        .modelContainer(container)
}
