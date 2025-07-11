import SwiftUI

/// 宠物类型选择视图
struct PetTypeSelectionView: View {
    @Binding var selectedType: PetType
    @State private var showUnsupportedAlert = false
    
    // 支持的宠物类型
    private let supportedTypes: [PetType] = [.cat, .dog]
    
    // 未来支持的宠物类型（仅作展示）
    private let futureTypes = ["Rabbit", "Hamster", "Bird", "Fish", "Turtle", "Guinea Pig", "Lizard"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizedStringKey("What kind of friend are you welcoming?"))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            // 滑块选择
            HStack {
                Text(LocalizedStringKey("Cat"))
                    .foregroundColor(selectedType == .cat ? .yellow : .gray)
                    .fontWeight(selectedType == .cat ? .bold : .regular)
                
                Slider(value: Binding(
                    get: { selectedType == .cat ? 0.0 : 1.0 },
                    set: { selectedType = $0 < 0.5 ? .cat : .dog }
                ), in: 0...1, step: 1)
                .tint(.yellow)
                
                Text(LocalizedStringKey("Dog"))
                    .foregroundColor(selectedType == .dog ? .yellow : .gray)
                    .fontWeight(selectedType == .dog ? .bold : .regular)
            }
            .padding(.horizontal, 40)
            
            // 宠物类型网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                // 支持的宠物类型
                PetTypeCircleButton(
                    type: "Cat",
                    iconName: "cat",
                    isSelected: selectedType == .cat,
                    isDisabled: false,
                    backgroundColor: .yellow
                ) {
                    selectedType = .cat
                }
                
                PetTypeCircleButton(
                    type: "Dog",
                    iconName: "dog",
                    isSelected: selectedType == .dog,
                    isDisabled: false,
                    backgroundColor: .pink
                ) {
                    selectedType = .dog
                }
                
                // 灰色但可点击的未来支持类型 (显示为仓鼠)
                PetTypeCircleButton(
                    type: "Hamster",
                    iconName: "pawprint.fill",
                    isSelected: false,
                    isDisabled: true,
                    backgroundColor: Color(.systemGray4)
                ) {
                    showUnsupportedAlert = true
                }
                
                // 未来支持的宠物类型（置灰）
                ForEach(futureTypes.prefix(6), id: \.self) { type in
                    PetTypeCircleButton(
                        type: type,
                        iconName: "pawprint.fill",
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
                    .foregroundColor(.brown)
                Text(LocalizedStringKey("We are working hard and will support more cute friends soon!"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(10)
            .padding(.horizontal)
            
            Spacer()
            
            // Next 按钮
            Button(action: {
                // 这里什么都不做，因为按钮交互由父视图处理
            }) {
                Text(LocalizedStringKey("Next"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray5))
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom)
            .disabled(true)
        }
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
        .alert(LocalizedStringKey("Coming Soon"), isPresented: $showUnsupportedAlert) {
            Button(LocalizedStringKey("OK"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey("We're working hard to support more lovely pets soon!"))
        }
    }
}

/// 圆形宠物类型按钮
struct PetTypeCircleButton: View {
    let type: String
    let iconName: String
    let isSelected: Bool
    let isDisabled: Bool
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(isDisabled ? Color(.systemGray4) : backgroundColor)
                        .frame(width: 70, height: 70)
                        .opacity(isDisabled ? 0.5 : 1.0)
                    
                    if iconName == "cat" || iconName == "dog" {
                        Image(iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .opacity(isDisabled ? 0.5 : 1.0)
                    } else {
                        Image(systemName: iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .opacity(isDisabled ? 0.5 : 1.0)
                    }
                }
                
                Text(LocalizedStringKey(type))
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? backgroundColor : .primary)
                    .opacity(isDisabled ? 0.5 : 1.0)
            }
        }
        .disabled(isDisabled)
    }
}

#Preview {
    @State var selectedType: PetType = .cat
    return PetTypeSelectionView(selectedType: $selectedType)
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
} 