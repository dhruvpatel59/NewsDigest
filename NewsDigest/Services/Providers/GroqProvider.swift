import Foundation

struct GroqRequest: Encodable {
    let model: String
    let messages: [GroqMessage]
}

struct GroqMessage: Encodable {
    let role: String
    let content: String
}

struct GroqResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

class GroqProvider: SummaryProvider {
    private var apiKey: String { AppConfig.groqAPIKey }
    private let endpoint = "https://api.groq.com/openai/v1/chat/completions"
    private let model = "llama-3.1-8b-instant"
    
    func generateInsight(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else { throw SummaryProviderError.missingAPIKey }
        guard let url = URL(string: endpoint) else { throw SummaryProviderError.invalidURL }
        
        print("--- Pulse AI Insight: Failover to Groq (\(model)) ---")
        
        let requestBody = GroqRequest(
            model: model,
            messages: [
                GroqMessage(role: "system", content: """
                You are a Senior Editorial Analyst for Pulse News AI. 
                Your goal is to transform basic news summaries into deep, narrative insights.
                - Each summary point should be descriptive (15-25 words).
                - Capture specific names, numbers, or emotional context.
                - Avoid generic phrases like "Microsoft is working on an agent."
                - Instead, explain the technical 'why' and the specific customer impact.
                - Ensure the tone is analytical yet engaging.
                """),
                GroqMessage(role: "user", content: prompt)
            ]
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SummaryProviderError.networkError("Connection failed.")
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw SummaryProviderError.networkError("Groq Error \(httpResponse.statusCode): \(errorMsg)")
        }
        
        let decoded = try JSONDecoder().decode(GroqResponse.self, from: data)
        if let text = decoded.choices.first?.message.content {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            throw SummaryProviderError.noData
        }
    }
}

