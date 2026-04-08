import Foundation

struct Article: Identifiable, Codable, Hashable {
    // We utilize the physical URL as a truly unique ID.
    var id: String { url }
    
    let title: String
    let summary: String
    let url: String
    let image_url: String?
    let publishedAt: String
    let newsSite: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case summary = "description"
        case url
        case image_url = "image"
        case publishedAt
        case source
    }
    
    enum SourceKeys: String, CodingKey {
        case name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.summary = (try? container.decodeIfPresent(String.self, forKey: .summary)) ?? "No description available."
        self.url = try container.decode(String.self, forKey: .url)
        self.image_url = try container.decodeIfPresent(String.self, forKey: .image_url)
        self.publishedAt = try container.decode(String.self, forKey: .publishedAt)
        
        // Try decoding GNews nested source, otherwise fallback to flat property
        if let sourceContainer = try? container.nestedContainer(keyedBy: SourceKeys.self, forKey: .source) {
            self.newsSite = try sourceContainer.decode(String.self, forKey: .name)
        } else {
            self.newsSite = try container.decodeIfPresent(String.self, forKey: .source) ?? "News"
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(summary, forKey: .summary)
        try container.encode(url, forKey: .url)
        try container.encode(image_url, forKey: .image_url)
        try container.encode(publishedAt, forKey: .publishedAt)
        
        // Always encode as flat 'source' for simpler local storage/RSS
        try container.encode(newsSite, forKey: .source)
    }
    
    // Manual initializer for Previews and internal Bookmark usage
    init(title: String, summary: String, url: String, image_url: String?, publishedAt: String, newsSite: String) {
        self.title = title
        self.summary = summary
        self.url = url
        self.image_url = image_url
        self.publishedAt = publishedAt
        self.newsSite = newsSite
    }
    
    static func == (lhs: Article, rhs: Article) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Global Time parsing
    var formattedPublishedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        
        if let date = formatter.date(from: publishedAt) {
            return displayFormatter.string(from: date)
        }
        return publishedAt
    }
}
