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
        
        guard !apiKey.isEmpty else {
            throw SummarizerError.missingAPIKey
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
        
        // Comprehensive Model List from your AI Studio Dashboard
        // Priority: High Quota (3.1/2.0) -> Stable (1.5)
        let models = [
            "gemini-3.1-flash-lite",
            "gemini-3.0-flash",
            "gemini-2.0-flash",
            "gemini-1.5-flash",
            "gemini-3.1-pro",
            "gemini-1.5-pro"
        ]
        
        var lastError: Error?
        
        for model in models {
            do {
                print("--- Pulse AI Insight: Attempting with \(model) ---")
                
                // CRITICAL FIX: Attempt both v1beta AND v1 to solve 404 errors automatically
                let rawResponse = try await attemptCallWithVersionRotation(prompt: prompt, model: model)
                
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
                lastError = error
                print("--- Pulse AI Insight: \(model) failed. Error: \(error.localizedDescription) ---")
                
                // Corner Case: If we hit a 429 (Rate Limit) or 503 (Overload), pause 2s
                if let sumError = error as? SummarizerError, case .networkError(let msg) = sumError {
                    if msg.contains("429") || msg.contains("503") {
                        print("--- Pulse AI: Throttled. Pausing 2s... ---")
                        try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                    }
                }
                continue
            }
        }
        
        throw lastError ?? SummarizerError.noData
    }
    
    // MARK: - API Versatility Logic (Solves 404 Errors)
    
    private func attemptCallWithVersionRotation(prompt: String, model: String) async throws -> String {
        // Try v1beta first (newer models live here)
        do {
            return try await callGemini(prompt: prompt, model: model, version: "v1beta")
        } catch let error as SummarizerError {
            // If v1beta returns 404, we immediately rotate to stable v1
            if error.is404 {
                print("--- Pulse AI: 404 on v1beta for \(model). Retrying on v1... ---")
                return try await callGemini(prompt: prompt, model: model, version: "v1")
            }
            throw error
        } catch {
            throw error
        }
    }
    
    private func callGemini(prompt: String, model: String, version: String) async throws -> String {
        let endpointString = "https://generativelanguage.googleapis.com/\(version)/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: endpointString) else {
            throw SummarizerError.invalidURL
        }
        
        let requestBody = GeminiRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: prompt)])],
            safetySettings: [
                GeminiSafetySetting(category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE")
            ]
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SummarizerError.networkError("Connection failed.")
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            if httpResponse.statusCode == 404 {
                throw SummarizerError.networkError("404")
            }
            throw SummarizerError.networkError("Error \(httpResponse.statusCode): \(errorMsg)")
        }
        
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        if let text = decoded.candidates?.first?.content?.parts?.first?.text {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            throw SummarizerError.noData
        }
    }
}

extension AISummarizerService.SummarizerError {
    var is404: Bool {
        if case .networkError(let msg) = self { return msg == "404" }
        return false
    }
}
