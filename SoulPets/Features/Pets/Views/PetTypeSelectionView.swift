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
            Text(LocalizedStringKey("Select Your Pet Type"))
                .font(.title2)
                .fontWeight(.bold)
            
            // 支持的宠物类型网格
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(supportedTypes, id: \.self) { type in
                    PetTypeButton(
                        type: type.rawValue,
                        iconName: type == .cat ? "cat.fill" : "dog.fill",
                        isSelected: selectedType == type,
                        isDisabled: false
                    ) {
                        selectedType = type
                    }
                }
                
                // 未来支持的宠物类型（置灰）
                ForEach(futureTypes, id: \.self) { type in
                    PetTypeButton(
                        type: type,
                        iconName: "pawprint.fill",
                        isSelected: false,
                        isDisabled: true
                    ) {
                        showUnsupportedAlert = true
                    }
                    .overlay(
                        Text(LocalizedStringKey("Soon"))
                            .font(.caption)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .padding(4),
                        alignment: .bottomTrailing
                    )
                }
            }
            .padding(.horizontal)
        }
        .alert(LocalizedStringKey("Coming Soon"), isPresented: $showUnsupportedAlert) {
            Button(LocalizedStringKey("OK"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey("We're working hard to support more lovely pets soon!"))
        }
    }
}

/// 宠物类型按钮
struct PetTypeButton: View {
    let type: String
    let iconName: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("AccentColor") : Color(.systemGray5))
                        .frame(width: 80, height: 80)
                        .opacity(isDisabled ? 0.5 : 1.0)
                    
                    Image(systemName: iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(isSelected ? .white : .gray)
                        .opacity(isDisabled ? 0.5 : 1.0)
                }
                
                Text(LocalizedStringKey(type))
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? Color("AccentColor") : .primary)
                    .opacity(isDisabled ? 0.5 : 1.0)
            }
        }
        .disabled(isDisabled)
    }
}

#Preview {
    @State var selectedType: PetType = .cat
    return PetTypeSelectionView(selectedType: $selectedType)
} 