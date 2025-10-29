//
//  Subject.swift
//  MyLovingDoll
//
//  主体提取结果数据模型
//

import Foundation
import SwiftData
import Photos

@Model
final class Subject {
    /// 唯一标识符
    @Attribute(.unique) var id: UUID
    
    /// 来源照片的 PHAsset 本地标识符
    var sourceAssetId: String
    
    /// 贴纸文件相对路径 (存储在 Documents/ObjectCamp/{specId}/subjects/)
    var stickerPath: String
    
    /// 缩略图文件相对路径
    var thumbnailPath: String?
    
    /// 边界框 (JSON 格式: {x, y, width, height})
    var boundingBox: String?
    
    /// 置信度分数 (0-1)
    var confidence: Double
    
    /// 特征向量 (用于聚类,JSON 数组格式)
    var featureVector: String?
    
    /// 提取时间
    var extractedAt: Date
    
    /// 所属目标规格
    var targetSpec: TargetSpec?
    
    /// 所属实体 (聚类后分配)
    var entity: Entity?
    
    /// 是否被标记为非目标
    var isMarkedAsNonTarget: Bool
    
    /// 提取方式 ("auto" 自动 | "manual" 手动调整)
    var extractionMethod: String = "auto"
    
    /// 是否需要人工审核/调整
    var needsReview: Bool = false
    
    /// 最后调整时间
    var lastAdjustedAt: Date?
    
    init(sourceAssetId: String, stickerPath: String, confidence: Double, targetSpec: TargetSpec?) {
        self.id = UUID()
        self.sourceAssetId = sourceAssetId
        self.stickerPath = stickerPath
        self.confidence = confidence
        self.extractedAt = Date()
        self.targetSpec = targetSpec
        self.isMarkedAsNonTarget = false
        self.extractionMethod = "auto"
        self.needsReview = false
    }
}
