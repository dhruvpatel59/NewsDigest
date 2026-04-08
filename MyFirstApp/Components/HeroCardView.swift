import SwiftUI

// MARK: - Hero Card (Full-width top article with image background)
struct HeroCardView: View {
    let article: Article
    @EnvironmentObject var bookmarkStore: BookmarkStore
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            if let urlString = article.image_url, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        LinearGradient(
                            colors: [.accentColor.opacity(0.6), .accentColor.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            } else {
                LinearGradient(
                    colors: [.accentColor.opacity(0.6), .accentColor.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            // Dark gradient overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Text overlay
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(article.newsSite)
                        .font(.caption)
                        .fontWeight(.heavy)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    Button {
                        bookmarkStore.toggleBookmark(for: article)
                    } label: {
                        Image(systemName: bookmarkStore.isSaved(article) ? "heart.fill" : "heart")
                            .foregroundColor(bookmarkStore.isSaved(article) ? .red : .white)
                            .font(.title3)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Text(article.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(3)
                
                Text(article.summary)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                
                Text(article.formattedPublishedTime)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(20)
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
}
