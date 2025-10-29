//
//  Entity.swift
//  MyLovingDoll
//
//  聚类实体数据模型
//

import Foundation
import SwiftData

@Model
final class Entity {
    /// 唯一标识符
    @Attribute(.unique) var id: UUID
    
    /// 用户自定义名称
    var customName: String?
    
    /// 代表图/封面主体 ID
    var coverSubjectId: UUID?
    
    /// 创建时间
    var createdAt: Date
    
    /// 最后更新时间
    var updatedAt: Date
    
    /// 所属目标规格
    var targetSpec: TargetSpec?
    
    /// 包含的主体
    @Relationship(deleteRule: .nullify, inverse: \Subject.entity)
    var subjects: [Subject]?
    
    /// 是否用户手动创建 (合并/拆分产生)
    var isManuallyCreated: Bool
    
    /// 平均置信度
    var averageConfidence: Double
    
    init(targetSpec: TargetSpec?, isManuallyCreated: Bool = false) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.targetSpec = targetSpec
        self.isManuallyCreated = isManuallyCreated
        self.averageConfidence = 0.0
    }
    
    /// 更新平均置信度
    func updateAverageConfidence() {
        guard let subjects = subjects, !subjects.isEmpty else {
            averageConfidence = 0.0
            return
        }
        averageConfidence = subjects.map { $0.confidence }.reduce(0, +) / Double(subjects.count)
    }
}
