import SwiftUI

/// 宠物类型选择视图
struct PetTypeSelectionView: View {
    @Binding var selectedType: PetType
    
    // 支持的宠物类型（v1.1.0 - 全部10种）
    private let supportedTypes: [PetType] = [
        .cat, .dog, .rabbit, .hamster, .snake,.tortoise,.guineaPig,
        .bird, .lizard,.fish
    ]
    
    // 宠物颜色配置
    private let petColors: [PetType: Color] = [
        .cat: .orange,
        .dog: .blue,
        .rabbit: .pink,
        .hamster: .brown,
        .snake: Color(red: 0.5, green: 0.7, blue: 0.3),
        .tortoise: Color(red: 0.4, green: 0.6, blue: 0.4),
        .guineaPig: Color(red: 0.8, green: 0.6, blue: 0.4),
        .bird: .cyan,
        .lizard: .green,
        .fish: Color(red: 0.2, green: 0.6, blue: 0.8)
    ]
    
    // 定义更高对比度的颜色
    private let textColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let labelColor = Color(red: 0.3, green: 0.3, blue: 0.3)
    private let accentColor = Color(red: 0.69, green: 0.45, blue: 0.25)
    
    var body: some View {
        VStack(spacing: 30) {
            Text(LocalizedStringKey("What kind of friend are you welcoming?"))
                .font(.appTitle2)
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 宠物类型网格 - v1.1.0 支持全部10种
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 25) {
                ForEach(supportedTypes, id: \.self) { petType in
                    PetTypeImageButton(
                        type: petType.rawValue,
                        imageName: petType.defaultImageName,
                        isSelected: selectedType == petType,
                        isDisabled: false,
                        backgroundColor: petColors[petType] ?? .gray
                    ) {
                        selectedType = petType
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 20)
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
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
