internal import SwiftUI

struct BroadcastersView: View {
    @StateObject private var broadcasterStore = BroadcasterStore()
    @EnvironmentObject var bookmarkStore: BookmarkStore
    @EnvironmentObject var historyStore: ReadingHistoryStore
    
    @State private var showAddFeed = false
    @State private var articleToSummarize: Article?
    @State private var articleToRead: Article?
    
    let impactLight = UIImpactFeedbackGenerator(style: .light)
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.ignoresSafeArea().premiumBackground()
                
                VStack(spacing: 0) {
                    sourceSelector
                        .padding(.vertical, 12)
                    
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if broadcasterStore.isFetching && broadcasterStore.articles.isEmpty {
                                SkeletonCardView().padding(.horizontal)
                                SkeletonCardView().padding(.horizontal)
                            } else if broadcasterStore.articles.isEmpty {
                                emptyStateView
                            } else {
                                articleList
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        impactLight.impactOccurred()
                        if let selected = broadcasterStore.selectedBroadcaster {
                            await broadcasterStore.fetchArticles(for: selected, forceRefresh: true)
                        }
                    }
                }
            }
            .navigationTitle("Broadcasters")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        impactMed.impactOccurred()
                        showAddFeed = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddFeed) {
                AddBroadcasterView(store: broadcasterStore)
                    .presentationDetents([.medium])
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
            .task {
                if let selected = broadcasterStore.selectedBroadcaster {
                    await broadcasterStore.fetchArticles(for: selected)
                }
            }
        }
    }
}

// MARK: - Subcomponents
extension BroadcastersView {
    
    private var sourceSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(broadcasterStore.allBroadcasters) { broadcaster in
                    let isSelected = broadcasterStore.selectedBroadcaster?.id == broadcaster.id
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        Task {
                            await broadcasterStore.select(broadcaster)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: broadcaster.iconName)
                                .font(.caption)
                                .foregroundColor(isSelected ? .white : .accentColor)
                            Text(broadcaster.name)
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isSelected ? Color.accentColor : Color.clear)
                        .foregroundColor(isSelected ? .white : .primary)
                        .glassPanel(cornerRadius: 20)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var articleList: some View {
        ForEach(broadcasterStore.articles) { article in
            ArticleCardView(article: article, onSummarize: {
                articleToSummarize = article
            })
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                articleToRead = article
                historyStore.markAsRead(article)
            }
            .padding(.horizontal)
            .swipeActions(
                isBookmarked: bookmarkStore.isSaved(article),
                onBookmark: { bookmarkStore.toggleBookmark(for: article) },
                onShare: { shareArticle(article) }
            )
            // Injecting Bookmark Actions via Context Menu
            .contextMenu {
                Button {
                    bookmarkStore.toggleBookmark(for: article)
                } label: {
                    Label(bookmarkStore.isSaved(article) ? "Remove Bookmark" : "Save Article", 
                          systemImage: bookmarkStore.isSaved(article) ? "heart.fill" : "heart")
                }
            }
        }
    }
    
    private func shareArticle(_ article: Article) {
        ArticleImageSharer.share(article)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rss")
                .font(.system(size: 64))
                .foregroundColor(.accentColor.opacity(0.6))
                .shadow(color: .accentColor.opacity(0.3), radius: 10)
            
            Text("No Articles Found")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("We couldn't retrieve any articles for this broadcaster. Try refreshing or checking your internet connection.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .glassPanel()
        .padding(.horizontal, 24)
        .padding(.top, 100)
    }
}

#Preview {
    BroadcastersView()
        .environmentObject(BookmarkStore())
        .environmentObject(ReadingHistoryStore())
}
