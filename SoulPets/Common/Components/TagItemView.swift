import SwiftUI

/// 可复用的标签项视图组件
struct TagItemView: View {
    let tag: Tag
    let isSelected: Bool
    let accentColor: Color
    let textColor: Color
    
    @State private var isPressed: Bool = false
    
    init(
        tag: Tag, 
        isSelected: Bool, 
        accentColor: Color = Color(red: 0.60, green: 0.35, blue: 0.15), 
        textColor: Color = Color(red: 0.25, green: 0.25, blue: 0.25)
    ) {
        self.tag = tag
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.textColor = textColor
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // 图标
            Image(tag.iconName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            
            // 名称
            Text(String(localized: LocalizedStringResource(stringLiteral: tag.name)))
                .font(.appCaption) // 使用统一的字体样式
                .foregroundColor(isSelected ? accentColor : textColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 88)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white) // 保持简洁的白色背景
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .scaleEffect(isPressed ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

#Preview {
    let sampleTag = Tag(
        code: "daily.food",
        name: "Dinner/Food",
        iconName: "fork.knife",
        category: .dailyLife,
        defaultIsReminder: true,
        isHidden: false,
        associatedPetTypes: [.cat, .dog]
    )
    
    let longNameTag = Tag(
        code: "grooming.nail",
        name: "Nail Trim",
        iconName: "scissors",
        category: .groomingCleaning,
        defaultIsReminder: true,
        isHidden: false,
        associatedPetTypes: [.cat, .dog]
    )
    
    VStack {
        // 展示横向滚动效果
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                TagItemView(tag: sampleTag, isSelected: false)
                    .frame(width: 100)
                TagItemView(tag: longNameTag, isSelected: true)
                    .frame(width: 100)
                TagItemView(tag: sampleTag, isSelected: false)
                    .frame(width: 100)
            }
            .padding(.horizontal)
        }
        
        // 展示单个组件
        HStack {
            TagItemView(tag: sampleTag, isSelected: false)
                .frame(width: 100)
            TagItemView(tag: sampleTag, isSelected: true)
                .frame(width: 100)
        }
    }
    .padding()
} 