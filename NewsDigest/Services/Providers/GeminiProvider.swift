import Foundation


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

class GeminiProvider: SummaryProvider {
    private var apiKey: String { AppConfig.geminiAPIKey }
    
    private let models = [
        "gemini-2.0-flash-lite",
        "gemini-flash-latest",
        "gemini-2.0-flash",
        "gemini-pro-latest",
        "gemini-2.5-flash"
    ]
    
    func generateInsight(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else { throw SummaryProviderError.missingAPIKey }
        var lastError: Error?
        
        for model in models {
            do {
                print("--- Pulse AI Insight: Attempting Gemini with \(model) ---")
                return try await attemptCallWithVersionRotation(prompt: prompt, model: model)
            } catch {
                lastError = error
                print("--- Pulse AI Insight: \(model) failed. Error: \(error.localizedDescription) ---")
                
                if let sumError = error as? SummaryProviderError, sumError.is429 {
                    throw sumError // Let Coordinator handle 429 Failover immediately
                }
                continue
            }
        }
        throw lastError ?? SummaryProviderError.noData
    }
    
    private func attemptCallWithVersionRotation(prompt: String, model: String) async throws -> String {
        do {
            return try await callGemini(prompt: prompt, model: model, version: "v1beta")
        } catch let error as SummaryProviderError {
            if case .networkError(let msg) = error, msg == "404" {
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
        guard let url = URL(string: endpointString) else { throw SummaryProviderError.invalidURL }
        
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
            throw SummaryProviderError.networkError("Connection failed.")
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            if httpResponse.statusCode == 404 { throw SummaryProviderError.networkError("404") }
            throw SummaryProviderError.networkError("Error \(httpResponse.statusCode): \(errorMsg)")
        }
        
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        if let text = decoded.candidates?.first?.content?.parts?.first?.text {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            throw SummaryProviderError.noData
        }
    }
}

