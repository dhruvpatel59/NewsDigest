import Foundation

struct ReadLaterArticle: Identifiable, Codable, Hashable {
    var id: String { article.id }
    let article: Article
    let savedAt: Date
    var isRead: Bool
    var readAt: Date?
    
    init(article: Article, isRead: Bool = false) {
        self.article = article
        self.savedAt = Date()
        self.isRead = isRead
        self.readAt = nil
    }
}
