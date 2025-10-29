//
//  SubjectAdjustmentView.swift
//  MyLovingDoll
//
//  VisionKit 交互式主体调整界面
//

import SwiftUI
import VisionKit
import Photos
import Vision

@available(iOS 17.0, *)
struct SubjectAdjustmentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let subject: Subject
    let specId: String
    @State private var sourceImage: UIImage?
    @State private var editedImage: UIImage? // 编辑后的图片
    @State private var croppedImage: UIImage? // 裁剪后的图片
    @State private var extractedSubject: UIImage? // 识别出的主体
    @State private var backgroundImage: UIImage? // 背景部分（用于消散）
    @State private var isAnalyzing = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var triggerDisintegration = false // 触发灭霸动画
    @State private var showSubject = false // 显示主体
    
    // 编辑状态
    @State private var rotationAngle: Double = 0
    @State private var cropRect: CGRect = CGRect(x: 50, y: 100, width: 300, height: 300) // 裁剪框
    @State private var containerSize: CGSize = .zero // 容器尺寸
    
    var currentDisplayImage: UIImage? {
        editedImage ?? sourceImage
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if extractedSubject == nil {
                    // 步骤 1: 显示图片 + 裁剪框 + 工具栏 + 识别按钮
                    VStack(spacing: 0) {
                        // 图片显示区域 + 可拖拽裁剪框
                        GeometryReader { geometry in
                            ZStack {
                                if let image = currentDisplayImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                } else {
                                    ProgressView("加载图片...")
                                }
                                
                                // 裁剪框蒙版
                                if sourceImage != nil {
                                    CropOverlay(
                                        cropRect: $cropRect,
                                        containerSize: geometry.size,
                                        imageSize: currentDisplayImage?.size ?? .zero
                                    )
                                }
                            }
                            .onAppear {
                                containerSize = geometry.size
                            }
                            .onChange(of: geometry.size) { oldValue, newValue in
                                containerSize = newValue
                            }
                        }
                        .frame(maxHeight: .infinity)
                        
                        // 编辑工具栏
                        if sourceImage != nil && !isAnalyzing {
                            ImageEditToolbar(
                                rotationAngle: $rotationAngle,
                                onRotate: { angle in
                                    applyRotation(angle)
                                },
                                onReset: {
                                    resetEditing()
                                }
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(.regularMaterial)
                        }
                        
                        // 识别按钮
                        if sourceImage != nil && !isAnalyzing {
                            Button {
                                Task {
                                    await reanalyzeImage()
                                }
                            } label: {
                                Label("重新识别主体", systemImage: "sparkles")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.blue.gradient)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        
                        if isAnalyzing {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("识别中...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 20)
                        }
                    }
                } else {
                    // 步骤 2: 显示裁剪图片 + 灭霸动画 + 主体 + Shimmer + 操作按钮
                    ZStack(alignment: .bottom) {
                        // 主体显示区域
                        ZStack {
                            // 底层: 完整裁剪图（消散动画）
                            if let cropped = croppedImage {
                                Image(uiImage: cropped)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .disintegrationEffect(isDeleted: triggerDisintegration) {
                                        // 动画完成后放大主体
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                            showSubject = true
                                        }
                                    }
                            }
                            
                            // 顶层: 主体（始终覆盖在上面，消散后加 Shimmer）
                            if let subject = extractedSubject {
                                Image(uiImage: subject)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .modifier(ConditionalShimmer(
                                        enabled: showSubject,
                                        config: ShimmerConfig(
                                            tint: .white.opacity(0.5),
                                            highlight: .white,
                                            blur: 5,
                                            highlightOpacity: 1,
                                            speed: 2,
                                            blendMode: .normal
                                        )
                                    ))
                                    .allowsHitTesting(false)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        
                        // 操作按钮 - 浮动在底部
                        if showSubject {
                            VStack(spacing: 12) {
                                // 确认保存
                                Button {
                                    if let subject = extractedSubject {
                                        Task {
                                            await saveAdjustedSubject(subject)
                                        }
                                    }
                                } label: {
                                    Label("确认保存", systemImage: "checkmark.circle.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(.green.gradient)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                
                                // 重新调整
                                Button {
                                    resetToEditMode()
                                } label: {
                                    Label("重新调整", systemImage: "arrow.counterclockwise")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(.gray.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("保存中...")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }
            }
            .navigationTitle("调整主体")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .task {
                await loadSourceImage()
            }
        }
    }
    
    private func loadSourceImage() async {
        // 从 PHAsset 加载原始照片
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [subject.sourceAssetId], options: nil).firstObject
        
        guard let asset = asset else {
            errorMessage = "无法找到原始照片"
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            self.sourceImage = image
        }
    }
    
    // MARK: - 图片编辑方法
    
    private func applyRotation(_ angle: Double) {
        guard let image = currentDisplayImage else { return }
        rotationAngle += angle
        editedImage = image.rotate(radians: angle)
    }
    
    private func resetEditing() {
        editedImage = nil
        rotationAngle = 0
        cropRect = CGRect(x: 50, y: 100, width: 300, height: 300)
    }
    
    /// 将屏幕坐标系的裁剪框转换为图片坐标系
    private func convertCropRectToImageCoordinates(
        cropRect: CGRect,
        imageSize: CGSize,
        containerSize: CGSize
    ) -> CGRect? {
        guard containerSize.width > 0 && containerSize.height > 0 else { return nil }
        
        // 计算图片在容器中的实际显示尺寸 (scaledToFit)
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        
        var displayedImageSize: CGSize
        var imageOffset: CGPoint
        
        if imageAspect > containerAspect {
            // 图片比容器更宽，以宽度为准
            displayedImageSize = CGSize(
                width: containerSize.width,
                height: containerSize.width / imageAspect
            )
            imageOffset = CGPoint(
                x: 0,
                y: (containerSize.height - displayedImageSize.height) / 2
            )
        } else {
            // 图片比容器更高，以高度为准
            displayedImageSize = CGSize(
                width: containerSize.height * imageAspect,
                height: containerSize.height
            )
            imageOffset = CGPoint(
                x: (containerSize.width - displayedImageSize.width) / 2,
                y: 0
            )
        }
        
        // 计算缩放比例
        let scaleX = imageSize.width / displayedImageSize.width
        let scaleY = imageSize.height / displayedImageSize.height
        
        // 转换裁剪框坐标
        let imageCropRect = CGRect(
            x: (cropRect.origin.x - imageOffset.x) * scaleX,
            y: (cropRect.origin.y - imageOffset.y) * scaleY,
            width: cropRect.width * scaleX,
            height: cropRect.height * scaleY
        )
        
        // 限制在图片范围内
        let clampedRect = CGRect(
            x: max(0, imageCropRect.origin.x),
            y: max(0, imageCropRect.origin.y),
            width: min(imageCropRect.width, imageSize.width - max(0, imageCropRect.origin.x)),
            height: min(imageCropRect.height, imageSize.height - max(0, imageCropRect.origin.y))
        )
        
        return clampedRect
    }
    
    private func reanalyzeImage() async {
        // 先应用裁剪，再识别
        guard var image = currentDisplayImage else { return }
        
        print("[DEBUG] 原始图片尺寸: \(image.size)")
        print("[DEBUG] 容器尺寸: \(containerSize)")
        print("[DEBUG] 裁剪框坐标(屏幕): \(cropRect)")
        
        // 转换裁剪坐标
        if let imageCropRect = convertCropRectToImageCoordinates(
            cropRect: cropRect,
            imageSize: image.size,
            containerSize: containerSize
        ) {
            print("[DEBUG] 裁剪框坐标(图片): \(imageCropRect)")
            
            if let cropped = image.crop(to: imageCropRect) {
                image = cropped
                // 保存裁剪后的图片用于动画
                croppedImage = cropped
                print("[DEBUG] 裁剪后图片尺寸: \(cropped.size)")
            } else {
                print("[ERROR] 裁剪失败")
            }
        } else {
            print("[ERROR] 坐标转换失败")
        }
        
        await MainActor.run {
            isAnalyzing = true
        }
        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        do {
            // 使用 Vision 重新提取主体
            let subjects = try await extractSubjectsUsingVision(from: image)
            
            await MainActor.run {
                if subjects.isEmpty {
                    errorMessage = "未识别到主体,请尝试其他照片"
                } else {
                    // 取第一个主体
                    extractedSubject = subjects[0].0
                    
                    // 创建背景图像（裁剪图 - 主体 = 背景）
                    if let cropped = croppedImage {
                        backgroundImage = cropped
                    }
                    
                    // 稍微延迟后触发灭霸动画
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        triggerDisintegration = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "识别失败: \(error.localizedDescription)"
            }
        }
    }
    
    /// 重置到编辑模式
    private func resetToEditMode() {
        withAnimation {
            extractedSubject = nil
            croppedImage = nil
            backgroundImage = nil
            triggerDisintegration = false
            showSubject = false
        }
    }
    
    private func extractSubjectsUsingVision(from image: UIImage) async throws -> [(UIImage, Double)] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "SubjectAdjustment", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNInstanceMaskObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var subjects: [(UIImage, Double)] = []
                
                for observation in results {
                    do {
                        let maskedPixelBuffer = try observation.generateMaskedImage(
                            ofInstances: observation.allInstances,
                            from: handler,
                            croppedToInstancesExtent: true
                        )
                        
                        let ciImage = CIImage(cvPixelBuffer: maskedPixelBuffer)
                        let context = CIContext()
                        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                            let uiImage = UIImage(cgImage: cgImage)
                            subjects.append((uiImage, Double(observation.confidence)))
                        }
                    } catch {
                        print("警告: 生成主体图像失败")
                    }
                }
                
                continuation.resume(returning: subjects)
            }
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func saveAdjustedSubject(_ extractedImage: UIImage) async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            let service = VisionKitService(modelContext: modelContext)
            try await service.updateSubject(subject, with: extractedImage, specId: specId)
            
            // 保存成功,关闭页面
            await MainActor.run {
                dismiss()
            }
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - Image Edit Toolbar
@available(iOS 17.0, *)
struct ImageEditToolbar: View {
    @Binding var rotationAngle: Double
    let onRotate: (Double) -> Void
    let onReset: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // 旋转
            Button {
                onRotate(.pi / 2) // 90度
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "rotate.right")
                        .font(.title3)
                    Text("旋转")
                        .font(.caption2)
                }
            }
            
            Spacer()
            
            Text("拖拽裁剪框调整范围")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // 重置
            Button {
                onReset()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                    Text("重置")
                        .font(.caption2)
                }
            }
            .foregroundColor(.orange)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Crop Overlay
struct CropOverlay: View {
    @Binding var cropRect: CGRect
    let containerSize: CGSize
    let imageSize: CGSize
    
    @GestureState private var dragOffset: CGSize = .zero
    @State private var baseRect: CGRect = .zero
    
    enum HandlePosition {
        case topLeft, topRight, bottomLeft, bottomRight
        case top, bottom, left, right
        case center
    }
    
    private let handleSize: CGFloat = 44
    private let minSize: CGFloat = 80
    
    var body: some View {
        ZStack {
            // 蒙版背景 (阴影区域)
            Color.black.opacity(0.5)
                .mask {
                    Rectangle()
                        .overlay {
                            Rectangle()
                                .frame(width: cropRect.width, height: cropRect.height)
                                .position(x: cropRect.midX, y: cropRect.midY)
                                .blendMode(.destinationOut)
                        }
                }
                .allowsHitTesting(false)
            
            // 裁剪框
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
            
            // 网格线
            Path { path in
                // 水平线
                let y1 = cropRect.minY + cropRect.height / 3
                let y2 = cropRect.minY + cropRect.height * 2 / 3
                path.move(to: CGPoint(x: cropRect.minX, y: y1))
                path.addLine(to: CGPoint(x: cropRect.maxX, y: y1))
                path.move(to: CGPoint(x: cropRect.minX, y: y2))
                path.addLine(to: CGPoint(x: cropRect.maxX, y: y2))
                
                // 垂直线
                let x1 = cropRect.minX + cropRect.width / 3
                let x2 = cropRect.minX + cropRect.width * 2 / 3
                path.move(to: CGPoint(x: x1, y: cropRect.minY))
                path.addLine(to: CGPoint(x: x1, y: cropRect.maxY))
                path.move(to: CGPoint(x: x2, y: cropRect.minY))
                path.addLine(to: CGPoint(x: x2, y: cropRect.maxY))
            }
            .stroke(Color.white.opacity(0.5), lineWidth: 1)
            
            // 拖拽把手
            handleView(at: .topLeft)
            handleView(at: .topRight)
            handleView(at: .bottomLeft)
            handleView(at: .bottomRight)
            handleView(at: .top)
            handleView(at: .bottom)
            handleView(at: .left)
            handleView(at: .right)
            
            // 中心移动区域
            Rectangle()
                .fill(Color.clear)
                .frame(width: max(cropRect.width - 80, 50), height: max(cropRect.height - 80, 50))
                .position(x: cropRect.midX, y: cropRect.midY)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newX = baseRect.origin.x + value.translation.width
                            let newY = baseRect.origin.y + value.translation.height
                            
                            var newRect = cropRect
                            newRect.origin.x = max(0, min(newX, containerSize.width - cropRect.width))
                            newRect.origin.y = max(0, min(newY, containerSize.height - cropRect.height))
                            cropRect = newRect
                        }
                        .onEnded { _ in
                            baseRect = cropRect
                        }
                )
                .onAppear {
                    baseRect = cropRect
                }
        }
    }
    
    @ViewBuilder
    private func handleView(at position: HandlePosition) -> some View {
        let point = handlePoint(for: position)
        let isCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight].contains(position)
        
        Circle()
            .fill(Color.white)
            .shadow(color: .black.opacity(0.3), radius: 2)
            .frame(width: isCorner ? 24 : 16, height: isCorner ? 24 : 16)
            .position(point)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        resizeCropRect(from: position, translation: value.translation)
                    }
                    .onEnded { _ in
                        baseRect = cropRect
                    }
            )
    }
    
    private func handlePoint(for position: HandlePosition) -> CGPoint {
        switch position {
        case .topLeft:
            return CGPoint(x: cropRect.minX, y: cropRect.minY)
        case .topRight:
            return CGPoint(x: cropRect.maxX, y: cropRect.minY)
        case .bottomLeft:
            return CGPoint(x: cropRect.minX, y: cropRect.maxY)
        case .bottomRight:
            return CGPoint(x: cropRect.maxX, y: cropRect.maxY)
        case .top:
            return CGPoint(x: cropRect.midX, y: cropRect.minY)
        case .bottom:
            return CGPoint(x: cropRect.midX, y: cropRect.maxY)
        case .left:
            return CGPoint(x: cropRect.minX, y: cropRect.midY)
        case .right:
            return CGPoint(x: cropRect.maxX, y: cropRect.midY)
        case .center:
            return CGPoint(x: cropRect.midX, y: cropRect.midY)
        }
    }
    
    private func resizeCropRect(from position: HandlePosition, translation: CGSize) {
        var newRect = baseRect
        
        switch position {
        case .topLeft:
            newRect.origin.x = baseRect.origin.x + translation.width
            newRect.origin.y = baseRect.origin.y + translation.height
            newRect.size.width = baseRect.width - translation.width
            newRect.size.height = baseRect.height - translation.height
        case .topRight:
            newRect.origin.y = baseRect.origin.y + translation.height
            newRect.size.width = baseRect.width + translation.width
            newRect.size.height = baseRect.height - translation.height
        case .bottomLeft:
            newRect.origin.x = baseRect.origin.x + translation.width
            newRect.size.width = baseRect.width - translation.width
            newRect.size.height = baseRect.height + translation.height
        case .bottomRight:
            newRect.size.width = baseRect.width + translation.width
            newRect.size.height = baseRect.height + translation.height
        case .top:
            newRect.origin.y = baseRect.origin.y + translation.height
            newRect.size.height = baseRect.height - translation.height
        case .bottom:
            newRect.size.height = baseRect.height + translation.height
        case .left:
            newRect.origin.x = baseRect.origin.x + translation.width
            newRect.size.width = baseRect.width - translation.width
        case .right:
            newRect.size.width = baseRect.width + translation.width
        case .center:
            break
        }
        
        // 限制最小尺寸
        if newRect.width >= minSize && newRect.height >= minSize {
            // 限制在容器内
            newRect.origin.x = max(0, min(newRect.origin.x, containerSize.width - newRect.width))
            newRect.origin.y = max(0, min(newRect.origin.y, containerSize.height - newRect.height))
            newRect.size.width = min(newRect.width, containerSize.width - newRect.origin.x)
            newRect.size.height = min(newRect.height, containerSize.height - newRect.origin.y)
            cropRect = newRect
        }
    }
    
    private func moveCropRect(by translation: CGSize) {
        var newRect = cropRect
        newRect.origin.x += translation.width
        newRect.origin.y += translation.height
        
        // 限制在容器内
        newRect.origin.x = max(0, min(newRect.origin.x, containerSize.width - newRect.width))
        newRect.origin.y = max(0, min(newRect.origin.y, containerSize.height - newRect.height))
        
        cropRect = newRect
    }
}

