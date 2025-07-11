import SwiftUI
import SwiftData

/// 宠物主页视图
struct PetsHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.name) private var pets: [Pet]
    @State private var showingAddPetSheet = false
    @State private var selectedPet: Pet?
    
    var body: some View {
        NavigationStack {
            VStack {
                // 欢迎信息
                welcomeHeader
                
                // 宠物选择器
                petSelector
                
                if let selectedPet = selectedPet {
                    // 当前宠物信息卡片
                    petDashboardCard(pet: selectedPet)
                } else {
                    // 无宠物时的提示
                    noPetsView
                }
                
                Spacer()
            }
            .navigationTitle(LocalizedStringKey("Home"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddPetSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPetSheet) {
                AddPetView(modelContext: modelContext)
            }
            .onChange(of: pets) { _, newPets in
                // 如果没有选择宠物但有宠物列表，选择第一个
                if selectedPet == nil && !newPets.isEmpty {
                    selectedPet = newPets.first
                }
            }
            .onAppear {
                // 首次加载时，如果有宠物，选择第一个
                if selectedPet == nil && !pets.isEmpty {
                    selectedPet = pets.first
                }
            }
        }
    }
    
    // 欢迎信息头部
    private var welcomeHeader: some View {
        VStack(alignment: .leading) {
            Text(LocalizedStringKey("Hello!"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text(LocalizedStringKey("Welcome to SoulPets"))
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
    }
    
    // 宠物选择器
    private var petSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(pets) { pet in
                    petAvatarButton(pet: pet)
                }
                
                // 添加宠物按钮
                Button(action: {
                    showingAddPetSheet = true
                }) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(Color("AccentColor"))
                        }
                        
                        Text(LocalizedStringKey("Add Pet"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // 宠物头像按钮
    private func petAvatarButton(pet: Pet) -> some View {
        Button(action: {
            selectedPet = pet
        }) {
            VStack {
                ZStack {
                    Circle()
                        .fill(selectedPet?.id == pet.id ? Color("AccentColor") : Color(.systemGray5))
                        .frame(width: 70, height: 70)
                    
                    if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 66, height: 66)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: pet.petType == .cat ? "cat.fill" : "dog.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35)
                            .foregroundColor(selectedPet?.id == pet.id ? .white : .gray)
                    }
                }
                
                Text(pet.name)
                    .font(.caption)
                    .fontWeight(selectedPet?.id == pet.id ? .bold : .regular)
                    .foregroundColor(selectedPet?.id == pet.id ? Color("AccentColor") : .primary)
            }
        }
    }
    
    // 宠物信息卡片
    private func petDashboardCard(pet: Pet) -> some View {
        NavigationLink(destination: PetDetailView(pet: pet)) {
            VStack(spacing: 16) {
                // 基本信息
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pet.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(pet.breed)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: pet.petType == .cat ? "cat.fill" : "dog.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .foregroundColor(Color("AccentColor"))
                }
                
                Divider()
                
                // 情感化数据
                HStack(spacing: 20) {
                    infoColumn(
                        title: "Age",
                        value: "\(pet.age.years)y \(pet.age.months)m \(pet.age.days)d"
                    )
                    
                    if let days = pet.daysWithOwner {
                        infoColumn(
                            title: "Together for",
                            value: "\(days) days"
                        )
                    }
                    
                    infoColumn(
                        title: "Next birthday",
                        value: "In \(pet.daysToNextBirthday) days"
                    )
                }
                
                Divider()
                
                // 健康速览
                HStack {
                    Image(systemName: "arrow.right")
                        .foregroundColor(Color("AccentColor"))
                    
                    Text(LocalizedStringKey("View Full Profile"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 信息列
    private func infoColumn(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(LocalizedStringKey(title))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
    
    // 无宠物时的视图
    private var noPetsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pawprint.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .foregroundColor(Color(.systemGray4))
            
            Text(LocalizedStringKey("No Pets Yet"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(LocalizedStringKey("Add your first pet to get started"))
                .foregroundColor(.secondary)
            
            Button(action: {
                showingAddPetSheet = true
            }) {
                Text(LocalizedStringKey("Add Your First Pet"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("AccentColor"))
                    )
            }
        }
        .padding()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    
    // 添加预览数据
    let pet1 = Pet(
        name: "Whiskers",
        petType: .cat,
        breed: "Tabby",
        gender: .male,
        isNeutered: true,
        birthday: Calendar.current.date(byAdding: .year, value: -2, to: Date())!,
        adoptionDay: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
        weightUnitPreference: .kg
    )
    
    let pet2 = Pet(
        name: "Buddy",
        petType: .dog,
        breed: "Golden Retriever",
        gender: .male,
        isNeutered: true,
        birthday: Calendar.current.date(byAdding: .year, value: -3, to: Date())!,
        adoptionDay: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
        weightUnitPreference: .kg
    )
    
    container.mainContext.insert(pet1)
    container.mainContext.insert(pet2)
    
    return PetsHomeView()
        .modelContainer(container)
} 