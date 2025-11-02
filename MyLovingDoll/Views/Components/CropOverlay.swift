//
//  CropOverlay.swift
//  MyLovingDoll
//
//  可拖拽裁剪框覆盖层
//

import SwiftUI

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
}
