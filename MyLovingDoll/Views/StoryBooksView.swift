//
//  StoryBooksView.swift
//  MyLovingDoll
//
//  故事书横向滑动浏览页面
//

import SwiftUI

struct StoryBooksView: View {
    @State private var selectedBook: StoryBook? = nil
    
    let books = StoryBook.samples
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 标题区域
                VStack(alignment: .leading, spacing: 8) {
                    Text("故事书馆")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("选择一本故事，开始你的冒险")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                // 横向滑动的书籍视图
                TabView {
                    ForEach(books) { book in
                        BookCardView(book: book)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 20)
                            .onTapGesture {
                                selectedBook = book
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedBook) { book in
                StoryBookDetailView(book: book)
            }
        }
    }
}

// MARK: - 书籍卡片视图
struct BookCardView: View {
    let book: StoryBook
    
    var body: some View {
        VStack(spacing: 0) {
            // 书本封面
            ZStack {
                // 背景阴影
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                
                // 封面图片（占位）
                VStack {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 120))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.bottom, 20)
                    
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Text(book.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(40)
            }
            .frame(height: 450)
            
            // 描述区域
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(book.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("\(book.previewPages.count) 页预览")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(book.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Spacer()
                    Image(systemName: "hand.tap.fill")
                        .font(.caption)
                    Text("点击查看详情")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                }
                .foregroundColor(.blue)
                .padding(.top, 4)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    StoryBooksView()
}
