import SwiftUI

/// 宠物类型选择视图
struct PetTypeSelectionView: View {
    @Binding var selectedType: PetType
    @State private var showUnsupportedAlert = false
    
    // 支持的宠物类型
    private let supportedTypes: [PetType] = [.cat, .dog]
    
    // 未来支持的宠物类型配置
    private let futureTypes = [
        ("Rabbit", "hare.fill"),
        ("Bird", "bird.fill"),
        ("Fish", "fish.fill"),
        ("Turtle", "tortoise.fill"),
        ("Lizard", "lizard.fill"),
        ("Mouse", "pawprint.fill"),
        ("Insect", "ladybug.fill") // 用简单图标替代
    ]
    
    // 定义更高对比度的颜色
    private let textColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let labelColor = Color(red: 0.3, green: 0.3, blue: 0.3)
    private let accentColor = Color(red: 0.69, green: 0.45, blue: 0.25)
    private let catColor = Color.orange
    private let dogColor = Color.blue
    
    var body: some View {
        VStack(spacing: 30) {
            Text(LocalizedStringKey("What kind of friend are you welcoming?"))
                .font(.appTitle2)
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 宠物类型网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 25) {
                // 支持的宠物类型 - 猫
                PetTypeImageButton(
                    type: "Cat",
                    imageName: "pet_cat",
                    isSelected: selectedType == .cat,
                    isDisabled: false,
                    backgroundColor: catColor
                ) {
                    selectedType = .cat
                }
                
                // 支持的宠物类型 - 狗
                PetTypeImageButton(
                    type: "Dog",
                    imageName: "pet_dog",
                    isSelected: selectedType == .dog,
                    isDisabled: false,
                    backgroundColor: dogColor
                ) {
                    selectedType = .dog
                }
                
                // 未来支持的宠物类型
                ForEach(futureTypes.prefix(7), id: \.0) { type, icon in
                    PetTypeCircleButton(
                        type: type,
                        iconName: icon,
                        isSelected: false,
                        isDisabled: true,
                        backgroundColor: Color(.systemGray4)
                    ) {
                        showUnsupportedAlert = true
                    }
                }
            }
            .padding(.horizontal)
            
            // 信息提示
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(accentColor)
                Text(LocalizedStringKey("We are working hard and will support more cute friends soon!"))
                    .font(.appCaption)
                    .foregroundColor(labelColor)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 20)
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
        .alert(LocalizedStringKey("Coming Soon"), isPresented: $showUnsupportedAlert) {
            Button(LocalizedStringKey("OK"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey("We're working hard to support more lovely pets soon!"))
                .foregroundColor(textColor)
        }
    }
}

/// 使用导入图片的宠物类型按钮
struct PetTypeImageButton: View {
    let type: String
    let imageName: String
    let isSelected: Bool
    let isDisabled: Bool
    let backgroundColor: Color
    let action: () -> Void
    
    // 定义更高对比度的颜色
    private let textColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    // 背景圆圈
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? backgroundColor : Color.clear,
                                    lineWidth: 3
                                )
                                .scaleEffect(1.1)
                        )
                    
                    // 宠物图片
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .opacity(isDisabled ? 0.7 : 1.0)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                
                Text(LocalizedStringKey(type))
                    .font(isSelected ? .appFootnote : .appCaption)
                    .foregroundColor(isSelected ? backgroundColor : textColor)
                    .opacity(isDisabled ? 0.6 : 1.0)
            }
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
}

/// 圆形宠物类型按钮（用于未来支持的宠物类型）
struct PetTypeCircleButton: View {
    let type: String
    let iconName: String
    let isSelected: Bool
    let isDisabled: Bool
    let backgroundColor: Color
    let action: () -> Void
    
    // 定义更高对比度的颜色
    private let textColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isDisabled ? Color(.systemGray5) : backgroundColor)
                        .frame(width: 80, height: 80)
                        .opacity(isDisabled ? 0.6 : 1.0)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? backgroundColor : Color.clear,
                                    lineWidth: 3
                                )
                                .scaleEffect(1.1)
                        )
                    
                    Image(systemName: iconName)
                        .font(.system(size: 35, weight: .medium))
                        .foregroundColor(isDisabled ? Color(.systemGray3) : .white)
                        .opacity(isDisabled ? 0.7 : 1.0)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                
                Text(LocalizedStringKey(type))
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? backgroundColor : textColor)
                    .opacity(isDisabled ? 0.6 : 1.0)
            }
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    struct PreviewWrapper: View {
    @State var selectedType: PetType = .cat
        
        var body: some View {
            PetTypeSelectionView(selectedType: $selectedType)
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
        }
    }
    
    return PreviewWrapper()
} 