// MARK: - Simple Crop View
struct SimpleCropView: View {
    @Environment(\.dismiss) var dismiss
    let image: UIImage
    let onCrop: (UIImage) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                
                // 裁剪框提示
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 300, height: 300)
                    .allowsHitTesting(false)
            }
            .navigationTitle("裁剪图片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        cropImage()
                    }
                }
            }
        }
    }
    
    private func cropImage() {
        // 简化版本: 直接返回缩放后的图片
        // 实际裁剪需要计算可见区域并裁剪
        if scale != 1.0, let scaledImage = image.scaled(by: scale) {
            onCrop(scaledImage)
        } else {
            onCrop(image)
        }
    }
}

// MARK: - Subject Selection View
@available(iOS 17.0, *)
struct SubjectSelectionView: View {
    let subjects: [(UIImage, Double)]
    @Binding var selectedIndex: Int?
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("选择一个主体")
                .font(.headline)
            
            Text("识别到 \(subjects.count) 个主体")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                    ForEach(subjects.indices, id: \.self) { index in
                        VStack(spacing: 8) {
                            Image(uiImage: subjects[index].0)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .overlay {
                                    if selectedIndex == index {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.blue, lineWidth: 3)
                                    }
                                }
                                .onTapGesture {
                                    selectedIndex = index
                                }
                            
                            Text(String(format: "%.0f%%", subjects[index].1 * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            
            HStack(spacing: 16) {
                Button("取消") {
                    onCancel()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)
                
                Button("确认") {
                    onConfirm()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedIndex != nil ? Color.blue.gradient : Color.gray.gradient)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(selectedIndex == nil)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - ImageAnalysisView (封装 ImageAnalysisInteraction)
@available(iOS 17.0, *)
struct ImageAnalysisView: UIViewRepresentable {
    let image: UIImage
    let onSubjectExtracted: (UIImage) -> Void
    
    func makeUIView(context: Context) -> ImageAnalysisContainerView {
        let containerView = ImageAnalysisContainerView()
        containerView.configure(with: image, onSubjectExtracted: onSubjectExtracted)
        return containerView
    }
    
    func updateUIView(_ uiView: ImageAnalysisContainerView, context: Context) {}
}

// MARK: - ImageAnalysisContainerView
@available(iOS 17.0, *)
class ImageAnalysisContainerView: UIView {
    private var imageView: UIImageView!
    private var interaction: ImageAnalysisInteraction!
    private var analyzer = ImageAnalyzer()
    private var onSubjectExtracted: ((UIImage) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // 创建 ImageView
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // 创建 ImageAnalysisInteraction
        interaction = ImageAnalysisInteraction()
        interaction.preferredInteractionTypes = [.imageSubject]
        imageView.addInteraction(interaction)
    }
    
    func configure(with image: UIImage, onSubjectExtracted: @escaping (UIImage) -> Void) {
        self.imageView.image = image
        self.onSubjectExtracted = onSubjectExtracted
        
        Task {
            await analyzeImage(image)
        }
    }
    
    private func analyzeImage(_ image: UIImage) async {
        do {
            let configuration = ImageAnalyzer.Configuration([.visualLookUp])
            let analysis = try await analyzer.analyze(image, configuration: configuration)
            
            await MainActor.run {
                interaction.analysis = analysis
                interaction.preferredInteractionTypes = [.imageSubject]
            }
            
        } catch {
            print("Image analysis failed: \(error)")
        }
    }
}
