import Foundation
import Combine
internal import CoreLocation


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
        
        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "API key is missing."
            case .invalidURL: return "Invalid API configuration."
            case .networkError(let msg): return msg
            case .noData: return "No data received from the AI."
            }
        }
    }
    
    
    @MainActor
    func summarize(article: Article) async throws -> String {
        let result = try await generateFullInsight(article: article)
        return result.summaryPoints.map { "• \($0)" }.joined(separator: "\n")
    }
    
    @MainActor
    func generateFullInsight(article: Article) async throws -> Pulse360Analysis {
        if let cachedAnalysis = AIInsightStore.shared.getAnalysis(for: article.url) {
            print("--- Pulse AI Insight: Using persistent cache for \(article.title) ---")
            return cachedAnalysis
        }
        
        var localContext = ""
        let location = LocationManager.shared.overriddenLocation ?? LocationManager.shared.localArea ?? "their local area"
        
        let simulatedIndustry = "Technology and Finance" 
        
        if LocationManager.shared.overriddenLocation != nil || 
           LocationManager.shared.authorizationStatus == .authorizedWhenInUse || 
           LocationManager.shared.authorizationStatus == .authorizedAlways {
            localContext = """
            
            USER CONTEXT FOR HYPER-LOCAL IMPACT:
            - Location: \(location)
            - Industry/Interests: \(simulatedIndustry)
            
            When writing the `globalImpact` sentence, if this news has an indirect economic, social, or industrial impact on this specific user context, point it out. Make it personal to their location or industry.
            """
        }
        
        let prompt = """
        Analyze this article and provide a holistic briefing in STRICT JSON format.
        
        Article Title: \(article.title)
        Article Summary: \(article.summary)
        \(localContext)

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
            throw SummarizerError.networkError(error.localizedDescription)
        }
    }
}

