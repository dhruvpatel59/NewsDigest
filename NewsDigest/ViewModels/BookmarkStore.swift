import Foundation
import Combine
internal import SwiftUI

class BookmarkStore: ObservableObject {
    @Published var savedArticles: [Article] = []
    
    private let storageKey = "Pulse_Bookmarks_v2"
    
    init() {
        Task {
            await loadBookmarks()
        }
    }
    
    func isSaved(_ article: Article) -> Bool {
        savedArticles.contains(where: { $0.id == article.id })
    }
    
    @MainActor
    func toggleBookmark(for article: Article) {
        HapticManager.shared.trigger(.medium)
        
        if isSaved(article) {
            savedArticles.removeAll(where: { $0.id == article.id })
        } else {
            savedArticles.insert(article, at: 0) // Pin newest to top
        }
        
        saveBookmarks()
    }
    
    @MainActor
    private func loadBookmarks() async {
        if let decoded = await StorageManager.shared.load(key: storageKey, as: [Article].self) {
            self.savedArticles = decoded
        }
    }
    
    private func saveBookmarks() {
        let copy = savedArticles
        Task {
            await StorageManager.shared.save(copy, key: storageKey)
        }
    }
}
