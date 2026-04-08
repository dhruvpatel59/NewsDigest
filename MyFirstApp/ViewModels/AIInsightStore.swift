import Foundation
import Combine

// MARK: - AI Insight Model
struct AIInsightEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let article: Article
    let summary: String
    let analysis: Pulse360Analysis? // Persistent analytical data
    let generatedAt: Date
    
    // For easy deduplication
    var normalizedURL: String {
        article.url.components(separatedBy: "?").first ?? article.url
    }
}

// MARK: - AI Insight Store
class AIInsightStore: ObservableObject {
    static let shared = AIInsightStore()
    
    @Published var entries: [AIInsightEntry] = [] {
        didSet {
            save()
        }
    }
    
    private let storageKey = "Pulse_AI_Insight_Vault_v2" 
    
    init() {
        Task {
            await load()
        }
    }
    
    // MARK: - API
    
    func saveInsight(article: Article, analysis: Pulse360Analysis) {
        let cleanURL = article.url.components(separatedBy: "?").first ?? article.url
        
        // Prevent duplicates
        if let index = entries.firstIndex(where: { $0.normalizedURL == cleanURL }) {
            entries.remove(at: index)
        }
        
        // Convert analysis points back to legacy summary string for compatibility
        let summaryString = analysis.summaryPoints.map { "• \($0)" }.joined(separator: "\n")
        
        let newEntry = AIInsightEntry(
            id: UUID(),
            article: article,
            summary: summaryString,
            analysis: analysis,
            generatedAt: Date()
        )
        
        entries.insert(newEntry, at: 0) // Newest first
    }
    
    func deleteInsight(id: UUID) {
        entries.removeAll { $0.id == id }
    }
    
    func getAnalysis(for url: String) -> Pulse360Analysis? {
        let cleanURL = url.components(separatedBy: "?").first ?? url
        return entries.first(where: { $0.normalizedURL == cleanURL })?.analysis
    }
    
    // MARK: - Persistence
    
    private func save() {
        let copy = entries
        Task {
            await StorageManager.shared.save(copy, key: storageKey)
        }
    }
    
    @MainActor
    private func load() async {
        if let decoded = await StorageManager.shared.load(key: storageKey, as: [AIInsightEntry].self) {
            self.entries = decoded
        }
    }
}
