import Foundation
import SwiftUI

struct Pulse360Analysis: Codable, Hashable {
    let summaryPoints: [String]
    let sentimentScore: Double // -1.0 (Negative) to 1.0 (Positive)
    let biasScore: Double      // -1.0 (Critical/Alternative) to 1.0 (Mainstream/Corporate)
    let analyticalTone: String // e.g., "Objective", "Sensationalist", "Analytical"
    let theOtherSide: String   // A concise counter-perspective
    let globalImpact: String   // 1-sentence on why this matters globally
    
    // UI Helpers
    var sentimentColor: Color {
        if sentimentScore > 0.3 { return .green }
        if sentimentScore < -0.3 { return .red }
        return .blue
    }
    
    var biasDescription: String {
        if biasScore > 0.5 { return "Mainstream Leaning" }
        if biasScore < -0.5 { return "Alternative Perspective" }
        return "Balanced Viewpoint"
    }
}
