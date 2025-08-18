import SwiftUI
import SwiftData

/// 宠物详情视图
struct PetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let pet: Pet
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let cardColor = Color.white
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.5, green: 0.5, blue: 0.5)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    // 创建格式化器
    private let birthdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: 24) {
                // 宠物头像
                petAvatarSection
                
                // 基本信息卡片
                infoCard(title: String(localized: "Basic Information")) {
                    infoRow(label: String(localized: "Name"), value: pet.name)
                    infoRow(label: String(localized: "Type"), value: pet.petType.rawValue)
                    infoRow(label: String(localized: "Breed / Color"), value: pet.breed)
                    infoRow(label: String(localized: "Gender"), value: pet.gender.rawValue)
                    infoRow(label: String(localized: "Neutered / Spayed"), value: pet.isNeutered ? String(localized: "Yes") : String(localized: "No"))
                }
                
                // 年龄与日期信息卡片
                infoCard(title: String(localized: "Age & Important Dates")) {
                    // 年龄显示
                    let age = pet.age
                    infoRow(label: String(localized: "Age"), value: "\(age.years)y \(age.months)m \(age.days)d")
                    
                    // 生日显示
                    infoRow(label: String(localized: "Birthday"), value: birthdayFormatter.string(from: pet.birthday))
                    
                    // 领养日显示
                    if let adoptionDay = pet.adoptionDay {
                        infoRow(label: String(localized: "Adoption Day"), value: birthdayFormatter.string(from: adoptionDay))
                        if let days = pet.daysWithOwner {
                            infoRow(label: String(localized: "Together for"), value: "\(days) days")
                        }
                    }
                    
                    // 下个生日
                    infoRow(label: String(localized: "Next Birthday"), value: "In \(pet.daysToNextBirthday) days")
                }
                
                // 健康信息卡片
                infoCard(title: String(localized: "Health Information")) {
                    if !pet.microchipID.isEmpty {
                        infoRow(label: String(localized: "Microchip ID"), value: pet.microchipID)
                    } else {
                        infoRow(label: String(localized: "Microchip ID"), value: String(localized: "Not set"))
                    }
                    
                    if !pet.insurancePolicyNo.isEmpty {
                        infoRow(label: String(localized: "Insurance Policy No."), value: pet.insurancePolicyNo)
                    } else {
                        infoRow(label: String(localized: "Insurance Policy No."), value: String(localized: "Not set"))
                    }
                    
                    infoRow(label: String(localized: "Weight Unit"), value: pet.weightUnitPreference.rawValue)
                }
            }
            .padding()
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 视图出现时的初始化逻辑
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label(String(localized: "Edit"), systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label(String(localized: "Delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(accentColor)
                        .font(.system(size: 18))
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditPetView(pet: pet)
        }
        .customConfirmAlert(
            title: String(localized: "delete_pet.title"),
            message: String(localized: "delete_pet.message"),
            isPresented: $showingDeleteAlert,
            confirmTitle: String(localized: "delete_pet.confirm"),
            confirmAction: {
                deletePet()
            },
            isDestructive: true
        )
    }
    
    // 宠物头像部分
    private var petAvatarSection: some View {
        VStack {
            if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(accentColor, lineWidth: 3)
                    )
            } else {
                Image(pet.petType == .cat ? "pet_cat" : "pet_dog")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(accentColor, lineWidth: 3)
                    )
            }
            
            Text(pet.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(textColor)
        }
    }
    
    // 信息卡片容器
    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(accentColor)
                .padding(.bottom, 4)
            
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // 信息行
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(labelColor)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(textColor)
        }
        .padding(.vertical, 4)
    }
    
    // 删除宠物 - 使用级联删除方法处理关系问题
    private func deletePet() {
        PetService.cascadeDeletePet(pet: pet, modelContext: modelContext)
        
        // 延迟关闭，确保删除操作先完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
} 
