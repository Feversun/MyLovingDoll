//
//  CanvasEditorView.swift
//  MyLovingDoll
//
//  画布编辑器 - 核心编辑功能
//

import SwiftUI
import SwiftData

struct CanvasEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var assetLibrary = AssetLibrary.shared
    
    let canvas: Canvas
    
    @State private var selectedElement: CanvasElement?
    @State private var showingAssetPicker = false
    @State private var showingShareSheet = false
    @State private var showingLayerManager = false
    @State private var renderedImage: UIImage?
    
    // 长按层级调整状态
    @State private var isLayerAdjustmentMode = false
    @State private var layerAdjustingElement: CanvasElement?
    @State private var dragOffsetY: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 画布背景
            Color.white
                .ignoresSafeArea()
            
            // 画布内容
            CanvasContent(
                canvas: canvas,
                selectedElement: $selectedElement,
                isLayerAdjustmentMode: $isLayerAdjustmentMode,
                layerAdjustingElement: $layerAdjustingElement,
                dragOffsetY: $dragOffsetY
            )
        }
        .navigationTitle(canvas.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // 添加元素按钮
                Button {
                    showingAssetPicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                
                // 分享按钮
                Button {
                    renderCanvas()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            
            // 底部工具栏
            ToolbarItemGroup(placement: .bottomBar) {
                if let selected = selectedElement {
                    // 层级管理
                    Button {
                        showingLayerManager = true
                    } label: {
                        Label("层级", systemImage: "square.3.layers.3d")
                    }
                    
                    Spacer()
                    
                    // 删除
                    Button(role: .destructive) {
                        canvas.removeElement(selected)
                        selectedElement = nil
                        try? modelContext.save()
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } else {
                    Text("点击选择元素进行编辑")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingAssetPicker) {
            AssetPickerView(
                onSelect: { asset in
                    addElement(asset)
                    showingAssetPicker = false
                },
                onSelectDoll: { dollAsset in
                    addDollElement(dollAsset)
                    showingAssetPicker = false
                }
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = renderedImage {
                ShareSheet(items: [image])
            }
        }
        .sheet(isPresented: $showingLayerManager) {
            LayerManagerSheet(canvas: canvas)
        }
    }
    
    private func addElement(_ asset: Asset) {
        let screenCenter = CGPoint(x: UIScreen.main.bounds.width / 2,
                                  y: UIScreen.main.bounds.height / 2)
        let element = CanvasElement(
            type: asset.category,
            assetName: asset.name,
            position: screenCenter
        )
        canvas.addElement(element)
        try? modelContext.save()
    }
    
    private func addDollElement(_ dollAsset: DollAsset) {
        let screenCenter = CGPoint(x: UIScreen.main.bounds.width / 2,
                                  y: UIScreen.main.bounds.height / 2)
        let element = CanvasElement(
            dollAsset: dollAsset,
            position: screenCenter
        )
        canvas.addElement(element)
        try? modelContext.save()
    }
    
    private func renderCanvas() {
        // TODO: 实现画布渲染为图片
        // 这里先创建一个占位图
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 1000))
        renderedImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 800, height: 1000)))
        }
        showingShareSheet = true
    }
    
    // MARK: - 层级控制方法
    private func bringToFront(_ element: CanvasElement) {
        guard let elements = canvas.elements else { return }
        let maxZIndex = elements.map { $0.zIndex }.max() ?? 0
        element.zIndex = maxZIndex + 1
        try? modelContext.save()
    }
    
    private func sendToBack(_ element: CanvasElement) {
        element.zIndex = 0
        // 其他元素层级 +1
        if let elements = canvas.elements {
            for el in elements where el.id != element.id {
                el.zIndex += 1
            }
        }
        try? modelContext.save()
    }
}

