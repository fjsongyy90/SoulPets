# 设置模块 (Settings Module)

## 📋 功能概览

设置页提供了应用的所有配置选项，按照清晰的卡片分组方式组织，符合 Apple HIG 设计规范。

## 🏗️ 架构设计

```
Settings/
├── SettingsView.swift              # 主设置页面
├── Components/
│   └── SettingsRowView.swift       # 设置行组件
├── Services/
│   └── SettingsService.swift       # 设置相关业务逻辑
└── Preview/
    └── SettingsPreview.swift       # 预览文件
```

## ✨ 主要功能

### 1. 通用设置 (General)
- **外观模式**: Light / Dark / System 三选一，支持实时切换
- **通知设置**: 直接跳转到 iOS 系统设置页面
- **语言设置**: MVP 版本显示"Coming Soon"提示

### 2. 支持与反馈 (Support & Feedback)
- **功能建议**: 打开邮件应用发送反馈
- **App Store 评分**: 使用 StoreKit 原生评分功能
- **分享应用**: 使用系统分享功能

### 3. 关于 (About)
- **隐私政策**: 打开官网隐私政策页面
- **服务条款**: 打开官网服务条款页面
- **版本信息**: 显示当前应用版本号

## 🎨 设计特点

### 视觉风格
- **卡片式布局**: 使用圆角卡片分组，视觉层次清晰
- **一致的配色**: 主色调 `#E5B487`，背景色 `#FDFBF8`
- **统一的图标**: 使用 SF Symbols 系统图标

### 交互设计
- **原生体验**: 严格遵循 iOS 设计规范
- **触觉反馈**: 按压动画和状态变化
- **无障碍支持**: 支持 VoiceOver 和动态字体

## 🔧 技术实现

### 核心组件

#### SettingsRowView
可复用的设置行组件，支持：
- 基础行（图标 + 标题 + 箭头）
- 带右侧文本的行
- 嵌入自定义内容的行（如分段控制器）

```swift
// 基础用法
SettingsRowView(
    icon: "bell",
    title: "Notifications",
    showChevron: true,
    action: { /* 处理点击 */ }
)

// 带自定义内容
SettingsRowView(
    icon: "paintbrush",
    title: "Appearance",
    showChevron: false
) {
    Picker("Appearance", selection: $selectedAppearance) {
        // 选项内容
    }
}
```

#### SettingsService
处理所有设置相关的业务逻辑：
- 系统集成（通知设置、评分、分享）
- 网页链接处理
- 邮件功能
- 版本信息获取

### 数据持久化
- 使用 SwiftData 的 `UserSettings` 模型
- 自动保存用户偏好设置
- 支持 iCloud 同步

## 📱 入口与导航

### 主页入口
- 位置：主页(Home Screen)导航栏左上角
- 图标：齿轮 (`gearshape`) 图标
- 交互：点击弹出全屏模态页面

### 页面导航
- 使用 `NavigationStack` 结构
- 左上角 X 按钮关闭页面
- 支持滑动返回手势

## 🌐 本地化支持

所有用户可见文本都已本地化：
- 设置页标题和分组标题
- 所有设置项名称
- 提示信息和对话框文本
- 邮件模板内容

## 🚀 扩展性

### 添加新设置项
1. 在 `SettingsView` 中添加新的 `SettingsRowView`
2. 在 `SettingsService` 中实现对应的业务逻辑
3. 在 `Localizable.strings` 中添加本地化字符串

### 添加新分组
1. 创建新的卡片视图
2. 按照现有模式添加标题和设置项
3. 更新布局和间距

## 🔍 测试与预览

项目包含完整的预览支持：
- 主设置页面预览
- 设置行组件预览
- 不同状态的预览

在 Xcode 中可以实时预览所有组件的效果。

## 📝 注意事项

1. **StoreKit 兼容性**: 代码已处理 iOS 18.0 的 API 变更
2. **网络链接**: 隐私政策和服务条款的 URL 需要在发布前更新
3. **邮件功能**: 会优雅降级到复制邮箱地址
4. **iPad 支持**: 分享功能已适配 iPad 的 popover 显示 