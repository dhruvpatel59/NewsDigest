internal import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var bookmarkStore: BookmarkStore
    @EnvironmentObject var historyStore: ReadingHistoryStore
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @StateObject private var searchStore = NewsStore()
    @State private var searchText = ""
    @State private var articleToSummarize: Article? {
        didSet {
            if let article = articleToSummarize {
                historyStore.markAsRead(article)
            }
        }
    }
    @State private var articleToRead: Article?
    
    private var isSearchActive: Bool {
        !searchText.isEmpty || !searchStore.articles.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.premiumBackground()
                
                if !networkMonitor.isConnected && !isSearchActive {
                    OfflineView {
                        HapticManager.shared.trigger(.light)
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            if !networkMonitor.isConnected && isSearchActive {
                                offlineWarningBar
                            }
                            
                            if isSearchActive {
                                searchResultsView
                            } else {
                                categoryGridView
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Explore")
            .searchable(text: $searchText, prompt: networkMonitor.isConnected ? "Search any topic..." : "Offline — Check Connection")
            .disabled(!networkMonitor.isConnected)
            .onSubmit(of: .search) {
                HapticManager.shared.trigger(.light)
                Task { await searchStore.fetchBySearch(query: searchText) }
            }
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty { searchStore.articles = [] }
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
    }
}

extension ExploreView {
    
    private var offlineWarningBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("Offline — Feed limited to cached content")
                .fontWeight(.bold)
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.4))
        .glassPanel()
        .padding(.bottom, 8)
    }
    
    private var categoryGridView: some View {
        Group {
            SectionHeaderView(title: "Browse by Topic", icon: "square.grid.2x2.fill")
            
            ForEach(NewsCategory.allCases) { category in
                NavigationLink(destination: CategoryDetailView(category: category)) {
                    CategoryCardView(category: category)
                }
                .buttonStyle(.plain)
                .disabled(!networkMonitor.isConnected)
                .opacity(networkMonitor.isConnected ? 1.0 : 0.6)
                .simultaneousGesture(TapGesture().onEnded {
                    HapticManager.shared.trigger(.light)
                })
            }
        }
    }
    
    @ViewBuilder
    private var searchResultsView: some View {
        SectionHeaderView(title: "Results for \"\(searchText)\"", icon: "magnifyingglass")
        
        if searchStore.isFetching {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonCardView()
            }
        } else if searchStore.articles.isEmpty && !searchText.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor.opacity(0.6))
                    .shadow(color: .accentColor.opacity(0.3), radius: 10)
                
                Text("No results found")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("We couldn't find any news matching \"\(searchText)\". Try adjusting your search query.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .glassPanel()
            .padding(.vertical, 40)
        } else {
            ForEach(searchStore.articles) { article in
                Button {
                    HapticManager.shared.trigger(.light)
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
            }
        }
    }
    
    private func shareArticle(_ article: Article) {
        ArticleImageSharer.share(article)
    }
}

struct CategoryCardView: View {
    let category: NewsCategory
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: category.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(category.tint)
                .cornerRadius(12)
                .shadow(color: category.tint.opacity(0.4), radius: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.body)
                    .fontWeight(.bold)
                
                Text("Global headlines")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .glassPanel()
    }
}

#Preview {
    ExploreView()
        .environmentObject(BookmarkStore())
}

