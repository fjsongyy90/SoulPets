import SwiftUI
import SwiftData

/// 宠物主页视图
struct PetsHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.name) private var pets: [Pet]
    @State private var showingAddPetSheet = false
    @State private var selectedPetIndex: Int = 0
    @State private var showingEditPetSheet = false
    @State private var selectedPet: Pet?
    
    // 背景和强调色
    private let backgroundColor = Color(red: 0.99, green: 0.98, blue: 0.94)
    private let accentColor = Color(red: 0.69, green: 0.45, blue: 0.25)
    private let peachColor = Color(red: 0.97, green: 0.63, blue: 0.46)
    private let mintColor = Color(red: 0.85, green: 0.95, blue: 0.9)
    
    var body: some View {
        ZStack {
            // 背景色
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 10) {
                // 右上角添加按钮
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingAddPetSheet = true
                    }) {
                        HStack {
                            Text("+ ID file")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(accentColor)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 5)
                
                if !pets.isEmpty {
                    // 宠物卡片滑动区域
                    TabView(selection: $selectedPetIndex) {
                        ForEach(Array(pets.enumerated()), id: \.element.id) { index, pet in
                            petIdentityCard(pet: pet)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 520)
                    .padding(.top, -10)
                    
                    // 页面指示器
                    HStack(spacing: 8) {
                        ForEach(0..<pets.count, id: \.self) { index in
                            Circle()
                                .fill(selectedPetIndex == index ? accentColor : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, -8)
                    
                    // 底部文案
                    Text("The digital heartbeat of your bond with pets.")
                        .font(.system(size: 16))
                        .italic()
                        .foregroundColor(accentColor)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    
                    Spacer()
                } else {
                    // 无宠物时的提示
                    noPetsView
                }
            }
            .onChange(of: pets) { _, newPets in
                // 如果没有选择宠物但有宠物列表，选择第一个
                if !newPets.isEmpty && selectedPetIndex >= newPets.count {
                    selectedPetIndex = 0
                }
            }
            .onAppear {
                // 首次加载时，如果有宠物，选择第一个
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
    }
    
    // 宠物身份卡片 - 参考图中的身份证样式
    private func petIdentityCard(pet: Pet) -> some View {
        VStack(spacing: 0) {
            // 身份证头部
            HStack {
                Text("IDENTITY CARD")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(pet.breed) • \(pet.gender == .female ? "Female" : "Male")")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                Rectangle()
                    .fill(accentColor)
                    .cornerRadius(20, corners: [.topLeft, .topRight])
            )
            
            // 身份证内容
            VStack(spacing: 20) {
                // 头像和名称
                HStack(spacing: 30) {
                    // 宠物头像
                    if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: pet.petType == .cat ? "cat.fill" : "dog.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .foregroundColor(.gray)
                            .padding()
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    
                    // 名称区域
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Name")
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        Text(pet.name)
                            .font(.system(size: 40))
                            .fontWeight(.bold)
                            .foregroundColor(accentColor)
                    }
                }
                .padding(.top, 20)
                
                // 年龄
                HStack {
                    Text("🍎")
                        .font(.title2)
                    
                    Text("Age")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(pet.age.years) years\(pet.age.months) months\(pet.age.days) days")
                        .font(.headline)
                        .foregroundColor(accentColor)
                }
                .padding(.horizontal)
                
                // 生日
                HStack {
                    Text("🥜")
                        .font(.title2)
                    
                    Text("Birthday")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    let birthdayString = formatDate(pet.birthday)
                    let zodiacSign = getZodiacSign(pet.birthday)
                    let daysUntilBirthday = pet.daysToNextBirthday
                    
                    Text("\(birthdayString) • \(zodiacSign) • Countdown \(daysUntilBirthday) days")
                        .font(.headline)
                        .foregroundColor(accentColor)
                }
                .padding(.horizontal)
                
                // 相识天数
                HStack {
                    Text("🤎")
                        .font(.title2)
                    
                    Text("We already know each other")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if let days = pet.daysWithOwner {
                        Text("\(days) days")
                            .font(.headline)
                            .foregroundColor(accentColor)
                    } else {
                        Text("--")
                            .font(.headline)
                            .foregroundColor(accentColor)
                    }
                }
                .padding(.horizontal)

                // 芯片ID
                HStack {
                    Text("💉")
                        .font(.title2)
                    
                    Text("Microchip ID")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(pet.microchipID ?? "Secret")
                        .font(.headline)
                        .foregroundColor(accentColor)
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                Divider()
                    .padding(.horizontal)
                
                // 最新信息
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Latest net worth")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Secret")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Latest weight")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if let latestWeight = pet.weights?.sorted(by: { $0.date > $1.date }).first {
                            Text("\(String(format: "%.1f", latestWeight.weightInKg)) kg")
                                .font(.headline)
                                .foregroundColor(accentColor)
                        } else {
                            Text("8 kg")
                                .font(.headline)
                                .foregroundColor(accentColor)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedPet = pet
                        showingEditPetSheet = true
                    }) {
                        Text("Enter ID file→")
                            .font(.caption)
                            .foregroundColor(accentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
            )
        }
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onTapGesture {
            selectedPet = pet
            showingEditPetSheet = true
        }
    }
    
    // 无宠物时的视图
    private var noPetsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "pawprint.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60)
                    .foregroundColor(Color(.systemGray2))
            }
            
            Text(LocalizedStringKey("Add Pet"))
                .font(.title2)
                .fontWeight(.bold)
            
            Button(action: {
                showingAddPetSheet = true
            }) {
                Text(LocalizedStringKey("Add Your First Pet"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(peachColor)
                    )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // 底部文案
            Text("The digital heartbeat of your bond with pets.")
                .font(.system(size: 16))
                .italic()
                .foregroundColor(accentColor)
                .padding(.top, 10)
                .padding(.bottom, 20)
        }
        .padding()
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd,MMM"
        return formatter.string(from: date)
    }
    
    // 获取星座
    private func getZodiacSign(_ date: Date) -> String {
        // 简化版，实际应用中需要更精确的计算
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        switch (month, day) {
        case (1, 1...19): return "Capricorn"
        case (1, 20...31): return "Aquarius"
        case (2, 1...18): return "Aquarius"
        case (2, 19...29): return "Pisces"
        case (3, 1...20): return "Pisces"
        case (3, 21...31): return "Aries"
        case (4, 1...19): return "Aries"
        case (4, 20...30): return "Taurus"
        case (5, 1...20): return "Taurus"
        case (5, 21...31): return "Gemini"
        case (6, 1...21): return "Gemini"
        case (6, 22...30): return "Cancer"
        case (7, 1...22): return "Cancer"
        case (7, 23...31): return "Leo"
        case (8, 1...22): return "Leo"
        case (8, 23...31): return "Virgo"
        case (9, 1...22): return "Virgo"
        case (9, 23...30): return "Libra"
        case (10, 1...23): return "Libra"
        case (10, 24...31): return "Scorpio"
        case (11, 1...22): return "Scorpio"
        case (11, 23...30): return "Sagittarius"
        case (12, 1...21): return "Sagittarius"
        case (12, 22...31): return "Capricorn"
        default: return "Unknown"
        }
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    
    // 添加预览数据
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

