//
//  CanvasListView.swift
//  MyLovingDoll
//
//  画布列表视图
//

import SwiftUI
import SwiftData

struct CanvasListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Canvas.updatedAt, order: .reverse) private var canvases: [Canvas]
    
    @State private var showingCreateSheet = false
    @State private var newCanvasName = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    // 创建新画布按钮
                    Button {
                        showingCreateSheet = true
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            
                            Text("新建画布")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // 现有画布列表
                    ForEach(canvases) { canvas in
                        NavigationLink {
                            CanvasEditorView(canvas: canvas)
                        } label: {
                            CanvasCard(canvas: canvas)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteCanvas(canvas)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("我的画布")
            .sheet(isPresented: $showingCreateSheet) {
                CreateCanvasSheet(
                    canvasName: $newCanvasName,
                    onCreate: {
                        createCanvas()
                        showingCreateSheet = false
                    }
                )
            }
        }
    }
    
    private func createCanvas() {
        let name = newCanvasName.isEmpty ? "画布 \(canvases.count + 1)" : newCanvasName
        let canvas = Canvas(name: name)
        modelContext.insert(canvas)
        try? modelContext.save()
        newCanvasName = ""
    }
    
    private func deleteCanvas(_ canvas: Canvas) {
        modelContext.delete(canvas)
        try? modelContext.save()
    }
}

// MARK: - 画布卡片
struct CanvasCard: View {
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
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("\(canvas.elements?.count ?? 0) 个元素")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 160)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(canvas.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(canvas.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 创建画布 Sheet
struct CreateCanvasSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var canvasName: String
    let onCreate: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("画布名称", text: $canvasName)
                } header: {
                    Text("输入画布名称")
                } footer: {
                    Text("留空将自动命名")
                }
            }
            .navigationTitle("新建画布")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        onCreate()
                    }
                }
            }
        }
    }
}

#Preview {
    CanvasListView()
        .modelContainer(for: [Canvas.self, CanvasElement.self])
}
