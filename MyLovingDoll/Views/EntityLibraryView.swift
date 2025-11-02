//
//  EntityLibraryView.swift
//  MyLovingDoll
//
//  实体库网格视图
//

import SwiftUI
import SwiftData

struct EntityLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Entity.updatedAt, order: .reverse) private var entities: [Entity]
    
    @State private var selectedEntities: Set<UUID> = []
    @State private var isSelectionMode = false
    @State private var showingMergeConfirmation = false
    @State private var showingDeleteConfirmation = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(entities) { entity in
                        Group {
                            if isSelectionMode {
                                EntityCardView(entity: entity)
                                    .overlay(alignment: .topLeading) {
                                        Image(systemName: selectedEntities.contains(entity.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.title2)
                                            .foregroundStyle(selectedEntities.contains(entity.id) ? .blue : .gray)
                                            .padding(8)
                                            .background(.regularMaterial)
                                            .clipShape(Circle())
                                            .padding(8)
                                    }
                                    .opacity(selectedEntities.contains(entity.id) ? 1.0 : 0.6)
                                    .scaleEffect(selectedEntities.contains(entity.id) ? 0.95 : 1.0)
                                    .animation(.spring(response: 0.3), value: selectedEntities.contains(entity.id))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            toggleSelection(entity.id)
                                        }
                                    }
                            } else {
                                NavigationLink {
                                    EntityDetailView(entity: entity)
                                } label: {
                                    EntityCardView(entity: entity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, isSelectionMode ? 100 : 0)
            }
            
            // 底部工具条
            if isSelectionMode {
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 20) {
                        // 合并按钮
                        Button {
                            showingMergeConfirmation = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.merge")
                                    .font(.title3)
                                Text("合并")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(selectedEntities.count >= 2 ? .blue : .gray)
                        }
                        .disabled(selectedEntities.count < 2)
                        
                        Divider()
                            .frame(height: 40)
                        
                        // 删除按钮
                        Button {
                            showingDeleteConfirmation = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.title3)
                                Text("删除")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(selectedEntities.isEmpty ? .gray : .red)
                        }
                        .disabled(selectedEntities.isEmpty)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .background(.regularMaterial)
                }
            }
        }
        .navigationTitle("对象库")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSelectionMode ? "完成" : "选择") {
                    withAnimation {
                        isSelectionMode.toggle()
                        if !isSelectionMode {
                            selectedEntities.removeAll()
                        }
                    }
                }
            }
        }
        .alert("确认合并", isPresented: $showingMergeConfirmation) {
            Button("取消", role: .cancel) {}
            Button("合并", role: .destructive) {
                mergeSelected()
            }
        } message: {
            Text("将 \(selectedEntities.count) 个对象合并为一个对象，其他对象将被删除")
        }
        .alert("确认删除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteSelected()
            }
        } message: {
            Text("确定要删除选中的 \(selectedEntities.count) 个对象吗？此操作不可恢复")
        }
    }
    
    // MARK: - Methods
    
    private func toggleSelection(_ entityId: UUID) {
        if selectedEntities.contains(entityId) {
            selectedEntities.remove(entityId)
        } else {
            selectedEntities.insert(entityId)
        }
    }
    
    private func mergeSelected() {
        let entitiesToMerge = entities.filter { selectedEntities.contains($0.id) }
        guard entitiesToMerge.count >= 2 else { return }
        
        let clusterService = EntityClusterService(modelContext: modelContext)
        try? clusterService.mergeEntities(entitiesToMerge)
        
        selectedEntities.removeAll()
        isSelectionMode = false
    }
    
    private func deleteSelected() {
        let entitiesToDelete = entities.filter { selectedEntities.contains($0.id) }
        
        for entity in entitiesToDelete {
            // 将所有主体标记为非目标
            if let subjects = entity.subjects {
                for subject in subjects {
                    subject.isMarkedAsNonTarget = true
                    subject.entity = nil
                }
            }
            
            // 删除相关的故事实例
            deleteRelatedStories(for: entity)
            
            modelContext.delete(entity)
        }
        
        try? modelContext.save()
        selectedEntities.removeAll()
        isSelectionMode = false
    }
    
    private func deleteRelatedStories(for entity: Entity) {
        let storyDescriptor = FetchDescriptor<StoryInstance>()
        if let allStories = try? modelContext.fetch(storyDescriptor) {
            let relatedStories = allStories.filter { $0.entity?.id == entity.id }
            for story in relatedStories {
                modelContext.delete(story)
            }
        }
    }
}

// MARK: - Entity Card
struct EntityCardView: View {
    @Bindable var entity: Entity
    @State private var coverImage: UIImage?
    
    var subjectCount: Int {
        entity.subjects?.count ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面图
            ZStack(alignment: .topTrailing) {
                if let image = coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 150)
                        .cornerRadius(12)
                        .overlay {
                            ProgressView()
                        }
                }
                
                // 数量徽标
                Text("\(subjectCount)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.pink.gradient)
                    .cornerRadius(8)
                    .padding(8)
            }
            
            // 名称
            Text(entity.customName ?? "未命名对象")
                .font(.subheadline.bold())
                .lineLimit(1)
            
            // 置信度
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                Text(String(format: "%.1f%%", entity.averageConfidence * 100))
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .task {
            await loadCoverImage()
        }
    }
    
    private func loadCoverImage() async {
        guard let coverSubjectId = entity.coverSubjectId,
              let subject = entity.subjects?.first(where: { $0.id == coverSubjectId }),
              let specId = entity.targetSpec?.specId else {
            // 使用第一个主体作为封面
            if let firstSubject = entity.subjects?.first,
               let specId = entity.targetSpec?.specId {
                coverImage = FileManager.loadImage(
                    relativePath: firstSubject.stickerPath,
                    specId: specId
                )
            }
            return
        }
        
        coverImage = FileManager.loadImage(
            relativePath: subject.stickerPath,
            specId: specId
        )
    }
}
