import SwiftUI

/// 可复用的宠物头像视图组件
struct PetAvatarView: View {
    let pet: Pet
    let isSelected: Bool
    let accentColor: Color
    let textColor: Color
    let size: CGFloat
    
    init(
        pet: Pet, 
        isSelected: Bool, 
        accentColor: Color = Color(red: 0.60, green: 0.35, blue: 0.15), 
        textColor: Color = Color(red: 0.25, green: 0.25, blue: 0.25),
        size: CGFloat = 60
    ) {
        self.pet = pet
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.textColor = textColor
        // 确保size是有效的正数
        self.size = max(20, size.isFinite ? size : 60)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // 头像
                if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    Image(pet.petType == .dog ? "pet_dog" : "pet_cat")
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .background(
                            Circle()
                                .fill(Color(red: 0.97, green: 0.90, blue: 0.83))
                        )
                }
                
                // 选中状态
                if isSelected {
                    Circle()
                        .stroke(accentColor, lineWidth: 3)
                        .frame(width: size + 4, height: size + 4)
                    
                    // 对勾图标 - 右下角
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: size * 0.25))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(accentColor)
                                        .frame(width: size * 0.3, height: size * 0.3)
                                )
                                .scaleEffect(isSelected ? 1.0 : 0.8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                        }
                    }
                    .frame(width: size, height: size)
                }
            }
            
            // 宠物名称
            Text(pet.name)
                .font(.caption)
                .foregroundColor(isSelected ? accentColor : textColor)
                .lineLimit(1)
                .frame(width: size + 8)
        }
    }
}

#Preview {
    let samplePet = Pet(
        name: "Fluffy",
        petType: .cat,
        breed: "Persian",
        gender: .female,
        isNeutered: true,
        birthday: Date(),
        adoptionDay: Date()
    )
    
    HStack {
        PetAvatarView(pet: samplePet, isSelected: false)
        PetAvatarView(pet: samplePet, isSelected: true)
    }
    .padding()
} 