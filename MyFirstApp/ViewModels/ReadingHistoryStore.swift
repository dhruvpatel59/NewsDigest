import Foundation
import Combine
import SwiftUI

class ReadingHistoryStore: ObservableObject {
    @Published var history: [Article] = []
    
    private let storageKey = "Pulse_History_v2"
    private let maxItems = 10
    
    init() {
        Task {
            await loadHistory()
        }
    }
    
    @MainActor
    func markAsRead(_ article: Article) {
        // Remove if already exists (to move it to the top)
        history.removeAll(where: { $0.id == article.id })
        
        // Insert at the top
        history.insert(article, at: 0)
        
        // Trim to max
        if history.count > maxItems {
            history = Array(history.prefix(maxItems))
        }
        
        saveHistory()
    }
    
    @MainActor
    private func loadHistory() async {
        if let decoded = await StorageManager.shared.load(key: storageKey, as: [Article].self) {
            self.history = decoded
        }
    }
    
    private func saveHistory() {
        let copy = history
        Task {
            await StorageManager.shared.save(copy, key: storageKey)
        }
    }
}
