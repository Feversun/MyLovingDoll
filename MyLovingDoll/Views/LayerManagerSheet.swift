//
//  LayerManagerSheet.swift
//  MyLovingDoll
//
//  层级管理器 - 可拖拽排序
//

import SwiftUI
import SwiftData

struct LayerManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var canvas: Canvas
    @State private var elements: [CanvasElement] = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(elements) { element in
                    LayerRow(element: element)
                }
                .onMove { from, to in
                    moveElements(from: from, to: to)
                }
            }
            .navigationTitle("图层管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        applyChanges()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Text("拖动调整层级顺序")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            loadElements()
        }
    }
    
    private func loadElements() {
        // 按 zIndex 从高到低排序（顶层在上）
        elements = (canvas.elements ?? []).sorted { $0.zIndex > $1.zIndex }
    }
    
    private func moveElements(from source: IndexSet, to destination: Int) {
        elements.move(fromOffsets: source, toOffset: destination)
    }
    
    private func applyChanges() {
        // 根据列表顺序重新分配 zIndex
        // 列表顶部 = 最高 zIndex
        for (index, element) in elements.enumerated() {
            element.zIndex = Double(elements.count - 1 - index)
        }
        try? modelContext.save()
    }
}

// MARK: - 图层行
struct LayerRow: View {
    let element: CanvasElement
    
    var body: some View {
        HStack(spacing: 12) {
            // 图层图标
            Image(systemName: element.elementType.icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(element.assetName)
                    .font(.body)
                
                Text(element.elementType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 拖动指示
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}
