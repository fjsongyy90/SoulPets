import Foundation
import SwiftData
import OSLog

/// 记录统计服务
class RecordStatsService {
    private static let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "RecordStats")
    
    // MARK: - 基础统计
    
    /// 获取总记录数
    static func getTotalRecordCount(modelContext: ModelContext) -> Int {
        let descriptor = FetchDescriptor<Record>()
        
        do {
            let records = try modelContext.fetch(descriptor)
            return records.count
        } catch {
            logger.error("获取总记录数时出错: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// 获取指定宠物的记录数
    static func getRecordCount(forPet pet: Pet, modelContext: ModelContext) -> Int {
        let records = RecordService.getAllRecords(forPet: pet, modelContext: modelContext)
        return records.count
    }
    
    /// 获取指定标签的记录数
    static func getRecordCount(forTag tag: Tag, modelContext: ModelContext) -> Int {
        let records = RecordService.searchRecords(withTag: tag, modelContext: modelContext)
        return records.count
    }
    
    // MARK: - 时间统计
    
    /// 获取今日记录数
    static func getTodayRecordCount(modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let records = RecordService.getRecords(from: today, to: tomorrow, modelContext: modelContext)
        return records.count
    }
    
    /// 获取本周记录数
    static func getThisWeekRecordCount(modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return 0
        }
        
        let records = RecordService.getRecords(from: weekStart, to: today, modelContext: modelContext)
        return records.count
    }
    
    /// 获取本月记录数
    static func getThisMonthRecordCount(modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        guard let monthStart = calendar.dateInterval(of: .month, for: today)?.start else {
            return 0
        }
        
        let records = RecordService.getRecords(from: monthStart, to: today, modelContext: modelContext)
        return records.count
    }
    
    // MARK: - 高级统计
    
    /// 获取最活跃的标签（按记录数排序）
    static func getMostActiveTagsStats(limit: Int = 5, modelContext: ModelContext) -> [(tag: Tag, count: Int)] {
        let descriptor = FetchDescriptor<Tag>()
        
        do {
            let allTags = try modelContext.fetch(descriptor)
            var tagStats: [(tag: Tag, count: Int)] = []
            
            for tag in allTags {
                let count = getRecordCount(forTag: tag, modelContext: modelContext)
                if count > 0 {
                    tagStats.append((tag: tag, count: count))
                }
            }
            
            // 按记录数降序排序
            tagStats.sort { $0.count > $1.count }
            
            // 限制返回数量
            return Array(tagStats.prefix(limit))
            
        } catch {
            logger.error("获取最活跃标签统计时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取最活跃的宠物（按记录数排序）
    static func getMostActivePetsStats(limit: Int = 5, modelContext: ModelContext) -> [(pet: Pet, count: Int)] {
        let descriptor = FetchDescriptor<Pet>()
        
        do {
            let allPets = try modelContext.fetch(descriptor)
            var petStats: [(pet: Pet, count: Int)] = []
            
            for pet in allPets {
                let count = getRecordCount(forPet: pet, modelContext: modelContext)
                if count > 0 {
                    petStats.append((pet: pet, count: count))
                }
            }
            
            // 按记录数降序排序
            petStats.sort { $0.count > $1.count }
            
            // 限制返回数量
            return Array(petStats.prefix(limit))
            
        } catch {
            logger.error("获取最活跃宠物统计时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取指定时间段内的记录频率分布
    static func getRecordFrequencyStats(
        from startDate: Date,
        to endDate: Date,
        groupBy interval: Calendar.Component = .day,
        modelContext: ModelContext
    ) -> [Date: Int] {
        let records = RecordService.getRecords(from: startDate, to: endDate, modelContext: modelContext)
        let calendar = Calendar.current
        var stats: [Date: Int] = [:]
        
        for record in records {
            let groupDate: Date
            
            switch interval {
            case .day:
                groupDate = calendar.startOfDay(for: record.timestamp)
            case .weekOfYear:
                groupDate = calendar.dateInterval(of: .weekOfYear, for: record.timestamp)?.start ?? record.timestamp
            case .month:
                groupDate = calendar.dateInterval(of: .month, for: record.timestamp)?.start ?? record.timestamp
            default:
                groupDate = calendar.startOfDay(for: record.timestamp)
            }
            
            stats[groupDate, default: 0] += 1
        }
        
        return stats
    }
    
    /// 获取记录的照片统计
    static func getPhotoStats(modelContext: ModelContext) -> (totalPhotos: Int, recordsWithPhotos: Int, averagePhotosPerRecord: Double) {
        let descriptor = FetchDescriptor<Record>()
        
        do {
            let allRecords = try modelContext.fetch(descriptor)
            var totalPhotos = 0
            var recordsWithPhotos = 0
            
            for record in allRecords {
                if let photos = record.photos, !photos.isEmpty {
                    totalPhotos += photos.count
                    recordsWithPhotos += 1
                }
            }
            
            // 安全的除法计算，避免NaN
            let averagePhotosPerRecord: Double
            if recordsWithPhotos > 0 && totalPhotos >= 0 {
                let rawAverage = Double(totalPhotos) / Double(recordsWithPhotos)
                averagePhotosPerRecord = rawAverage.isFinite ? rawAverage : 0.0
            } else {
                averagePhotosPerRecord = 0.0
            }
            
            return (totalPhotos: totalPhotos, recordsWithPhotos: recordsWithPhotos, averagePhotosPerRecord: averagePhotosPerRecord)
            
        } catch {
            logger.error("获取照片统计时出错: \(error.localizedDescription)")
            return (totalPhotos: 0, recordsWithPhotos: 0, averagePhotosPerRecord: 0.0)
        }
    }
    
    // MARK: - 趋势分析
    
    /// 获取记录趋势（与上一期间比较）
    static func getRecordTrend(
        for period: Calendar.Component = .month,
        modelContext: ModelContext
    ) -> (current: Int, previous: Int, changePercentage: Double) {
        let calendar = Calendar.current
        let now = Date()
        
        // 计算当前期间和上一期间的开始日期
        let currentPeriodStart: Date
        let previousPeriodStart: Date
        
        switch period {
        case .day:
            currentPeriodStart = calendar.startOfDay(for: now)
            previousPeriodStart = calendar.date(byAdding: .day, value: -1, to: currentPeriodStart) ?? currentPeriodStart
        case .weekOfYear:
            currentPeriodStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            previousPeriodStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentPeriodStart) ?? currentPeriodStart
        case .month:
            currentPeriodStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            previousPeriodStart = calendar.date(byAdding: .month, value: -1, to: currentPeriodStart) ?? currentPeriodStart
        default:
            currentPeriodStart = calendar.startOfDay(for: now)
            previousPeriodStart = calendar.date(byAdding: .day, value: -1, to: currentPeriodStart) ?? currentPeriodStart
        }
        
        // 获取当前期间的记录数
        let currentRecords = RecordService.getRecords(from: currentPeriodStart, to: now, modelContext: modelContext)
        let currentCount = currentRecords.count
        
        // 获取上一期间的记录数
        let previousRecords = RecordService.getRecords(from: previousPeriodStart, to: currentPeriodStart, modelContext: modelContext)
        let previousCount = previousRecords.count
        
        // 计算变化百分比
        let changePercentage: Double
        if previousCount > 0 {
            let rawPercentage = Double(currentCount - previousCount) / Double(previousCount) * 100
            changePercentage = rawPercentage.isFinite ? rawPercentage : 0.0
        } else {
            changePercentage = currentCount > 0 ? 100.0 : 0.0
        }
        
        return (current: currentCount, previous: previousCount, changePercentage: changePercentage)
    }
    
    /// 获取记录连续性统计（连续记录天数）
    static func getRecordStreakStats(modelContext: ModelContext) -> (currentStreak: Int, longestStreak: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 获取所有记录，按日期分组
        let allRecords = RecordService.getAllRecords(modelContext: modelContext)
        let recordDates = Set(allRecords.map { calendar.startOfDay(for: $0.timestamp) })
        
        // 计算当前连续天数
        var currentStreak = 0
        var checkDate = today
        
        while recordDates.contains(checkDate) {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        // 计算最长连续天数
        var longestStreak = 0
        var tempStreak = 0
        
        // 从最早的记录开始检查
        let sortedDates = recordDates.sorted()
        guard let firstDate = sortedDates.first else {
            return (currentStreak: 0, longestStreak: 0)
        }
        
        var currentDate = firstDate
        let lastDate = today
        
        while currentDate <= lastDate {
            if recordDates.contains(currentDate) {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 0
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return (currentStreak: currentStreak, longestStreak: longestStreak)
    }
} 