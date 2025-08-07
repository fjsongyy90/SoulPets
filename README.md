# SoulPets 🐾

[![Platform](https://img.shields.io/badge/platform-iOS-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.10%2B-orange.svg)](https://www.swift.org)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](./LICENSE)

**The digital heartbeat of your bond with pets.**

SoulPets 是一款为海外宠物主打造的、注重隐私安全的 iOS 应用，提供全面的宠物生活管理解决方案。所有数据 100% 存储于用户设备本地，通过 iCloud 在单用户多设备间安全同步。

---

## 项目愿景与核心哲学

### 我们的使命
我们相信，科技能加深人与宠物之间的情感纽带，而非取代它。SoulPets 的使命是提供一个安静、私密且充满关怀的数字空间，帮助宠物主记录、管理并珍藏与爱宠共度的每一个宝贵瞬间，让冰冷的数据充满温暖的“心跳”。

### 目标用户
- **核心用户**: 注重数据隐私与安全，希望精细化、科学化管理爱宠生活的海外宠物主。
- **特征**: 追求高品质原生应用体验，对复杂、臃肿的应用感到厌倦，珍视与宠物的情感连接。

### 核心原则
SoulPets 的开发始终遵循以下四大核心原则：

1.  **隐私第一 (Privacy First)**
    我们承诺，用户的任何数据都将 100% 存储在他们自己的设备上。iCloud 同步是用户自己的私有行为，我们作为开发者绝不触碰、收集或分析任何用户数据。这是我们与用户之间最重要的信任契约。

2.  **原生体验 (Native Experience)**
    我们坚信，最好的用户体验源于平台自身的生态。因此，我们全面拥抱 SwiftUI, SwiftData 等苹果原生技术，并严格遵循苹果人机交互指南 (HIG)，确保应用表现如丝般顺滑、操作直观自然。

3.  **情感化设计 (Emotional Design)**
    我们致力于打造一个有“温度”的应用。从柔和的奶油色系、治愈系的插画图标，到充满鼓励和关怀的文案，每一个设计细节都旨在为用户带来舒适、放松和被关爱的感觉。

4.  **全球化视野 (Global Perspective)**
    SoulPets 从第一天起就是为全球用户设计的。这意味着我们不仅在功能上（如多单位支持）考虑海外用户习惯，更在技术底层预埋了完整的国际化支持，确保未来能轻松适配更多语言和地区。

---

## 功能清单 (MVP & Pro)

### MVP (v1.0) 核心功能
MVP 版本专注于为单用户提供一个完整、流畅的核心功能闭环。

- **🐾 多宠物档案 (Multi-Pet Profiles)**: 为您的每一位家庭成员建立专属“数字身份证”，包含生日、纪念日、健康信息等，所有信息一目了然。
- **🗓️ 事件记录 (Record Timeline)**: 以精美的图文时间线形式，记录喂食、喂药、驱虫等所有日常与医疗事件，构成爱寵的完整生命日志。
- **🔔 智能提醒 (Smart Reminders)**: 强大的重复提醒引擎，确保您绝不会忘记任何一次疫苗、年度体检或购买耗材的重要日程。
- **⚖️ 体重追踪 (Weight Tracking)**: 通过直观的 `Apple Charts` 曲线图，轻松监控爱寵的体重变化，直观掌握健康趋势。
- **🏷️ 标签管理 (Tag Management)**: 免费提供对预设标签的排序、隐藏和配置是否用于提醒等个性化整理功能。

### Pro 会员功能 (未来规划)
Pro 功能专注于提供更强大的个性化、多用户协作和高级数据分析能力。

- **iCloud 家庭共享**: 邀请家庭成员（不同 Apple ID）共同管理宠物数据。
- **标签自定义**: 允许用户创建、编辑、删除个性化标签。
- **高级统计**: 提供详细的记账统计图表与年度财务报告。
- **无限照片**: 解除每个宠物档案的照片数量限制。
- **宠物减肥助手**: 设立目标并追踪减肥/增重进程的特别功能。
- **iOS 桌面小组件**: 在主屏幕快速查看宠物状态和即将到来的提醒。

---

## 应用架构说明

### 整体架构
应用采用标准的、以数据为中心的 SwiftUI 架构，其设计思想近似于 **MVVM (Model-View-ViewModel)**。
- **Model**: 由 **SwiftData** 的 `@Model` 宏定义的类组成，是应用的数据源和真理的唯一来源。
- **View**: 完全由 **SwiftUI** 构建的声明式视图。视图尽可能保持“无状态”，其渲染由其数据源驱动。
- **ViewModel**: 作为视图和模型之间的桥梁，处理复杂的业务逻辑、用户输入验证以及为视图准备和格式化数据。

### 数据层 (Data Layer)
- **持久化**: 完全依赖 **SwiftData** 进行数据持久化。这确保了类型安全、高性能以及与 SwiftUI 的无缝集成。
- **数据模型**: 核心模型包括 `Pet`, `LogEntry`, `WeightEntry`, `Reminder` 等，它们之间的关系通过 `@Relationship` 宏进行管理。
- **关键逻辑 - 重复提醒**: 为了避免数据库膨胀，重复性提醒在数据库中只存储一条“模板规则”（包含重复频率、开始日期等）。视图在显示时，会在内存中动态计算出未来需要显示的实例，这是一个保证应用长期高性能的关键架构决策。

### UI 层 (UI Layer)
- **声明式与响应式**: UI 完全由数据状态驱动。当 SwiftData 中的数据或 ViewModel 中的 `@Published` 属性发生变化时，相关视图会自动刷新。
- **组件化**: 视图被拆分为小型、可复用的组件，以提高代码的可维护性和复用性。

### 导航 (Navigation)
- **主导航**: 使用 SwiftUI 的 `TabView` 实现应用的底部标签栏，作为一级页面的主要入口。
- **层级导航**: 在各个功能模块内部，使用 `NavigationStack` 来管理视图的推入 (push) 和弹出 (pop)，实现层级导航。

---

## 技术栈

| 类别 | 技术 |
| :--- | :--- |
| **UI 框架** | SwiftUI |
| **数据持久化** | SwiftData |
| **图表** | Apple Charts Framework |
| **通知** | UserNotifications Framework |
| **架构模式** | MVVM (近似) |

---

## 快速开始

### 环境要求
- macOS Sonoma 14.0+
- Xcode 16.0+
- Swift 5.10+

### 安装与运行
1.  克隆仓库到本地：
    ```bash
    git clone [https://github.com/fjsongyy90/SoulPets.git](https://github.com/fjsongyy90/SoulPets.git)
    ```
2.  打开 `SoulPets.xcodeproj` 文件。
3.  选择一个模拟器或连接真实的 iOS 设备。
4.  点击 "Run" (▶) 按钮编译并运行。

---

## 项目结构

SoulPets项目采用模块化的目录结构，清晰地分离了不同功能组件：

```
SoulPets/
├── .cursor/rules/         # Cursor IDE规则配置
├── Assets.xcassets/       # 应用资源文件
├── Common/                # 通用组件和工具类
├── Core/                  # 核心功能模块
├── Data/                  # 数据层
│   ├── Models/            # 数据模型定义
│   ├── Services/          # 数据服务
│   └── ModelRegistration.swift  # 模型注册
├── Features/              # 功能模块
│   ├── Pets/              # 宠物管理功能
│   ├── Record/            # 记录功能
│   ├── Reminders/         # 提醒功能
│   ├── Tags/              # 标签功能
│   └── Weight/            # 体重功能
├── Resources/             # 资源文件
├── ContentView.swift      # 主内容视图
├── SoulPetsApp.swift      # 应用入口
├── SoulPets.xcodeproj/    # Xcode项目文件
├── SoulPetsTests/         # 单元测试
├── SoulPetsUITests/       # UI测试
├── .gitignore             # Git忽略配置
└── README.md              # 项目说明文档
```

这种结构遵循了功能模块化的设计原则，使代码组织更加清晰，便于维护和扩展。每个功能模块都有自己的目录，包含相关的视图、视图模型和辅助组件。

---

## 可复用组件 (Reusable Components)

为了提高代码复用性和保持设计一致性，SoulPets 创建了一系列通用组件，这些组件在多个功能模块中被广泛使用。

### UI 组件 (UI Components)

#### PetAvatarView
**位置**: `SoulPets/Common/Components/PetAvatarView.swift`  
**功能**: 统一的宠物头像显示组件
- 支持自定义头像图片或默认图标
- 提供选中/未选中状态的视觉反馈
- 可配置尺寸、颜色和选中状态
- **使用场景**: 宠物选择器、提醒列表、记录列表等

```swift
PetAvatarView(
    pet: pet,
    isSelected: selectedPet?.id == pet.id,
    accentColor: accentColor,
    textColor: textColor,
    size: 60
)
```

#### TagItemView
**位置**: `SoulPets/Common/Components/TagItemView.swift`  
**功能**: 统一的标签项显示组件
- 显示标签图标和名称
- 支持选中/未选中状态
- 一致的卡片样式和颜色主题
- **使用场景**: 添加记录页面、添加提醒页面的标签选择

```swift
TagItemView(
    tag: tag,
    isSelected: selectedTag?.id == tag.id,
    accentColor: accentColor,
    textColor: textColor
)
```

### 扩展组件 (Extensions)

#### View+Alert
**位置**: `SoulPets/Common/Extensions/View+Alert.swift`  
**功能**: 统一的确认对话框样式扩展
- `customConfirmAlert`: 用于删除等破坏性操作的确认
- `customChoiceAlert`: 用于用户选择的对话框
- 确保整个应用的对话框样式一致性，解决按钮文字可见性问题

```swift
.customConfirmAlert(
    title: "Delete Reminder",
    message: "This action cannot be undone.",
    isPresented: $showingDeleteAlert,
    confirmTitle: "Delete",
    confirmAction: { deleteAction() },
    isDestructive: true
)
```

### 设计原则与优势

#### 🎯 一致性保证
- **统一的配色方案**: 所有组件使用相同的颜色变量 (`accentColor`, `textColor`, `labelColor`)
- **统一的交互反馈**: 选中状态、按压效果等保持一致
- **统一的圆角和阴影**: 所有卡片组件使用相同的视觉样式

#### 🔄 高度复用
- **跨模块使用**: `PetAvatarView` 在 Records、Reminders 模块中都有使用
- **参数化配置**: 通过参数控制组件的外观和行为，无需重复代码
- **易于维护**: 样式修改只需在一个地方进行

#### 🚀 开发效率
- **快速原型**: 新功能开发时可以直接使用现有组件
- **减少错误**: 避免在多处重复实现相同逻辑导致的不一致
- **易于测试**: 独立的组件更容易进行单元测试

### 组件使用指南

#### 在新功能中使用组件
1. **导入组件**: 确保在 SwiftUI 视图中正确导入
2. **配色一致**: 使用项目定义的标准颜色变量
3. **参数传递**: 根据具体场景传递合适的参数
4. **状态管理**: 正确处理组件的选中状态和回调

#### 扩展现有组件
当需要扩展现有组件功能时：
1. **向后兼容**: 确保新参数有默认值，不影响现有使用
2. **文档更新**: 在本文档中更新组件说明
3. **测试验证**: 确保所有使用该组件的地方都正常工作

---