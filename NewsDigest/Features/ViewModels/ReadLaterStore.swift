import Foundation
import Combine
internal import SwiftUI

class ReadLaterStore: ObservableObject {
    @Published var savedArticles: [ReadLaterArticle] = []
    
    private let storageKey = "Pulse_ReadLater_v2"
    private let maxArticlesCount = 50
    private let autoDeleteInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days in seconds
    
    init() {
        Task {
            await loadReadLater()
            await MainActor.run {
                performAutoPurge()
            }
        }
    }
    
    var unreadCount: Int {
        savedArticles.filter { !$0.isRead }.count
    }
    
    func isInReadLater(_ article: Article) -> Bool {
        savedArticles.contains(where: { $0.id == article.id })
    }
    
    func addToReadLater(_ article: Article) -> Bool {
        // Prevent duplicates
        if isInReadLater(article) { return false }
        
        // Enforce 50-article cap
        guard savedArticles.count < maxArticlesCount else { return false }
        
        let newEntry = ReadLaterArticle(article: article)
        savedArticles.insert(newEntry, at: 0) // Newest at the top
        saveReadLater()
        return true
    }
    
    func removeFromReadLater(articleID: String) {
        savedArticles.removeAll(where: { $0.id == articleID })
        saveReadLater()
    }
    
    func toggleReadStatus(for articleID: String) {
        if let index = savedArticles.firstIndex(where: { $0.id == articleID }) {
            savedArticles[index].isRead.toggle()
            if savedArticles[index].isRead {
                savedArticles[index].readAt = Date()
            } else {
                savedArticles[index].readAt = nil
            }
            saveReadLater()
        }
    }
    
    func markAsRead(_ article: Article) {
        if let index = savedArticles.firstIndex(where: { $0.id == article.id }) {
            if !savedArticles[index].isRead {
                savedArticles[index].isRead = true
                savedArticles[index].readAt = Date()
                saveReadLater()
            }
        }
    }
    
    // MARK: - Internal Engine
    
    /// Auto-removes articles that have been marked "Read" for more than 7 days.
    private func performAutoPurge() {
        let now = Date()
        let purged = savedArticles.filter { entry in
            if entry.isRead, let readTime = entry.readAt {
                let elapsed = now.timeIntervalSince(readTime)
                return elapsed < autoDeleteInterval
            }
            return true // Keep all unread or recently read items
        }
        
        if purged.count != savedArticles.count {
            self.savedArticles = purged
            saveReadLater()
        }
    }
    
    @MainActor
    private func loadReadLater() async {
        if let decoded = await StorageManager.shared.load(key: storageKey, as: [ReadLaterArticle].self) {
            self.savedArticles = decoded
        }
    }
    
    private func saveReadLater() {
        let copy = savedArticles
        Task {
            await StorageManager.shared.save(copy, key: storageKey)
        }
    }
}
