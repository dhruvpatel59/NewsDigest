import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var bookmarkStore: BookmarkStore
    @EnvironmentObject var historyStore: ReadingHistoryStore
    @EnvironmentObject var readLaterStore: ReadLaterStore
    @EnvironmentObject var insightStore: AIInsightStore
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false
    
    @State private var showGuidance = false
    @State private var selectedArticle: Article? {
        didSet {
            if let article = selectedArticle {
                historyStore.markAsRead(article)
            }
        }
    }
    
    // Extract initials from the user's name
    private var userInitials: String {
        let name = authStore.currentUser?.name ?? "G"
        let parts = name.components(separatedBy: " ")
        let initials = parts.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
        return initials.joined()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.ignoresSafeArea().premiumBackground()
                
                ScrollView {
                    VStack(spacing: 28) {
                        profileHeader
                        statsDashboard
                        readLaterQuickPeek
                        recentlyReadSection
                        preferencesSection
                        logoutButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .sheet(item: $selectedArticle) { article in
                if let url = URL(string: article.url) {
                    SafariView(url: url).ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showGuidance) {
                AppGuidanceView()
            }
        }
    }
}

// MARK: - Subcomponents
extension ProfileView {
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .shadow(color: .accentColor.opacity(0.4), radius: 20, x: 0, y: 10)
                
                Text(userInitials)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text(authStore.currentUser?.name ?? "Guest User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 8) {
                    Text("Member Since 2026")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("NEWS ENTHUSIAST")
                        .font(.system(size: 9, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassPanel()
    }
    
    private var statsDashboard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statDashItem(value: "\(historyStore.history.count)", label: "Reads", icon: "book.fill", color: .blue)
                statDashItem(value: "\(bookmarkStore.savedArticles.count)", label: "Saved", icon: "heart.fill", color: .red)
                statDashItem(value: "\(readLaterStore.unreadCount)", label: "Unread", icon: "clock.fill", color: .accentColor)
            }
            
            // NEW: AI Insight Library Entry
            NavigationLink {
                AIInsightsListView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                            Text("MY AI INSIGHTS")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(insightStore.entries.count) Saved Summaries")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .glassPanel()
            }
            .buttonStyle(.plain)
        }
    }
    
    private func statDashItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .padding(10)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassPanel()
    }
    
    @ViewBuilder
    private var readLaterQuickPeek: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderView(title: "Read Later Preview", icon: "clock.badge.checkmark.fill")
                Spacer()
                NavigationLink {
                    ReadLaterListView()
                } label: {
                    Text("View All")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
            }
            
            if readLaterStore.savedArticles.isEmpty {
                HStack {
                    Text("Nothing saved for later yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .glassPanel()
            } else {
                VStack(spacing: 12) {
                    ForEach(readLaterStore.savedArticles.prefix(2)) { entry in
                        Button {
                            HapticManager.shared.trigger(.light)
                            selectedArticle = entry.article
                            readLaterStore.markAsRead(entry.article)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: entry.isRead ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(entry.isRead ? .green : .accentColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.article.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    Text(entry.article.newsSite)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .padding()
                            .glassPanel()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var recentlyReadSection: some View {
        if !historyStore.history.isEmpty {
            VStack(spacing: 12) {
                SectionHeaderView(title: "Recently Read", icon: "arrow.counterclockwise.circle.fill")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(historyStore.history.prefix(10)) { article in
                            Button {
                                HapticManager.shared.trigger(.light)
                                selectedArticle = article
                            } label: {
                                MiniArticleCard(article: article)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    private var preferencesSection: some View {
        VStack(spacing: 12) {
            SectionHeaderView(title: "Preferences", icon: "gearshape.fill")
            
            VStack(spacing: 1) {
                NavigationLink { ReadLaterListView() } label: {
                    settingsRow(title: "Reading List", icon: "clock.badge.checkmark", color: .blue)
                }
                
                Button {
                    HapticManager.shared.trigger(.medium)
                    showGuidance = true
                } label: {
                    settingsRow(title: "Help & Guidance", icon: "questionmark.circle", color: .yellow)
                }
                .buttonStyle(.plain)
                
                Toggle(isOn: $isDarkModeEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        Text("Dark Mode")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .tint(.accentColor)
                .padding()
                .background(Color.white.opacity(0.02))
            }
            .glassPanel(cornerRadius: 16)
        }
    }
    
    private func settingsRow(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.02))
    }
    
    private var logoutButton: some View {
        Button(role: .destructive) {
            HapticManager.shared.trigger(.medium)
            withAnimation { authStore.logout() }
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct MiniArticleCard: View {
    let article: Article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let urlString = article.image_url, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Color.accentColor.opacity(0.1)
                    }
                }
                .frame(width: 200, height: 110)
                .clipped()
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(article.newsSite)
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.accentColor)
                    .textCase(.uppercase)
            }
        }
        .frame(width: 200)
        .padding(12)
        .glassPanel()
    }
}
