import Foundation
import SwiftData
import OSLog

/// 记录服务，负责处理记录相关的业务逻辑
class RecordService {
    private static let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "Record")
    
    /// 获取所有记录（可按宠物筛选）
    static func getAllRecords(forPet pet: Pet? = nil, modelContext: ModelContext) -> [Record] {
            // 获取所有记录
        let descriptor = FetchDescriptor<Record>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
        
        do {
            let records = try modelContext.fetch(descriptor)
            
            // 如果指定了宠物，则在内存中过滤
            if let pet = pet {
                return records.filter { record in
                    guard let pets = record.pets else { return false }
                    return pets.contains(where: { $0.id == pet.id })
                }
            } else {
                return records
            }
        } catch {
            logger.error("获取记录时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 按标签搜索记录
    static func searchRecords(withTag tag: Tag, modelContext: ModelContext) -> [Record] {
        // 获取所有记录
        let descriptor = FetchDescriptor<Record>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let records = try modelContext.fetch(descriptor)
            
            // 在内存中过滤符合标签的记录
            return records.filter { record in
                record.tag.id == tag.id
            }
        } catch {
            logger.error("按标签搜索记录时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 按关键字搜索记录
    static func searchRecords(withKeyword keyword: String, modelContext: ModelContext) -> [Record] {
        guard !keyword.isEmpty else { return [] }
        
        // 首先获取所有记录
        let descriptor = FetchDescriptor<Record>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let allRecords = try modelContext.fetch(descriptor)
            
            // 在内存中进行过滤
            return allRecords.filter { record in
                let notesMatch = record.notes?.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                let tagMatch = record.tag.name.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                return notesMatch || tagMatch
            }
        } catch {
            logger.error("按关键字搜索记录时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取特定时间范围内的记录
    static func getRecords(from startDate: Date, to endDate: Date, modelContext: ModelContext) -> [Record] {
        let predicate = #Predicate<Record> { record in
            record.timestamp >= startDate && record.timestamp <= endDate
        }
        let descriptor = FetchDescriptor<Record>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("获取时间范围内记录时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 添加照片到记录
    static func addPhotoToRecord(record: Record, photoData: Data, modelContext: ModelContext) {
        let photo = RecordPhoto(
            photoData: photoData,
            record: record
        )
        
        modelContext.insert(photo)
        
        do {
            try modelContext.save()
            logger.info("成功为记录添加照片: \(record.id)")
        } catch {
            logger.error("为记录添加照片时出错: \(error.localizedDescription)")
        }
    }
    
    /// 删除记录照片
    static func deletePhoto(photo: RecordPhoto, modelContext: ModelContext) {
        modelContext.delete(photo)
        
        do {
            try modelContext.save()
            logger.info("成功删除照片: \(photo.id)")
        } catch {
            logger.error("删除照片时出错: \(error.localizedDescription)")
        }
    }
    
    /// 获取近期记录统计（例如，最近7天每天的记录数量）
    static func getRecentRecordStats(days: Int = 7, modelContext: ModelContext) -> [Date: Int] {
        let calendar = Calendar.current
        var stats: [Date: Int] = [:]
        
        // 获取过去days天的日期
        let today = calendar.startOfDay(for: Date())
        for dayOffset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                stats[date] = 0
            }
        }
        
        // 计算开始日期
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) else {
            return stats
        }
        
        // 获取时间范围内的所有记录
        let records = getRecords(from: startDate, to: today, modelContext: modelContext)
        
        // 按日期统计记录数量
        for record in records {
            let recordDate = calendar.startOfDay(for: record.timestamp)
            stats[recordDate, default: 0] += 1
        }
        
        return stats
    }
} 