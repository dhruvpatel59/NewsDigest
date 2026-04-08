import SwiftUI

struct CategoryDetailView: View {
    let category: NewsCategory
    
    @EnvironmentObject var bookmarkStore: BookmarkStore
    @EnvironmentObject var historyStore: ReadingHistoryStore
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @StateObject private var store = NewsStore()
    @State private var articleToSummarize: Article? {
        didSet {
            if let article = articleToSummarize {
                historyStore.markAsRead(article)
            }
        }
    }
    @State private var articleToRead: Article?
    let impactLight = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        ZStack {
            Color.clear.premiumBackground()
            
            if !networkMonitor.isConnected && store.articles.isEmpty {
                OfflineView {
                    fetchCategoryNews()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if !networkMonitor.isConnected && !store.articles.isEmpty {
                            offlineWarningBar
                        }
                        
                        // Category Header Banner
                        categoryBanner
                        
                        if store.isFetching && store.articles.isEmpty {
                            ForEach(0..<4, id: \.self) { _ in
                                SkeletonCardView()
                            }
                        } else if store.articles.isEmpty {
                            emptyState
                        } else {
                            ForEach(store.articles) { article in
                                Button {
                                    impactLight.impactOccurred()
                                    articleToRead = article
                                } label: {
                                    ArticleCardView(article: article) {
                                        articleToSummarize = article
                                    }
                                }
                                .buttonStyle(.plain)
                                .swipeActions(
                                    isBookmarked: bookmarkStore.isSaved(article),
                                    onBookmark: { bookmarkStore.toggleBookmark(for: article) },
                                    onShare: { shareArticle(article) }
                                )
                                .transition(.opacity.combined(with: .offset(y: 20)))
                                .animation(.easeOut(duration: 0.3), value: store.articles.count)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            fetchCategoryNews()
        }
        .refreshable {
            impactLight.impactOccurred()
            fetchCategoryNews(forceRefresh: true)
        }
        .sheet(item: $articleToSummarize) { article in
            AISummarySheet(article: article) {
                articleToSummarize = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    articleToRead = article
                }
            }
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(item: $articleToRead) { article in
            if let url = URL(string: article.url) {
                SafariView(url: url).ignoresSafeArea()
            }
        }
    }
    
    private func fetchCategoryNews(forceRefresh: Bool = false) {
        Task {
            await store.fetchByCategory(category: category.rawValue, forceRefresh: forceRefresh)
        }
    }
    
    private func shareArticle(_ article: Article) {
        ArticleImageSharer.share(article)
    }
}

// MARK: - Subcomponents
extension CategoryDetailView {
    
    private var offlineWarningBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("Offline — Showing local results only")
                .fontWeight(.medium)
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.6))
        .cornerRadius(8)
        .padding(.bottom, 8)
    }
    
    private var categoryBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(category.tint)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Top headlines in \(category.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .glassPanel()
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "newspaper")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No articles found")
                .font(.headline)
            Text("Try again later or check your connection.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
