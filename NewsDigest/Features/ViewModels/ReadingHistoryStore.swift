import Foundation
import Combine
internal import SwiftUI

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
        history.removeAll(where: { $0.id == article.id })
        
        history.insert(article, at: 0)
        
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

