internal import SwiftUI
internal import CoreLocation

struct DigestView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var bookmarkStore: BookmarkStore
    @EnvironmentObject var historyStore: ReadingHistoryStore
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @StateObject private var store = NewsStore()
    @StateObject private var locationManager = LocationManager.shared
    
    @State private var hasRequestedData = false
    @State private var selectedTopic: String? = nil
    @State private var articleToSummarize: Article? {
        didSet {
            if let article = articleToSummarize {
                historyStore.markAsRead(article)
            }
        }
    }
    @State private var articleToRead: Article?
    
    // Manual Location Search
    @State private var showingLocationSearch = false
    @State private var locationSearchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.premiumBackground()

                if locationManager.authorizationStatus == .notDetermined && !hasRequestedData {
                    locationPermissionRequestView
                } else if !networkMonitor.isConnected && store.articles.isEmpty {
                    // Cold start with no internet and no articles loaded
                    OfflineView {
                        refreshNews()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if !networkMonitor.isConnected && !store.articles.isEmpty {
                                // Already have articles but connection is lost
                                offlineWarningBar
                            }
                            
                            SectionHeaderView(
                                title: selectedTopic ?? "Latest in \(locationManager.displayLocation)",
                                icon: selectedTopic != nil ? "magnifyingglass" : "globe",
                                actionIcon: "location.magnifyingglass",
                                onAction: { withAnimation(.spring()) { showingLocationSearch.toggle(); isSearchFocused = true } }
                            )
                            
                            if showingLocationSearch {
                                manualLocationSearchBar
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            SwipeTipCard()
                            
                            TrendingTopicsBar(selectedTopic: $selectedTopic) { topic in
                                if let topic = topic {
                                    Task { await store.fetchBySearch(query: topic) }
                                } else {
                                    refreshNews()
                                }
                            }
                            
                            if store.isFetching && store.articles.isEmpty {
                                ForEach(0..<4, id: \.self) { _ in
                                    SkeletonCardView()
                                }
                            } else {
                                ForEach(store.articles) { article in
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
                                    .transition(.opacity.combined(with: .offset(y: 20)))
                                    .animation(.easeOut(duration: 0.3), value: store.articles.count)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .navigationTitle("News Digest")
                    .onChange(of: locationManager.countryCode) { newCountry in
                        if let country = newCountry {
                            Task { await store.fetchNews(countryCode: country) }
                        }
                    }
                    .refreshable { 
                        HapticManager.shared.trigger(.light)
                        if let topic = selectedTopic {
                            await store.fetchBySearch(query: topic, forceRefresh: true)
                        } else {
                            await store.fetchNews(countryCode: locationManager.countryCode ?? "us", forceRefresh: true)
                        }
                    }
                    .onAppear {
                        if hasRequestedData && locationManager.countryCode == nil && store.articles.isEmpty {
                            refreshNews()
                        }
                    }
                }
            }
            .sheet(item: $articleToSummarize) { article in
                AISummarySheet(article: article) {
                    // Dismiss the summary sheet
                    articleToSummarize = nil
                    // Add slight delay so the sheet can start dismissing before full screen cover appears
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
            .onChange(of: locationManager.authorizationStatus) { newStatus in
                if newStatus == .denied || newStatus == .restricted {
                    hasRequestedData = true
                }
            }
        }
    }
    
    private func refreshNews(forceRefresh: Bool = false) {
        Task {
            let country = locationManager.countryCode ?? "us"
            await store.fetchNews(countryCode: country, forceRefresh: forceRefresh)
        }
    }
    
    private func shareArticle(_ article: Article) {
        ArticleImageSharer.share(article)
    }
}

// MARK: - Subcomponents
extension DigestView {
    
    private var offlineWarningBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("No Internet Connection")
                .fontWeight(.bold)
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.4))
        .glassPanel()
        .padding(.bottom, 4)
    }
    
    private var locationPermissionRequestView: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .shadow(color: .accentColor.opacity(0.3), radius: 10)
            
            Text("Enable Location")
                .font(.title)
                .fontWeight(.bold)
            
            Text("We need your physical location to build a custom news feed explicitly tailored to your country!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            Button {
                HapticManager.shared.trigger(.light)
                locationManager.requestPermission()
            } label: {
                Text("Grant Permission")
                    .fontWeight(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            
            Button {
                HapticManager.shared.trigger(.medium)
                hasRequestedData = true
            } label: {
                Text("Skip — Show Global News")
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
        }
        .padding(32)
        .glassPanel()
        .padding(20)
    }
    private var manualLocationSearchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.accentColor)
                
                TextField("Enter City (e.g. Mumbai)", text: $locationSearchText)
                    .font(.subheadline)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        performManualLocationSearch()
                    }
                
                if !locationSearchText.isEmpty {
                    Button {
                        locationSearchText = ""
                        locationManager.overriddenLocation = nil
                        refreshNews()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(12)
            
            Button {
                performManualLocationSearch()
            } label: {
                Text("Scan")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding(.bottom, 8)
    }
    
    private func performManualLocationSearch() {
        guard !locationSearchText.isEmpty else { return }
        HapticManager.shared.trigger(.medium)
        
        locationManager.overriddenLocation = locationSearchText
        withAnimation { showingLocationSearch = false }
        
        Task {
            await store.fetchBySearch(query: locationSearchText, forceRefresh: true)
        }
    }
}
