import Foundation
import SwiftData

@Model
final class Record {
    // MARK: - 属性
    var id: UUID
    var timestamp: Date
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - 关系
    @Relationship(.nullify)
    var tag: Tag
    
    @Relationship(.cascade, inverse: \RecordPhoto.record)
    var photos: [RecordPhoto]?
    
    @Relationship
    var pets: [Pet]?
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        timestamp: Date,
        notes: String? = nil,
        tag: Tag,
        pets: [Pet]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.timestamp = timestamp
        self.notes = notes
        self.tag = tag
        self.pets = pets
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class RecordPhoto {
    // MARK: - 属性
    var id: UUID
    var photoData: Data
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - 关系
    @Relationship
    var record: Record
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        photoData: Data,
        record: Record,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.photoData = photoData
        self.record = record
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 