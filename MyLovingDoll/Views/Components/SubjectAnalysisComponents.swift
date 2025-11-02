//
//  SubjectAnalysisComponents.swift
//  MyLovingDoll
//
//  主体选择和图片分析相关组件
//

import SwiftUI
import VisionKit

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
