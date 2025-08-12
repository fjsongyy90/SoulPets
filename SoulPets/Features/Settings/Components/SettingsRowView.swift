import SwiftUI

struct SettingsRowView<Content: View>: View {
    let icon: String
    let title: String
    let rightText: String?
    let showChevron: Bool
    let action: (() -> Void)?
    let content: (() -> Content)?
    
    // 颜色定义
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15) // #E5B487
    
    // 适应性强调色 - 在深色模式下使用更亮的版本
    private var adaptiveAccentColor: Color {
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.90, green: 0.71, blue: 0.53, alpha: 1.0) // 深色模式：更亮的版本
            default:
                return UIColor(red: 0.60, green: 0.35, blue: 0.15, alpha: 1.0) // 浅色模式：原始棕褐色
            }
        })
    }
    
    // MARK: - 初始化器
    
    /// 基础设置行（仅标题和图标）
    init(
        icon: String,
        title: String,
        rightText: String? = nil,
        showChevron: Bool = false,
        action: (() -> Void)? = nil
    ) where Content == EmptyView {
        self.icon = icon
        self.title = title
        self.rightText = rightText
        self.showChevron = showChevron
        self.action = action
        self.content = nil
    }
    
    /// 带自定义内容的设置行
    init(
        icon: String,
        title: String,
        rightText: String? = nil,
        showChevron: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.rightText = rightText
        self.showChevron = showChevron
        self.action = action
        self.content = content
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // 左侧图标
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(adaptiveAccentColor) // 使用适应性强调色，确保在深色模式下也清晰可见
                        .frame(width: 24, height: 24)
                    
                    // 标题
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // 右侧内容区域
                    HStack(spacing: 8) {
                        // 自定义内容
                        if let content = content {
                            content()
                        }
                        
                        // 右侧文本
                        if let rightText = rightText {
                            Text(rightText)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // 箭头
                        if showChevron {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // 如果有自定义内容且不是空视图，添加内容区域
                if content != nil && !(Content.self == EmptyView.self) {
                    VStack {
                        content?()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .buttonStyle(SettingsRowButtonStyle())
        .disabled(action == nil && content == nil)
    }
}

// MARK: - 按钮样式
struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Color(.secondarySystemBackground) // 使用系统二级背景色，适应深色模式
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 预览
#Preview("基础设置行") {
    VStack(spacing: 1) {
        SettingsRowView(
            icon: "bell",
            title: "Notifications",
            showChevron: true,
            action: {
                print("Notifications tapped")
            }
        )
        
        SettingsRowView(
            icon: "globe",
            title: "Language",
            rightText: "English",
            showChevron: true,
            action: {
                print("Language tapped")
            }
        )
        
        SettingsRowView(
            icon: "info.circle",
            title: "Version",
            rightText: "1.0.0",
            showChevron: false
        )
    }
    .background(Color.white)
    .cornerRadius(12)
    .padding()
    .background(Color(hex: "FDFBF8"))
}

#Preview("带自定义内容的设置行") {
    VStack(spacing: 1) {
        SettingsRowView(
            icon: "paintbrush",
            title: "Appearance",
            showChevron: false
        ) {
            Picker("Appearance", selection: .constant(AppearanceMode.system)) {
                Text("Light").tag(AppearanceMode.light)
                Text("Dark").tag(AppearanceMode.dark)
                Text("System").tag(AppearanceMode.system)
            }
            .pickerStyle(.segmented)
        }
    }
    .background(Color.white)
    .cornerRadius(12)
    .padding()
    .background(Color(hex: "FDFBF8"))
} 