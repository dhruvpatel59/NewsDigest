internal import SwiftUI

struct ArticleCardView: View {
    let article: Article
    var onSummarize: (() -> Void)? = nil
    
    @EnvironmentObject var bookmarkStore: BookmarkStore
    @EnvironmentObject var readLaterStore: ReadLaterStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(article.newsSite)
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundColor(.accentColor)
                    .textCase(.uppercase)
                
                Spacer()
                
                if let onSummarize = onSummarize {
                    Button(action: {
                        onSummarize()
                    }) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
                
                Button(action: {
                    bookmarkStore.toggleBookmark(for: article)
                }) {
                    Image(systemName: bookmarkStore.isSaved(article) ? "heart.fill" : "heart")
                        .foregroundColor(bookmarkStore.isSaved(article) ? .red : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                
                Button(action: {
                    HapticManager.shared.trigger(.medium)
                    if readLaterStore.isInReadLater(article) {
                        readLaterStore.removeFromReadLater(articleID: article.id)
                    } else {
                        let _ = readLaterStore.addToReadLater(article)
                    }
                }) {
                    Image(systemName: readLaterStore.isInReadLater(article) ? "clock.badge.checkmark.fill" : "clock.badge.checkmark")
                        .foregroundColor(readLaterStore.isInReadLater(article) ? .accentColor : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                
                Text(article.formattedPublishedTime)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                if let urlString = article.image_url, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray6))
                                ProgressView()
                            }
                            .frame(width: 80, height: 80)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray6))
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 80, height: 80)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
        }
        .padding()
        .glassPanel()
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        ArticleCardView(article: Article(
            title: "NASA successfully commands new space telescope",
            summary: "The agency's latest flagship observatory has successfully aligned all mirrors.",
            url: "https://nasa.gov",
            image_url: "https://example.com/mock.jpg",
            publishedAt: "2023-10-12T14:30:15Z",
            newsSite: "NASA"
        ))
        .environmentObject(BookmarkStore())
        .padding()
    }
}

