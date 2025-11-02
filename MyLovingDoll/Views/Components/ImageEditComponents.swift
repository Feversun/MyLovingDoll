//
//  ImageEditComponents.swift
//  MyLovingDoll
//
//  图片编辑相关组件
//

import SwiftUI

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
