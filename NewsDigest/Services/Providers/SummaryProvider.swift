import Foundation

protocol SummaryProvider {
    func generateInsight(prompt: String) async throws -> String
}

enum SummaryProviderError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case networkError(String)
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "API key is missing."
        case .invalidURL: return "Invalid API configuration."
        case .networkError(let msg): return msg
        case .noData: return "No data received from the AI."
        case .decodingError: return "Failed to parse the summary."
        }
    }
    
    var is429: Bool {
        if case .networkError(let msg) = self { return msg.contains("429") }
        return false
    }
}

