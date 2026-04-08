import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authStore: AuthStore
    @StateObject private var bookmarkStore = BookmarkStore()
    @StateObject private var historyStore = ReadingHistoryStore()
    @StateObject private var readLaterStore = ReadLaterStore()
    @StateObject private var insightStore = AIInsightStore.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var body: some View {
        TabView {
            DigestView()
                .tabItem {
                    Label("Feed", systemImage: "newspaper.fill")
                }
            
            BroadcastersView()
                .tabItem {
                    Label("Broadcasters", systemImage: "antenna.radiowaves.left.and.right")
                }
            
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "square.grid.2x2.fill")
                }
            
            SavedView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .badge(readLaterStore.unreadCount)
        }
        .environmentObject(bookmarkStore)
        .environmentObject(historyStore)
        .environmentObject(readLaterStore)
        .environmentObject(insightStore)
        .environmentObject(networkMonitor)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthStore())
}
