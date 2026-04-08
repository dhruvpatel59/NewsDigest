import Foundation
import Combine

class NewsStore: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isFetching = false
    
    private var apiKey: String {
        AppConfig.gnewsAPIKey
    }
    
    @MainActor
    func fetchNews(countryCode: String, forceRefresh: Bool = false) async {
        let localEndpoint = "https://gnews.io/api/v4/top-headlines?category=general&country=\(countryCode)&lang=en&max=10&apikey=\(apiKey)"
        let cricketEndpoint = "https://gnews.io/api/v4/search?q=cricket&lang=en&max=5&apikey=\(apiKey)"
        
        isFetching = true
        
        // Parallel fetch with background priorities
        async let localArticles = fetchFrom(localEndpoint, forceRefresh: forceRefresh)
        async let cricketArticles = fetchFrom(cricketEndpoint, forceRefresh: forceRefresh)
        
        let local = await localArticles
        let cricket = await cricketArticles
        
        // Efficient Merge & Dedupe 
        var seen = Set<String>()
        var merged: [Article] = []
        merged.reserveCapacity(local.count + cricket.count)
        
        for article in (local + cricket) {
            if seen.insert(article.url).inserted {
                merged.append(article)
            }
        }
        
        self.articles = merged
        isFetching = false
    }
    
    private func fetchFrom(_ endpoint: String, forceRefresh: Bool = false) async -> [Article] {
        do {
            let response = try await NetworkManager.shared.fetch(from: endpoint, as: GNewsResponse.self, useCache: !forceRefresh)
            return response.articles
        } catch {
            print("--- NewsStore Fetch Error: \(error.localizedDescription) ---")
            return []
        }
    }
    
    @MainActor
    func fetchByCategory(category: String, forceRefresh: Bool = false) async {
        isFetching = true
        let endpoint = "https://gnews.io/api/v4/top-headlines?category=\(category)&lang=en&max=10&apikey=\(apiKey)"
        self.articles = await fetchFrom(endpoint, forceRefresh: forceRefresh)
        isFetching = false
    }
    
    @MainActor
    func fetchBySearch(query: String, forceRefresh: Bool = false) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isFetching = true
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let endpoint = "https://gnews.io/api/v4/search?q=\(encoded)&lang=en&max=10&apikey=\(apiKey)"
        self.articles = await fetchFrom(endpoint, forceRefresh: forceRefresh)
        isFetching = false
    }
}

struct GNewsResponse: Decodable {
    let totalArticles: Int
    let articles: [Article]
}
