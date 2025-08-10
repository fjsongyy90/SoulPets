import SwiftUI

/// 可复用的标签项视图组件
struct TagItemView: View {
    let tag: Tag
    let isSelected: Bool
    let accentColor: Color
    let textColor: Color
    
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
            Image(systemName: tag.iconName)
                .font(.system(size: 18))
                .foregroundColor(isSelected ? .white : accentColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isSelected ? accentColor : Color(red: 0.97, green: 0.90, blue: 0.83))
                )
            
            // 名称
            Text(String(localized: LocalizedStringResource(stringLiteral: tag.name)))
                .font(.caption2)
                .foregroundColor(isSelected ? .white : textColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? accentColor.opacity(0.8) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
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