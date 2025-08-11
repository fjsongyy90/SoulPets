# Debug 重置数据功能实现总结

## 功能概述

在设置页面添加了一个仅在Debug模式下可见的重置数据功能，允许开发者选择性清除以下数据类型：
- **UserDefaults**: 清除应用偏好设置
- **Database**: 删除所有宠物、记录、提醒和体重数据  
- **Cache Files**: 清理临时文件和缓存数据

## 实现详情

### 1. SettingsService.swift 扩展

**新增功能**:
- 添加了 `isDebugMode` 静态属性，使用编译条件判断是否为Debug模式
- 定义了 `ResetDataOption` 枚举，包含三种重置选项
- 实现了 `resetData` 主方法和三个具体的重置方法

**核心方法**:
```swift
enum ResetDataOption: String, CaseIterable {
    case userDefaults = "UserDefaults"
    case database = "Database" 
    case cacheFiles = "Cache Files"
}

static func resetData(options: Set<ResetDataOption>, modelContext: ModelContext? = nil)
```

**安全保护**:
- 只有在Debug模式下才能执行重置操作
- 完整的错误处理和日志记录
- 智能处理不同数据类型的清理逻辑

### 2. SettingsView.swift UI实现

**Debug卡片**: 仅在 `SettingsService.isDebugMode` 为 `true` 时显示

**用户交互流程**:
1. 点击"Reset Data"按钮
2. 弹出选项选择Sheet，支持多选
3. 显示详细的选项说明和警告信息
4. 确认删除操作的Alert
5. 完成后显示成功提示

**Sheet界面特性**:
- 每个选项都有标题和详细描述
- 支持多选/取消选择
- 实时显示警告信息
- 只有选择了选项才能进行下一步

### 3. 本地化支持

**新增本地化字符串**:
```
"settings.debug.title" = "Debug Tools";
"settings.debug.reset_data" = "Reset Data";
"settings.debug.reset.userdefaults" = "UserDefaults";
"settings.debug.reset.database" = "Database"; 
"settings.debug.reset.cache" = "Cache Files";
```

**用户友好的描述**:
- 每个选项都有清晰的说明文本
- 警告信息明确标注这是开发测试功能
- 多层确认避免误操作

### 4. 数据清理实现

#### UserDefaults 重置
```swift
UserDefaults.standard.removePersistentDomain(forName: bundleID)
UserDefaults.standard.synchronize()
```

#### 数据库重置  
- 按照依赖关系顺序删除所有模型数据
- 删除顺序：ReminderCompletion → Reminder → RecordPhoto → Record → WeightGoal → Weight → Pet → UserSettings
- 使用 SwiftData 的 FetchDescriptor 和 ModelContext

#### 缓存文件清理
- 清理 `cachesDirectory` 中的所有文件
- 清理 `temporaryDirectory` 中的临时文件
- 使用 FileManager 进行安全的文件操作

## 技术特点

### 🔒 安全性保证
- **编译时保护**: 使用 `#if DEBUG` 编译条件
- **运行时检查**: `isDebugMode` 运行时验证
- **多层确认**: Sheet选择 + Alert确认 + 成功提示

### 📝 完整日志
- 使用 OSLog 框架记录所有操作
- 详细的成功/失败日志信息
- 便于开发调试和问题排查

### 🎯 用户体验
- 清晰的界面层次结构
- 详细的选项说明和警告
- 符合iOS设计规范的交互模式

### 🧩 模块化设计
- 业务逻辑与UI完全分离
- 可扩展的选项枚举设计
- 符合项目的代码架构规范

## 使用场景

1. **开发测试**: 快速清除测试数据，重置应用状态
2. **Bug调试**: 隔离数据问题，验证功能逻辑  
3. **性能测试**: 清理缓存文件，测试冷启动性能
4. **版本迁移**: 清除旧版本数据，测试数据迁移逻辑

## 编译状态

✅ **编译成功**: 项目在Debug模式下编译无错误
✅ **功能可用**: Debug卡片只在Debug构建时显示
✅ **生产安全**: Release版本中不会包含此功能

## 注意事项

⚠️ **仅限开发使用**: 此功能专为开发和测试设计
⚠️ **数据不可恢复**: 删除的数据无法撤销
⚠️ **需要重启应用**: 某些重置操作可能需要重启应用才能完全生效 