import Foundation
import Combine
import SwiftUI

class BroadcasterStore: ObservableObject {
    @Published var selectedBroadcaster: Broadcaster?
    @Published var articles: [Article] = []
    @Published var isFetching = false
    @Published var customBroadcasters: [Broadcaster] = []
    
    private let customFeedsKey = "user_custom_rss_feeds"
    private let maxCustomFeeds = 10
    private let parser = RSSParserService()
    
    var allBroadcasters: [Broadcaster] {
        Broadcaster.defaults + customBroadcasters
    }
    
    init() {
        self.selectedBroadcaster = Broadcaster.defaults.first
        loadCustomFeeds()
    }
    
    @MainActor
    func select(_ broadcaster: Broadcaster) async {
        self.selectedBroadcaster = broadcaster
        await fetchArticles(for: broadcaster)
    }
    
    @MainActor
    func fetchArticles(for broadcaster: Broadcaster, forceRefresh: Bool = false) async {
        isFetching = true
        
        let cacheKey = "cached_rss_\(broadcaster.name.lowercased().replacingOccurrences(of: " ", with: "_"))"
        
        if !forceRefresh, let cachedArticles = await StorageManager.shared.load(key: cacheKey, as: [Article].self) {
            self.articles = cachedArticles
            isFetching = false
            return
        }
        
        guard let url = URL(string: broadcaster.rssURL) else {
            isFetching = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let rssArticles = await Task.detached(priority: .userInitiated) {
                self.parser.parse(xmlData: data, source: broadcaster.name)
            }.value
            
            self.articles = rssArticles
            
            let copy = rssArticles
            Task {
                await StorageManager.shared.save(copy, key: cacheKey)
            }
        } catch {
            print("RSS Fetch Error: \(error.localizedDescription)")
        }
        
        isFetching = false
    }
    
    // MARK: - Custom Feed Management
    
    func validateAndAdd(url: String, name: String) async -> Bool {
        guard customBroadcasters.count < maxCustomFeeds else { return false }
        guard let urlObj = URL(string: url) else { return false }
        
        var request = URLRequest(url: urlObj)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let parsed = parser.parse(xmlData: data, source: name)
            
            if !parsed.isEmpty {
                let newBroadcaster = Broadcaster(name: name, rssURL: url, iconName: "rss", isCustom: true)
                await MainActor.run {
                    self.customBroadcasters.append(newBroadcaster)
                    self.saveCustomFeeds()
                }
                return true
            }
        } catch {
            return false
        }
        return false
    }
    
    func deleteCustomFeeds(at offsets: IndexSet) {
        customBroadcasters.remove(atOffsets: offsets)
        saveCustomFeeds()
    }
    
    private func loadCustomFeeds() {
        Task {
            if let decoded = await StorageManager.shared.load(key: customFeedsKey, as: [Broadcaster].self) {
                await MainActor.run {
                    self.customBroadcasters = decoded
                }
            }
        }
    }
    
    private func saveCustomFeeds() {
        let copy = customBroadcasters
        Task {
            await StorageManager.shared.save(copy, key: customFeedsKey)
        }
    }
}
