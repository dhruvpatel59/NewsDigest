import Foundation

struct Broadcaster: Identifiable, Codable, Hashable {
    var id: String { rssURL } // URL is a unique identifier
    let name: String
    let rssURL: String
    let iconName: String // SF Symbol name
    let isCustom: Bool
    
    // Pre-configured list of popular broadcasters
    static let defaults: [Broadcaster] = [
        Broadcaster(
            name: "BBC News",
            rssURL: "https://feeds.bbci.co.uk/news/rss.xml",
            iconName: "globe.americas.fill",
            isCustom: false
        ),
        Broadcaster(
            name: "The Hindu",
            rssURL: "https://www.thehindu.com/news/national/feeder/default.rss",
            iconName: "book.fill",
            isCustom: false
        ),
        Broadcaster(
            name: "Times Now",
            rssURL: "https://www.timesnownews.com/feeds/rss",
            iconName: "clock.fill",
            isCustom: false
        ),
        Broadcaster(
            name: "NDTV News",
            rssURL: "https://feeds.feedburner.com/ndtvnews-top-stories",
            iconName: "newspaper.fill",
            isCustom: false
        )
    ]
}
