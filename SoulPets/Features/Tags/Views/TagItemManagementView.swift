import SwiftUI
import os.log

struct TagItemManagementView: View {
    // MARK: - 属性
    let tag: Tag
    let onToggleReminder: () -> Void
    let onToggleVisibility: () -> Void
    let usageStats: (recordCount: Int, reminderCount: Int)
    let isHidden: Bool
    
    // 颜色定义
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    // 调试日志
    private let logger = Logger(subsystem: "com.soulpets.app", category: "TagItemManagement")
    
    // MARK: - 视图
    var body: some View {
        HStack(spacing: 12) {
            // 标签信息
            tagInfo
            
            Spacer()
            
            // 控制按钮（右边）
            controlButtons
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHidden ? Color.gray.opacity(0.1) : Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHidden ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .opacity(isHidden ? 0.6 : 1.0)
        .onAppear {
            // 添加调试日志
            logger.info("显示标签: \(tag.name),编码：\(tag.code), 图标名: \(tag.iconName), 记录次数: \(usageStats.recordCount), 提醒次数: \(usageStats.reminderCount)")
        }
    }
    
    // MARK: - 子视图
    
    private var dragHandle: some View {
        Image(systemName: "line.horizontal.3")
            .font(.caption)
            .foregroundColor(.gray)
            .frame(width: 20)
    }
    
    private var tagInfo: some View {
        HStack(spacing: 12) {
            // 标签图标
            tagIcon
            
            // 标签详情
            VStack(alignment: .leading, spacing: 4) {
                // 标签名称
                HStack {
                    Text(tag.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isHidden ? .gray : .primary)
                        .strikethrough(isHidden)
                }
                
                // 使用统计
                if usageStats.recordCount > 0 || usageStats.reminderCount > 0 {
                    usageStatsView
                }
            }
        }
    }
    
    private var tagIcon: some View {
        ZStack {
            Circle()
                .fill(isHidden ? Color.gray.opacity(0.2) : accentColor.opacity(0.1))
                .frame(width: 32, height: 32)
            Image(tag.iconName)
                .resizable()
                .scaledToFill()
                .frame(width: 24, height: 24)
                .clipShape(Circle())
        }
    }
    
    private var usageStatsView: some View {
        HStack(spacing: 8) {
            if usageStats.recordCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.caption2)
                    Text("\(usageStats.recordCount)")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            
            if usageStats.reminderCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "bell")
                        .font(.caption2)
                    Text("\(usageStats.reminderCount)")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 16) {
            // 提醒可用性开关
            reminderToggle
            
            // 可见性开关
            visibilityToggle
        }
    }
    
    private var reminderToggle: some View {
        VStack(spacing: 2) {
            Button(action: onToggleReminder) {
                Image(systemName: tag.defaultIsReminder ? "bell.fill" : "bell.slash")
                    .font(.system(size: 16))
                    .foregroundColor(tag.defaultIsReminder ? accentColor : .gray)
            }
            .disabled(isHidden)
            
            Text(String(localized: "Reminder"))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var visibilityToggle: some View {
        VStack(spacing: 2) {
            Button(action: onToggleVisibility) {
                Image(systemName: isHidden ? "eye.slash" : "eye")
                    .font(.system(size: 16))
                    .foregroundColor(isHidden ? .gray : accentColor)
            }
            
            Text(String(localized: "Visible"))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 辅助方法
    
    private func getSystemIconName() -> String {
        // 将自定义图标名映射到系统图标
        switch tag.iconName {
        case "food":
            return "fork.knife"
        case "water":
            return "drop"
        case "treats":
            return "heart.fill"
        case "walk":
            return "figure.walk"
        case "training":
            return "icon_training"
        case "play":
            return "gamecontroller"
        case "milk":
            return "drop.fill"
        case "potty":
            return "trash"
        case "medication":
            return "pill"
        case "supplements":
            return "cross.case"
        case "deworm":
            return "ladybug"
        case "vaccine":
            return "syringe"
        case "brushing":
            return "comb"
        case "teeth":
            return "mouth"
        case "nail":
            return "scissors"
        case "ear":
            return "ear"
        case "bath":
            return "shower"
        case "anal":
            return "drop.circle"
        case "supplies":
            return "bag"
        case "litterbox":
            return "tray"
        case "bowls":
            return "bowl"
        case "refill":
            return "arrow.clockwise"
        case "litter":
            return "square.grid.3x3"
        case "bed":
            return "bed.double"
        case "toys":
            return "gamecontroller"
        case "checkup":
            return "stethoscope"
        case "grooming":
            return "scissors"
        case "antibody":
            return "cross.circle"
        case "abnormal":
            return "exclamationmark.triangle"
        case "surgery":
            return "cross.circle.fill"
        case "hospitalization":
            return "building.2"
        case "sitter":
            return "person"
        case "boarding":
            return "building.2"
        case "license":
            return "doc.text"
        case "insurance":
            return "shield"
        case "birthday":
            return "gift"
        case "adoption":
            return "heart.circle"
        default:
            return "tag"
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        // 普通标签
        TagItemManagementView(
            tag: Tag(
                code: "daily.food",
                name: "Dinner/Food",
                iconName: "food",
                category: .dailyLife,
                defaultIsReminder: true,
                associatedPetTypes: [.cat, .dog]
            ),
            onToggleReminder: {},
            onToggleVisibility: {},
            usageStats: (recordCount: 5, reminderCount: 2),
            isHidden: false
        )
        
        // 隐藏标签
        TagItemManagementView(
            tag: Tag(
                code: "daily.potty",
                name: "[Hidden] Potty",
                iconName: "potty",
                category: .dailyLife,
                defaultIsReminder: false,
                associatedPetTypes: [.cat, .dog]
            ),
            onToggleReminder: {},
            onToggleVisibility: {},
            usageStats: (recordCount: 0, reminderCount: 0),
            isHidden: true
        )
    }
    .padding()
    .background(Color(red: 0.98, green: 0.97, blue: 0.94))
} 
