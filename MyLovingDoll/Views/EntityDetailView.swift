//
//  EntityDetailView.swift
//  MyLovingDoll
//
//  实体详情视图
//

import SwiftUI
import SwiftData

struct EntityDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var entity: Entity
    
    @State private var showingRenameDialog = false
    @State private var newName = ""
    @State private var currentIndex = 0
    @State private var showingAdjustmentView = false
    @State private var showingAllPhotosSheet = false
    @State private var showingMoveSheet = false
    @State private var showingDeleteAlert = false
    
    var subjects: [Subject] {
        entity.subjects ?? []
    }
    
    var currentSubject: Subject? {
        subjects.indices.contains(currentIndex) ? subjects[currentIndex] : nil
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 大图显示
            if !subjects.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(subjects.indices, id: \.self) { index in
                        if let specId = entity.targetSpec?.specId {
                            SubjectLargeImageView(
                                subject: subjects[index],
                                specId: specId
                            )
                            .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("暂无照片")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // 底部工具栏
            if !subjects.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 0) {
                        // 调整主体
                        ToolbarButton(
                            icon: "crop.rotate",
                            title: "调整"
                        ) {
                            showingAdjustmentView = true
                        }
                        
                        Divider().frame(height: 40)
                        
                        // 查看所有
                        ToolbarButton(
                            icon: "square.grid.2x2",
                            title: "所有"
                        ) {
                            showingAllPhotosSheet = true
                        }
                        
                        Divider().frame(height: 40)
                        
                        // 移动
                        ToolbarButton(
                            icon: "arrow.right.circle",
                            title: "移动"
                        ) {
                            showingMoveSheet = true
                        }
                        
                        Divider().frame(height: 40)
                        
                        // 删除
                        ToolbarButton(
                            icon: "trash",
                            title: "删除",
                            color: .red
                        ) {
                            showingDeleteAlert = true
                        }
                    }
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                }
            }
        }
        .navigationTitle(entity.customName ?? "未命名对象")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newName = entity.customName ?? ""
                    showingRenameDialog = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(.pink.gradient)
                }
            }
        }
        .alert("重命名", isPresented: $showingRenameDialog) {
            TextField("名称", text: $newName)
            Button("取消", role: .cancel) {}
            Button("确定") {
                rename()
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteCurrentSubject()
            }
        } message: {
            Text("确定要删除这张照片吗?")
        }
        .sheet(isPresented: $showingAllPhotosSheet) {
            AllPhotosGridView(entity: entity, currentIndex: $currentIndex)
        }
        .sheet(isPresented: $showingMoveSheet) {
            if let specId = entity.targetSpec?.specId, let subject = currentSubject {
                MoveSubjectsView(
                    selectedSubjects: [subject.id],
                    currentEntity: entity,
                    specId: specId,
                    onComplete: {
                        if entity.subjects?.isEmpty ?? true {
                            dismiss()
                        }
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showingAdjustmentView) {
            if #available(iOS 17.0, *), let specId = entity.targetSpec?.specId, let subject = currentSubject {
                SubjectAdjustmentView(subject: subject, specId: specId)
            }
        }
    }
    
    // MARK: - Methods
    
    private func rename() {
        entity.customName = newName.isEmpty ? nil : newName
        entity.updatedAt = Date()
        try? modelContext.save()
    }
    
    private func deleteCurrentSubject() {
        guard let subject = currentSubject else { return }
        
        // 删除文件
        if let specId = entity.targetSpec?.specId {
            let stickerURL = FileManager.specDirectory(for: specId).appendingPathComponent(subject.stickerPath)
            try? FileManager.default.removeItem(at: stickerURL)
            
            if let thumbnailPath = subject.thumbnailPath {
                let thumbnailURL = FileManager.specDirectory(for: specId).appendingPathComponent(thumbnailPath)
                try? FileManager.default.removeItem(at: thumbnailURL)
            }
        }
        
        // 从实体中移除
        subject.entity = nil
        modelContext.delete(subject)
        
        // 如果删除后实体为空,删除实体并返回
        if entity.subjects?.isEmpty ?? true {
            modelContext.delete(entity)
            try? modelContext.save()
            dismiss()
        } else {
            // 调整当前索引
            if currentIndex >= subjects.count - 1 {
                currentIndex = max(0, subjects.count - 2)
            }
            entity.updateAverageConfidence()
            try? modelContext.save()
        }
    }
}

// MARK: - Toolbar Button
struct ToolbarButton: View {
    let icon: String
    let title: String
    var color: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Subject Large Image View
struct SubjectLargeImageView: View {
    let subject: Subject
    let specId: String
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .task {
            image = FileManager.loadImage(relativePath: subject.stickerPath, specId: specId)
        }
    }
}

// MARK: - All Photos Grid View
struct AllPhotosGridView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var entity: Entity
    @Binding var currentIndex: Int
    
    var subjects: [Subject] {
        entity.subjects ?? []
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(subjects.indices, id: \.self) { index in
                        if let specId = entity.targetSpec?.specId {
                            SubjectThumbnailView(subject: subjects[index], specId: specId)
                                .overlay {
                                    if index == currentIndex {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue, lineWidth: 3)
                                    }
                                }
                                .onTapGesture {
                                    currentIndex = index
                                    dismiss()
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("所有照片 (\(subjects.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Subject Thumbnail
struct SubjectThumbnailView: View {
    let subject: Subject
    let specId: String
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .task {
            image = FileManager.loadImage(relativePath: subject.stickerPath, specId: specId)
        }
    }
}
