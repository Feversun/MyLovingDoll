//
//  EntityLibraryView.swift
//  MyLovingDoll
//
//  实体库网格视图
//

import SwiftUI
import SwiftData
import Photos

struct EntityLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Entity.updatedAt, order: .reverse) private var entities: [Entity]
    @Query(sort: \Canvas.updatedAt, order: .reverse) private var canvases: [Canvas]
    
    @State private var selectedEntities: Set<UUID> = []
    @State private var isSelectionMode = false
    @State private var showingMergeConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingPhotoPicker = false
    @State private var showingProcessSheet = false
    @State private var selectedAssets: [PHAsset] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingCreateCanvasSheet = false
    @State private var newCanvasName = ""
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - 画布区域
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("我的画布")
                                    .font(.title2.bold())
                                Spacer()
                                NavigationLink {
                                    CanvasListView()
                                } label: {
                                    Text("全部")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    // 创建新画布按钮
                                    Button {
                                        showingCreateCanvasSheet = true
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.blue)
                                            
                                            Text("新建画布")
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                        }
                                        .frame(width: 140, height: 140)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                    
                                    // 现有画布列表
                                    ForEach(canvases.prefix(10)) { canvas in
                                        NavigationLink {
                                            CanvasEditorView(canvas: canvas)
                                        } label: {
                                            CanvasPreviewCard(canvas: canvas)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                        
                        // MARK: - 对象库区域
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("对象库")
                                    .font(.title2.bold())
                                Spacer()
                                Button(isSelectionMode ? "完成" : "选择") {
                                    withAnimation {
                                        isSelectionMode.toggle()
                                        if !isSelectionMode {
                                            selectedEntities.removeAll()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
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
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, isSelectionMode ? 100 : 80)
                }
            
            // FAB - 添加照片按钮
            if !isSelectionMode {
                Button {
                    checkPhotoLibraryPermission()
                } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(.pink.gradient))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.bottom, 20)
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
        .navigationTitle("MyLovingDoll")
        .navigationBarTitleDisplayMode(.large)
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
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView(selectedAssets: $selectedAssets)
                .onDisappear {
                    if !selectedAssets.isEmpty {
                        showingProcessSheet = true
                    }
                }
        }
        .sheet(isPresented: $showingProcessSheet) {
            ProcessingSheetView(selectedAssets: $selectedAssets, isPresented: $showingProcessSheet)
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingCreateCanvasSheet) {
            CreateCanvasSheet(
                canvasName: $newCanvasName,
                onCreate: {
                    createCanvas()
                    showingCreateCanvasSheet = false
                }
            )
        }
        }
    }
    
    // MARK: - Methods
    
    private func createCanvas() {
        let name = newCanvasName.isEmpty ? "画布 \(canvases.count + 1)" : newCanvasName
        let canvas = Canvas(name: name)
        modelContext.insert(canvas)
        try? modelContext.save()
        newCanvasName = ""
    }
    
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            showingPhotoPicker = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        showingPhotoPicker = true
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "请在系统设置中允许访问相册"
            showingError = true
        @unknown default:
            break
        }
    }
    
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

// MARK: - Canvas Preview Card
struct CanvasPreviewCard: View {
    let canvas: Canvas
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 缩略图
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray5))
                
                if let thumbnailPath = canvas.thumbnailPath {
                    // TODO: 加载缩略图
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "rectangle.on.rectangle.angled")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                        
                        Text("\(canvas.elements?.count ?? 0) 个元素")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 140, height: 100)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(canvas.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(canvas.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 140)
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
            if let image = coverImage {
                ZStack {
                    // 底层：白色描边
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .overlay {
                            Color.white
                        }
                        .mask(
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .padding(-6) // 扩展6pt作为描边
                        )
                    
                    // 阴影层
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // 顶层：主图像（不受影响）
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                }
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 150)
                    .overlay {
                        ProgressView()
                    }
            }
            
            // 名称
            Text(entity.customName ?? "未命名对象")
                .font(.subheadline.bold())
                .lineLimit(1)
            
            // 数量
            HStack(spacing: 4) {
                Image(systemName: "photo.stack")
                    .font(.caption2)
                Text("\(subjectCount) 张")
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
