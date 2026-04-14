import Foundation
import AVFoundation
import ActivityKit
internal import SwiftUI
import Combine

class AudioBriefingService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = AudioBriefingService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    @Published var isPlaying = false
    @Published var currentlyReadingArticleID: String? = nil
    @Published var selectedPersona: AudioPersona = AudioPersona.available[0]
    
    // Live Activity Management
    private var currentActivity: Activity<BriefingActivityAttributes>?
    private var progressUpdateTimer: Timer?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(article: Article, summary: String) {
        if isPlaying && currentlyReadingArticleID == article.id {
            stop()
            return
        }
        
        if isPlaying {
            stop()
        }
        
        let utteranceText = prepareText(article: article, summary: summary)
        let utterance = AVSpeechUtterance(string: utteranceText)
        
        // Dynamic Voice Selection based on Persona
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let voice = voices.first(where: { 
            $0.language == selectedPersona.languageCode && 
            ($0.identifier.contains(selectedPersona.id) || $0.name.lowercased().contains(selectedPersona.id))
        }) ?? voices.first(where: { $0.language == selectedPersona.languageCode })
           ?? AVSpeechSynthesisVoice(language: "en-US")
        
        utterance.voice = voice
        // Slower speech rate for better comprehension during news briefings
        utterance.rate = selectedPersona.id == "daniel" ? 0.48 : 0.45
        utterance.pitchMultiplier = 0.95
        utterance.postUtteranceDelay = 0.5
        
        currentlyReadingArticleID = article.id
        isPlaying = true
        
        HapticManager.shared.trigger(.soft)
        
        // Start Live Activity
        startActivity(for: article, summary: summary)
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        currentlyReadingArticleID = nil
        endActivity()
    }
    
    private func prepareText(article: Article, summary: String) -> String {
        let cleanSummary = summary.replacingOccurrences(of: "*", with: "")
        return """
        Pulse AI Insight for \(article.title). 
        Here are the key highlights. 
        \(cleanSummary). 
        End of briefing.
        """
    }
    
    // MARK: - Live Activity Logic
    
    private func startActivity(for article: Article, summary: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = BriefingActivityAttributes(
            articleTitle: article.title,
            newsSource: article.newsSite
        )
        
        // Parse summary into bullet points for the UI
        let points = summary.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .init(charactersIn: "*•- ")) }
            .filter { !$0.isEmpty }
        
        let initialContentState = BriefingActivityAttributes.ContentState(
            summaryPoints: points,
            progress: 0.0
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: nil
            )
            
            // Start simulation timer for progress
            var currentProgress = 0.0
            progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                currentProgress += 0.05
                if currentProgress > 1.0 { currentProgress = 1.0 }
                
                Task {
                    let updatedState = BriefingActivityAttributes.ContentState(
                        summaryPoints: points,
                        progress: currentProgress
                    )
                    await self.currentActivity?.update(.init(state: updatedState, staleDate: nil))
                }
            }
        } catch {
            print("--- Live Activity Error: \(error.localizedDescription) ---")
        }
    }
    
    private func endActivity() {
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
        
        Task {
            await currentActivity?.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
    
    // MARK: - Delegate Actions
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.stop()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechBoundary characterRange: NSRange, utterance: AVSpeechUtterance) {
        if characterRange.location % 40 == 0 {
            DispatchQueue.main.async {
                HapticManager.shared.trigger(.light)
            }
        }
    }
}
