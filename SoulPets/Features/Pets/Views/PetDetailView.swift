import SwiftUI
import SwiftData

/// 宠物详情视图
struct PetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let pet: Pet
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
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
                infoCard(title: "Basic Information") {
                    infoRow(label: "Name", value: pet.name)
                    infoRow(label: "Type", value: pet.petType.rawValue)
                    infoRow(label: "Breed / Color", value: pet.breed)
                    infoRow(label: "Gender", value: pet.gender.rawValue)
                    infoRow(label: "Neutered / Spayed", value: pet.isNeutered ? "Yes" : "No")
                }
                
                // 年龄与日期信息卡片
                infoCard(title: "Age & Important Dates") {
                    // 年龄显示
                    let age = pet.age
                    infoRow(label: "Age", value: "\(age.years)y \(age.months)m \(age.days)d")
                    
                    // 生日显示
                    infoRow(label: "Birthday", value: birthdayFormatter.string(from: pet.birthday))
                    
                    // 领养日显示
                    if let adoptionDay = pet.adoptionDay {
                        infoRow(label: "Adoption Day", value: birthdayFormatter.string(from: adoptionDay))
                        if let days = pet.daysWithOwner {
                            infoRow(label: "Together for", value: "\(days) days")
                        }
                    }
                    
                    // 下个生日
                    infoRow(label: "Next Birthday", value: "In \(pet.daysToNextBirthday) days")
                }
                
                // 健康信息卡片
                if pet.microchipID != nil || pet.insurancePolicyNo != nil {
                    infoCard(title: "Health Information") {
                        if let microchipID = pet.microchipID {
                            infoRow(label: "Microchip ID", value: microchipID)
                        }
                        
                        if let insurancePolicyNo = pet.insurancePolicyNo {
                            infoRow(label: "Insurance Policy No.", value: insurancePolicyNo)
                        }
                        
                        infoRow(label: "Weight Unit", value: pet.weightUnitPreference.rawValue)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: HStack {
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label(LocalizedStringKey("Edit"), systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label(LocalizedStringKey("Delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        )
        .sheet(isPresented: $showingEditSheet) {
            EditPetView(pet: pet)
        }
        .alert(LocalizedStringKey("Delete Pet"), isPresented: $showingDeleteAlert) {
            Button(LocalizedStringKey("Cancel"), role: .cancel) {}
            Button(LocalizedStringKey("Delete"), role: .destructive) {
                deletePet()
            }
        } message: {
            Text(LocalizedStringKey("Are you sure you want to delete \(pet.name)? This action cannot be undone."))
        }
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
                            .stroke(Color("AccentColor"), lineWidth: 3)
                    )
            } else {
                Image(systemName: pet.petType == .cat ? "cat.fill" : "dog.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60)
                    .padding(30)
                    .background(Circle().fill(Color(.systemGray5)))
                    .overlay(
                        Circle()
                            .stroke(Color("AccentColor"), lineWidth: 3)
                    )
            }
            
            Text(pet.name)
                .font(.title)
                .fontWeight(.bold)
        }
    }
    
    // 信息卡片容器
    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey(title))
                .font(.headline)
                .padding(.bottom, 4)
            
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // 信息行
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(LocalizedStringKey(label))
                .foregroundColor(.secondary)
            Spacer()
            Text(LocalizedStringKey(value))
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
    
    // 删除宠物
    private func deletePet() {
        do {
            modelContext.delete(pet)
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting pet: \(error.localizedDescription)")
        }
    }
} 