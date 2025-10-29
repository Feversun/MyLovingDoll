//
//  ProcessingTask.swift
//  MyLovingDoll
//
//  处理任务进度管理
//

import Foundation
import SwiftData

enum TaskStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

@Model
final class ProcessingTask {
    /// 唯一标识符
    @Attribute(.unique) var id: UUID
    
    /// 任务状态
    var statusRaw: String
    
    /// 所属目标规格 ID
    var targetSpecId: String
    
    /// 待处理的照片资产 ID 列表 (JSON 数组格式)
    var assetIdsJson: String
    
    /// 总数
    var totalCount: Int
    
    /// 已处理数
    var processedCount: Int
    
    /// 成功数
    var successCount: Int
    
    /// 失败数
    var failureCount: Int
    
    /// 失败的资产 ID 列表 (JSON 数组格式)
    var failedAssetIdsJson: String?
    
    /// 创建时间
    var createdAt: Date
    
    /// 开始时间
    var startedAt: Date?
    
    /// 完成时间
    var completedAt: Date?
    
    /// 错误信息
    var errorMessage: String?
    
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
    
    init(targetSpecId: String, assetIds: [String]) {
        self.id = UUID()
        self.statusRaw = TaskStatus.pending.rawValue
        self.targetSpecId = targetSpecId
        self.assetIdsJson = (try? JSONEncoder().encode(assetIds)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.totalCount = assetIds.count
        self.processedCount = 0
        self.successCount = 0
        self.failureCount = 0
        self.createdAt = Date()
    }
    
    /// 获取资产 ID 列表
    func getAssetIds() -> [String] {
        guard let data = assetIdsJson.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return ids
    }
    
    /// 获取失败的资产 ID 列表
    func getFailedAssetIds() -> [String] {
        guard let json = failedAssetIdsJson,
              let data = json.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return ids
    }
    
    /// 添加失败的资产 ID
    func addFailedAssetId(_ assetId: String) {
        var failedIds = getFailedAssetIds()
        if !failedIds.contains(assetId) {
            failedIds.append(assetId)
            if let data = try? JSONEncoder().encode(failedIds),
               let json = String(data: data, encoding: .utf8) {
                failedAssetIdsJson = json
            }
        }
    }
}
