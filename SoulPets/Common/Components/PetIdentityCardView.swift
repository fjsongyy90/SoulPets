import SwiftUI

/// 宠物灵魂身份卡视图 - v2.1设计规范的情感化宠物卡片
struct PetIdentityCardView: View {
    // MARK: - 属性
    let petAvatar: Data?
    let petName: String
    let petInfo: String
    let ageValue: String
    let ageLabel: String
    let togetherValue: String
    let togetherLabel: String
    let birthdayValue: String
    let birthdayLabel: String
    let onViewProfile: () -> Void
    
    var body: some View {
        ZStack {
            // 卡片容器
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "F7F1E8"))
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 10,
                    x: 0,
                    y: 5
                )
            
            // 装饰性爪印 - 背景装饰，位于右上角
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "E5B487").opacity(0.3))
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
            
            // 主要内容
            VStack(spacing: 0) {
                // 宠物头像
                Group {
                    if let avatarData = petAvatar, let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "E5B487"))
                    }
                }
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(hex: "F7F1E8"), lineWidth: 2)
                )
                .padding(.top, 20)
                
                // 宠物昵称
                Text(petName)
                    .font(.custom("Nunito-ExtraBold", size: 32))
                    .foregroundColor(Color(hex: "8B6F62"))
                    .padding(.top, 8)
                
                // 宠物信息
                Text(petInfo)
                    .font(.custom("Nunito-Regular", size: 15))
                    .foregroundColor(Color(hex: "A88C7D"))
                    .padding(.top, 8)
                
                // 情感数据区域
                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        // 年龄数据
                        EmotionalDataItemView(
                            value: ageValue,
                            label: ageLabel
                        )
                        
                        Spacer()
                        
                        // 陪伴数据
                        EmotionalDataItemView(
                            value: togetherValue,
                            label: togetherLabel
                        )
                    }
                    
                    // 生日数据 - 居中显示
                    HStack {
                        Spacer()
                        EmotionalDataItemView(
                            value: birthdayValue,
                            label: birthdayLabel
                        )
                        Spacer()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                
                // 分隔线
                Divider()
                    .frame(height: 1)
                    .background(Color(hex: "E5B487").opacity(0.5))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                
                // "查看档案"按钮
                Button(action: onViewProfile) {
                    Text("View Profile")
                        .font(.custom("Nunito-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(Color(hex: "E5B487"))
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .frame(maxHeight: 400) // 限制最大高度
    }
}

#Preview("宠物身份卡") {
    PetIdentityCardView(
        petAvatar: nil,
        petName: "Mimi",
        petInfo: "British Shorthair · Female",
        ageValue: "2y 5m 3d",
        ageLabel: "Time in this world",
        togetherValue: "642 days",
        togetherLabel: "Guarding each other for",
        birthdayValue: "in 362 days",
        birthdayLabel: "Next celebration in",
        onViewProfile: {}
    )
    .padding()
    .background(Color(hex: "FDFBF8"))
}
