//
//  MoveSubjectsView.swift
//  MyLovingDoll
//
//  移动主体到其他实体
//

import SwiftUI
import SwiftData

struct MoveSubjectsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntities: [Entity]
    
    let selectedSubjects: Set<UUID>
    let currentEntity: Entity
    let specId: String
    let onComplete: () -> Void
    
    var otherEntities: [Entity] {
        allEntities.filter { $0.id != currentEntity.id && $0.targetSpec?.specId == specId }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("选择目标对象")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section("现有对象") {
                    ForEach(otherEntities) { entity in
                        Button {
                            moveToEntity(entity)
                        } label: {
                            HStack {
                                // 封面缩略图
                                if let coverSubjectId = entity.coverSubjectId,
                                   let coverSubject = entity.subjects?.first(where: { $0.id == coverSubjectId }),
                                   let image = FileManager.loadImage(relativePath: coverSubject.stickerPath, specId: specId) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entity.customName ?? "未命名对象")
                                        .font(.headline)
                                    Text("\(entity.subjects?.count ?? 0) 张照片")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Button {
                        moveToNewEntity()
                    } label: {
                        Label("创建新对象", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("移动到")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func moveToEntity(_ targetEntity: Entity) {
        // 获取选中的主体
        guard let subjects = currentEntity.subjects else { return }
        let subjectsToMove = subjects.filter { selectedSubjects.contains($0.id) }
        
        // 移动主体
        for subject in subjectsToMove {
            subject.entity = targetEntity
        }
        
        // 更新实体统计
        currentEntity.updateAverageConfidence()
        targetEntity.updateAverageConfidence()
        currentEntity.updatedAt = Date()
        targetEntity.updatedAt = Date()
        
        // 如果当前实体已经没有主体，删除它
        if currentEntity.subjects?.isEmpty ?? true {
            modelContext.delete(currentEntity)
        }
        
        try? modelContext.save()
        
        onComplete()
        dismiss()
    }
    
    private func moveToNewEntity() {
        guard let targetSpec = currentEntity.targetSpec else { return }
        guard let subjects = currentEntity.subjects else { return }
        
        // 创建新实体
        let newEntity = Entity(targetSpec: targetSpec, isManuallyCreated: true)
        modelContext.insert(newEntity)
        
        // 移动主体
        let subjectsToMove = subjects.filter { selectedSubjects.contains($0.id) }
        for subject in subjectsToMove {
            subject.entity = newEntity
        }
        
        // 设置封面
        if let firstSubject = subjectsToMove.first {
            newEntity.coverSubjectId = firstSubject.id
        }
        
        // 更新统计
        newEntity.updateAverageConfidence()
        currentEntity.updateAverageConfidence()
        currentEntity.updatedAt = Date()
        
        // 如果当前实体已经没有主体，删除它
        if currentEntity.subjects?.isEmpty ?? true {
            modelContext.delete(currentEntity)
        }
        
        try? modelContext.save()
        
        onComplete()
        dismiss()
    }
}
