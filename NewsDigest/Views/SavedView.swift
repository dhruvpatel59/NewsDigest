internal import SwiftUI

struct SavedView: View {
    @EnvironmentObject var bookmarkStore: BookmarkStore
    @EnvironmentObject var historyStore: ReadingHistoryStore
    @State private var articleToSummarize: Article? {
        didSet {
            if let article = articleToSummarize {
                historyStore.markAsRead(article)
            }
        }
    }
    @State private var articleToRead: Article?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.premiumBackground()
                
                if bookmarkStore.savedArticles.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            SectionHeaderView(title: "Your Library", icon: "bookmark.fill")
                            
                            ForEach(bookmarkStore.savedArticles) { article in
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
                                    isBookmarked: true,
                                    onBookmark: { bookmarkStore.toggleBookmark(for: article) },
                                    onShare: { shareArticle(article) }
                                )
                                .transition(.opacity.combined(with: .offset(y: 20)))
                                .animation(.easeOut(duration: 0.3), value: bookmarkStore.savedArticles.count)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Favorites")
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
    
    private func shareArticle(_ article: Article) {
        ArticleImageSharer.share(article)
    }
}

// MARK: - Subcomponents
extension SavedView {
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor.opacity(0.6))
                .shadow(color: .accentColor.opacity(0.3), radius: 10)
            
            Text("Your Library is Empty")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Tap the heart icon on any article to save it here for a deeper read later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .glassPanel()
        .padding(.horizontal, 24)
    }
}

#Preview {
    SavedView()
        .environmentObject(BookmarkStore())
}
