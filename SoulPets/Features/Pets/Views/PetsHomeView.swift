import SwiftUI
import SwiftData

/// 宠物主页视图
struct PetsHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.name) private var pets: [Pet]
    @State private var showingAddPetSheet = false
    @State private var selectedPetIndex: Int = 0
    @State private var showingEditPetSheet = false
    @State private var showingPetDetailSheet = false // 新增：显示宠物详情
    @State private var showingSettingsSheet = false
    @State private var selectedPet: Pet?
    
    // 背景和强调色
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let cardBackground = Color.white
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !pets.isEmpty {
                        // 宠物卡片滑动区域
                        TabView(selection: $selectedPetIndex) {
                            ForEach(Array(pets.enumerated()), id: \.element.id) { index, pet in
                                petCard(pet: pet)
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: 480)
                        .padding(.top, 10)
                        
                        // 页面指示器
                        if pets.count > 1 {
                            HStack(spacing: 8) {
                                ForEach(0..<pets.count, id: \.self) { index in
                                    Circle()
                                        .fill(selectedPetIndex == index ? accentColor : Color.gray.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                        .animation(.easeInOut(duration: 0.2), value: selectedPetIndex)
                                }
                            }
                            .padding(.top, 16)
                        }
                        
                        Spacer()
                        
                        // 底部隐私承诺文案
                        Text("The digital heartbeat of your bond with pets.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom, 20)
                        
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
                        Image(systemName: "gearshape")
                            .foregroundColor(accentColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPetSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(accentColor)
                    }
                }
            }
            .onChange(of: pets) { _, newPets in
                if !newPets.isEmpty && selectedPetIndex >= newPets.count {
                    selectedPetIndex = 0
                }
            }
            .onAppear {
                if !pets.isEmpty && selectedPetIndex >= pets.count {
                    selectedPetIndex = 0
                }
            }
        }
        .sheet(isPresented: $showingAddPetSheet) {
            AddPetView(modelContext: modelContext)
        }
        .sheet(isPresented: $showingEditPetSheet) {
            if let pet = selectedPet {
                EditPetView(pet: pet)
            }
        }
        .sheet(isPresented: $showingPetDetailSheet) {
            if let pet = selectedPet {
                NavigationStack {
                    PetDetailView(pet: pet)
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Close") {
                                    showingPetDetailSheet = false
                                    selectedPet = nil  // 清除选中状态
                                }
                            }
                        }
                }
                .onAppear {
                    print("📱 PetDetailView Sheet 显示，宠物: \(pet.name)")
                }
            } else {
                Text("No pet selected")
                    .onAppear {
                        print("❌ PetDetailView Sheet 显示但没有选中的宠物")
                        // 如果没有选中宠物，自动关闭sheet
                        DispatchQueue.main.async {
                            showingPetDetailSheet = false
                        }
                    }
            }
        }
        .onAppear {
            // 确保selectedPet状态正确初始化
            if selectedPet == nil && !pets.isEmpty {
                selectedPet = pets.first
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
        }
    }
    
    // 优化的宠物卡片设计
    private func petCard(pet: Pet) -> some View {
        VStack(spacing: 0) {
            // 卡片主体
            VStack(spacing: 24) {
                // 头像和基本信息
                VStack(spacing: 16) {
                    // 宠物头像
                    if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [accentColor.opacity(0.2), accentColor.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: pet.petType == .cat ? "cat.fill" : "dog.fill")
                                .font(.system(size: 40))
                                .foregroundColor(accentColor)
                        }
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    }
                    
                    // 宠物名字和基本信息
                    VStack(spacing: 8) {
                        Text(pet.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        
                        HStack(spacing: 4) {
                            Text(pet.breed)
                                .font(.subheadline)
                                .foregroundColor(labelColor)
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(labelColor)
                            
                            Text(pet.gender.rawValue)
                                .font(.subheadline)
                                .foregroundColor(labelColor)
                        }
                    }
                }
                .padding(.top, 24)
                
                // 信息卡片区域
                VStack(spacing: 12) {
                    // 年龄信息
                    infoRow(
                        icon: "birthday.cake.fill",
                        title: String(localized: "Age"),
                        value: "\(pet.age.years)y \(pet.age.months)m \(pet.age.days)d"
                    )
                    
                    // 生日信息
                    infoRow(
                        icon: "calendar.badge.clock",
                        title: String(localized: "Next Birthday"),
                        value: "In \(pet.daysToNextBirthday) days"
                    )
                    
                    // 相伴天数
                    if let days = pet.daysWithOwner {
                        infoRow(
                            icon: "heart.fill",
                            title: String(localized: "Together for"),
                            value: "\(days) days"
                        )
                    }
                    
                    // 最新体重
                    infoRow(
                        icon: "scalemass.fill",
                        title: String(localized: "Latest Weight"),
                        value: latestWeightText(for: pet)
                    )
                }
                .padding(.horizontal, 20)
                
                // 查看详情按钮
                Button(action: {
                    selectedPet = pet
                    print("🔍 点击View Profile按钮，选中宠物: \(pet.name)")
                    showingPetDetailSheet = true
                }) {
                    HStack(spacing: 8) {
                        Text(String(localized: "View Profile"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [accentColor, accentColor.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
            )
        }
        .padding(.horizontal, 16)
    }
    
    // 信息行组件
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(accentColor)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(labelColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(textColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
    }
    
    // 获取最新体重文本
    private func latestWeightText(for pet: Pet) -> String {
        if let latestWeight = pet.weights?.sorted(by: { $0.date > $1.date }).first {
            let unit = pet.weightUnitPreference == .kg ? "kg" : "lbs"
            let weight = pet.weightUnitPreference == .kg ? 
                latestWeight.weightInKg : 
                latestWeight.weightInKg * 2.20462
            return String(format: "%.1f %@", weight, unit)
        } else {
            return "--"
        }
    }
    
    // 无宠物时的视图
    private var noPetsView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 插画图标
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 60))
                    .foregroundColor(accentColor)
            }
            
            VStack(spacing: 12) {
                Text(String(localized: "Welcome to SoulPets"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                
                Text(String(localized: "Start by adding your first pet to create their digital profile"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(labelColor)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                showingAddPetSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(String(localized: "Add Your First Pet"))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(accentColor)
                )
            }
            
            Spacer()
            
            // 底部隐私承诺文案
            Text("The digital heartbeat of your bond with pets.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
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

