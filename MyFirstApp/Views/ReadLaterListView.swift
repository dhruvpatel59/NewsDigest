import SwiftUI

struct ReadLaterListView: View {
    @EnvironmentObject var readLaterStore: ReadLaterStore
    @EnvironmentObject var historyStore: ReadingHistoryStore
    
    @State private var filterUnreadOnly = false
    @State private var sortOption: SortOption = .newestSaved
    @State private var selectedArticle: Article?
    
    enum SortOption: String, CaseIterable, Identifiable {
        case newestSaved = "Newest Saved"
        case oldestSaved = "Oldest Saved"
        case source = "By Source"
        var id: String { self.rawValue }
    }
    
    var filteredArticles: [ReadLaterArticle] {
        var result = readLaterStore.savedArticles
        
        if filterUnreadOnly {
            result = result.filter { !$0.isRead }
        }
        
        switch sortOption {
        case .newestSaved:
            result.sort { $0.savedAt > $1.savedAt }
        case .oldestSaved:
            result.sort { $0.savedAt < $1.savedAt }
        case .source:
            result.sort { $0.article.newsSite < $1.article.newsSite }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea().premiumBackground()
            
            VStack(spacing: 0) {
                filterHeader
                
                ScrollView {
                    if filteredArticles.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredArticles) { entry in
                                ReadLaterCard(entry: entry)
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedArticle = entry.article
                                        historyStore.markAsRead(entry.article)
                                        readLaterStore.markAsRead(entry.article)
                                    }
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationTitle("Reading List")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedArticle) { article in
            if let url = URL(string: article.url) {
                SafariView(url: url).ignoresSafeArea()
            }
        }
    }
}

// MARK: - Subcomponents
extension ReadLaterListView {
    
    private var filterHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Toggle("Unread Only", isOn: $filterUnreadOnly)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                
                Spacer()
                
                Menu {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortOption.rawValue)
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .glassPanel(cornerRadius: 0)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 72))
                .foregroundColor(.accentColor.opacity(0.6))
                .shadow(color: .accentColor.opacity(0.3), radius: 10)
            
            Text(filterUnreadOnly ? "No unread articles" : "Reading list is empty")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Tap the clock icon on any article to save it for a deeper read later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .glassPanel()
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }
}

struct ReadLaterCard: View {
    let entry: ReadLaterArticle
    @EnvironmentObject var readLaterStore: ReadLaterStore
    
    var body: some View {
        ArticleCardView(article: entry.article)
            .opacity(entry.isRead ? 0.7 : 1.0)
            .overlay(alignment: .topTrailing) {
                if !entry.isRead {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 10, height: 10)
                        .padding(12)
                }
            }
            .contextMenu {
                Button {
                    readLaterStore.toggleReadStatus(for: entry.id)
                } label: {
                    Label(entry.isRead ? "Mark as Unread" : "Mark as Read", 
                          systemImage: entry.isRead ? "circle" : "checkmark.circle")
                }
                
                Button(role: .destructive) {
                    readLaterStore.removeFromReadLater(articleID: entry.id)
                } label: {
                    Label("Remove from List", systemImage: "trash")
                }
            }
            .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ReadLaterListView()
            .environmentObject(ReadLaterStore())
            .environmentObject(ReadingHistoryStore())
            .environmentObject(BookmarkStore())
    }
}
