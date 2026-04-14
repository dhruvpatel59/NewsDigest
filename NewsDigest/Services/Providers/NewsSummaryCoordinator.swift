import Foundation

class NewsSummaryCoordinator {
    static let shared = NewsSummaryCoordinator()
    
    private let primaryProvider: SummaryProvider = GeminiProvider()
    private let backupProvider: SummaryProvider = GroqProvider()
    
    func generateInsight(prompt: String) async throws -> String {
        do {
            // Attempt with Primary (Gemini)
            return try await primaryProvider.generateInsight(prompt: prompt)
        } catch let primaryError {
            // Check if we should failover
            let isFailoverEligible: Bool = {
                if let sumError = primaryError as? SummaryProviderError {
                    return sumError.is429
                }
                let nsError = primaryError as NSError
                // Timeout or network connection lost
                if nsError.domain == NSURLErrorDomain && [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost].contains(nsError.code) {
                    return true
                }
                return false
            }()
            
            if isFailoverEligible {
                print("--- Pulse AI Insight: Primary engine failed with 429/Timeout. Initiating seamless failover... ---")
                do {
                    return try await backupProvider.generateInsight(prompt: prompt)
                } catch let backupError {
                    print("--- Pulse AI Insight: Backup engine also failed. Error: \(backupError.localizedDescription) ---")
                    throw primaryError // Throw the original error or a merged error for the UI
                }
            } else {
                throw primaryError
            }
        }
    }
}