// MARK: - 画布内容视图
struct CanvasContent: View {
    @Bindable var canvas: Canvas
    @Binding var selectedElement: CanvasElement?
    @Binding var isLayerAdjustmentMode: Bool
    @Binding var layerAdjustingElement: CanvasElement?
    @Binding var dragOffsetY: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 所有元素
                ForEach(canvas.elements ?? []) { element in
                    CanvasElementView(
                        element: element,
                        isSelected: selectedElement?.id == element.id,
                        canvas: canvas,
                        isLayerAdjustmentMode: $isLayerAdjustmentMode,
                        layerAdjustingElement: $layerAdjustingElement,
                        dragOffsetY: $dragOffsetY
                    )
                    .zIndex(element.zIndex)
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                // 只有在非层级调整模式下才响应点击
                                if !isLayerAdjustmentMode {
                                    selectedElement = element
                                }
                            }
                    )
                }
                
                // 浮动层级指示器
                if isLayerAdjustmentMode {
                    FloatingLayerIndicator(
                        canvas: canvas,
                        activeElement: layerAdjustingElement,
                        dragOffsetY: dragOffsetY
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// MARK: - 画布元素视图
struct CanvasElementView: View {
    @Bindable var element: CanvasElement
    @StateObject private var assetLibrary = AssetLibrary.shared
    
    let isSelected: Bool
    let canvas: Canvas
    @Binding var isLayerAdjustmentMode: Bool
    @Binding var layerAdjustingElement: CanvasElement?
    @Binding var dragOffsetY: CGFloat
    
    @State private var currentPosition: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    @State private var longPressActivated = false // 跟踪长按是否已激活
    @State private var initialZIndex: Double = 0 // 记录初始层级
    @State private var accumulatedOffset: CGFloat = 0 // 累计偏移量
    @State private var lastTargetIndex: Int = 0 // 记录上一次的目标索引
    
    var body: some View {
        Group {
            if element.elementType == .doll, 
               let stickerPath = element.dollStickerPath,
               let specId = element.dollSpecId,
               let uiImage = FileManager.loadImage(relativePath: stickerPath, specId: specId) {
                // 娃娃：从对象库加载
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else if let asset = findAsset() {
                // PDF 素材
                assetLibrary.getAssetImage(for: asset)
                    .resizable()
                    .scaledToFit()
            } else {
                // Fallback
                Image(systemName: element.elementType.icon)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 100 * element.scale * currentScale)
        .rotationEffect(Angle(degrees: element.rotation) + currentRotation)
        .overlay {
            if isSelected && !isLayerAdjustmentMode {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
            }
        }
        .position(element.position)
        .offset(currentPosition)
        .highPriorityGesture(longPressGesture) // 长按手势优先级最高
        .simultaneousGesture(isLayerAdjustmentMode ? nil : dragGesture)
        .simultaneousGesture(isLayerAdjustmentMode ? nil : magnificationGesture)
        .simultaneousGesture(isLayerAdjustmentMode ? nil : rotationGesture)
    }
    
    private func findAsset() -> Asset? {
        for (_, assets) in assetLibrary.assets {
            if let asset = assets.first(where: { $0.name == element.assetName }) {
                return asset
            }
        }
        return nil
    }
    
    // MARK: - 拖拽手势
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                currentPosition = value.translation
            }
            .onEnded { value in
                element.positionX += Double(value.translation.width)
                element.positionY += Double(value.translation.height)
                currentPosition = .zero
            }
    }
    
    // MARK: - 缩放手势
    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentScale = value
            }
            .onEnded { value in
                element.scale *= Double(value)
                currentScale = 1.0
            }
    }
    
    // MARK: - 旋转手势
    var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                currentRotation = value
            }
            .onEnded { value in
                element.rotation += value.degrees
                currentRotation = .zero
            }
    }
    
    // MARK: - 长按手势（1秒）+ 上下滑动调整层级
    var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 1.0)
            .onEnded { _ in
                // 长按1秒激活 - 提供haptic反馈
                longPressActivated = true
                initialZIndex = element.zIndex // 记录初始层级
                accumulatedOffset = 0 // 重置累计偏移
                
                // 记录初始索引
                if let elements = canvas.elements {
                    let sortedElements = elements.sorted { $0.zIndex < $1.zIndex }
                    lastTargetIndex = sortedElements.firstIndex(where: { $0.id == element.id }) ?? 0
                }
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                isLayerAdjustmentMode = true
                layerAdjustingElement = element
            }
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .second(true, let drag):
                    // 只有在长按已激活的情况下才响应拖动
                    if longPressActivated, let drag = drag, isLayerAdjustmentMode {
                        dragOffsetY = drag.translation.height
                        adjustLayer(offset: drag.translation.height)
                    }
                    
                default:
                    break
                }
            }
            .onEnded { value in
                // 立即重置状态
                longPressActivated = false
                accumulatedOffset = 0
                
                // 只有当确实进入了层级调整模式才退出
                if isLayerAdjustmentMode && layerAdjustingElement?.id == element.id {
                    isLayerAdjustmentMode = false
                    layerAdjustingElement = nil
                    dragOffsetY = 0
                }
            }
    }
    
    private func adjustLayer(offset: CGFloat) {
        // 渐进式调整层级：每20px调整一层
        let sensitivity: CGFloat = 20
        
        guard let elements = canvas.elements else { return }
        let sortedElements = elements.sorted { $0.zIndex < $1.zIndex }
        
        guard let currentIndex = sortedElements.firstIndex(where: { $0.id == element.id }) else { return }
        
        // 计算目标层级（基于累计偏移）
        let totalLayerChange = Int(-offset / sensitivity)
        var targetIndex = sortedElements.firstIndex(where: { $0.zIndex == initialZIndex }) ?? currentIndex
        targetIndex += totalLayerChange
        
        // 限制在合法范围内
        targetIndex = max(0, min(sortedElements.count - 1, targetIndex))
        
        // 只有当目标位置变化时才调整
        if targetIndex != currentIndex {
            // 检测是否真的移动了层级
            if targetIndex != lastTargetIndex {
                // 提供haptic反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                lastTargetIndex = targetIndex
            }
            
            // 重新分配所有元素的zIndex
            var newZIndexMap: [UUID: Double] = [:]
            
            // 移除当前元素
            var reorderedElements = sortedElements.filter { $0.id != element.id }
            // 插入到新位置
            reorderedElements.insert(element, at: targetIndex)
            
            // 重新分配zIndex
            for (index, el) in reorderedElements.enumerated() {
                newZIndexMap[el.id] = Double(index)
            }
            
            // 应用新的zIndex
            for el in elements {
                if let newZIndex = newZIndexMap[el.id] {
                    el.zIndex = newZIndex
                }
            }
        }
    }
}

// MARK: - 分享 Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 浮动层级指示器
struct FloatingLayerIndicator: View {
    let canvas: Canvas
    let activeElement: CanvasElement?
    let dragOffsetY: CGFloat
    
    var body: some View {
        HStack {
            VStack(spacing: 20) {
                ForEach(sortedElements, id: \.id) { element in
                    if element.id == activeElement?.id {
                        // 当前激活元素：横线
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 3)
                            .cornerRadius(1.5)
                    } else {
                        // 其他元素：圆点
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
            )
            .padding(.leading, 16)
            
            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var sortedElements: [CanvasElement] {
        (canvas.elements ?? []).sorted { $0.zIndex > $1.zIndex }
    }
}

#Preview {
    NavigationStack {
        CanvasEditorView(canvas: Canvas(name: "示例画布"))
    }
    .modelContainer(for: [Canvas.self, CanvasElement.self])
}
