//
//  PageCurlView.swift
//  MyLovingDoll
//
//  iBooks 风格的翻页卷曲效果
//

import SwiftUI
import UIKit

// MARK: - SwiftUI 包装器
struct PageCurlView: UIViewControllerRepresentable {
    let pages: [GeneratedStoryPage]
    @Binding var currentPage: Int
    let specId: String?
    
    func makeUIViewController(context: Context) -> PageCurlViewController {
        let controller = PageCurlViewController(pages: pages, specId: specId)
        controller.pageDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PageCurlViewController, context: Context) {
        // 如果当前页改变，更新 UIPageViewController
        if uiViewController.currentIndex != currentPage {
            uiViewController.goToPage(currentPage)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PageCurlDelegate {
        var parent: PageCurlView
        
        init(_ parent: PageCurlView) {
            self.parent = parent
        }
        
        func didChangePage(to index: Int) {
            parent.currentPage = index
        }
    }
}

// MARK: - 代理协议
protocol PageCurlDelegate: AnyObject {
    func didChangePage(to index: Int)
}

// MARK: - UIPageViewController 包装
class PageCurlViewController: UIViewController {
    private let pages: [GeneratedStoryPage]
    private let specId: String?
    private var pageViewController: UIPageViewController!
    private var pageControllers: [BookPageViewController] = []
    
    weak var pageDelegate: PageCurlDelegate?
    var currentIndex: Int = 0
    
    init(pages: [GeneratedStoryPage], specId: String?) {
        self.pages = pages
        self.specId = specId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建 UIPageViewController，使用 pageCurl 翻页效果
        pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [:]
        )
        
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        // 创建所有页面的 ViewController
        for (index, page) in pages.enumerated() {
            let pageVC = BookPageViewController(
                page: page,
                pageNumber: index + 1,
                totalPages: pages.count,
                specId: specId
            )
            pageControllers.append(pageVC)
        }
        
        // 设置初始页面
        if let firstPage = pageControllers.first {
            pageViewController.setViewControllers(
                [firstPage],
                direction: .forward,
                animated: false
            )
        }
        
        // 添加到视图层级
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.didMove(toParent: self)
        
        // 设置背景
        view.backgroundColor = .black
        pageViewController.view.backgroundColor = .black
    }
    
    func goToPage(_ index: Int) {
        guard index >= 0 && index < pageControllers.count else { return }
        
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        currentIndex = index
        
        pageViewController.setViewControllers(
            [pageControllers[index]],
            direction: direction,
            animated: true
        )
    }
}

// MARK: - UIPageViewController 代理
extension PageCurlViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let currentVC = viewController as? BookPageViewController,
              let index = pageControllers.firstIndex(of: currentVC),
              index > 0 else {
            return nil
        }
        return pageControllers[index - 1]
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let currentVC = viewController as? BookPageViewController,
              let index = pageControllers.firstIndex(of: currentVC),
              index < pageControllers.count - 1 else {
            return nil
        }
        return pageControllers[index + 1]
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first as? BookPageViewController,
              let index = pageControllers.firstIndex(of: currentVC) else {
            return
        }
        
        currentIndex = index
        pageDelegate?.didChangePage(to: index)
    }
}

// MARK: - 单页 ViewController
class BookPageViewController: UIViewController {
    private let page: GeneratedStoryPage
    private let pageNumber: Int
    private let totalPages: Int
    private let specId: String?
    
    private var imageView: UIImageView!
    private var textLabel: UILabel!
    private var pageLabel: UILabel!
    
    init(page: GeneratedStoryPage, pageNumber: Int, totalPages: Int, specId: String?) {
        self.page = page
        self.pageNumber = pageNumber
        self.totalPages = totalPages
        self.specId = specId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadContent()
    }
    
    private func setupUI() {
        // 书页背景
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowRadius = 20
        
        // 图片视图
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        
        // 文字标签
        textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.font = .systemFont(ofSize: 18, weight: .regular)
        textLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textLabel)
        
        // 页码
        pageLabel = UILabel()
        pageLabel.textAlignment = .center
        pageLabel.font = .systemFont(ofSize: 12)
        pageLabel.textColor = .gray
        pageLabel.text = "\(pageNumber)"
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageLabel)
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 图片：上方 60%
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            // 文字：中间区域
            textLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            textLabel.bottomAnchor.constraint(equalTo: pageLabel.topAnchor, constant: -10),
            
            // 页码：底部
            pageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            pageLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func loadContent() {
        // 加载图片
        if let imagePath = page.generatedImagePath,
           let specId = specId,
           let image = FileManager.loadImage(relativePath: imagePath, specId: specId) {
            imageView.image = image
        }
        
        // 设置文字
        textLabel.text = page.customText ?? page.originalText
    }
}
