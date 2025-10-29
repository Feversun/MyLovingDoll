//
//  EntityClusterService.swift
//  MyLovingDoll
//
//  EntityCluster - 实体聚类服务
//

import Foundation
import SwiftData
import Vision
import Combine

@MainActor
class EntityClusterService: ObservableObject {
    private var modelContext: ModelContext
    
    /// 相似度阈值 (0-1, 越高越严格)
    private let similarityThreshold: Float = 0.75
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 对指定 specId 的所有主体进行聚类
    func clusterSubjects(for specId: String) async throws {
        print("[CLUSTER] 开始聚类, specId: \(specId)")
        
        // SwiftData Predicate 关系查询有 bug, 改为获取所有主体然后手动过滤
        let descriptor = FetchDescriptor<Subject>()
        let allSubjects = try modelContext.fetch(descriptor)
        
        // 手动过滤
        let subjects = allSubjects.filter { subject in
            subject.targetSpec?.specId == specId &&
            subject.entity == nil &&
            subject.isMarkedAsNonTarget == false
        }
        
        print("[CLUSTER] 数据库中总主体数: \(allSubjects.count)")
        print("[CLUSTER] 过滤后符合条件的主体数: \(subjects.count)")
        
        guard !subjects.isEmpty else {
            print("[CLUSTER] 没有主体需要聚类")
            return
        }
        
        // 提取特征向量
        var subjectsWithVectors: [(Subject, [Float])] = []
        for subject in subjects {
            if let vectorJson = subject.featureVector,
               let vector = decodeFeatureVector(vectorJson) {
                subjectsWithVectors.append((subject, vector))
            } else {
                print("[CLUSTER] 警告: 主体 \(subject.id) 没有特征向量")
            }
        }
        
        print("[CLUSTER] 有特征向量的主体数: \(subjectsWithVectors.count)")
        
        // 执行聚类
        var clusters: [[Int]] = []
        var assigned = Set<Int>()
        
        for i in 0..<subjectsWithVectors.count {
            if assigned.contains(i) { continue }
            
            var cluster = [i]
            assigned.insert(i)
            
            let (_, vector1) = subjectsWithVectors[i]
            
            for j in (i+1)..<subjectsWithVectors.count {
                if assigned.contains(j) { continue }
                
                let (_, vector2) = subjectsWithVectors[j]
                let similarity = cosineSimilarity(vector1, vector2)
                
                if similarity >= similarityThreshold {
                    cluster.append(j)
                    assigned.insert(j)
                }
            }
            
            clusters.append(cluster)
        }
        
        print("[CLUSTER] 生成 \(clusters.count) 个聚类")
        
        // 为每个聚类创建 Entity
        guard let targetSpec = subjects.first?.targetSpec else {
            print("[CLUSTER] 错误: 没有 targetSpec")
            return
        }
        
        for (clusterIndex, cluster) in clusters.enumerated() {
            print("[CLUSTER] 创建实体 #\(clusterIndex + 1), 包含 \(cluster.count) 个主体")
            
            let entity = Entity(targetSpec: targetSpec)
            modelContext.insert(entity)
            
            var confidenceSum: Double = 0.0
            
            for index in cluster {
                let (subject, _) = subjectsWithVectors[index]
                subject.entity = entity
                confidenceSum += subject.confidence
            }
            
            entity.averageConfidence = confidenceSum / Double(cluster.count)
            
            // 设置封面为第一个主体
            if let firstSubject = cluster.first {
                entity.coverSubjectId = subjectsWithVectors[firstSubject].0.id
            }
        }
        
        print("[CLUSTER] 保存 \(clusters.count) 个实体")
        try modelContext.save()
        print("[CLUSTER] 聚类完成")
    }
    
    /// 计算余弦相似度
    private func cosineSimilarity(_ vector1: [Float], _ vector2: [Float]) -> Float {
        guard vector1.count == vector2.count else { return 0 }
        
        var dotProduct: Float = 0
        var magnitude1: Float = 0
        var magnitude2: Float = 0
        
        for i in 0..<vector1.count {
            dotProduct += vector1[i] * vector2[i]
            magnitude1 += vector1[i] * vector1[i]
            magnitude2 += vector2[i] * vector2[i]
        }
        
        let magnitude = sqrt(magnitude1) * sqrt(magnitude2)
        guard magnitude > 0 else { return 0 }
        
        return dotProduct / magnitude
    }
    
    /// 使用 Vision 计算相似度 (备用方案)
    func calculateSimilarity(between subject1: Subject, and subject2: Subject) async throws -> Float {
        guard let vector1Json = subject1.featureVector,
              let vector2Json = subject2.featureVector,
              let vector1 = decodeFeatureVector(vector1Json),
              let vector2 = decodeFeatureVector(vector2Json) else {
            return 0
        }
        
        return cosineSimilarity(vector1, vector2)
    }
    
    /// 合并多个实体
    func mergeEntities(_ entities: [Entity]) throws {
        guard entities.count > 1,
              let targetEntity = entities.first else { return }
        
        // 将其他实体的所有主体转移到目标实体
        for entity in entities.dropFirst() {
            if let subjects = entity.subjects {
                for subject in subjects {
                    subject.entity = targetEntity
                }
            }
            modelContext.delete(entity)
        }
        
        targetEntity.updateAverageConfidence()
        targetEntity.updatedAt = Date()
        targetEntity.isManuallyCreated = true
        
        try modelContext.save()
    }
    
    /// 拆分实体 (将指定主体移出到新实体)
    func splitEntity(_ entity: Entity, extractingSubjects: [Subject]) throws {
        guard let targetSpec = entity.targetSpec else { return }
        
        let newEntity = Entity(targetSpec: targetSpec, isManuallyCreated: true)
        modelContext.insert(newEntity)
        
        for subject in extractingSubjects {
            subject.entity = newEntity
        }
        
        entity.updateAverageConfidence()
        newEntity.updateAverageConfidence()
        
        if let firstSubject = extractingSubjects.first {
            newEntity.coverSubjectId = firstSubject.id
        }
        
        entity.updatedAt = Date()
        newEntity.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// 解码特征向量
    private func decodeFeatureVector(_ json: String) -> [Float]? {
        guard let data = json.data(using: .utf8),
              let vector = try? JSONDecoder().decode([Float].self, from: data) else {
            return nil
        }
        return vector
    }
}
