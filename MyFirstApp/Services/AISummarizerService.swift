import Foundation
import Combine
import SwiftUI

// MARK: - Gemini API Request/Response Models

struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let safetySettings: [GeminiSafetySetting]?
}

struct GeminiContent: Encodable {
    let parts: [GeminiPart]
}

struct GeminiPart: Encodable {
    let text: String
}

struct GeminiSafetySetting: Encodable {
    let category: String
    let threshold: String
}

struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
    let error: GeminiErrorResponse?
}

struct GeminiErrorResponse: Decodable {
    let code: Int?
    let message: String?
    let status: String?
}

struct GeminiCandidate: Decodable {
    let content: GeminiContentResponse?
    let finishReason: String?
}

struct GeminiContentResponse: Decodable {
    let parts: [GeminiPartResponse]?
}

struct GeminiPartResponse: Decodable {
    let text: String?
}

// MARK: - Service

class AISummarizerService: ObservableObject {
    static let shared = AISummarizerService()
    
    private var apiKey: String {
        AppConfig.geminiAPIKey
    }
    
    enum SummarizerError: Error, LocalizedError {
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
    }
    
    // MARK: - Public Interface
    
    @MainActor
    func summarize(article: Article) async throws -> String {
        let result = try await generateFullInsight(article: article)
        return result.summaryPoints.map { "• \($0)" }.joined(separator: "\n")
    }
    
    @MainActor
    func generateFullInsight(article: Article) async throws -> Pulse360Analysis {
        // 1. HARD PERSISTENCE CACHE
        if let cachedAnalysis = AIInsightStore.shared.getAnalysis(for: article.url) {
            print("--- Pulse AI Insight: Using persistent cache for \(article.title) ---")
            return cachedAnalysis
        }
        
        let prompt = """
        Analyze this article and provide a holistic briefing in STRICT JSON format.
        
        Article Title: \(article.title)
        Article Summary: \(article.summary)

        Required JSON structure:
        - summaryPoints: (array of 3 strings)
        - sentimentScore: (-1.0 to 1.0)
        - biasScore: (-1.0 to 1.0)
        - analyticalTone: (string)
        - theOtherSide: (1-sentence counter-perspective)
        - globalImpact: (1-sentence impact)

        Return ONLY the JSON.
        """
        
        do {
            let rawResponse = try await NewsSummaryCoordinator.shared.generateInsight(prompt: prompt)
            
            let analysis = try await Task.detached(priority: .userInitiated) {
                let cleanedJSON = rawResponse
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard let data = cleanedJSON.data(using: .utf8) else {
                    throw SummarizerError.noData
                }
                
                return try JSONDecoder().decode(Pulse360Analysis.self, from: data)
            }.value
            
            AIInsightStore.shared.saveInsight(article: article, analysis: analysis)
            return analysis
        } catch {
            print("--- Pulse AI Insight: All engines failed or formatting error. Error: \(error.localizedDescription) ---")
            // Throw generic error if network failed for all
            throw SummarizerError.networkError(error.localizedDescription)
        }
    }
}
